import 'dart:convert';
import 'dart:io';

import 'package:espanol_pro/core/assessment/assessment_engine.dart';
import 'package:espanol_pro/core/assessment/assessment_repository.dart';
import 'package:espanol_pro/core/content/content_parser.dart';
import 'package:espanol_pro/core/content/content_validator.dart';
import 'package:espanol_pro/core/content/models.dart';
import 'package:espanol_pro/core/learning/answer_evaluator.dart';
import 'package:espanol_pro/core/learning/exercises.dart';
import 'package:espanol_pro/core/learning/progress_repository.dart';
import 'package:espanol_pro/core/srs/review_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fsrs/fsrs.dart' as fsrs;
import 'package:material_ui/material_ui.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;

import 'support.dart';
import 'widget_support.dart';

/// Owner-approved B1 features (PHASE4-003): written accents count from B1
/// on, and B1+ activities may give a Spanish instruction with the Arabic
/// one a tap away. A1 / A2 grading and prompts are unchanged.
void main() {
  late ContentPack pack;
  setUpAll(() async {
    pack = await loadRealContent();
    await loadAppFonts();
    tzdata.initializeTimeZones();
  });

  /// The real content with [edit] applied to one JSON file.
  Future<ContentPack> packWith(
    String file,
    void Function(Map<String, dynamic> doc) edit,
  ) => parseContentPack((path) async {
    final text = await File('$contentDir/$path').readAsString();
    if (path != file) return text;
    final doc = jsonDecode(text) as Map<String, dynamic>;
    edit(doc);
    return jsonEncode(doc);
  });

  Map<String, dynamic> lessonOf(Map<String, dynamic> unit, String id) =>
      (unit['lessons'] as List).cast<Map<String, dynamic>>().firstWhere(
        (l) => l['id'] == id,
      );

  group('strict accents from B1', () {
    test('the levels: lenient through A2, strict from B1 on', () {
      for (final l in pack.levels) {
        final b1OrAbove = cefrOrder.indexOf(l.id) >= cefrOrder.indexOf('b1');
        expect(l.strictAccents, b1OrAbove, reason: l.id);
        expect(l.spanishPrompts, b1OrAbove, reason: l.id);
      }
    });

    test('the evaluator: accents count only in strict mode; ñ and meaning '
        'accents count everywhere', () {
      const accepted = ['me gustaría cambiar la fecha'];
      final lenient = evaluateAnswer('me gustaria cambiar la fecha', accepted);
      expect(lenient.isCorrect, isTrue);
      expect(lenient.verdict, AnswerVerdict.correctMissingAccents);
      final strict = evaluateAnswer(
        'me gustaria cambiar la fecha',
        accepted,
        strictAccents: true,
      );
      expect(strict.isCorrect, isFalse);
      expect(strict.issue, AnswerIssue.accents);
      expect(strict.bestMatch, accepted.first);
      expect(strict.explanationAr, contains('من مستوى B1'));
      expect(strict.explanationAr, contains('me gustaría cambiar la fecha'));
      // An exact answer stays correct, with or without capitals and
      // punctuation.
      expect(
        evaluateAnswer(
          '¡Me gustaría cambiar la fecha!',
          accepted,
          strictAccents: true,
        ).verdict,
        AnswerVerdict.correct,
      );
      for (final strictMode in [false, true]) {
        expect(
          evaluateAnswer('esta cerca', const [
            'está cerca',
          ], strictAccents: strictMode).issue,
          AnswerIssue.accentMeaning,
        );
        expect(
          evaluateAnswer('el ano pasado', const [
            'el año pasado',
          ], strictAccents: strictMode).issue,
          AnswerIssue.enye,
        );
      }
    });

    test('every B1 typed exercise is strict, every A2 one is not', () {
      final builder = ExerciseBuilder(pack);
      List<TypeExercise> typed(String levelId) => [
        for (final l in pack.orderedLessons.where((l) => l.levelId == levelId))
          ...builder.buildLesson(l).whereType<TypeExercise>(),
      ];
      expect(typed('b1'), isNotEmpty);
      expect(typed('b1').every((e) => e.strictAccents), isTrue);
      expect(typed('a2').any((e) => e.strictAccents), isFalse);
      // Practice and dialogue dictation follow the item's / dialogue's level.
      final b1Items = pack.unit('b1_u1')!.lessons.expand((l) => l.items);
      final practice = builder
          .buildPractice(mode: 'writing', items: b1Items.toList(), salt: 's')
          .whereType<TypeExercise>();
      expect(practice.every((e) => e.strictAccents), isTrue);
      for (final d in pack.dialogues.where(
        (d) => d.levelId == 'b1' || d.levelId == 'a2',
      )) {
        for (final e
            in builder.buildDialogueQuestions(d).whereType<TypeExercise>()) {
          expect(e.strictAccents, d.levelId == 'b1', reason: e.id);
        }
      }
    });

    test('checkpoints: a B1 typed answer missing an accent is wrong, an A2 '
        'one keeps the reminder; the outcome is stored either way', () {
      final chk = pack.assessment('chk_b1_u1')!;
      final answers = {
        for (final q in chk.questions) q.id: q.correctAnswer,
        'chk_b1_u1.q12': 'me gustaria cambiar la fecha',
      };
      GradedAnswer q12(bool strict) => gradeAssessment(
        chk,
        answers,
        strictAccents: strict,
      ).firstWhere((g) => g.question.id == 'chk_b1_u1.q12');
      expect(q12(true).isCorrect, isFalse);
      expect(q12(true).spelling, Spelling.missingAccents);
      expect(q12(false).isCorrect, isTrue);
      expect(
        Spelling.labelAr(Spelling.missingAccents, correct: false),
        contains('B1'),
      );
      expect(
        Spelling.labelAr(Spelling.missingAccents),
        'المعنى صحيح، لكن علامات النبر ناقصة',
      );
      // The A2 checkpoint is graded as before.
      final a2 = pack.assessment('chk_a2_u5')!;
      final g = gradeAssessment(a2, {
        for (final q in a2.questions) q.id: q.correctAnswer,
        'chk_a2_u5.q8': 'el correo electronico',
      }).firstWhere((g) => g.question.id == 'chk_a2_u5.q8');
      expect(g.isCorrect, isTrue);
      expect(g.spelling, Spelling.missingAccents);
    });

    test('the validator keeps the flags on once they start', () async {
      final broken = await packWith('curriculum.json', (doc) {
        (doc['levels'] as List).cast<Map<String, dynamic>>().firstWhere(
          (l) => l['id'] == 'c1',
        )['strict_accents'] = false;
      });
      expect(
        ContentValidator().validate(broken).map((i) => '$i'),
        contains(contains('strict_accents must stay on after it starts')),
      );
    });
  });

  group('Spanish-first prompts', () {
    const promptEs = '¿Por qué prefiere Marta la oferta de Sol?';
    // Built outside testWidgets: real file I/O never completes inside its
    // fake-async zone.
    late ContentPack promptPack;

    Future<ContentPack> withB1Prompt() => packWith('units/b1_u1.json', (doc) {
      final acts = (lessonOf(doc, 'b1_u1_l1')['activities'] as List)
          .cast<Map<String, dynamic>>();
      acts.firstWhere(
        (a) => a['type'] == 'choice' && a['skill'] == 'reading',
      )['prompt_es'] = promptEs;
    });

    setUpAll(() async => promptPack = await withB1Prompt());

    test('a B1 prompt_es is valid and reaches the exercise', () async {
      final p = promptPack;
      expect(ContentValidator().validate(p), isEmpty);
      final steps = ExerciseBuilder(p).buildLesson(p.lesson('b1_u1_l1')!);
      final withEs = steps.whereType<ChoiceExercise>().where(
        (e) => e.promptEs != null,
      );
      expect(withEs.single.promptEs, promptEs);
      // The Arabic instruction is still there.
      expect(withEs.single.promptAr, isNotEmpty);
    });

    test('the validator rejects prompt_es below B1, in Arabic, or on another '
        'activity type', () async {
      Future<List<String>> issues(
        String file,
        void Function(Map<String, dynamic>) edit,
      ) async => ContentValidator()
          .validate(await packWith(file, edit))
          .map((i) => '$i')
          .toList();

      final belowB1 = await issues('units/a2_u5.json', (doc) {
        (lessonOf(doc, 'a2_u5_l1')['activities'] as List)
                .cast<Map<String, dynamic>>()
                .firstWhere((a) => a['type'] == 'choice')['prompt_es'] =
            promptEs;
      });
      expect(
        belowB1,
        contains(contains('prompt_es needs a level with spanish_prompts')),
      );
      // Even if such content slipped through, an A2 exercise stays Arabic.
      final a2 = await packWith('units/a2_u5.json', (doc) {
        (lessonOf(doc, 'a2_u5_l1')['activities'] as List)
                .cast<Map<String, dynamic>>()
                .firstWhere((a) => a['type'] == 'choice')['prompt_es'] =
            promptEs;
      });
      expect(
        ExerciseBuilder(a2)
            .buildLesson(a2.lesson('a2_u5_l1')!)
            .whereType<Exercise>()
            .any((e) => e.promptEs != null),
        isFalse,
      );

      final arabic = await issues('units/b1_u1.json', (doc) {
        (lessonOf(doc, 'b1_u1_l1')['activities'] as List)
                .cast<Map<String, dynamic>>()
                .firstWhere((a) => a['type'] == 'choice')['prompt_es'] =
            'اختر الكلمة';
      });
      expect(arabic, contains(contains('prompt_es contains Arabic script')));

      final wrongType = await issues('units/b1_u1.json', (doc) {
        (lessonOf(doc, 'b1_u1_l1')['activities'] as List)
                .cast<Map<String, dynamic>>()
                .firstWhere((a) => a['type'] == 'type_es')['prompt_es'] =
            promptEs;
      });
      expect(
        wrongType,
        contains(contains('prompt_es is only for choice and respond')),
      );

      final unbalanced = await issues('units/b1_u1.json', (doc) {
        (lessonOf(doc, 'b1_u1_l1')['activities'] as List)
                .cast<Map<String, dynamic>>()
                .firstWhere((a) => a['type'] == 'choice')['prompt_es'] =
            'Por qué prefiere Marta?';
      });
      expect(unbalanced, isNotEmpty);
    });

    testWidgets('the lesson shows the Spanish prompt first and the Arabic on '
        'demand', (tester) async {
      final p = promptPack;
      final app = TestApp(p);
      await passA2AndCompleteBefore(app, p, 'b1_u1_l1');
      final lesson = p.lesson('b1_u1_l1')!;
      final steps = ExerciseBuilder(p).buildLesson(lesson);
      await app.pump(tester, location: '/lesson/${lesson.id}');
      await tester.tapKey('start-lesson');
      var i = 0;
      while (!(steps[i] is ChoiceExercise &&
          (steps[i] as ChoiceExercise).promptEs != null)) {
        await tester.answer(steps[i++]);
      }
      final target = steps[i] as ChoiceExercise;
      expect(find.byKey(const ValueKey('prompt-es')), findsOneWidget);
      expect(find.text(promptEs), findsOneWidget);
      expect(find.text(target.promptAr), findsNothing);
      await tester.tapKey('prompt-show-ar');
      expect(find.text(target.promptAr), findsOneWidget);
      // Steps without prompt_es stay Arabic-only.
      await tester.answer(target);
      expect(find.byKey(const ValueKey('prompt-show-ar')), findsNothing);
      await app.dispose(tester);
    });
  });

  group('typed answers in the app', () {
    Future<void> runUntilTyped(
      WidgetTester tester,
      TestApp app,
      Lesson lesson,
      void Function(TypeExercise) onTyped,
    ) async {
      final steps = ExerciseBuilder(app.pack).buildLesson(lesson);
      await app.pump(tester, location: '/lesson/${lesson.id}');
      await tester.tapKey('start-lesson');
      var i = 0;
      while (!(steps[i] is TypeExercise &&
          stripAccents((steps[i] as TypeExercise).accepted.first) !=
              (steps[i] as TypeExercise).accepted.first)) {
        await tester.answer(steps[i++]);
      }
      onTyped(steps[i] as TypeExercise);
    }

    testWidgets('a B1 lesson marks a missing accent wrong and explains it', (
      tester,
    ) async {
      final app = TestApp(pack);
      await passA2AndCompleteBefore(app, pack, 'b1_u1_l3');
      late TypeExercise ex;
      await runUntilTyped(tester, app, pack.lesson('b1_u1_l3')!, (e) => ex = e);
      await tester.enterText(
        find.byKey(const ValueKey('answer-field')),
        stripAccents(ex.accepted.first),
      );
      await tester.pumpAndSettle();
      await tester.tapSettled(find.text('تحقّق'));
      expect(
        find.textContaining('من مستوى B1 تُحسب علامات النبر'),
        findsWidgets,
      );
      final attempt = (await app.db.select(app.db.activityAttempts).get())
          .lastWhere((a) => a.activityId == ex.id);
      expect(attempt.isCorrect, isFalse);
      await app.dispose(tester);
    });

    testWidgets('the same slip in an A2 lesson is still accepted with a '
        'reminder', (tester) async {
      final app = TestApp(pack);
      await passA2AndCompleteBefore(app, pack, 'a2_u5_l1', passTest: false);
      late TypeExercise ex;
      await runUntilTyped(tester, app, pack.lesson('a2_u5_l1')!, (e) => ex = e);
      await tester.enterText(
        find.byKey(const ValueKey('answer-field')),
        stripAccents(ex.accepted.first),
      );
      await tester.pumpAndSettle();
      await tester.tapSettled(find.text('تحقّق'));
      expect(find.textContaining('المعنى صحيح'), findsWidgets);
      final attempt = (await app.db.select(app.db.activityAttempts).get())
          .lastWhere((a) => a.activityId == ex.id);
      expect(attempt.isCorrect, isTrue);
      await app.dispose(tester);
    });

    testWidgets('a B1 production review card without accents can only be '
        '"Again"', (tester) async {
      final app = TestApp(pack);
      final reviews = ReviewRepository(
        app.db,
        clock: app.clock.call,
        enableFuzzing: false,
      );
      await ProgressRepository(
        app.db,
        reviews,
        clock: app.clock.call,
      ).completeLesson(
        pack.lesson('b1_u1_l3')!,
        score: 1,
        seconds: 60,
        contentVersion: pack.version,
      );
      for (final c in await reviews.dueCards()) {
        await reviews.rate(c.id, fsrs.Rating.easy);
      }
      app.clock.advance(const Duration(days: 1, minutes: 1));
      await app.pump(tester, location: '/review');
      expect(find.text('استدعاء نشط: اكتب بالإسبانية'), findsOneWidget);
      final item = pack.item((await reviews.dueCards()).first.itemId)!;
      // Every B1-U1 lesson 3 phrase carries a written accent.
      expect(stripAccents(item.es), isNot(item.es));
      await tester.enterText(
        find.byKey(const ValueKey('review-answer')),
        stripAccents(item.es),
      );
      await tester.tapKey('review-check');
      expect(find.textContaining('من مستوى B1'), findsOneWidget);
      expect(find.byKey(const ValueKey('rate-again')), findsOneWidget);
      expect(find.byKey(const ValueKey('rate-good')), findsNothing);
      await app.dispose(tester);
    });
  });
}

/// Completes every lesson before [lessonId] and, unless [passTest] is
/// false, stores a passing lvl_a2 attempt (B1 is gated on it).
Future<void> passA2AndCompleteBefore(
  TestApp app,
  ContentPack pack,
  String lessonId, {
  bool passTest = true,
}) async {
  final repo = ProgressRepository(
    app.db,
    ReviewRepository(app.db, clock: app.clock.call, enableFuzzing: false),
    clock: app.clock.call,
  );
  for (final l in pack.orderedLessons) {
    if (l.id == lessonId) break;
    await repo.completeLesson(
      l,
      score: 1,
      seconds: 60,
      contentVersion: pack.version,
    );
  }
  if (!passTest) return;
  final lvl = pack.levelAssessmentFor('a2')!;
  await AssessmentRepository(app.db, clock: app.clock.call).submit(
    assessment: lvl,
    graded: gradeAssessment(lvl, {
      for (final q in lvl.questions) q.id: q.correctAnswer,
    }),
    startedAt: app.clock(),
    contentVersion: pack.version,
  );
}

import 'package:espanol_pro/core/assessment/assessment_engine.dart';
import 'package:espanol_pro/core/assessment/assessment_repository.dart';
import 'package:espanol_pro/core/content/content_validator.dart';
import 'package:espanol_pro/core/content/models.dart';
import 'package:espanol_pro/core/learning/answer_evaluator.dart';
import 'package:espanol_pro/core/learning/difficulty.dart';
import 'package:espanol_pro/core/learning/exercises.dart';
import 'package:espanol_pro/core/learning/progress_repository.dart';
import 'package:espanol_pro/core/srs/review_repository.dart';
import 'package:espanol_pro/features/library/verbs_view.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;

import 'support.dart';
import 'widget_support.dart';

/// B1-U2 — narration: imperfecto, its contrast with the indefinido, a
/// professional story, and the longer reading and listening lesson (owner
/// decision after PHASE4-002).
void main() {
  late ContentPack pack;
  setUpAll(() async {
    pack = await loadRealContent();
    await loadAppFonts();
    tzdata.initializeTimeZones();
  });

  Unit unit() => pack.unit('b1_u2')!;

  group('curriculum', () {
    test('six lessons after B1-U1, each building on the previous one', () {
      expect(unit().lessons.map((l) => l.id), [
        for (var i = 1; i <= 6; i++) 'b1_u2_l$i',
      ]);
      expect(unit().lessons.first.prerequisites, ['b1_u1_l5']);
      for (var i = 1; i < unit().lessons.length; i++) {
        expect(unit().lessons[i].prerequisites, [unit().lessons[i - 1].id]);
      }
      final b1 = pack.levels.firstWhere((l) => l.id == 'b1');
      expect(b1.units.map((u) => u.id).take(2), ['b1_u1', 'b1_u2']);
      expect(b1.units[1].isAvailable, isTrue);
      expect(ContentValidator().validate(pack), isEmpty);
    });

    test('every lesson practises every skill and explains wrong answers', () {
      for (final l in unit().lessons) {
        final types = l.activities.map((a) => a.type).toSet();
        expect(
          types,
          containsAll([
            'listen_choose',
            'listen_pick_es',
            'type_es',
            'order',
            'dictation',
            'fill',
            'respond',
            'choice',
            'speak',
            'match',
          ]),
          reason: l.id,
        );
        expect(l.items.length, inInclusiveRange(7, 10), reason: l.id);
        expect(l.items.where((i) => i.work), isNotEmpty, reason: l.id);
        for (final a in l.activities.where(
          (a) => a.type == 'fill' || a.data['skill'] == 'grammar',
        )) {
          expect(a.data['explain_ar'], isNotEmpty, reason: a.id);
        }
        for (final a in l.activities.where((a) => a.type == 'fill')) {
          final options = (a.data['options'] as List).cast<String>();
          expect(options, hasLength(3), reason: a.id);
          expect(options.first, a.data['answer'], reason: a.id);
        }
      }
    });

    test('no subjunctive before B1-U3', () {
      final banned = RegExp(
        r'\b(no creo que|para que|ojalá|es importante que|gustaría que|'
        r'sería mejor que|quiero que|espero que)\b',
      );
      final texts = <String, String>{};
      for (final l in unit().lessons) {
        for (final i in l.items) {
          texts[i.id] = i.es;
          for (final e in i.examples) {
            texts['${i.id} ex'] = e.es;
          }
        }
        for (final a in l.activities) {
          for (final k in ['es', 'stimulus_es', 'audio_es']) {
            if (a.data[k] is String) texts['${a.id} $k'] = a.data[k] as String;
          }
        }
      }
      for (final d in pack.dialogues.where((d) => d.unitId == 'b1_u2')) {
        for (final t in d.turns) {
          texts[t.id] = t.es;
        }
      }
      for (final e in texts.entries) {
        expect(banned.hasMatch(e.value.toLowerCase()), isFalse, reason: e.key);
      }
    });
  });

  test('aspect cues are taught as common patterns, not absolute rules '
      '(REVIEW-020 P3)', () {
    final note = unit().grammar.firstWhere((g) => g.id == 'g_b1_past_contrast');
    expect(note.bodyAr, isNot(contains('قواعد ثابتة')));
    expect(note.bodyAr, contains('أنماط شائعة'));
    expect(note.bodyAr, contains('السياق'));
    // A habitual counter-example is part of the note.
    expect(note.bodyAr, contains('sonaba'));
  });

  group('longer reading and listening (lesson 6)', () {
    test('one long reading text with four questions, and a 12-turn '
        'listening', () {
      final l6 = pack.lesson('b1_u2_l6')!;
      final reading = [
        for (final a in l6.activities)
          if (a.type == 'choice' && a.data['skill'] == 'reading') a,
      ];
      expect(reading.length, greaterThanOrEqualTo(4));
      final text = reading.first.data['stimulus_es'] as String;
      expect(wordsOf(text).length, greaterThanOrEqualTo(120));
      expect(
        reading.every((a) => a.data['stimulus_es'] == text),
        isTrue,
        reason: 'all four questions are about the same text',
      );
      final long = pack.dialogue('dlg_b1_historia')!;
      expect(long.lessonIds, ['b1_u2_l6']);
      expect(long.turns.length, greaterThanOrEqualTo(12));
      expect(long.questions.length, greaterThanOrEqualTo(6));
      // Longer than every A2 dialogue.
      final a2Max = pack.dialogues
          .where((d) => d.levelId == 'a2')
          .map((d) => d.turns.length)
          .reduce((a, b) => a > b ? a : b);
      expect(long.turns.length, greaterThan(a2Max));
    });
  });

  group('Spanish-first prompts are in use', () {
    test('reading and listening choices carry prompt_es, and the builder '
        'passes it on', () {
      final builder = ExerciseBuilder(pack);
      for (final l in unit().lessons) {
        final withEs = builder
            .buildLesson(l)
            .whereType<ChoiceExercise>()
            .where((e) => e.promptEs != null)
            .toList();
        expect(withEs, isNotEmpty, reason: l.id);
        for (final e in withEs) {
          expect(e.promptAr, isNotEmpty, reason: e.id);
        }
      }
      final chk = pack.assessment('chk_b1_u2')!;
      expect(chk.questions.where((q) => q.promptEs != null), isNotEmpty);
      final dialogueEs = pack.dialogues
          .where((d) => d.unitId == 'b1_u2')
          .expand((d) => builder.buildDialogueQuestions(d))
          .where((e) => e.promptEs != null);
      expect(dialogueEs, isNotEmpty);
      // A1 / A2 never show one.
      for (final l in pack.orderedLessons.where(
        (l) => l.levelId == 'a1' || l.levelId == 'a2',
      )) {
        expect(
          builder
              .buildLesson(l)
              .whereType<Exercise>()
              .any((e) => e.promptEs != null),
          isFalse,
          reason: l.id,
        );
      }
    });
  });

  group('verbs: the imperfect', () {
    test(
      'every verb has six imperfect forms; only ser, ir and ver by hand',
      () {
        for (final v in pack.verbs) {
          expect(v.imperfect.keys, Verb.persons, reason: v.id);
          if (const {'ser', 'ir', 'ver'}.contains(v.id)) {
            expect(v.imperfectRegular, isFalse, reason: v.id);
          } else {
            expect(v.imperfectRegular, isTrue, reason: v.id);
            expect(
              v.imperfect,
              Verb.regularImperfect(v.infinitive),
              reason: v.id,
            );
          }
        }
        final byId = {for (final v in pack.verbs) v.id: v};
        expect(byId['ser']!.imperfect['nosotros'], 'éramos');
        expect(byId['ir']!.imperfect['yo'], 'iba');
        expect(byId['ver']!.imperfect['el'], 'veía');
        // Irregular in the present, regular in the imperfect.
        expect(byId['tener']!.imperfect['yo'], 'tenía');
        expect(byId['hacer']!.imperfect['el'], 'hacía');
        expect(byId['conseguir']!.forms['yo'], 'consigo');
        expect(byId['sonar']!.preterite['el'], 'sonó');
      },
    );

    testWidgets('the library shows the imperfect after the past', (
      tester,
    ) async {
      final app = TestApp(pack);
      await app.pump(tester, location: '/library');
      await tester.tapSettled(find.text('الأفعال'));
      final tile = find.byKey(const ValueKey('verb-ser'));
      await tester.scrollUntilVisible(
        tile,
        200,
        scrollable: find
            .descendant(
              of: find.byType(VerbsView),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.tapSettled(tile);
      expect(find.byKey(const ValueKey('verb-past-ser')), findsOneWidget);
      expect(find.byKey(const ValueKey('verb-imperfect-ser')), findsOneWidget);
      expect(
        tester
            .widget<Text>(
              find.descendant(
                of: find.byKey(const ValueKey('verb-imperfect-ser-nosotros')),
                matching: find.byType(Text),
              ),
            )
            .data,
        'éramos',
      );
      await app.dispose(tester);
    });
  });

  group('answer evaluation', () {
    test('a present or infinitive for the imperfect is a form mistake; a '
        'missing accent is wrong at B1', () {
      final form = evaluateAnswer('Antes trabajo en un banco', [
        'Antes trabajaba en un banco.',
      ]);
      expect(form.isCorrect, isFalse);
      expect(form.issue, AnswerIssue.grammarForm);
      expect(form.expectedWord, 'trabajaba');
      final accent = evaluateAnswer('habia mucho trabajo', const [
        'había mucho trabajo',
      ], strictAccents: true);
      expect(accent.isCorrect, isFalse);
      expect(accent.issue, AnswerIssue.accents);
    });
  });

  group('dialogues', () {
    test('four B1-U2 dialogues, understandable right after their lessons', () {
      final ds = pack.dialogues.where((d) => d.unitId == 'b1_u2').toList();
      expect(ds.map((d) => d.id), [
        'dlg_b1_antes',
        'dlg_b1_manana',
        'dlg_b1_entrevista',
        'dlg_b1_historia',
      ]);
      final order = [for (final l in pack.orderedLessons) l.id];
      for (final d in ds) {
        final last = d.lessonIds
            .map(order.indexOf)
            .reduce((a, b) => a > b ? a : b);
        final e = estimateDialogue(
          d,
          LearnerExposure.from(pack, order.take(last + 1)),
        );
        expect(
          e.band,
          isIn([DifficultyBand.veryEasy, DifficultyBand.appropriate]),
          reason: '${d.id}: ${e.reasonsAr}',
        );
        expect(e.coverage, greaterThanOrEqualTo(0.95), reason: d.id);
        expect(e.newGrammarIds, isEmpty, reason: d.id);
      }
    });
  });

  group('checkpoint chk_b1_u2', () {
    late Assessment chk;
    setUp(() => chk = pack.assessment('chk_b1_u2')!);

    test('12 questions, three can-dos, five skills, dialogue sentences', () {
      expect(chk.unitId, 'b1_u2');
      expect(chk.questions.length, 12);
      expect(chk.canDos.length, 3);
      expect(chk.questions.map((q) => q.skill).toSet(), {
        'grammar',
        'listening',
        'reading',
        'writing',
        'vocabulary',
      });
      expect(chk.questions.where((q) => q.dialogueTurnId != null).length, 3);
      for (final c in chk.canDos) {
        expect(
          chk.questions.where((q) => q.canDoId == c.id).length,
          greaterThanOrEqualTo(4),
          reason: c.id,
        );
      }
      for (final q in chk.questions.where((q) => q.skill == 'grammar')) {
        expect(q.explainAr, isNotEmpty, reason: q.id);
      }
      // Every can-do points at lessons of this unit, including lesson 6.
      expect(
        {for (final c in chk.canDos) ...c.lessonIds},
        {for (final l in unit().lessons) l.id},
      );
    });

    test('grades strictly at B1 and shuffles options', () {
      final all = gradeAssessment(chk, {
        for (final q in chk.questions) q.id: q.correctAnswer,
      }, strictAccents: true);
      expect(all.every((g) => g.isCorrect), isTrue);
      final wrong = gradeAssessment(chk, {
        for (final q in chk.questions) q.id: q.correctAnswer,
        'chk_b1_u2.q4': 'habia mucho trabajo',
      }, strictAccents: true);
      final q4 = wrong.firstWhere((g) => g.question.id == 'chk_b1_u2.q4');
      expect(q4.isCorrect, isFalse);
      expect(q4.spelling, Spelling.missingAccents);
      var firstRight = 0;
      var choices = 0;
      for (var s = 0; s < 10; s++) {
        for (final q in chk.questions.where((q) => q.type == 'choice')) {
          choices++;
          if (displayedChoices(q, 'attempt$s').first == q.correctAnswer) {
            firstRight++;
          }
        }
      }
      expect(firstRight / choices, lessThan(0.5));
    });
  });

  testWidgets('every B1-U2 lesson can be completed in the app and schedules '
      'two FSRS cards per item', (tester) async {
    for (final lesson in unit().lessons) {
      final app = TestApp(pack);
      final repo = ProgressRepository(
        app.db,
        ReviewRepository(app.db, clock: app.clock.call, enableFuzzing: false),
        clock: app.clock.call,
      );
      for (final l in pack.orderedLessons) {
        if (l.id == lesson.id) break;
        await repo.completeLesson(
          l,
          score: 1,
          seconds: 60,
          contentVersion: pack.version,
        );
      }
      final lvl = pack.levelAssessmentFor('a2')!;
      await AssessmentRepository(app.db, clock: app.clock.call).submit(
        assessment: lvl,
        graded: gradeAssessment(lvl, {
          for (final q in lvl.questions) q.id: q.correctAnswer,
        }),
        startedAt: app.clock(),
        contentVersion: pack.version,
      );
      final before = (await app.db.select(app.db.reviewCards).get()).length;
      final steps = ExerciseBuilder(pack).buildLesson(lesson);
      await app.pump(tester, location: '/lesson/${lesson.id}');
      await tester.tapKey('start-lesson');
      for (final step in steps) {
        await tester.answer(step);
        expect(tester.takeException(), isNull, reason: step.id);
      }
      expect(find.text('أكملت الدرس'), findsOneWidget, reason: lesson.id);
      await tester.tapKey('finish-lesson');
      final row = (await app.db.select(app.db.lessonProgress).get()).firstWhere(
        (p) => p.lessonId == lesson.id,
      );
      expect(row.bestScore, 1.0, reason: lesson.id);
      expect(await app.db.select(app.db.errorRecords).get(), isEmpty);
      final cards = await app.db.select(app.db.reviewCards).get();
      expect(cards.length - before, lesson.items.length * 2, reason: lesson.id);
      await app.dispose(tester);
    }
  });
}

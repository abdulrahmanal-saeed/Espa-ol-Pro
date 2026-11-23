import 'dart:io';

import 'package:drift/native.dart';
import 'package:espanol_pro/core/assessment/assessment_engine.dart';
import 'package:espanol_pro/core/assessment/assessment_repository.dart';
import 'package:espanol_pro/core/content/content_validator.dart';
import 'package:espanol_pro/core/content/models.dart';
import 'package:espanol_pro/core/db/database.dart';
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

/// B1-U1 — opinion and reasoning: connectors and the simple conditional.
void main() {
  late ContentPack pack;
  setUpAll(() async {
    pack = await loadRealContent();
    await loadAppFonts();
    tzdata.initializeTimeZones();
  });

  LessonProgressData done(String id) => LessonProgressData(
    lessonId: id,
    status: 'completed',
    bestScore: 1,
    lastScore: 1,
    completions: 1,
    startedAt: 0,
    contentVersion: pack.version,
  );

  /// A stored, passing lvl_a2 attempt.
  AttemptRecord passedA2() {
    final lvl = pack.levelAssessmentFor('a2')!;
    return AttemptRecord(
      id: 1,
      assessmentId: lvl.id,
      assessmentVersion: lvl.version,
      completedAtMs: 0,
      localDay: '2026-11-23',
      answers: [
        for (final q in lvl.questions)
          AnswerRecord(
            questionId: q.id,
            skill: q.skill,
            canDoId: q.canDoId,
            isCorrect: true,
          ),
      ],
    );
  }

  group('curriculum', () {
    test('five lessons after the last A2 lesson, each building on the '
        'previous one', () {
      final unit = pack.unit('b1_u1')!;
      expect(unit.lessons.map((l) => l.id), [
        for (var i = 1; i <= 5; i++) 'b1_u1_l$i',
      ]);
      expect(unit.lessons.first.prerequisites, ['a2_u5_l5']);
      for (var i = 1; i < unit.lessons.length; i++) {
        expect(unit.lessons[i].prerequisites, [unit.lessons[i - 1].id]);
      }
      final b1 = pack.levels.firstWhere((l) => l.id == 'b1');
      expect(b1.units.first.id, 'b1_u1');
      expect(b1.units.first.isAvailable, isTrue);
      // Planned B1 units have no lessons.
      for (final u in b1.units.where((u) => !u.isAvailable)) {
        expect(u.lessons, isEmpty, reason: u.id);
      }
      expect(ContentValidator().validate(pack), isEmpty);
    });

    test('every lesson practises every skill and explains wrong answers', () {
      for (final l in pack.unit('b1_u1')!.lessons) {
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
        expect(l.objectivesAr, isNotEmpty, reason: l.id);
        expect(l.workRelevanceAr, isNotEmpty, reason: l.id);
        for (final a in l.activities.where(
          (a) => a.type == 'fill' || a.data['skill'] == 'grammar',
        )) {
          expect(a.data['explain_ar'], isNotEmpty, reason: a.id);
        }
        // Reading and listening comprehension both appear.
        final choiceSkills = {
          for (final a in l.activities.where((a) => a.type == 'choice'))
            a.data['skill'],
        };
        expect(choiceSkills, containsAll(['reading', 'listening']));
      }
      expect(
        {for (final l in pack.unit('b1_u1')!.lessons) l.id: l.grammarIds},
        {
          'b1_u1_l1': ['g_b1_opinion'],
          'b1_u1_l2': ['g_b1_connectors'],
          'b1_u1_l3': ['g_b1_conditional'],
          'b1_u1_l4': ['g_b1_conditional_irregular'],
          'b1_u1_l5': ['g_b1_argue'],
        },
      );
    });

    test('fill distractors are infinitives, participles or other forms that '
        'cannot complete the sentence', () {
      for (final l in pack.unit('b1_u1')!.lessons) {
        for (final a in l.activities.where((a) => a.type == 'fill')) {
          final options = (a.data['options'] as List).cast<String>();
          expect(options, hasLength(3), reason: a.id);
          expect(options.first, a.data['answer'], reason: a.id);
        }
      }
    });

    test('no grammar before its unit: no subjunctive triggers and no '
        'imperfect in B1-U1', () {
      // «no creo que», «para que», «cuando» + verb, «ojalá», «es importante
      // que», «me gustaría que» and «sería mejor que» need the subjunctive
      // (B1-U3); the imperfect arrives in B1-U2.
      final banned = RegExp(
        r'\b(no creo que|no pienso que|para que|ojalá|es importante que|'
        r'gustaría que|sería mejor que|cuando [a-z]+|'
        r'era|eras|tenía|había|estaba|hacía|iba)\b',
      );
      final texts = <String, String>{};
      void add(String where, Object? s) {
        if (s is String) texts[where] = s.toLowerCase();
      }

      final unit = pack.unit('b1_u1')!;
      for (final g in unit.grammar) {
        for (final e in g.examples) {
          add(g.id, e.es);
        }
      }
      for (final l in unit.lessons) {
        for (final i in l.items) {
          add(i.id, i.es);
          for (final e in i.examples) {
            add('${i.id} example', e.es);
          }
        }
        for (final a in l.activities) {
          for (final k in ['es', 'stimulus_es', 'audio_es']) {
            add('${a.id} $k', a.data[k]);
          }
          for (final c in a.data['accepted'] as List? ?? const []) {
            add('${a.id} accepted', c);
          }
        }
      }
      for (final d in pack.dialogues.where((d) => d.unitId == 'b1_u1')) {
        for (final t in d.turns) {
          add(t.id, t.es);
        }
      }
      for (final e in texts.entries) {
        expect(banned.hasMatch(e.value), isFalse, reason: e.key);
      }
    });

    test('lesson 58 needs both the last A2 lesson and a pass in lvl_a2', () {
      final first = pack.lesson('b1_u1_l1')!;
      final allBefore = {
        for (final l in pack.orderedLessons.takeWhile((l) => l.id != first.id))
          l.id: done(l.id),
      };
      final locked = LevelGates.from(pack, const []);
      final open = LevelGates.from(pack, [passedA2()]);
      // Prerequisites met, no pass: locked, and the path points at lvl_a2.
      expect(
        ProgressRepository.isUnlocked(first, allBefore, gates: locked),
        isFalse,
      );
      expect(
        ProgressRepository.nextLesson(pack, allBefore, gates: locked),
        isNull,
      );
      expect(
        ProgressRepository.gatedLesson(pack, allBefore, gates: locked)?.id,
        first.id,
      );
      // A pass, but prerequisites missing: still locked.
      expect(
        ProgressRepository.isUnlocked(first, const {}, gates: open),
        isFalse,
      );
      // Both: open.
      expect(
        ProgressRepository.isUnlocked(first, allBefore, gates: open),
        isTrue,
      );
      expect(
        ProgressRepository.nextLesson(pack, allBefore, gates: open)?.id,
        first.id,
      );
      expect(
        ProgressRepository.gatedLesson(pack, allBefore, gates: open),
        isNull,
      );
    });
  });

  group('verbs: the conditional', () {
    test('regular conditionals are machine-checked, irregular by hand', () {
      final byId = {for (final v in pack.verbs) v.id: v};
      for (final id in ['hablar', 'llamar', 'necesitar', 'gustar', 'deber']) {
        expect(byId[id]!.conditional, Verb.regularConditional(id), reason: id);
      }
      // Irregular in the present, regular in the conditional.
      for (final id in ['ser', 'estar', 'preferir', 'convencer']) {
        expect(byId[id]!.regular, isFalse, reason: id);
        expect(byId[id]!.conditionalRegular, isTrue, reason: id);
        expect(byId[id]!.conditional, Verb.regularConditional(id), reason: id);
      }
      expect(byId['poder']!.conditional['nosotros'], 'podríamos');
      expect(byId['tener']!.conditional['nosotros'], 'tendríamos');
      expect(byId['hacer']!.conditional['yo'], 'haría');
      expect(byId['querer']!.conditional['yo'], 'querría');
      for (final id in ['poder', 'tener', 'hacer', 'querer']) {
        expect(byId[id]!.conditionalRegular, isFalse, reason: id);
      }
      expect(byId['convencer']!.forms['yo'], 'convenzo');
      expect(byId['deber']!.forms, Verb.regularPresent('deber'));
      expect(byId['importar']!.preterite, Verb.regularPreterite('importar'));
      // The subjunctive arrives with its unit (B1-U3).
      expect(pack.verbs.where((v) => v.subjunctive.isNotEmpty), isEmpty);
    });

    testWidgets('the library shows the conditional after the past, keeping '
        'the existing keys', (tester) async {
      final app = TestApp(pack);
      await app.pump(tester, location: '/library');
      await tester.tapSettled(find.text('الأفعال'));
      final tile = find.byKey(const ValueKey('verb-poder'));
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
      expect(find.byKey(const ValueKey('verb-form-poder-yo')), findsOneWidget);
      expect(find.byKey(const ValueKey('verb-past-poder')), findsOneWidget);
      expect(
        find.byKey(const ValueKey('verb-conditional-poder')),
        findsOneWidget,
      );
      expect(
        tester
            .widget<Text>(
              find.descendant(
                of: find.byKey(const ValueKey('verb-conditional-poder-yo')),
                matching: find.byType(Text),
              ),
            )
            .data,
        'podría',
      );
      // No tense that has not been taught yet.
      expect(
        find.byKey(const ValueKey('verb-subjunctive-poder')),
        findsNothing,
      );
      await app.dispose(tester);
    });
  });

  group('answer evaluation', () {
    test('conditional and connector mistakes are wrong, with a diagnosis', () {
      // Present instead of conditional: a different form of the verb.
      final tense = evaluateAnswer('Me gusta cambiar la fecha', [
        'Me gustaría cambiar la fecha.',
      ]);
      expect(tense.isCorrect, isFalse);
      // por qué (why) is not porque (because).
      expect(
        evaluateAnswer('No voy por que tengo una cita', [
          'No voy porque tengo una cita.',
        ]).isCorrect,
        isFalse,
      );
      // A missing accent on the -ía ending is a spelling reminder, not a
      // different word (no -ia form competes with it).
      final accent = evaluateAnswer('me gustaria cambiar la fecha', [
        'me gustaría cambiar la fecha',
      ]);
      expect(accent.isCorrect, isTrue);
      expect(accent.issue, AnswerIssue.accents);
      // está / esta stays a meaning pair.
      expect(
        evaluateAnswer('El hotel es barato y, además, esta cerca.', [
          'El hotel es barato y, además, está cerca.',
        ]).issue,
        AnswerIssue.accentMeaning,
      );
    });

    test('near-synonyms are never offered as each other\'s distractor', () {
      final syn = {for (final i in pack.allItems) i.id: i.syn};
      for (final group in [
        ['por_eso', 'asi_que', 'por_lo_tanto'],
        ['pero', 'sin_embargo', 'en_cambio', 'por_otro_lado'],
        ['quisiera', 'me_encantaria', 'me_gustaria', 'nos_gustaria'],
        ['prefiero', 'preferiria'],
        ['puedes', 'me_puede_ayudar', 'podria'],
        ['mejor', 'seria_mejor'],
        ['creo_que', 'pienso_que', 'en_mi_opinion', 'desde_mi_punto_de_vista'],
        ['porque', 'ya_que'],
        ['estoy_de_acuerdo', 'de_acuerdo', 'me_parece_bien'],
        ['en_resumen', 'en_conclusion'],
      ]) {
        expect(
          {for (final id in group) syn[id]},
          hasLength(1),
          reason: group.join(', '),
        );
        expect(syn[group.first], isNotEmpty);
      }
      // The builder honours the groups.
      final builder = ExerciseBuilder(pack);
      for (final l in pack.unit('b1_u1')!.lessons) {
        for (final step in builder.buildLesson(l).whereType<ChoiceExercise>()) {
          final item = step.itemId == null ? null : pack.item(step.itemId!);
          if (item == null || item.syn.isEmpty) continue;
          final rivals = {
            for (final other in pack.allItems)
              if (other.id != item.id && other.syn == item.syn) ...[
                other.ar,
                other.es,
              ],
          };
          for (final o in step.options) {
            expect(rivals.contains(o), isFalse, reason: '${step.id}: $o');
          }
        }
      }
    });
  });

  group('dialogues', () {
    test('three B1-U1 dialogues, understandable right after their lessons', () {
      final ds = pack.dialogues.where((d) => d.unitId == 'b1_u1').toList();
      expect(ds.map((d) => d.id), [
        'dlg_b1_horario',
        'dlg_b1_cliente_enfadado',
        'dlg_b1_proveedor',
      ]);
      final order = [for (final l in pack.orderedLessons) l.id];
      for (final d in ds) {
        expect(d.levelId, 'b1');
        expect(
          d.lessonIds.every((l) => pack.lesson(l)?.unitId == 'b1_u1'),
          isTrue,
        );
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
        expect(e.wordsPerSentence, lessThanOrEqualTo(10), reason: d.id);
        expect(e.newGrammarIds, isEmpty, reason: d.id);
      }
    });
  });

  group('checkpoint chk_b1_u1', () {
    late Assessment chk;
    setUp(() => chk = pack.assessment('chk_b1_u1')!);

    test('12 questions, three can-dos, five skills, dialogue sentences', () {
      expect(chk.unitId, 'b1_u1');
      expect(chk.levelId, 'b1');
      expect(chk.questions.length, 12);
      expect(chk.canDos.length, 3);
      expect(chk.questions.map((q) => q.skill).toSet(), {
        'grammar',
        'listening',
        'reading',
        'writing',
        'vocabulary',
      });
      expect(chk.questions.any((q) => q.skill == 'speaking'), isFalse);
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
    });

    test('grades, shuffles and persists', () async {
      final all = gradeAssessment(chk, {
        for (final q in chk.questions) q.id: q.correctAnswer,
      });
      expect(all.every((g) => g.isCorrect), isTrue);
      final wrong = gradeAssessment(chk, {
        for (final q in chk.questions) q.id: q.correctAnswer,
        'chk_b1_u1.q8': 'para ejemplo',
        'chk_b1_u1.q12': 'me gusta cambiar la fecha',
      });
      expect(
        wrong.where((g) => !g.isCorrect).map((g) => g.question.id).toSet(),
        {'chk_b1_u1.q8', 'chk_b1_u1.q12'},
      );
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

      final tmp = Directory.systemTemp.createTempSync('espanol_pro_b1u1');
      addTearDown(() => tmp.deleteSync(recursive: true));
      final file = File('${tmp.path}/app.sqlite');
      final clock = FakeClock();
      var db = AppDatabase(NativeDatabase(file));
      final id = await AssessmentRepository(db, clock: clock.call).submit(
        assessment: chk,
        graded: wrong,
        startedAt: clock(),
        contentVersion: pack.version,
      );
      await db.close();
      db = AppDatabase(NativeDatabase(file));
      final repo = AssessmentRepository(db, clock: clock.call);
      expect((await repo.attempt(id))!.score, chk.questions.length - 2);
      await db.close();
    });
  });

  Future<void> passA2AndCompleteBefore(TestApp app, String lessonId) async {
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

  testWidgets('every B1-U1 lesson can be completed in the app and schedules '
      'two FSRS cards per item', (tester) async {
    for (final lesson in pack.unit('b1_u1')!.lessons) {
      final app = TestApp(pack);
      await passA2AndCompleteBefore(app, lesson.id);
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
      final progress = await app.db.select(app.db.lessonProgress).get();
      final row = progress.firstWhere((p) => p.lessonId == lesson.id);
      expect(row.status, 'completed', reason: lesson.id);
      expect(row.bestScore, 1.0, reason: lesson.id);
      expect(await app.db.select(app.db.errorRecords).get(), isEmpty);
      final cards = await app.db.select(app.db.reviewCards).get();
      expect(cards.length - before, lesson.items.length * 2, reason: lesson.id);
      await app.dispose(tester);
    }
  });
}

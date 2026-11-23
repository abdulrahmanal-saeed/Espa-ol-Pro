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

/// B1-U3 — solving problems with clients: the first subjunctive (requests,
/// wishes, advice, negated opinion), a complaint, solutions, and the longer
/// reading and listening lesson.
void main() {
  late ContentPack pack;
  setUpAll(() async {
    pack = await loadRealContent();
    await loadAppFonts();
    tzdata.initializeTimeZones();
  });

  Unit unit() => pack.unit('b1_u3')!;

  group('curriculum', () {
    test('six lessons after B1-U2, each building on the previous one', () {
      expect(unit().lessons.map((l) => l.id), [
        for (var i = 1; i <= 6; i++) 'b1_u3_l$i',
      ]);
      expect(unit().lessons.first.prerequisites, ['b1_u2_l6']);
      for (var i = 1; i < unit().lessons.length; i++) {
        expect(unit().lessons[i].prerequisites, [unit().lessons[i - 1].id]);
      }
      expect(pack.version, '1.14.0');
      expect(ContentValidator().validate(pack), isEmpty);
    });

    test('every lesson practises every skill and explains wrong answers', () {
      for (final l in unit().lessons) {
        expect(
          l.activities.map((a) => a.type).toSet(),
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

    test('the subjunctive is taught with its triggers, and the indicative '
        'where Spanish needs it', () {
      final items = {
        for (final l in unit().lessons)
          for (final i in l.items) i.id,
      };
      // Requests, wishes, advice, feelings, proposals, negated opinion.
      expect(
        items,
        containsAll([
          'quiero_que',
          'necesito_que',
          'le_pido_que',
          'espero_que',
          'ojala',
          'le_recomiendo_que',
          'es_importante_que',
          'no_creo_que',
          'lamento_que',
          'le_propongo_que',
        ]),
      );
      // B1-U1 promised «no creo que» for this unit.
      expect(
        pack.lesson('b1_u3_l3')!.items.map((i) => i.id),
        contains('no_creo_que'),
      );
      // ¿Qué le parece si…? and le prometo que… stay indicative.
      final l5 = pack.lesson('b1_u3_l5')!;
      final siChoice = l5.activities.firstWhere(
        (a) => a.type == 'choice' && a.data['skill'] == 'grammar',
      );
      expect(siChoice.data['stimulus_es'], contains('si le ___'));
      expect((siChoice.data['choices'] as List).first, 'enviamos');
      final l4 = pack.lesson('b1_u3_l4')!;
      expect(
        l4.activities.any(
          (a) =>
              a.type == 'fill' &&
              a.data['es'] == 'Le prometo que lo ___ hoy.' &&
              a.data['answer'] == 'solucionamos',
        ),
        isTrue,
      );
    });
  });

  group('longer reading and listening (lesson 6)', () {
    test('a complaint and its answer with four questions, and a 12-turn '
        'call', () {
      final l6 = pack.lesson('b1_u3_l6')!;
      final reading = [
        for (final a in l6.activities)
          if (a.type == 'choice' && a.data['skill'] == 'reading') a,
      ];
      expect(reading.length, greaterThanOrEqualTo(4));
      final text = reading.first.data['stimulus_es'] as String;
      expect(wordsOf(text).length, greaterThanOrEqualTo(120));
      expect(reading.every((a) => a.data['stimulus_es'] == text), isTrue);
      final call = pack.dialogue('dlg_b1_impresora')!;
      expect(call.lessonIds, ['b1_u3_l6']);
      expect(call.turns.length, greaterThanOrEqualTo(12));
      expect(call.questions.length, greaterThanOrEqualTo(6));
    });
  });

  group('verbs: the present subjunctive', () {
    test('every verb has six forms; regular ones follow the rules, '
        'irregular ones are entered by hand', () {
      for (final v in pack.verbs) {
        expect(v.subjunctive.keys, Verb.persons, reason: v.id);
        if (v.subjunctiveRegular) {
          expect(
            v.subjunctive,
            Verb.regularSubjunctive(v.infinitive),
            reason: v.id,
          );
        }
      }
      final byId = {for (final v in pack.verbs) v.id: v};
      expect(byId['ser']!.subjunctive['yo'], 'sea');
      expect(byId['estar']!.subjunctive['el'], 'esté');
      expect(byId['ir']!.subjunctive['nosotros'], 'vayamos');
      expect(byId['dar']!.subjunctive['el'], 'dé');
      expect(byId['enviar']!.subjunctive['el'], 'envíe');
      expect(byId['poder']!.subjunctive['el'], 'pueda');
      expect(byId['poder']!.subjunctive['nosotros'], 'podamos');
      expect(byId['tener']!.subjunctive['yo'], 'tenga');
      expect(byId['preferir']!.subjunctive['nosotros'], 'prefiramos');
      expect(byId['empezar']!.subjunctive['nosotros'], 'empecemos');
      // Spelling kept by sound in regular verbs.
      expect(byId['llegar']!.subjunctive['el'], 'llegue');
      expect(byId['explicar']!.subjunctive['yo'], 'explique');
      expect(byId['reemplazar']!.subjunctive['nosotros'], 'reemplacemos');
      expect(byId['probar']!.subjunctive['el'], 'pruebe');
      expect(byId['probar']!.subjunctive['nosotros'], 'probemos');
      // Every tense is complete for every verb now.
      for (final v in pack.verbs) {
        for (final t in Verb.optionalTenses) {
          expect(t.forms(v).keys, Verb.persons, reason: '${v.id} ${t.key}');
        }
      }
    });

    testWidgets('the library shows the subjunctive after the conditional', (
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
      expect(
        find.byKey(const ValueKey('verb-subjunctive-ser')),
        findsOneWidget,
      );
      expect(
        tester
            .widget<Text>(
              find.descendant(
                of: find.byKey(const ValueKey('verb-subjunctive-ser-yo')),
                matching: find.byType(Text),
              ),
            )
            .data,
        'sea',
      );
      await app.dispose(tester);
    });
  });

  group('answer evaluation', () {
    test('indicative for subjunctive is a form mistake; esté without its '
        'accent is wrong at B1', () {
      final mood = evaluateAnswer('Quiero que usted revisa el informe', [
        'Quiero que usted revise el informe.',
      ]);
      expect(mood.isCorrect, isFalse);
      expect(mood.issue, AnswerIssue.grammarForm);
      expect(mood.expectedWord, 'revise');
      final accent = evaluateAnswer('espero que todo este bien', const [
        'espero que todo esté bien',
      ], strictAccents: true);
      expect(accent.isCorrect, isFalse);
      expect(accent.issue, AnswerIssue.accents);
    });
  });

  group('dialogues', () {
    test('four B1-U3 dialogues, understandable right after their lessons', () {
      final ds = pack.dialogues.where((d) => d.unitId == 'b1_u3').toList();
      expect(ds.map((d) => d.id), [
        'dlg_b1_pedido_urgente',
        'dlg_b1_soporte',
        'dlg_b1_queja',
        'dlg_b1_impresora',
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
      // Spanish-first prompts are used here too.
      expect(
        ds
            .expand((d) => ExerciseBuilder(pack).buildDialogueQuestions(d))
            .where((e) => e.promptEs != null),
        isNotEmpty,
      );
    });
  });

  group('checkpoint chk_b1_u3', () {
    late Assessment chk;
    setUp(() => chk = pack.assessment('chk_b1_u3')!);

    test('12 questions, three can-dos over all six lessons, five skills', () {
      expect(chk.unitId, 'b1_u3');
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
      expect(
        {for (final c in chk.canDos) ...c.lessonIds},
        {for (final l in unit().lessons) l.id},
      );
      expect(chk.questions.where((q) => q.promptEs != null), isNotEmpty);
    });

    test('grades strictly at B1 and shuffles options', () {
      final all = gradeAssessment(chk, {
        for (final q in chk.questions) q.id: q.correctAnswer,
      }, strictAccents: true);
      expect(all.every((g) => g.isCorrect), isTrue);
      final wrong = gradeAssessment(chk, {
        for (final q in chk.questions) q.id: q.correctAnswer,
        'chk_b1_u3.q3': 'espero que todo este bien',
        'chk_b1_u3.q12': 'lamento que el pedido llega tarde',
      }, strictAccents: true);
      expect(
        wrong.where((g) => !g.isCorrect).map((g) => g.question.id).toSet(),
        {'chk_b1_u3.q3', 'chk_b1_u3.q12'},
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
    });
  });

  testWidgets('every B1-U3 lesson can be completed in the app and schedules '
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

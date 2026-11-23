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
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;

import 'support.dart';
import 'widget_support.dart';

/// A2-U5 — simple work conversations (the last A2 unit).
void main() {
  late ContentPack pack;
  setUpAll(() async {
    pack = await loadRealContent();
    await loadAppFonts();
    tzdata.initializeTimeZones();
  });

  group('curriculum', () {
    test('five lessons after A2-U4, each building on the previous one', () {
      final unit = pack.unit('a2_u5')!;
      expect(unit.lessons.map((l) => l.id), [
        for (var i = 1; i <= 5; i++) 'a2_u5_l$i',
      ]);
      expect(unit.lessons.first.prerequisites, ['a2_u4_l5']);
      for (var i = 1; i < unit.lessons.length; i++) {
        expect(unit.lessons[i].prerequisites, [unit.lessons[i - 1].id]);
      }
      final a2 = pack.levels.firstWhere((l) => l.id == 'a2');
      expect(a2.units.where((u) => u.isAvailable).map((u) => u.id), [
        'a2_u1',
        'a2_u2',
        'a2_u3',
        'a2_u4',
        'a2_u5',
      ]);
      // Every A2 unit is now available.
      expect(a2.units.every((u) => u.isAvailable), isTrue);
      expect(ContentValidator().validate(pack), isEmpty);
    });

    test('every lesson practises every skill and explains wrong answers', () {
      for (final l in pack.unit('a2_u5')!.lessons) {
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
      }
      expect(
        {for (final l in pack.unit('a2_u5')!.lessons) l.id: l.grammarIds},
        {
          'a2_u5_l1': ['g_email_formal'],
          'a2_u5_l2': ['g_registers'],
          'a2_u5_l3': ['g_new_client'],
          'a2_u5_l4': ['g_follow_up'],
          'a2_u5_l5': ['g_meeting_close'],
        },
      );
    });

    test('lesson 53 opens only after the last A2-U4 lesson', () {
      final first = pack.lesson('a2_u5_l1')!;
      expect(ProgressRepository.isUnlocked(first, const {}), isFalse);
      final done = {
        for (final l in pack.orderedLessons.takeWhile((l) => l.id != first.id))
          l.id: LessonProgressData(
            lessonId: l.id,
            status: 'completed',
            bestScore: 1,
            lastScore: 1,
            completions: 1,
            startedAt: 0,
            contentVersion: pack.version,
          ),
      };
      expect(ProgressRepository.isUnlocked(first, done), isTrue);
      expect(ProgressRepository.nextLesson(pack, done)?.id, first.id);
    });
  });

  group('verbs', () {
    test('irregular verbs by hand, regular ones machine-checked', () {
      final byId = {for (final v in pack.verbs) v.id: v};
      expect(byId['dar']!.forms['yo'], 'doy');
      expect(byId['dar']!.preterite['el'], 'dio');
      expect(byId['seguir']!.forms['yo'], 'sigo');
      expect(byId['seguir']!.preterite['el'], 'siguió');
      expect(byId['recordar']!.forms['yo'], 'recuerdo');
      expect(byId['recordar']!.preterite, Verb.regularPreterite('recordar'));
      expect(byId['acordar']!.forms['nosotros'], 'acordamos');
      expect(byId['acordar']!.preterite['nosotros'], 'acordamos');
      for (final id in ['adjuntar', 'avisar', 'interesar']) {
        expect(byId[id]!.forms, Verb.regularPresent(id), reason: id);
        expect(byId[id]!.preterite, Verb.regularPreterite(id), reason: id);
      }
    });
  });

  group('answer evaluation', () {
    test('register and agreement mistakes are wrong, with a diagnosis', () {
      // tú instead of usted in a formal message: another form of the verb.
      final register = evaluateAnswer('Perdone, ¿puedes enviarme la factura?', [
        'Perdone, ¿puede enviarme la factura?',
      ]);
      expect(register.isCorrect, isFalse);
      expect(register.issue, AnswerIssue.grammarForm);
      expect(register.expectedWord, 'puede');
      final agreement = evaluateAnswer('Me interesa los precios', [
        'Me interesan los precios.',
      ]);
      expect(agreement.isCorrect, isFalse);
      expect(agreement.expectedWord, 'interesan');
      // como (as) and cómo (how) are not a meaning pair in the engine: a
      // missing accent on cómo is a reminder, as for other interrogatives.
      expect(
        evaluateAnswer('como se escribe', ['¿Cómo se escribe?']).isCorrect,
        isTrue,
      );
    });
  });

  group('dialogues', () {
    test('three A2-U5 dialogues, understandable right after their lessons', () {
      final ds = pack.dialogues.where((d) => d.unitId == 'a2_u5').toList();
      expect(ds.map((d) => d.id), [
        'dlg_a2_mensajes',
        'dlg_a2_cliente_nuevo',
        'dlg_a2_seguimiento',
      ]);
      final order = [for (final l in pack.orderedLessons) l.id];
      for (final d in ds) {
        expect(
          d.lessonIds.every((l) => pack.lesson(l)?.unitId == 'a2_u5'),
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
      }
    });
  });

  group('checkpoint chk_a2_u5', () {
    late Assessment chk;
    setUp(() => chk = pack.assessment('chk_a2_u5')!);

    test('12 questions, three can-dos, five skills, dialogue sentences', () {
      expect(chk.unitId, 'a2_u5');
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
        'chk_a2_u5.q2': 'adjunto el presupuesto mañana',
        'chk_a2_u5.q12': 'el próximo pasado',
      });
      expect(
        wrong.where((g) => !g.isCorrect).map((g) => g.question.id).toSet(),
        {'chk_a2_u5.q2', 'chk_a2_u5.q12'},
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

      final tmp = Directory.systemTemp.createTempSync('espanol_pro_a2u5');
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

  testWidgets('a completed A2-U5 lesson schedules FSRS cards for its items', (
    tester,
  ) async {
    final lesson = pack.lesson('a2_u5_l4')!;
    final app = TestApp(pack);
    final repo = ProgressRepository(
      app.db,
      ReviewRepository(app.db, clock: app.clock.call, enableFuzzing: false),
      clock: app.clock.call,
    );
    for (final l in pack.orderedLessons.takeWhile((l) => l.id != lesson.id)) {
      await repo.completeLesson(
        l,
        score: 1,
        seconds: 60,
        contentVersion: pack.version,
      );
    }
    final before = (await app.db.select(app.db.reviewCards).get()).length;
    final steps = ExerciseBuilder(pack).buildLesson(lesson);
    await app.pump(tester, location: '/lesson/${lesson.id}');
    await tester.tapKey('start-lesson');
    for (final step in steps) {
      await tester.answer(step);
    }
    await tester.tapKey('finish-lesson');
    final cards = await app.db.select(app.db.reviewCards).get();
    expect(cards.length - before, lesson.items.length * 2);
    await app.dispose(tester);
  });
}

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

/// A2-U4 — preferences and comparison.
void main() {
  late ContentPack pack;
  setUpAll(() async {
    pack = await loadRealContent();
    await loadAppFonts();
    tzdata.initializeTimeZones();
  });

  group('curriculum', () {
    test('five lessons after A2-U3, each building on the previous one', () {
      final unit = pack.unit('a2_u4')!;
      expect(unit.lessons.map((l) => l.id), [
        for (var i = 1; i <= 5; i++) 'a2_u4_l$i',
      ]);
      expect(unit.lessons.first.prerequisites, ['a2_u3_l5']);
      for (var i = 1; i < unit.lessons.length; i++) {
        expect(unit.lessons[i].prerequisites, [unit.lessons[i - 1].id]);
      }
      final a2 = pack.levels.firstWhere((l) => l.id == 'a2');
      expect(
        a2.units.where((u) => u.isAvailable).map((u) => u.id),
        containsAllInOrder(['a2_u1', 'a2_u2', 'a2_u3', 'a2_u4']),
      );
      expect(ContentValidator().validate(pack), isEmpty);
    });

    test('every lesson practises every skill and explains wrong answers', () {
      for (final l in pack.unit('a2_u4')!.lessons) {
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
        {for (final l in pack.unit('a2_u4')!.lessons) l.id: l.grammarIds},
        {
          'a2_u4_l1': ['g_gustar'],
          'a2_u4_l2': ['g_preferir'],
          'a2_u4_l3': ['g_comparison'],
          'a2_u4_l4': ['g_opinion'],
          'a2_u4_l5': ['g_superlative'],
        },
      );
    });

    test('lesson 48 opens only after the last A2-U3 lesson', () {
      final first = pack.lesson('a2_u4_l1')!;
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
    test('stem changes and the irregular pasts are entered by hand', () {
      final byId = {for (final v in pack.verbs) v.id: v};
      expect(byId['preferir']!.forms['yo'], 'prefiero');
      expect(byId['preferir']!.preterite['el'], 'prefirió');
      expect(byId['preferir']!.preteriteRegular, isFalse);
      expect(byId['creer']!.regular, isTrue);
      expect(byId['creer']!.forms, Verb.regularPresent('creer'));
      expect(byId['creer']!.preterite['el'], 'creyó');
      expect(byId['creer']!.preteriteRegular, isFalse);
      expect(byId['parecer']!.forms['yo'], 'parezco');
      expect(byId['parecer']!.preterite, Verb.regularPreterite('parecer'));
      expect(byId['recomendar']!.forms['yo'], 'recomiendo');
      for (final id in ['gustar', 'encantar']) {
        expect(byId[id]!.forms, Verb.regularPresent(id), reason: id);
        expect(byId[id]!.preterite, Verb.regularPreterite(id), reason: id);
      }
    });
  });

  group('answer evaluation', () {
    test('gusta / gustan and a / mí errors are wrong, with a diagnosis', () {
      final number = evaluateAnswer('Me gusta los idiomas', [
        'Me gustan los idiomas.',
      ]);
      expect(number.isCorrect, isFalse);
      expect(number.issue, AnswerIssue.grammarForm);
      expect(number.expectedWord, 'gustan');
      // mí (pronoun) and mi (my) are different words.
      final mi = evaluateAnswer('a mi tambien', ['a mí también']);
      expect(mi.isCorrect, isFalse);
      expect(mi.issue, AnswerIssue.accentMeaning);
      // A missing accent on también alone is only a spelling reminder.
      final tambien = evaluateAnswer('a mí tambien', ['a mí también']);
      expect(tambien.verdict, AnswerVerdict.correctMissingAccents);
    });

    test('comparatives: the irregular forms are required', () {
      expect(
        evaluateAnswer('la más buena opción', ['la mejor opción']).isCorrect,
        isFalse,
      );
      expect(
        evaluateAnswer('más rápido como ese', ['más rápido que ese']).isCorrect,
        isFalse,
      );
    });
  });

  group('dialogues', () {
    test('three A2-U4 dialogues, understandable right after their lessons', () {
      final ds = pack.dialogues.where((d) => d.unitId == 'a2_u4').toList();
      expect(ds.map((d) => d.id), [
        'dlg_a2_gustos',
        'dlg_a2_portatiles',
        'dlg_a2_ofertas',
      ]);
      final order = [for (final l in pack.orderedLessons) l.id];
      for (final d in ds) {
        expect(
          d.lessonIds.every((l) => pack.lesson(l)?.unitId == 'a2_u4'),
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

  group('checkpoint chk_a2_u4', () {
    late Assessment chk;
    setUp(() => chk = pack.assessment('chk_a2_u4')!);

    test('12 questions, three can-dos, five skills, dialogue sentences', () {
      expect(chk.unitId, 'a2_u4');
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
        'chk_a2_u4.q1': 'gusta',
        'chk_a2_u4.q3': 'a mi tampoco',
      });
      expect(
        wrong.where((g) => !g.isCorrect).map((g) => g.question.id).toSet(),
        {'chk_a2_u4.q1', 'chk_a2_u4.q3'},
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

      final tmp = Directory.systemTemp.createTempSync('espanol_pro_a2u4');
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

  testWidgets('a completed A2-U4 lesson schedules FSRS cards for its items', (
    tester,
  ) async {
    final lesson = pack.lesson('a2_u4_l5')!;
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

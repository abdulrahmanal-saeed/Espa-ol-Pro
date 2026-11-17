import 'package:espanol_pro/core/assessment/assessment_engine.dart';
import 'package:espanol_pro/core/content/models.dart';
import 'package:espanol_pro/core/learning/progress_repository.dart';
import 'package:espanol_pro/core/srs/review_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;

import 'support.dart';
import 'widget_support.dart';

/// REVIEW-012 P1: the correct option is listed first in content, so options
/// must not be shown in content order.
void main() {
  late ContentPack pack;
  setUpAll(() async {
    pack = await loadRealContent();
    await loadAppFonts();
    tzdata.initializeTimeZones();
  });

  Iterable<AssessmentQuestion> choiceQuestions() => pack.assessments
      .expand((a) => a.questions)
      .where((q) => q.type == 'choice');

  group('displayed option order', () {
    test('is a stable permutation and never changes the content', () {
      for (final q in choiceQuestions()) {
        final authored = [...q.choices];
        for (var s = 0; s < 20; s++) {
          final shown = displayedChoices(q, 'seed$s');
          expect(shown.toSet(), authored.toSet(), reason: q.id);
          expect(shown.length, authored.length, reason: q.id);
          expect(displayedChoices(q, 'seed$s'), shown, reason: q.id);
        }
        expect(q.choices, authored, reason: '${q.id}: content mutated');
      }
    });

    test('puts the correct option in different positions across attempts', () {
      for (final q in choiceQuestions()) {
        final positions = {
          for (var s = 0; s < 40; s++)
            displayedChoices(q, 'seed$s').indexOf(q.correctAnswer),
        };
        expect(positions.length, greaterThan(1), reason: q.id);
      }
    });

    test('"always pick the first option" no longer passes any assessment', () {
      // Every shipped checkpoint and level assessment, A1 and A2 included.
      expect(
        pack.assessments.map((a) => a.levelId).toSet(),
        containsAll(['pre_a1', 'a1', 'a2']),
      );
      final seed = attemptSeed(DateTime.utc(2026, 3, 10, 9));
      var choices = 0;
      var firstIsRight = 0;
      for (final a in pack.assessments) {
        final first = {
          for (final q in a.questions)
            q.id: q.type == 'choice'
                ? displayedChoices(q, seed).first
                : q.correctAnswer,
        };
        final graded = gradeAssessment(a, first);
        final wrongChoices = graded.where(
          (g) => g.question.type == 'choice' && !g.isCorrect,
        );
        expect(wrongChoices, isNotEmpty, reason: a.id);
        for (final g in graded.where((g) => g.question.type == 'choice')) {
          choices++;
          if (g.isCorrect) firstIsRight++;
        }
        // Answering by text is still graded right whatever the order.
        final right = gradeAssessment(a, {
          for (final q in a.questions) q.id: q.correctAnswer,
        });
        expect(right.every((g) => g.isCorrect), isTrue, reason: a.id);
      }
      // Chance level is about 1/3; content order would be 100 %.
      expect(firstIsRight / choices, lessThan(0.5));
    });
  });

  group('checkpoint screen', () {
    Future<void> completeUnit(TestApp app, String unitId) async {
      final repo = ProgressRepository(
        app.db,
        ReviewRepository(app.db, clock: app.clock.call, enableFuzzing: false),
        clock: app.clock.call,
      );
      for (final l in pack.orderedLessons) {
        await repo.completeLesson(
          l,
          score: 1,
          seconds: 60,
          contentVersion: pack.version,
        );
        if (l.unitId == unitId && l == pack.unit(unitId)!.lessons.last) break;
      }
    }

    testWidgets('shows the attempt order, keeps it across navigation and '
        'grades the chosen text', (tester) async {
      final chk = pack.assessment('chk_a2_u1')!;
      final app = TestApp(pack);
      await completeUnit(app, 'a2_u1');
      await app.pump(tester, location: '/assessment/${chk.id}');
      final seed = attemptSeed(app.clock());
      await tester.tapKey('assessment-start');

      final q1 = chk.questions[0];
      expect(q1.type, 'choice');
      final shown = tester.shownOptions();
      expect(shown, displayedChoices(q1, seed));

      // Same order after selecting, moving on and coming back.
      await tester.tapOption(q1.correctAnswer);
      expect(tester.shownOptions(), shown);
      await tester.tapKey('assessment-next');
      await tester.tapKey('assessment-prev');
      expect(tester.shownOptions(), shown);

      // Across the checkpoint, content order is not what is shown.
      var differs = 0;
      for (final q in chk.questions.where((q) => q.type == 'choice')) {
        if (displayedChoices(q, seed).first != q.correctAnswer) differs++;
      }
      expect(differs, greaterThan(0));
      await app.dispose(tester);
    });

    testWidgets('a later attempt can show a different order', (tester) async {
      final chk = pack.assessment('chk_a2_u1')!;
      final orders = <String>{};
      for (var attempt = 0; attempt < 3; attempt++) {
        final app = TestApp(pack);
        app.clock.advance(Duration(minutes: 7 * attempt));
        await completeUnit(app, 'a2_u1');
        await app.pump(tester, location: '/assessment/${chk.id}');
        await tester.tapKey('assessment-start');
        orders.add(tester.shownOptions().join('|'));
        await app.dispose(tester);
      }
      expect(orders.length, greaterThan(1));
    });
  });
}

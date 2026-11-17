import 'package:espanol_pro/core/assessment/assessment_engine.dart';
import 'package:espanol_pro/core/content/models.dart';
import 'package:espanol_pro/core/learning/exercises.dart';
import 'package:espanol_pro/core/learning/progress_repository.dart';
import 'package:espanol_pro/core/srs/review_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;

import 'support.dart';
import 'widget_support.dart';

/// A1 units added after A1-U1. Each must be teachable end to end.
const newUnits = ['a1_u2', 'a1_u3', 'a1_u4', 'a1_u5', 'a1_u6'];

void main() {
  late ContentPack pack;
  setUpAll(() async {
    pack = await loadRealContent();
    await loadAppFonts();
    tzdata.initializeTimeZones();
  });

  Future<void> completeBefore(TestApp app, String lessonId) async {
    final repo = ProgressRepository(
      app.db,
      ReviewRepository(app.db, clock: app.clock.call, enableFuzzing: false),
      clock: app.clock.call,
    );
    for (final l in pack.orderedLessons) {
      if (l.id == lessonId) return;
      await repo.completeLesson(
        l,
        score: 1,
        seconds: 60,
        contentVersion: pack.version,
      );
    }
  }

  test('the new units are available, in order, with four lessons each', () {
    final a1 = pack.levels.firstWhere((l) => l.id == 'a1');
    final ids = a1.units.where((u) => u.isAvailable).map((u) => u.id);
    expect(ids, containsAllInOrder(['a1_u1', ...newUnits]));
    for (final u in newUnits) {
      final unit = pack.unit(u)!;
      expect(unit.lessons.length, 4, reason: u);
      // Each lesson builds on the previous one.
      for (var i = 1; i < unit.lessons.length; i++) {
        expect(unit.lessons[i].prerequisites, [unit.lessons[i - 1].id]);
      }
      for (final l in unit.lessons) {
        expect(l.objectivesAr, isNotEmpty);
        expect(l.workRelevanceAr, isNotEmpty);
        expect(l.items.length, inInclusiveRange(7, 10), reason: l.id);
      }
      // Professional situations are part of every unit.
      expect(
        unit.lessons.expand((l) => l.items).where((i) => i.work),
        isNotEmpty,
        reason: u,
      );
    }
    // A1-U1 ids are untouched.
    expect(pack.unit('a1_u1')!.lessons.map((l) => l.id), [
      'a1_u1_l1',
      'a1_u1_l2',
      'a1_u1_l3',
    ]);
  });

  test('each new unit has a checkpoint and dialogues that unlock in it', () {
    for (final u in newUnits) {
      final chk = pack.checkpointFor(u);
      expect(chk, isNotNull, reason: u);
      final full = gradeAssessment(chk!, {
        for (final q in chk.questions) q.id: q.correctAnswer,
      });
      expect(full.every((g) => g.isCorrect), isTrue, reason: chk.id);
      final dialogues = pack.dialogues.where((d) => d.unitId == u);
      expect(dialogues.length, greaterThanOrEqualTo(2), reason: u);
      for (final d in dialogues) {
        expect(
          d.lessonIds.every((l) => pack.lesson(l)?.unitId == u),
          isTrue,
          reason: d.id,
        );
      }
    }
  });

  for (final unitId in newUnits) {
    testWidgets('every lesson of $unitId can be completed in the app', (
      tester,
    ) async {
      final unit = pack.unit(unitId)!;
      for (final lesson in unit.lessons) {
        final app = TestApp(pack);
        await completeBefore(app, lesson.id);
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
        await app.dispose(tester);
      }
    });
  }
}

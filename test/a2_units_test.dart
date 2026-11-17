import 'package:espanol_pro/core/assessment/assessment_engine.dart';
import 'package:espanol_pro/core/content/models.dart';
import 'package:espanol_pro/core/learning/exercises.dart';
import 'package:espanol_pro/core/learning/progress_repository.dart';
import 'package:espanol_pro/core/srs/review_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;

import 'support.dart';
import 'widget_support.dart';

/// A2 units that are available. Each must be teachable end to end.
const a2Units = ['a2_u1'];

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

  test('A2 starts after the last A1 lesson and each lesson builds on the '
      'previous one', () {
    final a2 = pack.levels.firstWhere((l) => l.id == 'a2');
    final available = a2.units.where((u) => u.isAvailable).map((u) => u.id);
    expect(available, a2Units);
    // Later A2 units stay visible but planned, with no lessons.
    for (final u in a2.units.where((u) => !u.isAvailable)) {
      expect(pack.unit(u.id)?.lessons ?? const [], isEmpty, reason: u.id);
    }

    final unit = pack.unit('a2_u1')!;
    expect(unit.lessons.map((l) => l.id), [
      'a2_u1_l1',
      'a2_u1_l2',
      'a2_u1_l3',
      'a2_u1_l4',
      'a2_u1_l5',
    ]);
    expect(unit.lessons.first.prerequisites, ['a1_u6_l4']);
    for (var i = 1; i < unit.lessons.length; i++) {
      expect(unit.lessons[i].prerequisites, [unit.lessons[i - 1].id]);
    }
    for (final l in unit.lessons) {
      expect(l.objectivesAr, isNotEmpty);
      expect(l.workRelevanceAr, isNotEmpty);
      expect(l.items.length, inInclusiveRange(7, 10), reason: l.id);
      expect(l.items.where((i) => i.work), isNotEmpty, reason: l.id);
    }
  });

  test('the A2-U1 checkpoint is fully answerable and its dialogues unlock '
      'inside the unit', () {
    final chk = pack.checkpointFor('a2_u1');
    expect(chk, isNotNull);
    expect(chk!.levelId, 'a2');
    final full = gradeAssessment(chk, {
      for (final q in chk.questions) q.id: q.correctAnswer,
    });
    expect(full.every((g) => g.isCorrect), isTrue);

    final dialogues = pack.dialogues.where((d) => d.unitId == 'a2_u1');
    expect(dialogues.map((d) => d.id), [
      'dlg_a2_banco',
      'dlg_a2_averia',
      'dlg_a2_reclamacion',
    ]);
    for (final d in dialogues) {
      expect(
        d.lessonIds.every((l) => pack.lesson(l)?.unitId == 'a2_u1'),
        isTrue,
        reason: d.id,
      );
    }
  });

  test(
    'stem-changing A2 verbs are entered by hand, the rest machine-checked',
    () {
      final byId = {for (final v in pack.verbs) v.id: v};
      for (final id in ['abrir', 'sacar', 'arreglar', 'cobrar']) {
        expect(byId[id]!.regular, isTrue, reason: id);
        expect(byId[id]!.forms, Verb.regularPresent(id), reason: id);
      }
      expect(byId['devolver']!.regular, isFalse);
      expect(byId['devolver']!.forms['yo'], 'devuelvo');
      expect(byId['devolver']!.forms['nosotros'], 'devolvemos');
      expect(byId['comprobar']!.forms['el'], 'comprueba');
      expect(byId['poder']!.lessonIds, contains('a2_u1_l1'));
    },
  );

  test(
    'comprobar and revisar are never offered as each other\'s distractor',
    () {
      final comprobar = pack
          .lesson('a2_u1_l5')!
          .items
          .firstWhere((i) => i.id == 'comprobar');
      final revisar = pack
          .lesson('a1_u6_l3')!
          .items
          .firstWhere((i) => i.id == 'revisar');
      expect(comprobar.syn, isNotEmpty);
      expect(comprobar.syn, revisar.syn);
    },
  );

  for (final unitId in a2Units) {
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

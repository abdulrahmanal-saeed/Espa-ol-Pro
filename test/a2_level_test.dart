import 'dart:io';

import 'package:drift/native.dart';
import 'package:espanol_pro/core/assessment/assessment_engine.dart';
import 'package:espanol_pro/core/assessment/assessment_repository.dart';
import 'package:espanol_pro/core/content/models.dart';
import 'package:espanol_pro/core/db/database.dart';
import 'package:espanol_pro/core/learning/progress_repository.dart';
import 'package:espanol_pro/core/srs/review_repository.dart';
import 'package:espanol_pro/features/assessment/assessment_screens.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;

import 'support.dart';
import 'widget_support.dart';

/// The A2 level assessment `lvl_a2`, built like `lvl_a1`.
void main() {
  late ContentPack pack;
  late Assessment lvl;
  setUpAll(() async {
    pack = await loadRealContent();
    lvl = pack.levelAssessmentFor('a2')!;
    await loadAppFonts();
    tzdata.initializeTimeZones();
  });

  test('covers every A2 unit and five skills, with no speaking', () {
    expect(lvl.id, 'lvl_a2');
    expect(lvl.kind, 'level');
    expect(lvl.unitId, isNull);
    expect(lvl.questions.length, 25);
    final a2 = pack.levels.firstWhere((l) => l.id == 'a2');
    final covered = {
      for (final c in lvl.canDos)
        for (final l in c.lessonIds) pack.lesson(l)!.unitId,
    };
    expect(covered, {for (final u in a2.units) u.id});
    // Every A2 lesson is evidence for one can-do.
    expect(
      {for (final c in lvl.canDos) ...c.lessonIds},
      {
        for (final l in pack.orderedLessons)
          if (l.levelId == 'a2') l.id,
      },
    );
    expect(lvl.questions.map((q) => q.skill).toSet(), {
      'grammar',
      'listening',
      'reading',
      'writing',
      'vocabulary',
    });
    expect(lvl.questions.any((q) => q.skill == 'speaking'), isFalse);
    // Each can-do has evidence from at least four questions.
    for (final c in lvl.canDos) {
      expect(
        lvl.questions.where((q) => q.canDoId == c.id).length,
        greaterThanOrEqualTo(4),
        reason: c.id,
      );
    }
    // One dialogue sentence per unit, from that unit's dialogues.
    final played = lvl.questions.where((q) => q.dialogueTurnId != null);
    expect(played.length, 5);
    for (final q in lvl.questions.where((q) => q.skill == 'grammar')) {
      expect(q.explainAr, isNotEmpty, reason: q.id);
    }
  });

  test('grades right, wrong and missing-accent answers', () {
    final all = gradeAssessment(lvl, {
      for (final q in lvl.questions) q.id: q.correctAnswer,
    });
    expect(all.every((g) => g.isCorrect), isTrue);
    final wrong = gradeAssessment(lvl, {
      for (final q in lvl.questions) q.id: q.correctAnswer,
      'lvl_a2.q9': 'llegue', // llegué without its accent: a different form
      'lvl_a2.q3': 'la pantalla esta rota', // está ≠ esta
      'lvl_a2.q19': 'prefiero el blanco',
    });
    expect(wrong.where((g) => !g.isCorrect).map((g) => g.question.id).toSet(), {
      'lvl_a2.q3',
      'lvl_a2.q9',
      'lvl_a2.q19',
    });
  });

  test('options are shuffled per attempt: the first is no shortcut', () {
    var firstRight = 0;
    var choices = 0;
    for (var s = 0; s < 10; s++) {
      for (final q in lvl.questions.where((q) => q.type == 'choice')) {
        choices++;
        if (displayedChoices(q, 'attempt$s').first == q.correctAnswer) {
          firstRight++;
        }
      }
    }
    expect(firstRight / choices, lessThan(0.5));
  });

  test('results persist across a database reopen', () async {
    final tmp = Directory.systemTemp.createTempSync('espanol_pro_lvl_a2');
    addTearDown(() => tmp.deleteSync(recursive: true));
    final file = File('${tmp.path}/app.sqlite');
    final clock = FakeClock();
    var db = AppDatabase(NativeDatabase(file));
    final id = await AssessmentRepository(db, clock: clock.call).submit(
      assessment: lvl,
      graded: gradeAssessment(lvl, {
        for (final q in lvl.questions) q.id: q.correctAnswer,
      }),
      startedAt: clock(),
      contentVersion: pack.version,
    );
    await db.close();
    db = AppDatabase(NativeDatabase(file));
    final repo = AssessmentRepository(db, clock: clock.call);
    expect((await repo.attempt(id))!.score, lvl.questions.length);
    expect((await repo.answers(id)).length, lvl.questions.length);
    await db.close();
  });

  Future<void> completeThrough(TestApp app, String lastLessonId) async {
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
      if (l.id == lastLessonId) return;
    }
  }

  testWidgets('locked until every A2 lesson is done, then it can start', (
    tester,
  ) async {
    // Everything except the last A2 lesson: still locked.
    var app = TestApp(pack);
    await completeThrough(app, 'a2_u5_l4');
    await app.pump(tester, location: '/assessment/lvl_a2');
    expect(find.byKey(const ValueKey('assessment-locked')), findsOneWidget);
    await app.dispose(tester);

    app = TestApp(pack);
    await completeThrough(app, 'a2_u5_l5');
    final progress = {
      for (final p in await app.db.select(app.db.lessonProgress).get())
        p.lessonId: p,
    };
    expect(levelCompleted(pack, 'a2', progress), isTrue);
    await app.pump(tester, location: '/path');
    final tile = find.byKey(const ValueKey('checkpoint-lvl_a2'));
    await tester.scrollUntilVisible(tile, 300);
    expect(
      find.descendant(of: tile, matching: find.text('اختبار مستوى A2')),
      findsOneWidget,
    );
    await tester.tapSettled(tile);
    final start = tester.widget<FilledButton>(
      find.byKey(const ValueKey('assessment-start')),
    );
    expect(start.onPressed, isNotNull);
    expect(find.textContaining('ليست شهادة CEFR'), findsOneWidget);
    await app.dispose(tester);
  });
}

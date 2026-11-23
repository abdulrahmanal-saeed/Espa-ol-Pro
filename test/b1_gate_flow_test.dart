import 'package:espanol_pro/core/assessment/assessment_engine.dart';
import 'package:espanol_pro/core/assessment/assessment_repository.dart';
import 'package:espanol_pro/core/content/models.dart';
import 'package:espanol_pro/core/learning/progress_repository.dart';
import 'package:espanol_pro/core/srs/review_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;

import 'support.dart';
import 'widget_support.dart';

/// The B1 gate in the app: locked with every A2 lesson done, explained in
/// Arabic with a button to `lvl_a2`; a passing attempt taken on screen opens
/// it, a failing one does not, and a later failure never closes it again.
void main() {
  late ContentPack pack;
  late Assessment lvl;
  setUpAll(() async {
    pack = await loadRealContent();
    lvl = pack.levelAssessmentFor('a2')!;
    await loadAppFonts();
    tzdata.initializeTimeZones();
  });

  Future<TestApp> a2Done() async {
    final app = TestApp(pack);
    final repo = ProgressRepository(
      app.db,
      ReviewRepository(app.db, clock: app.clock.call, enableFuzzing: false),
      clock: app.clock.call,
    );
    for (final l in pack.orderedLessons) {
      if (l.levelId == 'b1') break;
      await repo.completeLesson(
        l,
        score: 1,
        seconds: 60,
        contentVersion: pack.version,
      );
    }
    return app;
  }

  /// Takes lvl_a2 on screen. With [pass] false, every question of the first
  /// can-do is answered wrongly, so that can-do is not met.
  Future<void> takeTest(WidgetTester tester, {required bool pass}) async {
    final failing = {
      if (!pass)
        for (final q in lvl.questions)
          if (q.canDoId == lvl.canDos.first.id) q.id,
    };
    await tester.tapKey('assessment-start');
    for (var i = 0; i < lvl.questions.length; i++) {
      final q = lvl.questions[i];
      final wrong = failing.contains(q.id);
      if (q.audioEs != null) await tester.tapKey('assessment-play');
      if (q.type == 'choice') {
        await tester.tapOption(
          wrong
              ? q.choices.firstWhere((c) => c != q.correctAnswer)
              : q.correctAnswer,
        );
      } else {
        await tester.enterText(
          find.byKey(const ValueKey('assessment-answer')),
          wrong ? 'zzz' : q.correctAnswer,
        );
        await tester.pumpAndSettle();
      }
      await tester.tapKey(
        i < lvl.questions.length - 1 ? 'assessment-next' : 'assessment-submit',
      );
    }
    expect(find.text('نتيجة نقطة التحقق'), findsOneWidget);
  }

  Future<void> scrollTo(WidgetTester tester, Finder f) => tester
      .scrollUntilVisible(f, 300, scrollable: find.byType(Scrollable).first);

  bool startEnabled(WidgetTester tester) =>
      tester
          .widget<FilledButton>(find.byKey(const ValueKey('start-lesson')))
          .onPressed !=
      null;

  testWidgets('locked → a passing attempt on screen → B1 unlocked', (
    tester,
  ) async {
    final app = await a2Done();
    await app.pump(tester, location: '/path');

    // The B1 card explains the gate and links to the test.
    final gate = find.byKey(const ValueKey('level-gate-b1'));
    await scrollTo(tester, gate);
    expect(
      find.descendant(
        of: gate,
        matching: find.textContaining('اختبار مستوى A2'),
      ),
      findsWidgets,
    );
    expect(find.textContaining('75٪'), findsWidgets);

    // A locked B1 lesson says why, with a shortcut to the test.
    final tile = find.byKey(const ValueKey('lesson-b1_u1_l1'));
    await scrollTo(tester, tile);
    await tester.tapSettled(tile);
    final snack = find.byType(SnackBar);
    expect(
      find.descendant(
        of: snack,
        matching: find.textContaining('يُفتح B1 بعد النجاح'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(of: snack, matching: find.text('الاختبار')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('start-lesson')), findsNothing);

    // Opening the lesson directly shows the same explanation; Start is off.
    await app.pump(tester, location: '/lesson/b1_u1_l1');
    expect(find.byKey(const ValueKey('level-gate-b1')), findsOneWidget);
    expect(startEnabled(tester), isFalse);

    // Its button opens lvl_a2, which says what it opens.
    await tester.tapKey('level-gate-b1-test');
    expect(find.byKey(const ValueKey('assessment-opens-b1')), findsOneWidget);
    await takeTest(tester, pass: true);
    expect(find.byKey(const ValueKey('gate-opened-b1')), findsOneWidget);
    await tester.tapKey('assessment-done');

    // Back on the lesson: the gate is gone and the lesson can start.
    expect(find.byKey(const ValueKey('level-gate-b1')), findsNothing);
    expect(startEnabled(tester), isTrue);

    // The path agrees: no gate card, and B1-U1 L1 is the next lesson.
    await app.pump(tester, location: '/path');
    expect(find.byKey(const ValueKey('level-gate-b1')), findsNothing);
    await scrollTo(tester, tile);
    await tester.tapSettled(tile);
    expect(startEnabled(tester), isTrue);
    await app.dispose(tester);
  });

  testWidgets('a failing attempt keeps B1 locked', (tester) async {
    final app = await a2Done();
    await app.pump(tester, location: '/assessment/lvl_a2');
    await takeTest(tester, pass: false);
    expect(find.byKey(const ValueKey('gate-still-locked-b1')), findsOneWidget);
    expect(find.byKey(const ValueKey('gate-opened-b1')), findsNothing);

    await app.pump(tester, location: '/lesson/b1_u1_l1');
    expect(find.byKey(const ValueKey('level-gate-b1')), findsOneWidget);
    expect(startEnabled(tester), isFalse);

    // Home points at the test instead of a lesson.
    await app.pump(tester, location: '/home');
    expect(find.textContaining('اختبار مستوى A2'), findsWidgets);
    expect(find.byKey(const ValueKey('level-gate-b1')), findsOneWidget);
    await app.dispose(tester);
  });

  testWidgets('a failed retry after a pass does not re-lock B1', (
    tester,
  ) async {
    final app = await a2Done();
    // An earlier pass, stored.
    await AssessmentRepository(app.db, clock: app.clock.call).submit(
      assessment: lvl,
      graded: gradeAssessment(lvl, {
        for (final q in lvl.questions) q.id: q.correctAnswer,
      }),
      startedAt: app.clock(),
      contentVersion: pack.version,
    );
    app.clock.advance(const Duration(days: 1));
    await app.pump(tester, location: '/assessment/lvl_a2');
    await takeTest(tester, pass: false);
    expect(find.byKey(const ValueKey('gate-still-open-b1')), findsOneWidget);

    await app.pump(tester, location: '/lesson/b1_u1_l1');
    expect(find.byKey(const ValueKey('level-gate-b1')), findsNothing);
    expect(startEnabled(tester), isTrue);
    await app.dispose(tester);
  });

  testWidgets('A1 → A2 needs no level-test pass', (tester) async {
    final app = TestApp(pack);
    final repo = ProgressRepository(
      app.db,
      ReviewRepository(app.db, clock: app.clock.call, enableFuzzing: false),
      clock: app.clock.call,
    );
    for (final l in pack.orderedLessons) {
      if (l.levelId == 'a2') break;
      await repo.completeLesson(
        l,
        score: 1,
        seconds: 60,
        contentVersion: pack.version,
      );
    }
    // lvl_a1 never taken.
    await app.pump(tester, location: '/lesson/a2_u1_l1');
    expect(find.byKey(const ValueKey('level-gate-a2')), findsNothing);
    expect(startEnabled(tester), isTrue);
    await app.dispose(tester);
  });
}

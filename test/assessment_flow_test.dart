import 'package:espanol_pro/core/assessment/assessment_engine.dart';
import 'package:espanol_pro/core/assessment/assessment_repository.dart';
import 'package:espanol_pro/core/content/models.dart';
import 'package:espanol_pro/core/learning/progress_repository.dart';
import 'package:espanol_pro/core/srs/review_repository.dart';
import 'package:espanol_pro/core/widgets/common.dart';
import 'package:espanol_pro/features/assessment/assessment_screens.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;

import 'support.dart';
import 'widget_support.dart';

void main() {
  late ContentPack pack;
  late Assessment chk;
  setUpAll(() async {
    pack = await loadRealContent();
    chk = pack.assessment('chk_pa1_u1')!;
    await loadAppFonts();
    tzdata.initializeTimeZones();
  });

  Future<void> completeUnit(TestApp app, String unitId) async {
    final repo = ProgressRepository(
      app.db,
      ReviewRepository(app.db, clock: app.clock.call, enableFuzzing: false),
      clock: app.clock.call,
    );
    for (final l in pack.unit(unitId)!.lessons) {
      await repo.completeLesson(
        l,
        score: 1,
        seconds: 60,
        contentVersion: pack.version,
      );
    }
  }

  Future<void> storeAttempt(TestApp app, Map<String, String> answers) =>
      AssessmentRepository(app.db, clock: app.clock.call).submit(
        assessment: chk,
        graded: gradeAssessment(chk, answers),
        startedAt: app.clock(),
        contentVersion: pack.version,
      );

  Map<String, String> correct() => {
    for (final q in chk.questions) q.id: q.correctAnswer,
  };

  /// Answers every question on screen; [typed] overrides typed answers.
  Future<void> answerAll(
    WidgetTester tester, {
    Map<String, String> typed = const {},
  }) async {
    for (var i = 0; i < chk.questions.length; i++) {
      final q = chk.questions[i];
      if (q.type == 'choice') {
        await tester.tapKey('assessment-option-${q.answer}');
      } else {
        await tester.enterText(
          find.byKey(const ValueKey('assessment-answer')),
          typed[q.id] ?? q.correctAnswer,
        );
        await tester.pumpAndSettle();
      }
      // No feedback of any kind while the checkpoint is running.
      expect(find.textContaining('صحيح'), findsNothing);
      expect(find.byIcon(Icons.check_circle_rounded), findsNothing);
      if (i < chk.questions.length - 1) await tester.tapKey('assessment-next');
    }
  }

  testWidgets('a checkpoint stays locked until its unit is complete', (
    tester,
  ) async {
    final app = TestApp(pack);
    await app.pump(tester, location: '/assessment/${chk.id}');
    expect(find.byKey(const ValueKey('assessment-locked')), findsOneWidget);
    final start = tester.widget<FilledButton>(
      find.byKey(const ValueKey('assessment-start')),
    );
    expect(start.onPressed, isNull);
    await app.dispose(tester);
  });

  testWidgets('taking a checkpoint: no feedback, then an honest result', (
    tester,
  ) async {
    final app = TestApp(pack);
    await completeUnit(app, chk.unitId!);
    await app.pump(tester, location: '/assessment/${chk.id}');
    expect(find.byKey(const ValueKey('assessment-locked')), findsNothing);
    await tester.tapKey('assessment-start');

    // An answer is required before moving on.
    final next = tester.widget<FilledButton>(
      find.byKey(const ValueKey('assessment-next')),
    );
    expect(next.onPressed, isNull);

    await answerAll(tester, typed: {'chk_pa1_u1.q7': 'telefono'});
    await tester.tapKey('assessment-submit');

    expect(find.text('نتيجة نقطة التحقق'), findsOneWidget);
    expect(
      tester.widget<Text>(find.byKey(const ValueKey('assessment-score'))).data,
      fraction(chk.questions.length, chk.questions.length),
    );
    expect(find.text('التحدث: غير مُقاس.'), findsOneWidget);
    await tester.ensureVisible(
      find.byKey(const ValueKey('assessment-disclaimer')),
    );
    expect(find.textContaining('ليست شهادة CEFR'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('accent-note-chk_pa1_u1.q7')),
      200,
    );
    expect(find.textContaining('telefono'), findsWidgets);
    expect(find.text('يحتاج تدريباً'), findsNothing);

    final stored = await app.db.select(app.db.assessmentAttempts).get();
    expect(stored.single.score, chk.questions.length);
    // Measuring never teaches: no lesson attempts, no FSRS ratings.
    expect(await app.db.select(app.db.activityAttempts).get(), isEmpty);
    expect(await app.db.select(app.db.reviewLogs).get(), isEmpty);
    await app.dispose(tester);
  });

  testWidgets('a failed save keeps the answers and a retry stores one '
      'attempt', (tester) async {
    final app = TestApp(pack);
    await completeUnit(app, chk.unitId!);
    await app.pump(tester, location: '/assessment/${chk.id}');
    await tester.tapKey('assessment-start');
    await answerAll(tester);

    await app.db.customStatement('''
      CREATE TEMP TRIGGER fail_answers BEFORE INSERT ON assessment_answers
      BEGIN SELECT RAISE(ABORT, 'test write failure'); END
    ''');
    await tester.tapKey('assessment-submit');
    expect(
      find.byKey(const ValueKey('assessment-submit-error')),
      findsOneWidget,
    );
    expect(find.text('أعد محاولة الحفظ'), findsOneWidget);
    expect(await app.db.select(app.db.assessmentAttempts).get(), isEmpty);
    expect(await app.db.select(app.db.assessmentAnswers).get(), isEmpty);

    // Answers are still there: going back shows the earlier typed answer.
    await tester.tapKey('assessment-prev');
    final prev = chk.questions[chk.questions.length - 2];
    if (prev.type != 'choice') {
      expect(find.text(prev.correctAnswer), findsOneWidget);
    }
    await tester.tapKey('assessment-next');

    await app.db.customStatement('DROP TRIGGER fail_answers');
    await tester.tapKey('assessment-submit');
    expect(find.text('نتيجة نقطة التحقق'), findsOneWidget);
    expect((await app.db.select(app.db.assessmentAttempts).get()).length, 1);
    expect(
      (await app.db.select(app.db.assessmentAnswers).get()).length,
      chk.questions.length,
    );
    await app.dispose(tester);
  });

  testWidgets('weak can-dos point back to the lessons to revisit', (
    tester,
  ) async {
    final app = TestApp(pack);
    await completeUnit(app, chk.unitId!);
    await storeAttempt(app, const {});
    final id = (await app.db.select(app.db.assessmentAttempts).get()).single.id;
    await app.pump(tester, location: '/assessment/${chk.id}/result/$id');
    expect(
      tester.widget<Text>(find.byKey(const ValueKey('assessment-score'))).data,
      fraction(0, chk.questions.length),
    );
    expect(find.text('يحتاج تدريباً'), findsOneWidget);
    for (final c in chk.canDos) {
      expect(find.text(c.ar), findsOneWidget);
      for (final l in c.lessonIds) {
        expect(find.byKey(ValueKey('revisit-$l')), findsWidgets);
      }
    }
    await app.dispose(tester);
  });

  testWidgets('the path shows the checkpoint, locked then with its result', (
    tester,
  ) async {
    final tile = find.byKey(ValueKey('checkpoint-${chk.id}'));
    var app = TestApp(pack);
    await app.pump(tester, location: '/path');
    await tester.scrollUntilVisible(tile, 200);
    expect(
      find.descendant(
        of: tile,
        matching: find.text('تُفتح بعد إكمال كل دروس الوحدة'),
      ),
      findsOneWidget,
    );
    await app.dispose(tester);

    app = TestApp(pack);
    await completeUnit(app, chk.unitId!);
    await storeAttempt(app, correct());
    await app.pump(tester, location: '/path');
    await tester.scrollUntilVisible(tile, 200);
    expect(
      find.descendant(
        of: tile,
        matching: find.text(
          'آخر نتيجة: ${fraction(chk.questions.length, chk.questions.length)} · المحاولات: 1',
        ),
      ),
      findsOneWidget,
    );
    await tester.tapSettled(tile);
    expect(find.byKey(const ValueKey('assessment-start')), findsOneWidget);
    await app.dispose(tester);
  });

  testWidgets('progress shows can-do states from checkpoints only', (
    tester,
  ) async {
    final hear = chk.canDos.first;
    Future<String> stateText(TestApp app) async {
      await app.pump(tester, location: '/progress');
      final f = find.byKey(ValueKey('cando-${hear.id}'));
      await tester.scrollUntilVisible(f, 200);
      return tester.widget<Text>(f).data!;
    }

    // Completing lessons alone proves nothing.
    var app = TestApp(pack);
    await completeUnit(app, chk.unitId!);
    expect(await stateText(app), canDoLabels[CanDoState.notAssessed]);
    await app.dispose(tester);

    app = TestApp(pack);
    await storeAttempt(app, correct());
    expect(await stateText(app), canDoLabels[CanDoState.demonstrated]);
    await app.dispose(tester);

    app = TestApp(pack);
    await storeAttempt(app, correct());
    app.clock.advance(const Duration(days: 1));
    await storeAttempt(app, correct());
    expect(await stateText(app), canDoLabels[CanDoState.consistent]);
    await app.dispose(tester);

    app = TestApp(pack);
    await storeAttempt(app, correct());
    app.clock.advance(const Duration(days: 1));
    await storeAttempt(app, const {});
    expect(await stateText(app), canDoLabels[CanDoState.needsPractice]);
    await app.dispose(tester);
  });
}

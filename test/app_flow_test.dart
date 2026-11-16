import 'package:espanol_pro/core/content/models.dart';
import 'package:espanol_pro/core/learning/exercises.dart';
import 'package:espanol_pro/core/learning/progress_repository.dart';
import 'package:espanol_pro/core/settings.dart';
import 'package:espanol_pro/core/srs/review_repository.dart';
import 'package:espanol_pro/core/widgets/common.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fsrs/fsrs.dart' as fsrs;
import 'package:material_ui/material_ui.dart';

import 'support.dart';
import 'widget_support.dart';

void main() {
  late ContentPack pack;
  setUpAll(() async {
    pack = await loadRealContent();
    await loadAppFonts();
  });

  Future<void> completeViaRepo(TestApp app, Lesson lesson) async {
    final reviews = ReviewRepository(
      app.db,
      clock: app.clock.call,
      enableFuzzing: false,
    );
    await ProgressRepository(
      app.db,
      reviews,
      clock: app.clock.call,
    ).completeLesson(
      lesson,
      score: 1,
      seconds: 300,
      contentVersion: pack.version,
    );
  }

  testWidgets('new learner: Arabic RTL shell, Spanish stays LTR', (
    tester,
  ) async {
    final app = TestApp(pack);
    await app.pump(tester);

    expect(find.text('ابدأ درسك الأول'), findsOneWidget);
    expect(find.text('خطة اليوم'), findsOneWidget);
    expect(
      Directionality.of(tester.element(find.text('خطة اليوم'))),
      TextDirection.rtl,
    );
    expect(
      Directionality.of(tester.element(find.text('Español Pro'))),
      TextDirection.ltr,
    );
    // The plan for a brand-new learner is exactly the first lesson.
    expect(
      find.textContaining(pack.orderedLessons.first.titleAr),
      findsOneWidget,
    );
    await app.dispose(tester);
  });

  testWidgets('all five tabs and settings render without layout errors', (
    tester,
  ) async {
    final app = TestApp(pack);
    await completeViaRepo(app, pack.orderedLessons.first);
    await app.pump(tester);
    for (final label in [
      'المسار',
      'التدريب',
      'المكتبة',
      'التقدّم',
      'الرئيسية',
    ]) {
      await tester.tapSettled(find.text(label));
      expect(tester.takeException(), isNull, reason: label);
    }
    await tester.tapSettled(find.text('المكتبة'));
    await tester.tapSettled(find.text('القواعد'));
    await tester.tapSettled(find.text('دفتر الأخطاء'));
    expect(find.text('لا أخطاء مسجّلة'), findsOneWidget);
    await tester.tapSettled(find.text('الرئيسية'));
    await tester.tapSettled(find.byTooltip('الإعدادات'));
    expect(find.text('مدة الجلسة اليومية'), findsOneWidget);
    await app.dispose(tester);
  });

  testWidgets('large text on a small phone, dark theme: no overflow', (
    tester,
  ) async {
    final app = TestApp(pack);
    await completeViaRepo(app, pack.orderedLessons.first);
    await app.pump(
      tester,
      size: const Size(360, 640),
      settings: const AppSettings(textScale: 1.4, themeMode: 'dark'),
    );
    expect(
      Theme.of(tester.element(find.text('خطة اليوم'))).brightness,
      Brightness.dark,
    );
    for (final label in [
      'المسار',
      'التدريب',
      'المكتبة',
      'التقدّم',
      'الرئيسية',
    ]) {
      await tester.tapSettled(find.text(label));
      expect(tester.takeException(), isNull, reason: label);
    }
    await app.dispose(tester);
  });

  testWidgets('a locked lesson explains its prerequisite and cannot start', (
    tester,
  ) async {
    final app = TestApp(pack);
    await app.pump(tester, location: '/lesson/${pack.orderedLessons[1].id}');
    expect(find.textContaining('أكمل أولاً'), findsOneWidget);
    final start = tester.widget<FilledButton>(
      find.byKey(const ValueKey('start-lesson')),
    );
    expect(start.onPressed, isNull);
    await app.dispose(tester);
  });

  testWidgets('initial A1 opens when the Pre-A1 sequence is completed', (
    tester,
  ) async {
    final app = TestApp(pack);
    final introductoryA1 = pack.orderedLessons.firstWhere(
      (lesson) => lesson.levelId == 'a1',
    );
    final preA1 = pack.orderedLessons
        .takeWhile((lesson) => lesson.levelId == 'pre_a1')
        .toList();
    for (final lesson in preA1.take(preA1.length - 1)) {
      await completeViaRepo(app, lesson);
    }
    await app.pump(tester, location: '/lesson/${introductoryA1.id}');
    final start = find.byKey(const ValueKey('start-lesson'));
    expect(tester.widget<FilledButton>(start).onPressed, isNull);

    await completeViaRepo(app, preA1.last);
    await tester.pumpAndSettle();
    await tester.tapKey('start-lesson');
    final first = ExerciseBuilder(pack).buildLesson(introductoryA1).first;
    await tester.answer(first);
    expect(tester.takeException(), isNull);
    await app.dispose(tester);
  });

  testWidgets(
    'full lesson end-to-end: learn, answer, complete, schedule, unlock',
    (tester) async {
      final app = TestApp(pack);
      final lesson = pack.orderedLessons.first;
      final steps = ExerciseBuilder(pack).buildLesson(lesson);
      await app.pump(tester);

      await tester.tapKey('continue-learning');
      expect(find.text(lesson.titleAr), findsOneWidget);
      await tester.tapKey('start-lesson');

      for (final step in steps) {
        await tester.answer(step);
        expect(tester.takeException(), isNull, reason: step.id);
      }

      expect(find.text('أكملت الدرس'), findsOneWidget);
      final measured = steps
          .whereType<Exercise>()
          .where((e) => e.isMeasured)
          .length;
      expect(find.textContaining('($measured من $measured)'), findsOneWidget);
      await tester.tapKey('finish-lesson');

      // Persisted results.
      final progress = await app.db.select(app.db.lessonProgress).get();
      expect(progress.single.status, 'completed');
      expect(progress.single.bestScore, 1.0);
      final cards = await app.db.select(app.db.reviewCards).get();
      expect(cards.length, lesson.items.length * 2);
      final attempts = await app.db.select(app.db.activityAttempts).get();
      expect(attempts.length, steps.whereType<Exercise>().length);
      expect(attempts.where((a) => a.isMeasured).length, measured);
      expect(await app.db.select(app.db.errorRecords).get(), isEmpty);
      // Audio was requested for the taught words.
      expect(app.speech.spoken, contains(lesson.items.first.es));

      // Home now offers the due reviews; today's lesson goal is met.
      expect(find.textContaining('ابدأ بمراجعة'), findsOneWidget);
      expect(find.text('تعلّم جديد'), findsOneWidget);
      // The next lesson is unlocked on the path, the one after is not.
      await tester.tapSettled(find.text('المسار'));
      await tester.tapKey('lesson-${pack.orderedLessons[1].id}');
      final start = tester.widget<FilledButton>(
        find.byKey(const ValueKey('start-lesson')),
      );
      expect(start.onPressed, isNotNull);
      await app.dispose(tester);
    },
  );

  testWidgets(
    'wrong answers are detected, explained, retried and logged as errors',
    (tester) async {
      final app = TestApp(pack);
      final lesson = pack.orderedLessons.first;
      final steps = ExerciseBuilder(pack).buildLesson(lesson);
      await app.pump(tester, location: '/lesson/${lesson.id}');
      await tester.tapKey('start-lesson');

      final firstChoice = steps.whereType<ChoiceExercise>().first;
      final firstTyped = steps.whereType<TypeExercise>().first;
      for (final step in steps) {
        if (step == firstChoice || step == firstTyped) {
          // Stop at the feedback panel to inspect it.
          if (step is ChoiceExercise) {
            await tester.tapKey(
              'option-${(step.correctIndex + 1) % step.options.length}',
            );
          } else {
            await tester.enterText(
              find.byKey(const ValueKey('answer-field')),
              'zzz',
            );
            await tester.pumpAndSettle();
          }
          await tester.tapSettled(find.text('تحقّق'));
          expect(find.text('إجابة غير صحيحة'), findsOneWidget);
          expect(find.text('إجابة صحيحة'), findsNothing);
          expect(
            find.text('سيظهر هذا السؤال مرة أخرى في نهاية الجلسة.'),
            findsOneWidget,
          );
          await tester.tapKey('continue-button');
        } else {
          await tester.answer(step);
        }
      }
      // Both missed exercises come back once at the end.
      expect(find.text('أكملت الدرس'), findsNothing);
      await tester.answer(firstChoice);
      await tester.answer(firstTyped);

      expect(find.text('أكملت الدرس'), findsOneWidget);
      final measured = steps
          .whereType<Exercise>()
          .where((e) => e.isMeasured)
          .length;
      // Retries do not inflate the first-try score.
      expect(
        find.textContaining('(${measured - 2} من $measured)'),
        findsOneWidget,
      );
      expect(find.text('راجع ما أخطأت فيه'), findsOneWidget);

      // Every answer was persisted; the two retries are marked as such.
      final attempts = await app.db.select(app.db.activityAttempts).get();
      expect(attempts.length, steps.whereType<Exercise>().length + 2);
      final retries = attempts.where((a) => a.attemptNumber == 2).toList();
      expect(retries.length, 2);
      expect(retries.every((a) => a.isCorrect), isTrue);
      expect(retries.map((a) => a.activityId).toSet(), {
        firstChoice.id,
        firstTyped.id,
      });

      final errors = await app.db.select(app.db.errorRecords).get();
      expect(errors.length, 2);
      expect(errors.map((e) => e.incorrect), contains('zzz'));
      expect(errors.every((e) => e.count == 1 && e.correctSince == 1), isTrue);
      final progress = await app.db.select(app.db.lessonProgress).get();
      expect(
        progress.single.bestScore,
        closeTo((measured - 2) / measured, 1e-9),
      );
      await app.dispose(tester);
    },
  );

  testWidgets('accent-less answers are accepted with a spelling reminder', (
    tester,
  ) async {
    final app = TestApp(pack);
    final lesson = pack.lesson('pa1_u1_l3')!;
    for (final l in pack.orderedLessons.take(2)) {
      await completeViaRepo(app, l);
    }
    final steps = ExerciseBuilder(pack).buildLesson(lesson);
    await app.pump(tester, location: '/lesson/${lesson.id}');
    await tester.tapKey('start-lesson');
    final target = steps.whereType<TypeExercise>().firstWhere(
      (e) => e.itemId == 'telefono',
    );
    for (final step in steps) {
      if (step == target) break;
      await tester.answer(step);
    }
    await tester.enterText(
      find.byKey(const ValueKey('answer-field')),
      'telefono',
    );
    await tester.pumpAndSettle();
    await tester.tapSettled(find.text('تحقّق'));
    expect(find.text('إجابة صحيحة'), findsOneWidget);
    expect(find.textContaining('انتبه لعلامات النبر'), findsOneWidget);
    await app.dispose(tester);
  });

  testWidgets('review session: reveal → rate → FSRS state persisted', (
    tester,
  ) async {
    final app = TestApp(pack);
    final lesson = pack.orderedLessons.first;
    await completeViaRepo(app, lesson);
    await app.pump(tester, location: '/review');

    expect(find.text('المتبقي: ${lesson.items.length}'), findsOneWidget);
    // Rating is impossible before the answer is revealed.
    expect(find.byKey(const ValueKey('rate-good')), findsNothing);

    Future<int> ratePass() async {
      var n = 0;
      while (find
          .byKey(const ValueKey('review-reveal'))
          .evaluate()
          .isNotEmpty) {
        await tester.tapKey('review-reveal');
        for (final r in ['again', 'hard', 'good', 'easy']) {
          expect(find.byKey(ValueKey('rate-$r')), findsOneWidget);
        }
        await tester.tapKey('rate-good');
        expect(++n, lessThan(40), reason: 'session must terminate');
      }
      return n;
    }

    // First pass: every new card moves to its 10-minute learning step.
    var ratings = await ratePass();
    expect(ratings, lesson.items.length);

    // None of them may be answered before it is due.
    expect(find.byKey(const ValueKey('review-waiting')), findsOneWidget);
    expect(find.text('البطاقة التالية بعد 10:00'), findsOneWidget);
    expect(find.byKey(const ValueKey('review-reveal')), findsNothing);
    expect(find.byKey(const ValueKey('rate-good')), findsNothing);
    final nowMs = app.clock.now.millisecondsSinceEpoch;
    final afterFirst = await app.db.select(app.db.reviewCards).get();
    expect(
      afterFirst
          .where((c) => c.cardType == cardRecognition)
          .every((c) => c.due == nowMs + 600000 && c.reps == 1),
      isTrue,
    );

    // One second before the step is due: still locked.
    app.clock.advance(const Duration(minutes: 9, seconds: 59));
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(find.text('البطاقة التالية بعد 00:01'), findsOneWidget);
    expect(find.byKey(const ValueKey('review-reveal')), findsNothing);
    expect((await app.db.select(app.db.reviewLogs).get()).length, ratings);

    // At the due instant the cards become available again.
    app.clock.advance(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('review-waiting')), findsNothing);
    expect(find.byKey(const ValueKey('review-reveal')), findsOneWidget);
    ratings += await ratePass();

    expect(find.text('انتهت مراجعة اليوم'), findsOneWidget);
    // New cards pass two learning steps, each at its own due time.
    expect(ratings, lesson.items.length * 2);

    final cards = await app.db.select(app.db.reviewCards).get();
    final recognition = cards.where((c) => c.cardType == cardRecognition);
    expect(
      recognition.every((c) => c.state == fsrs.State.review.value),
      isTrue,
    );
    expect(recognition.every((c) => c.reps == 2), isTrue);
    expect(
      recognition.every(
        (c) => c.due > app.clock.now.millisecondsSinceEpoch + 3600000,
      ),
      isTrue,
    );
    final logs = await app.db.select(app.db.reviewLogs).get();
    expect(logs.length, ratings);
    // The second review of each card happened no earlier than its due time.
    for (final c in recognition) {
      final mine = logs.where((l) => l.cardId == c.id).toList();
      expect(mine.length, 2);
      expect(mine[1].reviewedAt, greaterThanOrEqualTo(mine[0].dueAfter));
    }
    await tester.tapKey('review-done');
    await app.dispose(tester);
    // Leaving the screen logs the review as study time.
    // (db is closed by dispose; the row was written before.)
  });

  testWidgets('production card: a wrong typed answer can only be "Again"', (
    tester,
  ) async {
    final app = TestApp(pack);
    final lesson = pack.orderedLessons.first;
    await completeViaRepo(app, lesson);
    final reviews = ReviewRepository(
      app.db,
      clock: app.clock.call,
      enableFuzzing: false,
    );
    for (final c in await reviews.dueCards()) {
      await reviews.rate(c.id, fsrs.Rating.easy);
    }
    app.clock.advance(const Duration(days: 1, minutes: 1));
    await app.pump(tester, location: '/review');

    expect(find.text('استدعاء نشط: اكتب بالإسبانية'), findsOneWidget);
    await tester.enterText(
      find.byKey(const ValueKey('review-answer')),
      'no lo sé',
    );
    await tester.tapKey('review-check');
    expect(find.byKey(const ValueKey('rate-again')), findsOneWidget);
    for (final r in ['hard', 'good', 'easy']) {
      expect(find.byKey(ValueKey('rate-$r')), findsNothing);
    }
    await tester.tapKey('rate-again');
    final log = (await app.db.select(app.db.reviewLogs).get()).last;
    expect(log.rating, fsrs.Rating.again.value);

    // A correct answer offers Hard / Good / Easy as well.
    final cards = await reviews.dueCards();
    final item = pack.item(cards.first.itemId)!;
    await tester.enterText(
      find.byKey(const ValueKey('review-answer')),
      item.es,
    );
    await tester.tapKey('review-check');
    expect(find.byKey(const ValueKey('rate-good')), findsOneWidget);
    await app.dispose(tester);
  });

  testWidgets('a waiting review session can be ended; cards stay scheduled', (
    tester,
  ) async {
    final app = TestApp(pack);
    final lesson = pack.orderedLessons.first;
    await completeViaRepo(app, lesson);
    await app.pump(tester, location: '/review');
    while (find.byKey(const ValueKey('review-reveal')).evaluate().isNotEmpty) {
      await tester.tapKey('review-reveal');
      await tester.tapKey('rate-again');
    }
    // "Again" on a new card = 1-minute step: locked, with a countdown.
    expect(find.text('البطاقة التالية بعد 01:00'), findsOneWidget);
    await tester.tapKey('review-finish-early');
    expect(find.text('انتهت مراجعة اليوم'), findsOneWidget);

    // Nothing was lost: a minute later the same cards are due again.
    final reviews = ReviewRepository(
      app.db,
      clock: app.clock.call,
      enableFuzzing: false,
    );
    expect(await reviews.dueCount(), 0);
    app.clock.advance(const Duration(minutes: 1));
    expect(await reviews.dueCount(), lesson.items.length);
    await app.dispose(tester);
  });

  testWidgets('answers are saved before the run moves on, even when leaving', (
    tester,
  ) async {
    final app = TestApp(pack);
    final lesson = pack.orderedLessons.first;
    final steps = ExerciseBuilder(pack).buildLesson(lesson);
    await app.pump(tester, location: '/lesson/${lesson.id}');
    await tester.tapKey('start-lesson');

    // Answer up to and including the third exercise, then leave at once.
    var answered = 0;
    for (final step in steps) {
      await tester.answer(step);
      if (step is Exercise && ++answered == 3) break;
    }
    await tester.tapSettled(find.byTooltip('خروج'));
    await tester.tapSettled(find.text('خروج'));
    expect(tester.takeException(), isNull);

    final attempts = await app.db.select(app.db.activityAttempts).get();
    expect(attempts.length, 3);
    expect(attempts.every((a) => a.attemptNumber == 1), isTrue);
    // The lesson is started, not completed, and nothing was scheduled.
    final progress = await app.db.select(app.db.lessonProgress).get();
    expect(progress.single.status, 'started');
    expect(await app.db.select(app.db.reviewCards).get(), isEmpty);
    await app.dispose(tester);
  });

  testWidgets('a failed save keeps the answer on both first try and retry', (
    tester,
  ) async {
    final app = TestApp(pack);
    final lesson = pack.orderedLessons.first;
    final steps = ExerciseBuilder(pack).buildLesson(lesson);
    final target = steps.whereType<ChoiceExercise>().first;
    final wrong = (target.correctIndex + 1) % target.options.length;
    final continued = find.byKey(const ValueKey('continue-button'));

    Future<void> failNextSave() => app.db.customStatement('''
      CREATE TEMP TRIGGER fail_attempt BEFORE INSERT ON activity_attempts
      BEGIN SELECT RAISE(ABORT, 'test write failure'); END
    ''');
    Future<void> allowSave() =>
        app.db.customStatement('DROP TRIGGER fail_attempt');
    Future<void> expectFailure() async {
      await tester.tapSettled(find.text('تحقّق'));
      expect(find.text('تعذّر حفظ إجابتك. حاول مرة أخرى.'), findsOneWidget);
      expect(find.text('إجابة صحيحة'), findsNothing);
      expect(find.text('إجابة غير صحيحة'), findsNothing);
      expect(continued, findsNothing);
      expect(find.text('أكملت الدرس'), findsNothing);
    }

    await app.pump(tester, location: '/lesson/${lesson.id}');
    await tester.tapKey('start-lesson');
    for (final step in steps) {
      if (step != target) {
        await tester.answer(step);
        continue;
      }
      await failNextSave();
      final before = await app.db.select(app.db.activityAttempts).get();
      await tester.tapKey('option-$wrong');
      await expectFailure();
      expect(await app.db.select(app.db.activityAttempts).get(), before);
      await tester.tapSettled(find.byTooltip('خروج'));
      expect(find.textContaining('ستفقد إجابتك الحالية'), findsOneWidget);
      await tester.tapSettled(find.text('متابعة التعلّم'));
      await allowSave();
      await tester.tapKey('retry-answer-save');
      expect(find.text('إجابة غير صحيحة'), findsOneWidget);
      await tester.tapKey('continue-button');
    }

    await failNextSave();
    await tester.tapKey('option-${target.correctIndex}');
    await expectFailure();
    final firstAttempts = await app.db.select(app.db.activityAttempts).get();
    expect(firstAttempts.where((a) => a.attemptNumber == 2), isEmpty);
    expect(
      (await app.db.select(app.db.lessonProgress).get()).single.status,
      'started',
    );
    await allowSave();
    await tester.tapKey('retry-answer-save');
    expect(find.text('إجابة صحيحة'), findsOneWidget);
    await tester.tapKey('continue-button');

    final attempts = await app.db.select(app.db.activityAttempts).get();
    final targetAttempts = attempts.where((a) => a.activityId == target.id);
    expect(targetAttempts.map((a) => a.attemptNumber), [1, 2]);
    expect(targetAttempts.map((a) => a.userAnswer), [
      target.options[wrong],
      target.options[target.correctIndex],
    ]);
    expect(attempts.length, firstAttempts.length + 1);
    final measured = steps
        .whereType<Exercise>()
        .where((e) => e.isMeasured)
        .length;
    expect(
      (await app.db.select(app.db.lessonProgress).get()).single.bestScore,
      closeTo((measured - 1) / measured, 1e-9),
    );
    expect(tester.takeException(), isNull);
    await app.dispose(tester);
  });

  testWidgets('home due counter goes live when a card falls due, no DB write', (
    tester,
  ) async {
    final app = TestApp(pack);
    final lesson = pack.orderedLessons.first;
    await completeViaRepo(app, lesson);
    final reviews = ReviewRepository(
      app.db,
      clock: app.clock.call,
      enableFuzzing: false,
    );
    // Clear everything due now: recognition cards move days ahead.
    for (final c in await reviews.dueCards()) {
      await reviews.rate(c.id, fsrs.Rating.easy);
    }
    await app.pump(tester);
    expect(find.textContaining('ابدأ بمراجعة'), findsNothing);
    final logsBefore = (await app.db.select(app.db.reviewLogs).get()).length;

    // Production cards were created due exactly one day after the lesson.
    const almost = Duration(hours: 23, minutes: 59, seconds: 59);
    app.clock.advance(almost);
    await tester.pump(almost);
    expect(find.textContaining('ابدأ بمراجعة'), findsNothing);

    app.clock.advance(const Duration(seconds: 2));
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(
      find.text('ابدأ بمراجعة ${lesson.items.length} بطاقة'),
      findsOneWidget,
    );
    // Nothing was written: the count changed because time passed.
    expect((await app.db.select(app.db.reviewLogs).get()).length, logsBefore);
    await app.dispose(tester);
  });

  testWidgets('save phrases from the dictionary, annotate, remove and undo', (
    tester,
  ) async {
    final app = TestApp(pack);
    await completeViaRepo(app, pack.orderedLessons.first);
    await app.pump(tester, location: '/library');
    await tester.tapSettled(find.widgetWithText(EsText, 'casa'));
    // The headword and its example sentence, from the vocabulary sheet.
    await tester.tapKey('save-phrase-casa');
    await tester.tapKey('save-phrase-mi casa es tu casa');
    // Saving the same sentence again from the same place removes it, so tap
    // the headword twice more to prove the toggle and that it ends saved.
    await tester.tapKey('save-phrase-casa');
    await tester.tapKey('save-phrase-casa');
    var rows = await app.db.select(app.db.savedPhrases).get();
    expect(rows.map((r) => r.es).toSet(), {'casa', 'Mi casa es tu casa.'});
    final example = rows.firstWhere((r) => r.es != 'casa');
    expect(example.sourceKind, 'example');
    expect(example.sourceLessonId, pack.orderedLessons.first.id);

    await tester.tapAt(const Offset(20, 20)); // dismiss the sheet
    await tester.pumpAndSettle();
    await tester.tapSettled(find.text('عباراتي'));
    expect(find.byKey(const ValueKey('phrase-casa')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('phrase-mi casa es tu casa')),
      findsOneWidget,
    );

    // Personal note.
    await tester.tapKey('phrase-note-mi casa es tu casa');
    await tester.enterText(
      find.byKey(const ValueKey('phrase-note-field')),
      'ترحيب بضيف في البيت',
    );
    await tester.tapKey('phrase-note-save');
    expect(find.text('ترحيب بضيف في البيت'), findsOneWidget);

    // Search.
    await tester.enterText(find.byKey(const ValueKey('phrase-search')), 'ضيف');
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('phrase-casa')), findsNothing);
    await tester.enterText(find.byKey(const ValueKey('phrase-search')), '');
    await tester.pumpAndSettle();

    // Remove, then undo: the row comes back with its note and date.
    final before = (await app.db.select(app.db.savedPhrases).get()).firstWhere(
      (r) => r.es != 'casa',
    );
    await tester.tapKey('phrase-remove-mi casa es tu casa');
    expect(
      find.byKey(const ValueKey('phrase-mi casa es tu casa')),
      findsNothing,
    );
    await tester.tapSettled(find.text('تراجع'));
    rows = await app.db.select(app.db.savedPhrases).get();
    expect(rows.firstWhere((r) => r.es != 'casa').toJson(), before.toJson());
    await app.dispose(tester);
  });

  testWidgets(
    'time on an unrated card is stored when the app is backgrounded',
    (tester) async {
      final app = TestApp(pack);
      await completeViaRepo(app, pack.orderedLessons.first);
      final sessionsBefore =
          (await app.db.select(app.db.studySessions).get()).length;
      await app.pump(tester, location: '/review');
      expect(find.byKey(const ValueKey('review-reveal')), findsOneWidget);

      // The learner looks at the card for over a second, then leaves the app
      // without rating it. Review time uses a real stopwatch, so wait for real.
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 1200)),
      );
      for (final state in [
        AppLifecycleState.inactive,
        AppLifecycleState.hidden,
        AppLifecycleState.paused,
      ]) {
        tester.binding.handleAppLifecycleStateChanged(state);
        await tester.pump();
      }
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      var review = (await app.db.select(app.db.studySessions).get())
          .where((r) => r.kind == 'review')
          .toList();
      expect(review.length, 1, reason: 'stored before the process could die');
      expect(review.single.seconds, greaterThanOrEqualTo(1));
      expect(await app.db.select(app.db.reviewLogs).get(), isEmpty);

      // Back in the app, the card is rated: no second counts the same time.
      for (final state in [
        AppLifecycleState.hidden,
        AppLifecycleState.inactive,
        AppLifecycleState.resumed,
      ]) {
        tester.binding.handleAppLifecycleStateChanged(state);
        await tester.pump();
      }
      await tester.tapKey('review-reveal');
      await tester.tapKey('rate-good');
      review = (await app.db.select(app.db.studySessions).get())
          .where((r) => r.kind == 'review')
          .toList();
      final total = review.fold<int>(0, (n, r) => n + r.seconds);
      expect(total, lessThanOrEqualTo(3), reason: 'no double counting');
      expect(
        (await app.db.select(app.db.studySessions).get()).length,
        greaterThan(sessionsBefore),
      );
      await app.dispose(tester);
    },
  );

  testWidgets('empty review queue shows a helpful empty state', (tester) async {
    final app = TestApp(pack);
    await app.pump(tester, location: '/review');
    expect(find.text('لا مراجعات مستحقة الآن'), findsOneWidget);
    await app.dispose(tester);
  });

  testWidgets('practice is locked until something is learned, then runs', (
    tester,
  ) async {
    final app = TestApp(pack);
    await app.pump(tester, location: '/practice');
    final tile = tester.widget<ListTile>(
      find.byKey(const ValueKey('practice-listening')),
    );
    expect(tile.enabled, isFalse);
    await app.dispose(tester);

    final app2 = TestApp(pack);
    await completeViaRepo(app2, pack.orderedLessons.first);
    await app2.pump(tester, location: '/practice/writing');
    var answered = 0;
    while (find.byKey(const ValueKey('answer-field')).evaluate().isNotEmpty) {
      // The Arabic prompt identifies the item; answer it correctly.
      final item = pack.orderedLessons.first.items.firstWhere(
        (i) => find.text(i.ar).evaluate().isNotEmpty,
      );
      await tester.enterText(
        find.byKey(const ValueKey('answer-field')),
        item.es,
      );
      await tester.pumpAndSettle();
      await tester.tapSettled(find.text('تحقّق'));
      expect(find.text('إجابة صحيحة'), findsOneWidget);
      await tester.tapKey('continue-button');
      answered++;
    }
    expect(answered, pack.orderedLessons.first.items.length);
    expect(find.text('انتهى التدريب'), findsOneWidget);
    final attempts = await app2.db.select(app2.db.activityAttempts).get();
    expect(attempts.length, answered);
    expect(attempts.every((a) => a.context == 'practice'), isTrue);
    await app2.dispose(tester);
  });

  testWidgets('settings: session length persists and re-plans the day', (
    tester,
  ) async {
    final app = TestApp(pack);
    await completeViaRepo(app, pack.orderedLessons.first);
    await app.pump(tester, location: '/settings');
    await tester.tapSettled(find.text('60 د'));
    expect((await SettingsRepository(app.db).load()).dailyMinutes, 60);

    // "Restart": a brand-new widget tree over the same database.
    final stored = await SettingsRepository(app.db).load();
    await app.pump(tester, settings: stored);
    expect(find.textContaining('جلسة مكثّفة'), findsOneWidget);
    expect(find.text('كتابة من الذاكرة'), findsOneWidget);
    // Changing the session length did not touch progress.
    expect((await app.db.select(app.db.lessonProgress).get()).length, 1);
    await app.dispose(tester);
  });

  testWidgets('learned words appear in the dictionary with details', (
    tester,
  ) async {
    final app = TestApp(pack);
    final lesson = pack.orderedLessons.first;
    await completeViaRepo(app, lesson);
    await app.pump(tester, location: '/library');
    expect(find.text('${lesson.items.length} عبارة'), findsOneWidget);
    expect(find.widgetWithText(EsText, 'casa'), findsOneWidget);
    await tester.tapSettled(find.widgetWithText(EsText, 'oficina'));
    expect(find.text('شبيهة بالإنجليزية'), findsOneWidget);
    await app.dispose(tester);
  });
}

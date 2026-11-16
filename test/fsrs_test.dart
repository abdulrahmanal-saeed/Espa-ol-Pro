import 'package:espanol_pro/core/content/models.dart';
import 'package:espanol_pro/core/db/database.dart';
import 'package:espanol_pro/core/srs/review_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fsrs/fsrs.dart' as fsrs;

import 'support.dart';

void main() {
  late ContentPack pack;
  late AppDatabase db;
  late FakeClock clock;
  late ReviewRepository repo;
  late Lesson lesson;

  setUpAll(() async => pack = await loadRealContent());
  setUp(() {
    db = memoryDb();
    clock = FakeClock();
    repo = ReviewRepository(db, clock: clock.call, enableFuzzing: false);
    lesson = pack.orderedLessons.first;
  });
  tearDown(() => db.close());

  DateTime due(ReviewCard c) =>
      DateTime.fromMillisecondsSinceEpoch(c.due, isUtc: true);

  Future<ReviewCard> card(String type) async =>
      (await repo.allCards()).firstWhere(
        (c) => c.itemId == lesson.items.first.id && c.cardType == type,
      );

  test('creates one recognition and one production card per item', () async {
    final created = await repo.ensureCardsForLesson(lesson);
    expect(created, lesson.items.length * 2);
    final cards = await repo.allCards();
    expect(
      cards.where((c) => c.cardType == cardRecognition).length,
      lesson.items.length,
    );
    expect(
      cards.where((c) => c.cardType == cardProduction).length,
      lesson.items.length,
    );
  });

  test('repeating a lesson never duplicates or resets cards', () async {
    await repo.ensureCardsForLesson(lesson);
    final c = await card(cardRecognition);
    await repo.rate(c.id, fsrs.Rating.good);
    clock.advance(const Duration(days: 3));
    expect(await repo.ensureCardsForLesson(lesson), 0);
    final after = await card(cardRecognition);
    expect(after.reps, 1);
    expect((await repo.allCards()).length, lesson.items.length * 2);
  });

  test('recognition is due now; production starts one day later', () async {
    await repo.ensureCardsForLesson(lesson);
    expect(await repo.dueCount(), lesson.items.length);
    expect(
      (await repo.dueCards()).every((c) => c.cardType == cardRecognition),
      isTrue,
    );
    clock.advance(const Duration(days: 1));
    expect(await repo.dueCount(), lesson.items.length * 2);
  });

  test('merely creating or viewing a card records no review', () async {
    await repo.ensureCardsForLesson(lesson);
    await repo.dueCards();
    repo.preview(await card(cardRecognition));
    expect(await db.select(db.reviewLogs).get(), isEmpty);
    expect((await card(cardRecognition)).reps, 0);
  });

  test('new card: Good walks the learning steps, then graduates', () async {
    await repo.ensureCardsForLesson(lesson);
    var c = await card(cardRecognition);
    expect(c.state, fsrs.State.learning.value);

    c = await repo.rate(c.id, fsrs.Rating.good);
    expect(c.state, fsrs.State.learning.value);
    expect(c.step, 1);
    expect(due(c).difference(clock.now), const Duration(minutes: 10));
    expect(c.stability, isNotNull);
    expect(c.difficulty, isNotNull);

    clock.advance(const Duration(minutes: 10));
    c = await repo.rate(c.id, fsrs.Rating.good);
    expect(c.state, fsrs.State.review.value);
    expect(c.step, isNull);
    expect(due(c).difference(clock.now).inDays, greaterThanOrEqualTo(1));
  });

  test('Again keeps a new card in the first learning step', () async {
    await repo.ensureCardsForLesson(lesson);
    final c = await repo.rate(
      (await card(cardRecognition)).id,
      fsrs.Rating.again,
    );
    expect(c.state, fsrs.State.learning.value);
    expect(c.step, 0);
    expect(due(c).difference(clock.now), const Duration(minutes: 1));
    expect(c.lapses, 0, reason: 'a lapse is forgetting a REVIEW-state card');
  });

  test(
    'Easy graduates a new card immediately with a longer interval',
    () async {
      await repo.ensureCardsForLesson(lesson);
      final ids = (await repo.dueCards()).map((c) => c.id).toList();
      final easy = await repo.rate(ids[0], fsrs.Rating.easy);
      expect(easy.state, fsrs.State.review.value);

      var good = await repo.rate(ids[1], fsrs.Rating.good);
      clock.advance(const Duration(minutes: 10));
      good = await repo.rate(ids[1], fsrs.Rating.good);
      expect(easy.stability!, greaterThan(good.stability!));
    },
  );

  test(
    'intervals grow with successful reviews and shrink after a lapse',
    () async {
      await repo.ensureCardsForLesson(lesson);
      var c = await repo.rate(
        (await card(cardRecognition)).id,
        fsrs.Rating.easy,
      );
      final intervals = <int>[];
      for (var i = 0; i < 4; i++) {
        clock.now = due(c);
        c = await repo.rate(c.id, fsrs.Rating.good);
        intervals.add(due(c).difference(clock.now).inDays);
      }
      for (var i = 1; i < intervals.length; i++) {
        expect(
          intervals[i],
          greaterThan(intervals[i - 1]),
          reason: '$intervals',
        );
      }
      final stableBefore = c.stability!;

      clock.now = due(c);
      c = await repo.rate(c.id, fsrs.Rating.again);
      expect(c.state, fsrs.State.relearning.value);
      expect(c.lapses, 1);
      expect(c.stability!, lessThan(stableBefore));
      expect(due(c).difference(clock.now), const Duration(minutes: 10));
    },
  );

  test('higher desired retention schedules shorter intervals', () async {
    Future<int> intervalAt(double retention) async {
      final d = memoryDb();
      final ck = FakeClock();
      final r = ReviewRepository(
        d,
        clock: ck.call,
        desiredRetention: retention,
        enableFuzzing: false,
      );
      await r.ensureCardsForLesson(lesson);
      var c = await r.rate((await r.dueCards()).first.id, fsrs.Rating.easy);
      ck.now = DateTime.fromMillisecondsSinceEpoch(c.due, isUtc: true);
      c = await r.rate(c.id, fsrs.Rating.good);
      final days = DateTime.fromMillisecondsSinceEpoch(
        c.due,
        isUtc: true,
      ).difference(ck.now).inDays;
      await d.close();
      return days;
    }

    expect(await intervalAt(0.95), lessThan(await intervalAt(0.80)));
  });

  test('scheduling is reproducible without fuzzing', () async {
    Future<List<int>> run() async {
      final d = memoryDb();
      final ck = FakeClock();
      final r = ReviewRepository(d, clock: ck.call, enableFuzzing: false);
      await r.ensureCardsForLesson(lesson);
      var c = (await r.dueCards()).first;
      final out = <int>[];
      for (final rating in [
        fsrs.Rating.good,
        fsrs.Rating.good,
        fsrs.Rating.hard,
        fsrs.Rating.good,
        fsrs.Rating.again,
        fsrs.Rating.good,
      ]) {
        ck.now = DateTime.fromMillisecondsSinceEpoch(c.due, isUtc: true);
        c = await r.rate(c.id, rating);
        out.add(c.due);
      }
      await d.close();
      return out;
    }

    expect(await run(), await run());
  });

  test(
    'every rating writes exactly one history row with its context',
    () async {
      await repo.ensureCardsForLesson(lesson);
      var c = await repo.rate(
        (await card(cardRecognition)).id,
        fsrs.Rating.easy,
        durationMs: 4200,
      );
      clock.now = due(c);
      c = await repo.rate(c.id, fsrs.Rating.hard);
      final logs = await db.select(db.reviewLogs).get();
      expect(logs.length, 2);
      expect(logs[0].rating, 4);
      expect(logs[0].durationMs, 4200);
      expect(logs[0].retrievability, isNull, reason: 'first exposure');
      expect(logs[1].rating, 2);
      expect(logs[1].stateBefore, fsrs.State.review.value);
      expect(logs[1].retrievability, closeTo(0.9, 0.03));
      expect(logs[1].dueAfter, c.due);
    },
  );

  test('rating a missing card changes nothing', () async {
    await repo.ensureCardsForLesson(lesson);
    await expectLater(repo.rate(999999, fsrs.Rating.good), throwsStateError);
    expect(await db.select(db.reviewLogs).get(), isEmpty);
  });

  test('preview matches what rating actually does', () async {
    await repo.ensureCardsForLesson(lesson);
    final c = await card(cardRecognition);
    final preview = repo.preview(c);
    expect(preview.map((p) => p.rating), fsrs.Rating.values);
    final good = preview.firstWhere((p) => p.rating == fsrs.Rating.good);
    final rated = await repo.rate(c.id, fsrs.Rating.good);
    expect(due(rated), good.due);
    // Ordering sanity: easier ratings never come back sooner.
    for (var i = 1; i < preview.length; i++) {
      expect(preview[i].due.isBefore(preview[i - 1].due), isFalse);
    }
  });

  test(
    'due times are absolute instants, unaffected by local time zone',
    () async {
      await repo.ensureCardsForLesson(lesson);
      final c = await repo.rate(
        (await card(cardRecognition)).id,
        fsrs.Rating.easy,
      );
      // The same instant expressed in local time must give the same decision.
      final localRepo = ReviewRepository(
        db,
        clock: () => due(c).toLocal(),
        enableFuzzing: false,
      );
      expect((await localRepo.dueCards()).map((x) => x.id), contains(c.id));
      final early = ReviewRepository(
        db,
        clock: () => due(c).subtract(const Duration(seconds: 1)).toLocal(),
        enableFuzzing: false,
      );
      expect((await early.dueCards()).map((x) => x.id), isNot(contains(c.id)));
    },
  );

  test(
    'stats report measured retention only from review-state cards',
    () async {
      await repo.ensureCardsForLesson(lesson);
      var stats = await repo.stats();
      expect(stats.totalCards, lesson.items.length * 2);
      expect(stats.neverReviewed, stats.totalCards);
      expect(stats.measuredRetention, isNull);

      final ids = (await repo.dueCards()).map((c) => c.id).take(2).toList();
      var a = await repo.rate(ids[0], fsrs.Rating.easy);
      var b = await repo.rate(ids[1], fsrs.Rating.easy);
      expect((await repo.stats()).measuredRetention, isNull);

      clock.now = due(a).isAfter(due(b)) ? due(a) : due(b);
      a = await repo.rate(a.id, fsrs.Rating.good);
      b = await repo.rate(b.id, fsrs.Rating.again);
      stats = await repo.stats();
      expect(stats.matureReviews, 2);
      expect(stats.measuredRetention, 0.5);
      expect(stats.relearning, 1);
      expect(stats.review, 1);
    },
  );
}

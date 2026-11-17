import 'dart:async';

import 'package:espanol_pro/core/learning/study_time_checkpoint.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late List<int> stored;
  late int failNext;
  late Completer<void>? gate;
  late StudyTimeCheckpoint time;

  setUp(() {
    stored = [];
    failNext = 0;
    gate = null;
    time = StudyTimeCheckpoint(
      writeTime: (seconds) async {
        if (gate != null) await gate!.future;
        if (failNext > 0) {
          failNext--;
          throw StateError('database is locked');
        }
        stored.add(seconds);
      },
    );
  });

  int total() => stored.fold(0, (a, b) => a + b);

  test('a flush stores only what is new', () async {
    await time.flush(() => 10);
    await time.flush(() => 10);
    await time.flush(() => 14);
    expect(stored, [10, 4]);
    expect(time.acknowledged, 14);
  });

  test(
    'a failed flush keeps its seconds pending; the next one retries them',
    () async {
      failNext = 1;
      await expectLater(time.flush(() => 10), throwsStateError);
      expect(stored, isEmpty);
      expect(time.acknowledged, 0, reason: 'nothing was stored');
      await time.flush(() => 12);
      expect(stored, [12], reason: 'the 10 failed seconds are not lost');
    },
  );

  test('a rating after a failed flush carries the unsaved seconds', () async {
    failNext = 1;
    await expectLater(time.flush(() => 10), throwsStateError);
    final carried = await time.commitWithRating(() => 15, (s) async => s);
    expect(carried, 15);
    expect(time.acknowledged, 15);
  });

  test('a failed rating acknowledges nothing; time is retried later', () async {
    await expectLater(
      time.commitWithRating(() => 8, (_) async => throw StateError('rollback')),
      throwsStateError,
    );
    expect(time.acknowledged, 0);
    await time.flush(() => 9);
    expect(stored, [9]);
  });

  test('backgrounding during a slow rating never double-counts', () async {
    final rating = Completer<void>();
    final ratedWith = <int>[];
    final rate = time.commitWithRating(() => 12, (s) async {
      ratedWith.add(s);
      await rating.future; // the transaction is still being written
      return s;
    });
    // Lifecycle pause arrives while the rating is in flight.
    final flush = time.flush(() => 20);
    await Future<void>.delayed(Duration.zero);
    expect(stored, isEmpty, reason: 'the flush waits for the rating');
    rating.complete();
    await rate;
    await flush;
    expect(ratedWith, [12]);
    expect(stored, [8], reason: 'only the 8 seconds after the rating');
    expect(ratedWith.single + total(), 20);
  });

  test(
    'a rating during a slow flush counts only what the flush did not',
    () async {
      gate = Completer<void>();
      final flush = time.flush(() => 10);
      final rate = time.commitWithRating(() => 15, (s) async => s);
      await Future<void>.delayed(Duration.zero);
      gate!.complete();
      await flush;
      expect(await rate, 5);
      expect(total() + 5, 15);
    },
  );

  test(
    'a failed flush in the middle of the queue does not block later writes',
    () async {
      failNext = 1;
      final a = time.flush(() => 5);
      final b = time.flush(() => 7);
      await expectLater(a, throwsStateError);
      await b;
      expect(stored, [7]);
      await time.idle;
    },
  );

  test('time never goes backwards', () async {
    await time.flush(() => 10);
    await time.flush(() => 6);
    expect(await time.commitWithRating(() => 4, (s) async => s), 0);
    expect(time.acknowledged, 10);
  });
}

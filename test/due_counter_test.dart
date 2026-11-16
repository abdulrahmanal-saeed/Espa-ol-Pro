import 'package:espanol_pro/core/db/database.dart';
import 'package:espanol_pro/core/srs/due_counter.dart';
import 'package:flutter_test/flutter_test.dart';

ReviewCard card(int id, int due) => ReviewCard(
  id: id,
  itemId: 'i$id',
  cardType: 'recognition',
  state: 1,
  due: due,
  reps: 0,
  lapses: 0,
  createdAt: 0,
);

void main() {
  final now = DateTime.utc(2026, 3, 10, 9);
  final ms = now.millisecondsSinceEpoch;

  test('counts due cards and finds the next future due time', () {
    final s = DueSummary.of([
      card(1, ms - 1000),
      card(2, ms),
      card(3, ms + 60000),
      card(4, ms + 600000),
    ], now);
    expect(s.dueNow, 2, reason: 'due exactly now counts as due');
    expect(
      s.nextDue,
      DateTime.fromMillisecondsSinceEpoch(ms + 60000, isUtc: true),
    );
    expect(s.refreshAfter(now), const Duration(minutes: 1, milliseconds: 1));
  });

  test('nothing scheduled means no timer at all', () {
    final s = DueSummary.of([card(1, ms - 5)], now);
    expect(s.dueNow, 1);
    expect(s.nextDue, isNull);
    expect(s.refreshAfter(now), isNull);
    expect(DueSummary.of([], now).refreshAfter(now), isNull);
  });

  test('the same instant gives the same answer in any time zone', () {
    final cards = [card(1, ms + 1), card(2, ms - 1)];
    expect(
      DueSummary.of(cards, now).dueNow,
      DueSummary.of(cards, now.toLocal()).dueNow,
    );
  });

  test('a stale next-due time never produces a negative wait', () {
    final s = DueSummary.of([card(1, ms + 5000)], now);
    expect(s.refreshAfter(now.add(const Duration(hours: 1))), Duration.zero);
  });
}

import '../db/database.dart';

/// How many cards are due now, and when the next one becomes due.
class DueSummary {
  const DueSummary({required this.dueNow, required this.nextDue});

  final int dueNow;

  /// The earliest due instant still in the future, or null if none.
  final DateTime? nextDue;

  static DueSummary of(Iterable<ReviewCard> cards, DateTime now) {
    final nowMs = now.toUtc().millisecondsSinceEpoch;
    var due = 0;
    int? next;
    for (final c in cards) {
      if (c.due <= nowMs) {
        due++;
      } else if (next == null || c.due < next) {
        next = c.due;
      }
    }
    return DueSummary(
      dueNow: due,
      nextDue: next == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(next, isUtc: true),
    );
  }

  /// How long to wait before the count can change without a database write.
  /// Null means nothing will become due on its own.
  Duration? refreshAfter(DateTime now) {
    final next = nextDue;
    if (next == null) return null;
    final wait = next.difference(now.toUtc());
    // The extra millisecond guarantees `due <= now` when the timer fires.
    return wait.isNegative
        ? Duration.zero
        : wait + const Duration(milliseconds: 1);
  }
}

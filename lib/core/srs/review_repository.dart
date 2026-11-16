import 'package:drift/drift.dart';
import 'package:fsrs/fsrs.dart' as fsrs;

import '../content/models.dart';
import '../db/database.dart';

const cardRecognition = 'recognition';
const cardProduction = 'production';

typedef Clock = DateTime Function();

/// What the scheduler would do for each rating — shown on the rating buttons.
class RatingPreview {
  const RatingPreview(this.rating, this.due);
  final fsrs.Rating rating;
  final DateTime due;
}

class ReviewStats {
  const ReviewStats({
    required this.totalCards,
    required this.dueNow,
    required this.learning,
    required this.review,
    required this.relearning,
    required this.neverReviewed,
    required this.totalReviews,
    required this.matureReviews,
    required this.matureRecalled,
    required this.averageStabilityDays,
  });

  final int totalCards;
  final int dueNow;
  final int learning;
  final int review;
  final int relearning;
  final int neverReviewed;
  final int totalReviews;

  /// Reviews of cards that were in the Review state (true recall tests).
  final int matureReviews;
  final int matureRecalled;
  final double? averageStabilityDays;

  /// Measured retention on Review-state cards, or null without evidence.
  double? get measuredRetention =>
      matureReviews == 0 ? null : matureRecalled / matureReviews;
}

/// FSRS-backed spaced repetition. All scheduling maths is delegated to the
/// `fsrs` package (FSRS-6, Open Spaced Repetition, MIT); this class only
/// persists state and enforces invariants.
class ReviewRepository {
  ReviewRepository(
    this.db, {
    required this.clock,
    this.desiredRetention = 0.9,
    this.enableFuzzing = true,
  });

  final AppDatabase db;
  final Clock clock;
  final double desiredRetention;
  final bool enableFuzzing;

  late final fsrs.Scheduler scheduler = fsrs.Scheduler(
    desiredRetention: desiredRetention,
    enableFuzzing: enableFuzzing,
  );

  DateTime _now() => clock().toUtc();

  static fsrs.Card toFsrs(ReviewCard row) => fsrs.Card(
    cardId: row.id,
    state: fsrs.State.fromValue(row.state),
    step: row.step,
    stability: row.stability,
    difficulty: row.difficulty,
    due: DateTime.fromMillisecondsSinceEpoch(row.due, isUtc: true),
    lastReview: row.lastReview == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(row.lastReview!, isUtc: true),
  );

  /// Creates recognition + production cards for every item of a completed
  /// lesson. Idempotent: repeating a lesson never duplicates or resets cards.
  ///
  /// Production cards start one day later so that a new word is first
  /// recognised, then actively recalled.
  Future<int> ensureCardsForLesson(Lesson lesson) async {
    final now = _now();
    var created = 0;
    await db.transaction(() async {
      final existing = {
        for (final c in await db.select(db.reviewCards).get())
          '${c.itemId}|${c.cardType}',
      };
      for (final item in lesson.items) {
        for (final type in const [cardRecognition, cardProduction]) {
          if (existing.contains('${item.id}|$type')) continue;
          final due = type == cardRecognition
              ? now
              : now.add(const Duration(days: 1));
          await db
              .into(db.reviewCards)
              .insert(
                ReviewCardsCompanion.insert(
                  itemId: item.id,
                  cardType: type,
                  due: due.millisecondsSinceEpoch,
                  step: const Value(0),
                  sourceLessonId: Value(lesson.id),
                  createdAt: now.millisecondsSinceEpoch,
                ),
              );
          created++;
        }
      }
    });
    return created;
  }

  Future<List<ReviewCard>> dueCards({int limit = 50}) {
    final now = _now().millisecondsSinceEpoch;
    return (db.select(db.reviewCards)
          ..where((c) => c.due.isSmallerOrEqualValue(now))
          ..orderBy([
            (c) => OrderingTerm.asc(c.due),
            (c) => OrderingTerm.asc(c.id),
          ])
          ..limit(limit))
        .get();
  }

  Future<int> dueCount() async {
    final now = _now().millisecondsSinceEpoch;
    final count = db.reviewCards.id.count();
    final q = db.selectOnly(db.reviewCards)
      ..addColumns([count])
      ..where(db.reviewCards.due.isSmallerOrEqualValue(now));
    return (await q.getSingle()).read(count) ?? 0;
  }

  Stream<int> watchDueCount() {
    // Re-evaluated whenever the table changes; time-based changes are picked
    // up when screens refresh.
    return db.select(db.reviewCards).watch().map((rows) {
      final now = _now().millisecondsSinceEpoch;
      return rows.where((r) => r.due <= now).length;
    });
  }

  Future<List<ReviewCard>> allCards() => db.select(db.reviewCards).get();

  List<RatingPreview> preview(ReviewCard row) {
    final now = _now();
    // Fuzz-free preview so the labels are stable while the card is on screen.
    final plain = fsrs.Scheduler(
      desiredRetention: desiredRetention,
      enableFuzzing: false,
    );
    return [
      for (final r in fsrs.Rating.values)
        RatingPreview(
          r,
          plain.reviewCard(toFsrs(row), r, reviewDateTime: now).card.due,
        ),
    ];
  }

  double? retrievability(ReviewCard row) {
    if (row.lastReview == null || row.stability == null) return null;
    return scheduler.getCardRetrievability(
      toFsrs(row),
      currentDateTime: _now(),
    );
  }

  /// Applies a rating atomically: the card update and its history row are
  /// written in one transaction, so an interrupted review can never leave a
  /// half-applied state. Returns the updated card.
  Future<ReviewCard> rate(int cardId, fsrs.Rating rating, {int? durationMs}) {
    return db.transaction(() async {
      final row = await (db.select(
        db.reviewCards,
      )..where((c) => c.id.equals(cardId))).getSingle();
      final now = _now();
      final before = toFsrs(row);
      final r = row.lastReview == null ? null : retrievability(row);
      final result = scheduler.reviewCard(before, rating, reviewDateTime: now);
      final card = result.card;
      final lapsed = rating == fsrs.Rating.again && row.state == 2;

      await (db.update(
        db.reviewCards,
      )..where((c) => c.id.equals(cardId))).write(
        ReviewCardsCompanion(
          state: Value(card.state.value),
          step: Value(card.step),
          stability: Value(card.stability),
          difficulty: Value(card.difficulty),
          due: Value(card.due.millisecondsSinceEpoch),
          lastReview: Value(now.millisecondsSinceEpoch),
          reps: Value(row.reps + 1),
          lapses: Value(row.lapses + (lapsed ? 1 : 0)),
        ),
      );
      await db
          .into(db.reviewLogs)
          .insert(
            ReviewLogsCompanion.insert(
              cardId: cardId,
              rating: rating.value,
              stateBefore: row.state,
              reviewedAt: now.millisecondsSinceEpoch,
              durationMs: Value(durationMs),
              stabilityAfter: Value(card.stability),
              difficultyAfter: Value(card.difficulty),
              dueAfter: card.due.millisecondsSinceEpoch,
              retrievability: Value(r),
            ),
          );
      return (db.select(
        db.reviewCards,
      )..where((c) => c.id.equals(cardId))).getSingle();
    });
  }

  Future<ReviewStats> stats() async {
    final now = _now().millisecondsSinceEpoch;
    final cards = await allCards();
    final logs = await db.select(db.reviewLogs).get();
    final mature = logs.where((l) => l.stateBefore == 2).toList();
    final stabilities = cards
        .where((c) => c.state == 2 && c.stability != null)
        .map((c) => c.stability!)
        .toList();
    return ReviewStats(
      totalCards: cards.length,
      dueNow: cards.where((c) => c.due <= now).length,
      learning: cards.where((c) => c.state == 1 && c.reps > 0).length,
      review: cards.where((c) => c.state == 2).length,
      relearning: cards.where((c) => c.state == 3).length,
      neverReviewed: cards.where((c) => c.reps == 0).length,
      totalReviews: logs.length,
      matureReviews: mature.length,
      matureRecalled: mature.where((l) => l.rating > 1).length,
      averageStabilityDays: stabilities.isEmpty
          ? null
          : stabilities.reduce((a, b) => a + b) / stabilities.length,
    );
  }
}

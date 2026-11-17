import 'package:drift/drift.dart';
import 'package:fsrs/fsrs.dart' as fsrs;

import '../content/models.dart';
import '../db/database.dart';
import '../srs/review_repository.dart';
import 'answer_evaluator.dart';
import 'exercises.dart';

String dayKey(DateTime local) =>
    '${local.year.toString().padLeft(4, '0')}-'
    '${local.month.toString().padLeft(2, '0')}-'
    '${local.day.toString().padLeft(2, '0')}';

class SkillEvidence {
  const SkillEvidence(this.skill, this.attempts, this.correct);
  final String skill;
  final int attempts;
  final int correct;
  double? get accuracy => attempts == 0 ? null : correct / attempts;
}

class LessonOutcome {
  const LessonOutcome({
    required this.score,
    required this.newCards,
    required this.firstCompletion,
  });
  final double score;
  final int newCards;
  final bool firstCompletion;
}

/// Lesson progress, graded attempts, study time and the error notebook.
class ProgressRepository {
  ProgressRepository(this.db, this.reviews, {required this.clock});

  final AppDatabase db;
  final ReviewRepository reviews;
  final Clock clock;

  int get _nowMs => clock().toUtc().millisecondsSinceEpoch;

  // ---- lessons -------------------------------------------------------------

  Stream<Map<String, LessonProgressData>> watchLessonProgress() => db
      .select(db.lessonProgress)
      .watch()
      .map((rows) => {for (final r in rows) r.lessonId: r});

  Future<Map<String, LessonProgressData>> lessonProgressMap() async => {
    for (final r in await db.select(db.lessonProgress).get()) r.lessonId: r,
  };

  static bool isCompleted(LessonProgressData? p) => p?.status == 'completed';

  /// A lesson unlocks when every prerequisite has been completed.
  static bool isUnlocked(Lesson lesson, Map<String, LessonProgressData> map) =>
      lesson.prerequisites.every((id) => isCompleted(map[id]));

  /// First unlocked, not-yet-completed lesson in curriculum order.
  static Lesson? nextLesson(
    ContentPack pack,
    Map<String, LessonProgressData> map,
  ) {
    for (final l in pack.orderedLessons) {
      if (!isCompleted(map[l.id]) && isUnlocked(l, map)) return l;
    }
    return null;
  }

  Future<void> markStarted(String lessonId) async {
    await db
        .into(db.lessonProgress)
        .insert(
          LessonProgressCompanion.insert(
            lessonId: lessonId,
            status: 'started',
            startedAt: _nowMs,
          ),
          mode: InsertMode.insertOrIgnore,
        );
  }

  /// Completes a lesson: stores the score, schedules its review cards and logs
  /// the study time — atomically.
  Future<LessonOutcome> completeLesson(
    Lesson lesson, {
    required double score,
    required int seconds,
    required String contentVersion,
  }) {
    return db.transaction(() async {
      final now = _nowMs;
      final existing = await (db.select(
        db.lessonProgress,
      )..where((t) => t.lessonId.equals(lesson.id))).getSingleOrNull();
      final first = !isCompleted(existing);
      await db
          .into(db.lessonProgress)
          .insertOnConflictUpdate(
            LessonProgressCompanion.insert(
              lessonId: lesson.id,
              status: 'completed',
              startedAt: existing?.startedAt ?? now,
              bestScore: Value(
                existing == null || score > existing.bestScore
                    ? score
                    : existing.bestScore,
              ),
              lastScore: Value(score),
              completions: Value((existing?.completions ?? 0) + 1),
              firstCompletedAt: Value(existing?.firstCompletedAt ?? now),
              lastCompletedAt: Value(now),
              contentVersion: Value(contentVersion),
            ),
          );
      final created = await reviews.ensureCardsForLesson(lesson);
      // A completed lesson always leaves a study record, however fast.
      await logStudy(
        kind: 'lesson',
        refId: lesson.id,
        seconds: seconds < 1 ? 1 : seconds,
      );
      return LessonOutcome(
        score: score,
        newCards: created,
        firstCompletion: first,
      );
    });
  }

  // ---- attempts & error notebook -------------------------------------------

  Future<void> recordAttempt(
    Exercise ex, {
    required bool isCorrect,
    required String userAnswer,
    required String context,
    String? lessonId,
    int attemptNumber = 1,
  }) async {
    final now = _nowMs;
    await db.transaction(() async {
      await db
          .into(db.activityAttempts)
          .insert(
            ActivityAttemptsCompanion.insert(
              activityId: ex.id,
              lessonId: Value(lessonId),
              itemId: Value(ex.itemId),
              skill: ex.skill,
              exerciseType: ex.type,
              context: context,
              isCorrect: isCorrect,
              isMeasured: Value(ex.isMeasured),
              attemptNumber: Value(attemptNumber),
              userAnswer: Value(userAnswer),
              expected: Value(ex.expected),
              createdAt: now,
            ),
          );
      if (!ex.isMeasured) return;

      final signature = '${ex.type}|${normalizeAnswer(ex.expected)}';
      final existing = await (db.select(
        db.errorRecords,
      )..where((t) => t.signature.equals(signature))).getSingleOrNull();
      if (isCorrect) {
        if (existing != null) {
          await (db.update(
            db.errorRecords,
          )..where((t) => t.id.equals(existing.id))).write(
            ErrorRecordsCompanion(
              correctSince: Value(existing.correctSince + 1),
            ),
          );
        }
      } else if (existing == null) {
        await db
            .into(db.errorRecords)
            .insert(
              ErrorRecordsCompanion.insert(
                signature: signature,
                incorrect: userAnswer,
                correct: ex.expected,
                category: errorCategory(ex, userAnswer),
                promptAr: Value(_promptFor(ex)),
                lessonId: Value(lessonId),
                itemId: Value(ex.itemId),
                firstSeen: now,
                lastSeen: now,
              ),
            );
      } else {
        await (db.update(
          db.errorRecords,
        )..where((t) => t.id.equals(existing.id))).write(
          ErrorRecordsCompanion(
            incorrect: Value(userAnswer),
            count: Value(existing.count + 1),
            correctSince: const Value(0),
            lastSeen: Value(now),
          ),
        );
      }
    });
  }

  static String _promptFor(Exercise ex) => switch (ex) {
    TypeExercise e => e.stimulusAr ?? e.promptAr,
    OrderExercise e => e.targetAr,
    _ => ex.promptAr,
  };

  /// Category derived from what the exercise objectively tested — never a
  /// guess about the learner's intent. For a typed Spanish answer the
  /// evaluator's diagnosis decides between spelling, grammar, word order
  /// and meaning.
  static String errorCategory(Exercise ex, [String? userAnswer]) {
    if (userAnswer != null &&
        ex is TypeExercise &&
        (ex.type == 'type_es' || ex.type == 'respond')) {
      final issue = evaluateAnswer(userAnswer, ex.accepted).issue;
      switch (issue) {
        case AnswerIssue.accents ||
            AnswerIssue.accentMeaning ||
            AnswerIssue.enye ||
            AnswerIssue.spelling:
          return 'spelling';
        case AnswerIssue.grammarForm:
          return 'grammar';
        case AnswerIssue.wordOrder:
          return 'word_order';
        case AnswerIssue.meaning:
          if (ex.type == 'type_es') return 'vocabulary';
        case AnswerIssue.none:
          break;
      }
    }
    return _typeCategory(ex);
  }

  static String _typeCategory(Exercise ex) => switch (ex.type) {
    'order' => 'word_order',
    'dictation' || 'listen_choose' || 'listen_pick_es' => 'listening',
    'fill' => 'grammar',
    'type_es' => 'spelling',
    'respond' => 'communication',
    'choice' => ex.skill == 'grammar' ? 'grammar' : 'meaning',
    'dialogue_speaker' => 'listening',
    'dialogue_choice' => switch (ex.skill) {
      'grammar' => 'grammar',
      'reading' => 'meaning',
      _ => 'listening',
    },
    _ => 'vocabulary',
  };

  Stream<List<ErrorRecord>> watchErrors() =>
      (db.select(db.errorRecords)..orderBy([
            (t) => OrderingTerm.desc(t.count),
            (t) => OrderingTerm.desc(t.lastSeen),
          ]))
          .watch();

  /// Errors not yet answered correctly twice since the last mistake.
  static bool isOpenError(ErrorRecord e) => e.correctSince < 2;

  Future<List<ErrorRecord>> openErrors() async =>
      (await db.select(db.errorRecords).get()).where(isOpenError).toList();

  /// First-try accuracy per skill. Prompted retries are excluded: answering
  /// correctly right after being shown the answer is not independent
  /// evidence of ability.
  Future<List<SkillEvidence>> skillEvidence() async {
    final rows =
        await (db.select(db.activityAttempts)..where(
              (t) => t.isMeasured.equals(true) & t.attemptNumber.equals(1),
            ))
            .get();
    return [
      for (final s in skills)
        SkillEvidence(
          s,
          rows.where((r) => r.skill == s).length,
          rows.where((r) => r.skill == s && r.isCorrect).length,
        ),
    ];
  }

  // ---- study time ----------------------------------------------------------

  /// Checkpoints active study time with the rating and its FSRS state.
  Future<ReviewCard> rateReview(
    int cardId,
    fsrs.Rating rating, {
    required int durationMs,
    required int activeSeconds,
  }) {
    return db.transaction(() async {
      final card = await reviews.rate(cardId, rating, durationMs: durationMs);
      await logStudy(kind: 'review', seconds: activeSeconds);
      return card;
    });
  }

  Future<void> logStudy({
    required String kind,
    String? refId,
    required int seconds,
  }) async {
    if (seconds <= 0) return;
    final local = clock().toLocal();
    await db
        .into(db.studySessions)
        .insert(
          StudySessionsCompanion.insert(
            day: dayKey(local),
            kind: kind,
            refId: Value(refId),
            startedAt: _nowMs - seconds * 1000,
            // Guard against a backgrounded app inflating a session.
            seconds: seconds > 5400 ? 5400 : seconds,
          ),
        );
  }

  Stream<List<StudySession>> watchSessions() =>
      db.select(db.studySessions).watch();

  static int secondsOn(List<StudySession> sessions, String day) =>
      sessions.where((s) => s.day == day).fold(0, (sum, s) => sum + s.seconds);

  /// Consecutive days with study, ending today (or yesterday if today has
  /// none yet — the streak is not broken until a full day is missed).
  static int streak(List<StudySession> sessions, DateTime nowLocal) {
    final days = sessions.map((s) => s.day).toSet();
    var cursor = DateTime(nowLocal.year, nowLocal.month, nowLocal.day);
    if (!days.contains(dayKey(cursor))) {
      cursor = cursor.subtract(const Duration(days: 1));
    }
    var n = 0;
    while (days.contains(dayKey(cursor))) {
      n++;
      cursor = DateTime(cursor.year, cursor.month, cursor.day - 1);
    }
    return n;
  }
}

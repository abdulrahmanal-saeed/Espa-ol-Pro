import 'package:drift/drift.dart';

import '../content/models.dart';
import '../db/database.dart';
import '../learning/progress_repository.dart' show dayKey;
import '../srs/review_repository.dart';
import 'assessment_engine.dart';

/// Stores and reads assessment results (schema v5).
///
/// Never touches FSRS cards, lesson progress or the error notebook: an
/// assessment measures, it does not teach.
class AssessmentRepository {
  AssessmentRepository(this.db, {required this.clock});

  final AppDatabase db;
  final Clock clock;

  /// Writes the attempt and all its answers in ONE transaction and returns
  /// the attempt id. If anything fails, nothing is stored and the error is
  /// rethrown, so a failed write can never look like a submission.
  Future<int> submit({
    required Assessment assessment,
    required List<GradedAnswer> graded,
    required DateTime startedAt,
    required String contentVersion,
  }) {
    if (graded.length != assessment.questions.length) {
      throw ArgumentError('Every question must be graded before submitting.');
    }
    return db.transaction(() async {
      final id = await db
          .into(db.assessmentAttempts)
          .insert(
            AssessmentAttemptsCompanion.insert(
              assessmentId: assessment.id,
              assessmentVersion: assessment.version,
              contentVersion: contentVersion,
              startedAt: startedAt.toUtc().millisecondsSinceEpoch,
              completedAt: clock().toUtc().millisecondsSinceEpoch,
              maxScore: graded.length,
              score: graded.where((g) => g.isCorrect).length,
            ),
          );
      await db.batch((b) {
        b.insertAll(db.assessmentAnswers, [
          for (final g in graded)
            AssessmentAnswersCompanion.insert(
              attemptId: id,
              questionId: g.question.id,
              skill: g.question.skill,
              canDoId: g.question.canDoId,
              isCorrect: g.isCorrect,
              spelling: Value(g.spelling),
              userAnswer: Value(g.userAnswer),
              expected: Value(g.question.correctAnswer),
            ),
        ]);
      });
      return id;
    });
  }

  Stream<List<AssessmentAttempt>> watchAttempts() =>
      (db.select(db.assessmentAttempts)..orderBy([
            (t) => OrderingTerm.desc(t.completedAt),
            (t) => OrderingTerm.desc(t.id),
          ]))
          .watch();

  Future<AssessmentAttempt?> attempt(int id) => (db.select(
    db.assessmentAttempts,
  )..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<List<AssessmentAnswer>> answers(int attemptId) =>
      (db.select(db.assessmentAnswers)
            ..where((t) => t.attemptId.equals(attemptId))
            ..orderBy([(t) => OrderingTerm.asc(t.id)]))
          .get();

  /// Every stored attempt with its answers, for can-do evidence.
  Stream<List<AttemptRecord>> watchRecords() {
    return db.select(db.assessmentAnswers).watch().asyncMap((_) async {
      final attempts = await db.select(db.assessmentAttempts).get();
      final answers = await db.select(db.assessmentAnswers).get();
      return [
        for (final a in attempts)
          AttemptRecord(
            id: a.id,
            assessmentId: a.assessmentId,
            completedAtMs: a.completedAt,
            localDay: dayKey(
              DateTime.fromMillisecondsSinceEpoch(
                a.completedAt,
                isUtc: true,
              ).toLocal(),
            ),
            answers: [
              for (final x in answers)
                if (x.attemptId == a.id)
                  AnswerRecord(
                    questionId: x.questionId,
                    skill: x.skill,
                    canDoId: x.canDoId,
                    isCorrect: x.isCorrect,
                  ),
            ],
          ),
      ];
    });
  }
}

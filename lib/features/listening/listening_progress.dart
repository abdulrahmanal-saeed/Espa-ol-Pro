import '../../core/content/models.dart';
import '../../core/db/database.dart';
import '../../core/learning/progress_repository.dart';

/// Where a learner stands on one dialogue, derived only from recorded
/// answers. Nothing is stored separately, so nothing can disagree with the
/// attempts table.
class DialogueProgress {
  const DialogueProgress({
    required this.total,
    required this.answered,
    required this.correct,
  });

  /// Comprehension questions in the dialogue.
  final int total;

  /// Questions with at least one recorded FIRST attempt.
  final int answered;

  /// Of those, how many were right on the most recent first attempt.
  final int correct;

  bool get completed => total > 0 && answered == total;
  bool get started => answered > 0;

  /// The context recorded with every dialogue answer.
  static const context = 'listening';

  /// Counts only measured first attempts (prompted retries are remediation,
  /// not evidence), and for each question only the most recent run.
  static DialogueProgress of(Dialogue d, Iterable<ActivityAttempt> attempts) {
    final ids = {for (final q in d.questions) q.id};
    final latest = <String, ActivityAttempt>{};
    for (final a in attempts) {
      if (a.context != context ||
          !a.isMeasured ||
          a.attemptNumber != 1 ||
          !ids.contains(a.activityId)) {
        continue;
      }
      final prev = latest[a.activityId];
      if (prev == null ||
          a.createdAt > prev.createdAt ||
          (a.createdAt == prev.createdAt && a.id > prev.id)) {
        latest[a.activityId] = a;
      }
    }
    return DialogueProgress(
      total: ids.length,
      answered: latest.length,
      correct: latest.values.where((a) => a.isCorrect).length,
    );
  }

  /// A dialogue opens once every lesson it is built on is completed.
  static bool isUnlocked(Dialogue d, Map<String, LessonProgressData> lessons) =>
      d.lessonIds.every((id) => ProgressRepository.isCompleted(lessons[id]));
}

import '../content/models.dart';
import '../learning/answer_evaluator.dart';

/// Spelling outcome of a typed answer.
abstract final class Spelling {
  static const exact = 'exact';
  static const missingAccents = 'missing_accents';
  static const wrong = 'wrong';
}

/// One graded answer, before it is stored.
class GradedAnswer {
  const GradedAnswer({
    required this.question,
    required this.userAnswer,
    required this.isCorrect,
    required this.spelling,
  });

  final AssessmentQuestion question;
  final String userAnswer;

  /// The meaning is right. At Pre-A1/A1 a word written without its accents
  /// still counts, but [spelling] records it separately.
  final bool isCorrect;

  /// For typed answers only (see [Spelling]); null for choices.
  final String? spelling;
}

/// Grades a complete set of answers. Pure and deterministic.
///
/// [answers] maps question id to the learner's answer: the chosen option
/// text for choices, the typed text otherwise. A missing answer is wrong.
List<GradedAnswer> gradeAssessment(Assessment a, Map<String, String> answers) =>
    [for (final q in a.questions) _grade(q, answers[q.id] ?? '')];

GradedAnswer _grade(AssessmentQuestion q, String answer) {
  switch (q.type) {
    case 'choice':
      return GradedAnswer(
        question: q,
        userAnswer: answer,
        isCorrect: answer == q.choices[q.answer],
        spelling: null,
      );
    default:
      final accepted = q.type == 'dictation' ? [q.audioEs!] : q.accepted;
      if (answer.trim().isEmpty) {
        return GradedAnswer(
          question: q,
          userAnswer: answer,
          isCorrect: false,
          spelling: Spelling.wrong,
        );
      }
      final r = evaluateAnswer(answer, accepted);
      return GradedAnswer(
        question: q,
        userAnswer: answer,
        isCorrect: r.isCorrect,
        spelling: switch (r.verdict) {
          AnswerVerdict.correct => Spelling.exact,
          AnswerVerdict.correctMissingAccents => Spelling.missingAccents,
          AnswerVerdict.incorrect => Spelling.wrong,
        },
      );
  }
}

/// A stored answer, as needed for scoring (decoupled from the database).
class AnswerRecord {
  const AnswerRecord({
    required this.questionId,
    required this.skill,
    required this.canDoId,
    required this.isCorrect,
  });

  final String questionId;
  final String skill;
  final String canDoId;
  final bool isCorrect;
}

/// A stored attempt with its answers.
class AttemptRecord {
  const AttemptRecord({
    required this.id,
    required this.assessmentId,
    required this.completedAtMs,
    required this.localDay,
    required this.answers,
  });

  final int id;
  final String assessmentId;
  final int completedAtMs;

  /// Local calendar day of completion, `YYYY-MM-DD`.
  final String localDay;
  final List<AnswerRecord> answers;
}

class SkillScore {
  const SkillScore(this.skill, this.correct, this.total);
  final String skill;
  final int correct;
  final int total;
}

/// Score per measured skill, in a fixed order.
List<SkillScore> skillScores(Iterable<AnswerRecord> answers) => [
  for (final s in const [
    'vocabulary',
    'reading',
    'listening',
    'writing',
    'grammar',
  ])
    if (answers.any((a) => a.skill == s))
      SkillScore(
        s,
        answers.where((a) => a.skill == s && a.isCorrect).length,
        answers.where((a) => a.skill == s).length,
      ),
];

enum CanDoState {
  /// No submitted checkpoint covers it.
  notAssessed,

  /// The latest checkpoint did not meet the rule.
  needsPractice,

  /// The latest checkpoint met the rule.
  demonstrated,

  /// The two latest checkpoints met the rule, on different days.
  consistent,
}

/// The documented rule behind every "أستطيع" state:
///
/// A can-do is **met** in an attempt when at least [threshold] of its
/// questions in that attempt were answered correctly (with 2–4 questions per
/// can-do this means: all of 2, all of 3, or 3 of 4).
/// - latest attempt not met → needs practice;
/// - latest met → demonstrated;
/// - latest and the previous attempt both met, completed on different local
///   days → consistent (an immediate retake cannot produce it).
/// Lessons opened or completed never change these states.
abstract final class CanDoEvidence {
  static const threshold = 0.75;

  static bool met(String canDoId, AttemptRecord attempt) {
    final relevant = attempt.answers.where((a) => a.canDoId == canDoId);
    if (relevant.isEmpty) return false;
    final correct = relevant.where((a) => a.isCorrect).length;
    return correct >= threshold * relevant.length;
  }

  /// [attempts] are the attempts at the assessment that defines [canDoId].
  static CanDoState state(String canDoId, List<AttemptRecord> attempts) {
    final covering =
        attempts
            .where((a) => a.answers.any((x) => x.canDoId == canDoId))
            .toList()
          ..sort((a, b) {
            final byTime = b.completedAtMs.compareTo(a.completedAtMs);
            return byTime != 0 ? byTime : b.id.compareTo(a.id);
          });
    if (covering.isEmpty) return CanDoState.notAssessed;
    final latest = covering.first;
    if (!met(canDoId, latest)) return CanDoState.needsPractice;
    if (covering.length > 1) {
      final previous = covering[1];
      if (met(canDoId, previous) && previous.localDay != latest.localDay) {
        return CanDoState.consistent;
      }
    }
    return CanDoState.demonstrated;
  }
}

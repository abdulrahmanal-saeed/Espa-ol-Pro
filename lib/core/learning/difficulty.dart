/// Deterministic, explainable difficulty estimate of a Spanish text for this
/// learner. No model, no guess: every band is derived from three numbers
/// that are shown to the learner.
library;

import '../content/models.dart';
import 'answer_evaluator.dart';

enum DifficultyBand { veryEasy, appropriate, challenging, tooDifficult }

const difficultyLabelsAr = {
  DifficultyBand.veryEasy: 'سهل جداً',
  DifficultyBand.appropriate: 'مناسب',
  DifficultyBand.challenging: 'فيه تحدٍّ',
  DifficultyBand.tooDifficult: 'صعب الآن',
};

/// The thresholds, in one place.
///
/// Word coverage follows the reading-research rule of thumb that about 95 %
/// known words allows comprehension with effort and about 98 % comfortable
/// comprehension.
abstract final class DifficultyRules {
  /// Below this share of known words a text is too difficult.
  static const minCoverage = 0.80;

  /// Below this share it is challenging.
  static const comfortableCoverage = 0.95;

  /// At or above this share (with short sentences and no new grammar) it is
  /// very easy.
  static const easyCoverage = 0.98;

  /// More words per sentence than this makes a text challenging.
  static const longSentence = 10.0;

  /// At most this many words per sentence for "very easy".
  static const shortSentence = 6.0;

  /// This many grammar points not yet taught makes a text too difficult.
  static const maxNewGrammar = 2;
}

/// What the learner has been taught so far.
class LearnerExposure {
  const LearnerExposure({required this.knownWords, required this.grammarIds});

  /// Normalised word forms (see [wordsOf]) met in completed lessons.
  final Set<String> knownWords;
  final Set<String> grammarIds;

  /// Everything taught by [completedLessonIds]: vocabulary, its examples,
  /// and the examples of the lessons' grammar notes.
  factory LearnerExposure.from(
    ContentPack pack,
    Iterable<String> completedLessonIds,
  ) {
    final words = <String>{};
    final grammar = <String>{};
    for (final id in completedLessonIds) {
      final lesson = pack.lesson(id);
      if (lesson == null) continue;
      for (final item in lesson.items) {
        words.addAll(wordsOf(item.es));
        for (final e in item.examples) {
          words.addAll(wordsOf(e.es));
        }
      }
      for (final g in lesson.grammarIds) {
        grammar.add(g);
        for (final e in pack.grammarNote(g)?.examples ?? const <Example>[]) {
          words.addAll(wordsOf(e.es));
        }
      }
    }
    return LearnerExposure(knownWords: words, grammarIds: grammar);
  }
}

final _opensSentence = RegExp('^[¿¡]');
final _endsSentence = RegExp(r'[.?!…]["»)]*$');
final _leadingPunct = RegExp('^[¿¡"«(]+');
final _number = RegExp(r'^\d+$');

/// The countable words of [spanish]: lower-cased, punctuation removed,
/// accents kept. Numbers and capitalised names inside a sentence are not
/// vocabulary and are left out.
List<String> wordsOf(String spanish) {
  final out = <String>[];
  var sentenceStart = true;
  for (final token in spanish.split(RegExp(r'\s+'))) {
    if (token.isEmpty) continue;
    // A word opening with ¿ or ¡, or following . ? ! …, starts a sentence,
    // so its capital letter says nothing about it being a name.
    final starts = sentenceStart || _opensSentence.hasMatch(token);
    sentenceStart = _endsSentence.hasMatch(token);
    final letters = token.replaceAll(_leadingPunct, '');
    final capital =
        letters.isNotEmpty && letters[0] != letters[0].toLowerCase();
    if (capital && !starts) continue; // a name mid-sentence
    for (final part in normalizeAnswer(token).split(' ')) {
      if (part.isEmpty || _number.hasMatch(part)) continue;
      out.add(part);
    }
  }
  return out;
}

class DifficultyEstimate {
  const DifficultyEstimate({
    required this.band,
    required this.coverage,
    required this.unknownWords,
    required this.newGrammarIds,
    required this.wordsPerSentence,
  });

  final DifficultyBand band;

  /// Share of running words already met (0..1).
  final double coverage;

  /// Distinct words not met yet, in order of first appearance.
  final List<String> unknownWords;

  /// Grammar used by the text and not taught yet.
  final List<String> newGrammarIds;
  final double wordsPerSentence;

  /// The reasons behind [band], in Arabic, one per line.
  List<String> get reasonsAr => [
    'كلمات تعرفها: ${(coverage * 100).round()}٪'
        '${unknownWords.isEmpty ? '' : ' (جديدة: ${unknownWords.take(5).join('، ')}${unknownWords.length > 5 ? '…' : ''})'}',
    newGrammarIds.isEmpty
        ? 'لا قواعد جديدة'
        : 'قواعد لم تُدرَّس بعد: ${newGrammarIds.length}',
    'متوسط طول الجملة: ${wordsPerSentence.toStringAsFixed(1)} كلمة',
  ];
}

/// Estimates how hard [sentences] (one entry per sentence or turn) using
/// [grammarIds] are for a learner with [exposure]. [names] (e.g. the
/// speakers) are not vocabulary and are not counted.
DifficultyEstimate estimateDifficulty({
  required List<String> sentences,
  required List<String> grammarIds,
  required LearnerExposure exposure,
  Set<String> names = const {},
}) {
  final ignored = {for (final n in names) ...wordsOf(n)};
  final words = [
    for (final s in sentences)
      for (final w in wordsOf(s))
        if (!ignored.contains(w)) w,
  ];
  final known = words.where(exposure.knownWords.contains).length;
  final coverage = words.isEmpty ? 1.0 : known / words.length;
  final unknown = <String>[];
  for (final w in words) {
    if (!exposure.knownWords.contains(w) && !unknown.contains(w)) {
      unknown.add(w);
    }
  }
  final newGrammar = [
    for (final g in grammarIds)
      if (!exposure.grammarIds.contains(g)) g,
  ];
  final perSentence = sentences.isEmpty ? 0.0 : words.length / sentences.length;

  final DifficultyBand band;
  if (coverage < DifficultyRules.minCoverage ||
      newGrammar.length >= DifficultyRules.maxNewGrammar) {
    band = DifficultyBand.tooDifficult;
  } else if (coverage < DifficultyRules.comfortableCoverage ||
      newGrammar.isNotEmpty ||
      perSentence > DifficultyRules.longSentence) {
    band = DifficultyBand.challenging;
  } else if (coverage >= DifficultyRules.easyCoverage &&
      perSentence <= DifficultyRules.shortSentence) {
    band = DifficultyBand.veryEasy;
  } else {
    band = DifficultyBand.appropriate;
  }
  return DifficultyEstimate(
    band: band,
    coverage: coverage,
    unknownWords: unknown,
    newGrammarIds: newGrammar,
    wordsPerSentence: perSentence,
  );
}

/// The estimate for a dialogue.
DifficultyEstimate estimateDialogue(Dialogue d, LearnerExposure exposure) =>
    estimateDifficulty(
      sentences: [for (final t in d.turns) t.es],
      grammarIds: d.grammarIds,
      exposure: exposure,
      names: {for (final s in d.speakers) s.name},
    );

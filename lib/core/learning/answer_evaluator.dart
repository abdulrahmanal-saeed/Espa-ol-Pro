/// Deterministic grading of typed Spanish answers.
library;

enum AnswerVerdict {
  /// Matches an accepted answer exactly (ignoring case/punctuation/spacing).
  correct,

  /// Right words, but written accents (á é í ó ú ü) are missing or wrong.
  /// Accepted, with an explicit spelling reminder.
  correctMissingAccents,
  incorrect,
}

class AnswerResult {
  const AnswerResult(this.verdict, this.bestMatch);
  final AnswerVerdict verdict;

  /// The accepted answer closest to what was typed (shown as the correction).
  final String bestMatch;

  bool get isCorrect => verdict != AnswerVerdict.incorrect;
}

final _punct = RegExp(r'''[¿?¡!.,;:"'()«»…\-–—]''');
final _spaces = RegExp(r'\s+');

/// Lower-cases, strips punctuation and collapses whitespace.
/// Accents and ñ are preserved.
String normalizeAnswer(String s) =>
    s.toLowerCase().replaceAll(_punct, ' ').replaceAll(_spaces, ' ').trim();

const _accentMap = {'á': 'a', 'é': 'e', 'í': 'i', 'ó': 'o', 'ú': 'u', 'ü': 'u'};

/// Removes written accents but keeps ñ, which is a distinct letter
/// (año ≠ ano), never an "accent".
String stripAccents(String s) {
  final b = StringBuffer();
  for (final ch in s.split('')) {
    b.write(_accentMap[ch] ?? ch);
  }
  return b.toString();
}

AnswerResult evaluateAnswer(String input, List<String> accepted) {
  assert(accepted.isNotEmpty);
  final typed = normalizeAnswer(input);
  for (final a in accepted) {
    if (normalizeAnswer(a) == typed) {
      return AnswerResult(AnswerVerdict.correct, a);
    }
  }
  final typedBare = stripAccents(typed);
  for (final a in accepted) {
    if (stripAccents(normalizeAnswer(a)) == typedBare) {
      return AnswerResult(AnswerVerdict.correctMissingAccents, a);
    }
  }
  // Pick the closest accepted answer to show as the correction.
  var best = accepted.first;
  var bestDistance = 1 << 30;
  for (final a in accepted) {
    final d = levenshtein(typedBare, stripAccents(normalizeAnswer(a)));
    if (d < bestDistance) {
      bestDistance = d;
      best = a;
    }
  }
  return AnswerResult(AnswerVerdict.incorrect, best);
}

int levenshtein(String a, String b) {
  if (a == b) return 0;
  if (a.isEmpty) return b.length;
  if (b.isEmpty) return a.length;
  var prev = List<int>.generate(b.length + 1, (i) => i);
  for (var i = 0; i < a.length; i++) {
    final cur = List<int>.filled(b.length + 1, 0);
    cur[0] = i + 1;
    for (var j = 0; j < b.length; j++) {
      final cost = a[i] == b[j] ? 0 : 1;
      cur[j + 1] = [
        cur[j] + 1,
        prev[j + 1] + 1,
        prev[j] + cost,
      ].reduce((x, y) => x < y ? x : y);
    }
    prev = cur;
  }
  return prev[b.length];
}

/// Splits a sentence into ordering tokens, keeping punctuation attached.
List<String> tokenize(String sentence) =>
    sentence.trim().split(_spaces).where((t) => t.isNotEmpty).toList();

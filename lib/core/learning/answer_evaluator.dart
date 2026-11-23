/// Deterministic grading of typed Spanish answers.
library;

enum AnswerVerdict {
  /// Matches an accepted answer exactly (ignoring case/punctuation/spacing).
  correct,

  /// Right words, but written accents (á é í ó ú ü) are missing or wrong,
  /// and no missing accent changes the meaning. Accepted, with an explicit
  /// spelling reminder.
  correctMissingAccents,
  incorrect,
}

/// What kind of difference separates the answer from the closest accepted
/// one. Derived only from the two strings — never a guess about intent.
enum AnswerIssue {
  /// No difference.
  none,

  /// Only written accents differ, and none of them changes the meaning.
  accents,

  /// An accent that changes the meaning is missing or misplaced
  /// (si/sí, tu/tú, el/él …). Marked wrong.
  accentMeaning,

  /// ñ written as n (or the reverse): a different letter, so a different
  /// word (año / ano). Marked wrong.
  enye,

  /// The same words in a different order.
  wordOrder,

  /// One word has the wrong form (ending or article), e.g. hablo/habla,
  /// bueno/buena, el/la.
  grammarForm,

  /// A small misspelling of the right word(s).
  spelling,

  /// A different answer.
  meaning,
}

/// Pairs where the written accent distinguishes two words. Missing it is a
/// meaning error, not a spelling slip. Interrogatives (qué, cómo, dónde …)
/// are deliberately not here: at Pre-A1/A1 they are accepted with a
/// reminder, because the question marks already carry the meaning.
const meaningAccentPairs = {
  'si': 'sí',
  'tu': 'tú',
  'el': 'él',
  'mi': 'mí',
  'te': 'té',
  'se': 'sé',
  'de': 'dé',
  'mas': 'más',
  'aun': 'aún',
  'esta': 'está',
  'papa': 'papá',
};

/// Endings that mark person, number or gender at A1. Two forms of one word
/// differ only in these (hablo/habla, bueno/buenas, casa/casas).
const _endings = {
  'o',
  'a',
  'e',
  'as',
  'es',
  'os',
  'an',
  'en',
  'amos',
  'emos',
  'imos',
  'ais',
  'eis',
  'is',
  // Pretérito indefinido (compared without accents: é → e, ió → io).
  'aste',
  'aron',
  'i',
  'io',
  'iste',
  'ieron',
  'asteis',
  'isteis',
  // Pretérito imperfecto (B1-U2), accents stripped: trabajaba, comía.
  'aba',
  'abas',
  'abamos',
  'abais',
  'aban',
  'ia',
  'ias',
  'iamos',
  'iais',
  'ian',
};

bool _isInflection(String a, String b) {
  var p = 0;
  while (p < a.length && p < b.length && a[p] == b[p]) {
    p++;
  }
  if (p < 2 || a == b) return false;
  final x = a.substring(p);
  final y = b.substring(p);
  bool ending(String s) => _endings.contains(s);
  // Plural: casa/casas, ciudad/ciudades.
  if ((x.isEmpty && (y == 's' || y == 'es')) ||
      (y.isEmpty && (x == 's' || x == 'es'))) {
    return true;
  }
  return ending(x) && ending(y) ||
      // trabajo/trabajamos share "trabaj" only after backing off one letter.
      (p >= 3 && ending(a.substring(p - 1)) && ending(b.substring(p - 1)));
}

const _articles = {'el', 'la', 'los', 'las', 'un', 'una', 'unos', 'unas'};

class AnswerResult {
  const AnswerResult(
    this.verdict,
    this.bestMatch, {
    this.issue = AnswerIssue.none,
    this.typedWord,
    this.expectedWord,
  });
  final AnswerVerdict verdict;

  /// The accepted answer closest to what was typed (shown as the correction).
  final String bestMatch;

  final AnswerIssue issue;

  /// For single-word issues, the word as typed and as expected.
  final String? typedWord;
  final String? expectedWord;

  bool get isCorrect => verdict != AnswerVerdict.incorrect;

  /// One-line Arabic explanation of [issue], empty when there is nothing to
  /// say.
  String get explanationAr => switch (issue) {
    AnswerIssue.none => '',
    AnswerIssue.accents =>
      verdict == AnswerVerdict.incorrect
          ? 'من مستوى B1 تُحسب علامات النبر: الصحيح «$bestMatch».'
          : 'المعنى صحيح، لكن انتبه لعلامات النبر: $bestMatch',
    AnswerIssue.accentMeaning =>
      isFinalStressPair(typedWord ?? '', expectedWord ?? '') &&
              !finalStressNonVerbs.contains(expectedWord) &&
              !finalStressNonVerbs.contains(typedWord)
          ? 'علامة النبر في آخر الفعل تغيّر الزمن أو الشخص: «$expectedWord» ليست «$typedWord».'
          : 'علامة النبر هنا تغيّر المعنى: «$expectedWord» ليست «$typedWord».',
    AnswerIssue.enye => 'ñ حرف مستقل وليس n بعلامة: «$expectedWord».',
    AnswerIssue.wordOrder => 'الكلمات صحيحة لكن ترتيبها مختلف.',
    AnswerIssue.grammarForm =>
      'الكلمة صحيحة لكن صيغتها لا تناسب الجملة: «$expectedWord» بدل «$typedWord».',
    AnswerIssue.spelling => 'قريبة جداً — خطأ إملائي: «$expectedWord».',
    AnswerIssue.meaning => '',
  };
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

/// Grades [input] against [accepted].
///
/// With [strictAccents] (B1 and above, see `Level.strictAccents`), an
/// answer whose only difference is written accents is **incorrect**, with
/// the same [AnswerIssue.accents] diagnosis and the correct form. Without
/// it (Pre-A1 to A2) it is accepted with a reminder. ñ and meaning-bearing
/// accents are wrong either way.
AnswerResult evaluateAnswer(
  String input,
  List<String> accepted, {
  bool strictAccents = false,
}) {
  assert(accepted.isNotEmpty);
  final typed = normalizeAnswer(input);
  for (final a in accepted) {
    if (normalizeAnswer(a) == typed) {
      return AnswerResult(AnswerVerdict.correct, a);
    }
  }
  final typedBare = stripAccents(typed);
  AnswerResult? meaningAccent;
  for (final a in accepted) {
    final norm = normalizeAnswer(a);
    if (stripAccents(norm) != typedBare) continue;
    final pair = _meaningAccentDifference(typed, norm);
    if (pair == null) {
      return AnswerResult(
        strictAccents
            ? AnswerVerdict.incorrect
            : AnswerVerdict.correctMissingAccents,
        a,
        issue: AnswerIssue.accents,
      );
    }
    meaningAccent ??= AnswerResult(
      AnswerVerdict.incorrect,
      a,
      issue: AnswerIssue.accentMeaning,
      typedWord: pair.$1,
      expectedWord: pair.$2,
    );
  }
  if (meaningAccent != null) return meaningAccent;

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
  return _diagnose(typed, best);
}

/// Words of five letters or more ending in a stressed é / ó that are not
/// verb forms (REVIEW-015 P3). A missing accent still changes the word
/// (bebé ≠ bebe), but the explanation must not talk about tense. The content
/// validator requires every such word in an answer to be a verb form from
/// the reference or listed here, so new content cannot slip past this.
const finalStressNonVerbs = {
  'bebé',
  'canapé',
  'carné',
  'chalé',
  'cliché',
  'comité',
  'consomé',
  'dominó',
  'puré',
};

/// Whether [a] and [b] differ only by a written accent on a final é / ó, in
/// a word of five letters or more: habló / hablo, trabajé / trabaje,
/// envió / envio. In verbs that accent marks the pretérito indefinido (or
/// another person), so leaving it out is a different form, not a slip.
/// Short words keep the lenient rule (café / cafe).
bool isFinalStressPair(String a, String b) {
  if (a.length != b.length || a.length < 5 || a == b) return false;
  const plain = {'é': 'e', 'ó': 'o'};
  final head = a.substring(0, a.length - 1);
  if (head != b.substring(0, b.length - 1)) return false;
  final x = a[a.length - 1];
  final y = b[b.length - 1];
  return plain[x] == y || plain[y] == x;
}

/// The first word pair whose only difference is a meaning-bearing accent.
(String, String)? _meaningAccentDifference(String typed, String expected) {
  final t = typed.split(' ');
  final e = expected.split(' ');
  if (t.length != e.length) return null;
  for (var i = 0; i < t.length; i++) {
    if (t[i] == e[i]) continue;
    if (isFinalStressPair(t[i], e[i])) return (t[i], e[i]);
    final bare = stripAccents(e[i]);
    final accented = meaningAccentPairs[bare];
    if (accented == null) continue;
    // Either form typed where the other was required.
    if ((e[i] == accented && t[i] == bare) ||
        (e[i] == bare && t[i] == accented)) {
      return (t[i], e[i]);
    }
  }
  return null;
}

AnswerResult _diagnose(String typed, String best) {
  AnswerResult r(AnswerIssue issue, [String? tw, String? ew]) => AnswerResult(
    AnswerVerdict.incorrect,
    best,
    issue: issue,
    typedWord: tw,
    expectedWord: ew,
  );
  final expected = normalizeAnswer(best);
  final tBare = stripAccents(typed);
  final eBare = stripAccents(expected);
  final tWords = tBare.split(' ');
  final eWords = eBare.split(' ');
  final eShown = expected.split(' ');

  int? differing() {
    if (tWords.length != eWords.length) return null;
    int? index;
    for (var i = 0; i < tWords.length; i++) {
      if (tWords[i] == eWords[i]) continue;
      if (index != null) return null;
      index = i;
    }
    return index;
  }

  // ñ ↔ n.
  if (tBare.replaceAll('ñ', 'n') == eBare.replaceAll('ñ', 'n')) {
    final k = differing();
    return r(
      AnswerIssue.enye,
      k == null ? null : typed.split(' ')[k],
      k == null ? expected : eShown[k],
    );
  }
  // Same words, other order.
  if (tWords.length > 1 && tWords.length == eWords.length) {
    final a = [...tWords]..sort();
    final b = [...eWords]..sort();
    if (a.join(' ') == b.join(' ')) return r(AnswerIssue.wordOrder);
  }
  final k = differing();
  if (k != null) {
    final tw = tWords[k];
    final ew = eWords[k];
    final articleSwap = _articles.contains(tw) && _articles.contains(ew);
    if (articleSwap || _isInflection(tw, ew)) {
      return r(AnswerIssue.grammarForm, typed.split(' ')[k], eShown[k]);
    }
    final limit = ew.length <= 5 ? 1 : 2;
    if (levenshtein(tw, ew) <= limit) {
      return r(AnswerIssue.spelling, typed.split(' ')[k], eShown[k]);
    }
    return r(AnswerIssue.meaning);
  }
  final limit = eBare.length <= 5 ? 1 : 2;
  if (levenshtein(tBare, eBare) <= limit) {
    return r(AnswerIssue.spelling, null, expected);
  }
  return r(AnswerIssue.meaning);
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

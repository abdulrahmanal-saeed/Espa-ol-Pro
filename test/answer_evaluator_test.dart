import 'package:espanol_pro/core/learning/answer_evaluator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('exact answers are correct regardless of case and punctuation', () {
    final r = evaluateAnswer('  ¿como ESTÁS?  ', ['¿Cómo estás?']);
    // accent on "cómo" is missing here → accepted with reminder
    expect(r.verdict, AnswerVerdict.correctMissingAccents);
    expect(
      evaluateAnswer('¿Cómo estás?', ['¿Cómo estás?']).verdict,
      AnswerVerdict.correct,
    );
    expect(
      evaluateAnswer('cómo estás', ['¿Cómo estás?']).verdict,
      AnswerVerdict.correct,
    );
  });

  test('missing accents are accepted but flagged', () {
    final r = evaluateAnswer('telefono', ['teléfono']);
    expect(r.isCorrect, isTrue);
    expect(r.verdict, AnswerVerdict.correctMissingAccents);
    expect(r.bestMatch, 'teléfono');
  });

  test('ñ is a letter, not an accent', () {
    expect(evaluateAnswer('manana', ['mañana']).isCorrect, isFalse);
    expect(evaluateAnswer('espanol', ['español']).isCorrect, isFalse);
  });

  test('wrong words are incorrect', () {
    expect(evaluateAnswer('adios', ['hola']).isCorrect, isFalse);
    expect(evaluateAnswer('casaa', ['casa']).isCorrect, isFalse);
    expect(evaluateAnswer('', ['casa']).isCorrect, isFalse);
  });

  test('any accepted alternative matches', () {
    expect(
      evaluateAnswer('encantada', ['encantado', 'encantada']).verdict,
      AnswerVerdict.correct,
    );
  });

  test('incorrect answers report the closest accepted form', () {
    final r = evaluateAnswer('soy de egypto', [
      'De Egipto',
      'Soy de Egipto',
      'Yo soy de Egipto',
    ]);
    expect(r.isCorrect, isFalse);
    expect(r.bestMatch, 'Soy de Egipto');
  });

  test('levenshtein distance', () {
    expect(levenshtein('casa', 'casa'), 0);
    expect(levenshtein('casa', 'cosa'), 1);
    expect(levenshtein('', 'abc'), 3);
    expect(levenshtein('gato', 'pato'), 1);
  });

  test('tokenize keeps punctuation attached', () {
    expect(tokenize('Muy bien, gracias. ¿Y tú?'), [
      'Muy',
      'bien,',
      'gracias.',
      '¿Y',
      'tú?',
    ]);
  });

  group('diagnosis', () {
    AnswerIssue issue(String typed, List<String> accepted) =>
        evaluateAnswer(typed, accepted).issue;

    test('harmless missing accents are accepted as "accents"', () {
      final r = evaluateAnswer('telefono', ['teléfono']);
      expect(r.issue, AnswerIssue.accents);
      expect(r.explanationAr, contains('teléfono'));
      // Interrogatives stay lenient at this level.
      expect(evaluateAnswer('como estas', ['¿Cómo estás?']).isCorrect, isTrue);
    });

    test('si / sí and tu / tú change the meaning and are wrong', () {
      final si = evaluateAnswer('si, soy Ana', ['Sí, soy Ana.']);
      expect(si.isCorrect, isFalse);
      expect(si.issue, AnswerIssue.accentMeaning);
      expect(si.typedWord, 'si');
      expect(si.expectedWord, 'sí');
      expect(si.explanationAr, contains('تغيّر المعنى'));

      final tu = evaluateAnswer('¿Y tu?', ['¿Y tú?']);
      expect(tu.isCorrect, isFalse);
      expect(tu.issue, AnswerIssue.accentMeaning);

      // The reverse — an accent where none belongs — is also wrong.
      final mi = evaluateAnswer('mí casa', ['mi casa']);
      expect(mi.isCorrect, isFalse);
      expect(mi.issue, AnswerIssue.accentMeaning);
      expect(issue('el es Juan', ['Él es Juan.']), AnswerIssue.accentMeaning);
      expect(
        issue('esta en casa', ['Está en casa.']),
        AnswerIssue.accentMeaning,
      );
    });

    test('a meaning accent alongside harmless ones still fails', () {
      expect(
        evaluateAnswer('si, telefono', ['Sí, teléfono']).isCorrect,
        isFalse,
      );
    });

    test('another accepted answer can rescue a meaning-accent mismatch', () {
      // "tu" is accepted in its own right here.
      expect(
        evaluateAnswer('tu casa', ['tú casa', 'tu casa']).verdict,
        AnswerVerdict.correct,
      );
    });

    test('ñ is a distinct letter with its own diagnosis', () {
      final r = evaluateAnswer('manana', ['mañana']);
      expect(r.isCorrect, isFalse);
      expect(r.issue, AnswerIssue.enye);
      expect(r.expectedWord, 'mañana');
      expect(issue('hablo espanol', ['Hablo español.']), AnswerIssue.enye);
      expect(
        evaluateAnswer('hablo espanol', ['Hablo español.']).typedWord,
        'espanol',
      );
    });

    test('word order', () {
      expect(issue('egipto soy de', ['Soy de Egipto']), AnswerIssue.wordOrder);
    });

    test('grammar form: endings, plural and articles', () {
      final r = evaluateAnswer('yo habla español', ['Yo hablo español.']);
      expect(r.issue, AnswerIssue.grammarForm);
      expect(r.typedWord, 'habla');
      expect(r.expectedWord, 'hablo');
      expect(
        issue('buenos tardes', ['Buenas tardes']),
        AnswerIssue.grammarForm,
      );
      expect(issue('las casa', ['las casas']), AnswerIssue.grammarForm);
      expect(issue('el mesa', ['la mesa']), AnswerIssue.grammarForm);
      expect(
        issue('nosotros trabajo', ['nosotros trabajamos']),
        AnswerIssue.grammarForm,
      );
    });

    test('spelling: a near miss of the right word', () {
      expect(issue('casaa', ['casa']), AnswerIssue.spelling);
      expect(issue('cliennte', ['cliente']), AnswerIssue.spelling);
      expect(issue('soy de egypto', ['Soy de Egipto']), AnswerIssue.spelling);
    });

    test('meaning: a different word', () {
      expect(issue('adios', ['hola']), AnswerIssue.meaning);
      expect(issue('soy', ['es']), AnswerIssue.meaning);
      expect(issue('perro grande', ['gato negro']), AnswerIssue.meaning);
      expect(evaluateAnswer('adios', ['hola']).explanationAr, isEmpty);
    });

    test('correct answers have no issue', () {
      expect(issue('Hola', ['hola']), AnswerIssue.none);
    });
  });
}

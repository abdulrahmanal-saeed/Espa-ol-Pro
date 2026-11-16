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
}

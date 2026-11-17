import 'package:espanol_pro/core/content/models.dart';
import 'package:espanol_pro/core/learning/difficulty.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support.dart';

/// A text of [total] words per sentence-set with exactly [known] known
/// words, built from distinct synthetic words.
DifficultyEstimate withCoverage(
  int known,
  int total, {
  int sentences = 0,
  List<String> grammar = const [],
  Set<String> taught = const {},
}) {
  final words = [for (var i = 0; i < total; i++) 'w$i'];
  final perSentence = sentences == 0 ? 1 : (total / sentences).ceil();
  final text = [
    for (var i = 0; i < total; i += perSentence)
      words.skip(i).take(perSentence).join(' '),
  ];
  return estimateDifficulty(
    sentences: text,
    grammarIds: grammar,
    exposure: LearnerExposure(
      knownWords: words.take(known).toSet(),
      grammarIds: taught,
    ),
  );
}

void main() {
  group('bands at their boundaries', () {
    test(
      'coverage exactly 80 % is challenging; just below is too difficult',
      () {
        expect(
          withCoverage(80, 100, sentences: 20).band,
          DifficultyBand.challenging,
        );
        expect(
          withCoverage(79, 100, sentences: 20).band,
          DifficultyBand.tooDifficult,
        );
      },
    );

    test('coverage exactly 95 % is appropriate; just below is challenging', () {
      expect(
        withCoverage(95, 100, sentences: 20).band,
        DifficultyBand.appropriate,
      );
      expect(
        withCoverage(94, 100, sentences: 20).band,
        DifficultyBand.challenging,
      );
    });

    test('98 % with short sentences is very easy; 97 % is appropriate', () {
      expect(
        withCoverage(98, 100, sentences: 20).band,
        DifficultyBand.veryEasy,
      );
      expect(
        withCoverage(97, 100, sentences: 20).band,
        DifficultyBand.appropriate,
      );
    });

    test('sentence length: 6 words can be very easy, 7 cannot', () {
      expect(withCoverage(60, 60, sentences: 10).band, DifficultyBand.veryEasy);
      expect(
        withCoverage(70, 70, sentences: 10).band,
        DifficultyBand.appropriate,
      );
    });

    test('sentence length: 10 words is fine, 11 is challenging', () {
      expect(
        withCoverage(100, 100, sentences: 10).band,
        DifficultyBand.appropriate,
      );
      expect(
        withCoverage(110, 110, sentences: 10).band,
        DifficultyBand.challenging,
      );
    });

    test('one new grammar point is challenging; two are too difficult', () {
      expect(
        withCoverage(10, 10, sentences: 5, grammar: ['g1']).band,
        DifficultyBand.challenging,
      );
      expect(
        withCoverage(10, 10, sentences: 5, grammar: ['g1', 'g2']).band,
        DifficultyBand.tooDifficult,
      );
      expect(
        withCoverage(
          10,
          10,
          sentences: 5,
          grammar: ['g1'],
          taught: {'g1'},
        ).band,
        DifficultyBand.veryEasy,
      );
    });

    test('an empty text is not an error', () {
      final e = estimateDifficulty(
        sentences: const [],
        grammarIds: const [],
        exposure: const LearnerExposure(knownWords: {}, grammarIds: {}),
      );
      expect(e.coverage, 1);
      expect(e.band, DifficultyBand.veryEasy);
    });
  });

  group('words', () {
    test('punctuation, case and numbers are ignored; accents kept', () {
      expect(wordsOf('¡Hola! ¿Cómo estás? Tengo 3 hijos.'), [
        'hola',
        'cómo',
        'estás',
        'tengo',
        'hijos',
      ]);
    });

    test('capitalised names inside a sentence are not vocabulary', () {
      expect(wordsOf('Soy de Egipto y trabajo con Laura.'), [
        'soy',
        'de',
        'y',
        'trabajo',
        'con',
      ]);
    });

    test('named speakers are excluded even at the start of a sentence', () {
      final e = estimateDifficulty(
        sentences: const ['Omar, buenos días.'],
        grammarIds: const [],
        exposure: const LearnerExposure(
          knownWords: {'buenos', 'días'},
          grammarIds: {},
        ),
        names: const {'Omar'},
      );
      expect(e.coverage, 1);
      expect(e.unknownWords, isEmpty);
    });

    test('reasons name the numbers behind the band', () {
      final e = withCoverage(9, 10, sentences: 2, grammar: ['g']);
      expect(e.unknownWords, ['w9']);
      expect(e.reasonsAr.join('\n'), contains('90٪'));
      expect(e.reasonsAr.join('\n'), contains('w9'));
      expect(e.reasonsAr.join('\n'), contains('قواعد لم تُدرَّس بعد: 1'));
      expect(e.reasonsAr.join('\n'), contains('5.0'));
    });
  });

  group('real content', () {
    late ContentPack pack;
    setUpAll(() async => pack = await loadRealContent());

    LearnerExposure upTo(Dialogue d) {
      final last = d.lessonIds
          .map((l) => pack.orderedLessons.indexWhere((x) => x.id == l))
          .reduce((a, b) => a > b ? a : b);
      return LearnerExposure.from(
        pack,
        pack.orderedLessons.take(last + 1).map((l) => l.id),
      );
    }

    test('every dialogue is accessible right after its lessons', () {
      for (final d in pack.dialogues) {
        final e = estimateDialogue(d, upTo(d));
        expect(
          e.band,
          isIn([DifficultyBand.veryEasy, DifficultyBand.appropriate]),
          reason: '${d.id}: ${e.reasonsAr}',
        );
      }
    });

    test('a beginner with no lessons finds A1 dialogues too difficult', () {
      final empty = LearnerExposure.from(pack, const []);
      for (final d in pack.dialogues.where((d) => d.levelId == 'a1')) {
        expect(estimateDialogue(d, empty).band, DifficultyBand.tooDifficult);
      }
    });

    test('the estimate is deterministic', () {
      final d = pack.dialogues.first;
      final a = estimateDialogue(d, upTo(d));
      final b = estimateDialogue(d, upTo(d));
      expect(a.band, b.band);
      expect(a.coverage, b.coverage);
      expect(a.unknownWords, b.unknownWords);
    });
  });
}

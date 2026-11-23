import 'dart:convert';
import 'dart:io';

import 'package:espanol_pro/core/content/content_parser.dart';
import 'package:espanol_pro/core/content/content_validator.dart';
import 'package:espanol_pro/core/content/models.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support.dart';

/// B1 verb reference: optional imperfect, conditional and present
/// subjunctive, rule-checked for regular verbs and backward compatible.
void main() {
  Future<List<String>> verbIssuesWith(
    void Function(List<Map<String, dynamic>> verbs) edit,
  ) async {
    final broken = await parseContentPack((path) async {
      final text = await File('$contentDir/$path').readAsString();
      if (path != 'verbs.json') return text;
      final doc = jsonDecode(text) as Map<String, dynamic>;
      edit((doc['verbs'] as List).cast<Map<String, dynamic>>());
      return jsonEncode(doc);
    });
    return ContentValidator().validate(broken).map((i) => '$i').toList();
  }

  Map<String, dynamic> verb(List<Map<String, dynamic>> vs, String id) =>
      vs.firstWhere((v) => v['id'] == id);

  Map<String, String> six(List<String> f) => {
    for (var i = 0; i < 6; i++) Verb.persons[i]: f[i],
  };

  group('rules for regular verbs', () {
    test('imperfect: -aba / -ía', () {
      expect(
        Verb.regularImperfect('hablar'),
        six([
          'hablaba',
          'hablabas',
          'hablaba',
          'hablábamos',
          'hablabais',
          'hablaban',
        ]),
      );
      expect(
        Verb.regularImperfect('comer'),
        six(['comía', 'comías', 'comía', 'comíamos', 'comíais', 'comían']),
      );
      expect(Verb.regularImperfect('vivir')!['nosotros'], 'vivíamos');
      // tener is irregular in the present, regular here.
      expect(Verb.regularImperfect('tener')!['yo'], 'tenía');
      expect(Verb.regularImperfect('x'), isNull);
    });

    test('conditional: the whole infinitive + -ía', () {
      expect(
        Verb.regularConditional('hablar'),
        six([
          'hablaría',
          'hablarías',
          'hablaría',
          'hablaríamos',
          'hablaríais',
          'hablarían',
        ]),
      );
      expect(Verb.regularConditional('ser')!['el'], 'sería');
      expect(Verb.regularConditional('ir')!['yo'], 'iría');
      expect(Verb.regularConditional('vivir')!['ellos'], 'vivirían');
      expect(Verb.regularConditional('xyz'), isNull);
    });

    test('present subjunctive: swapped vowel, spelling kept by sound', () {
      expect(
        Verb.regularSubjunctive('hablar'),
        six(['hable', 'hables', 'hable', 'hablemos', 'habléis', 'hablen']),
      );
      expect(
        Verb.regularSubjunctive('comer'),
        six(['coma', 'comas', 'coma', 'comamos', 'comáis', 'coman']),
      );
      expect(Verb.regularSubjunctive('vivir')!['tu'], 'vivas');
      // -car / -gar / -zar / -ger change in EVERY person, not only yo.
      expect(Verb.regularSubjunctive('explicar')!['nosotros'], 'expliquemos');
      expect(Verb.regularSubjunctive('llegar')!['el'], 'llegue');
      expect(Verb.regularSubjunctive('organizar')!['ellos'], 'organicen');
      expect(Verb.regularSubjunctive('escoger')!['yo'], 'escoja');
      expect(Verb.regularSubjunctive('x'), isNull);
    });

    test('the optional tenses are listed in teaching order', () {
      expect(Verb.optionalTenses.map((t) => t.key), [
        'preterite',
        'imperfect',
        'conditional',
        'subjunctive',
      ]);
      // The library key of the past is unchanged (`verb-past-…`).
      expect(Verb.optionalTenses.first.uiKey, 'verb-past');
    });
  });

  group('parser and validator', () {
    test(
      'a verb file without the new fields still loads and validates',
      () async {
        final issues = await verbIssuesWith((vs) {
          for (final v in vs) {
            for (final k in ['imperfect', 'conditional', 'subjunctive']) {
              v.remove(k);
              v.remove('${k}_regular');
            }
          }
        });
        // Only the final-stress rule may notice answers that lose their verb
        // backing; nothing about the verb file itself.
        expect(
          issues.where((i) => i.contains('verb:')),
          isEmpty,
          reason: issues.join('\n'),
        );
        expect(
          issues.every((i) => i.contains('ends in a stressed é/ó')),
          isTrue,
          reason: issues.join('\n'),
        );
      },
    );

    test('regular forms are machine-checked; irregular ones by hand', () async {
      final ok = await verbIssuesWith((vs) {
        final h = verb(vs, 'hablar');
        h['imperfect'] = Verb.regularImperfect('hablar');
        h['conditional'] = Verb.regularConditional('hablar');
        h['subjunctive'] = Verb.regularSubjunctive('hablar');
        // tener: regular imperfect (override), irregular conditional and
        // subjunctive (its default, since tener is irregular).
        final t = verb(vs, 'tener');
        t['imperfect'] = Verb.regularImperfect('tener');
        t['imperfect_regular'] = true;
        t['conditional'] = six([
          'tendría',
          'tendrías',
          'tendría',
          'tendríamos',
          'tendríais',
          'tendrían',
        ]);
        t['subjunctive'] = six([
          'tenga',
          'tengas',
          'tenga',
          'tengamos',
          'tengáis',
          'tengan',
        ]);
      });
      expect(ok.where((i) => i.contains('verb:')), isEmpty, reason: '$ok');

      final pack = await parseContentPack((path) async {
        final text = await File('$contentDir/$path').readAsString();
        if (path != 'verbs.json') return text;
        final doc = jsonDecode(text) as Map<String, dynamic>;
        final t = verb((doc['verbs'] as List).cast(), 'tener');
        t['imperfect'] = Verb.regularImperfect('tener');
        t['imperfect_regular'] = true;
        return jsonEncode(doc);
      });
      final tener = pack.verb('tener')!;
      expect(tener.imperfect['yo'], 'tenía');
      expect(tener.imperfectRegular, isTrue);
      expect(tener.conditionalRegular, isFalse); // defaults to `regular`
      expect(tener.allForms, contains('tenía'));
    });

    test('wrong, missing and unknown forms are rejected per tense', () async {
      expect(
        await verbIssuesWith((vs) {
          verb(vs, 'hablar')['imperfect'] = {
            ...Verb.regularImperfect('hablar')!,
            'nosotros': 'hablabamos',
          };
        }),
        contains(
          contains(
            'regular imperfect form for "nosotros" should be "hablábamos"',
          ),
        ),
      );
      expect(
        await verbIssuesWith((vs) {
          verb(vs, 'comer')['conditional'] = {
            ...Verb.regularConditional('comer')!,
            'yo': 'comeria',
          };
        }),
        contains(
          contains('regular conditional form for "yo" should be "comería"'),
        ),
      );
      expect(
        await verbIssuesWith((vs) {
          verb(vs, 'llegar')['subjunctive'] = {
            ...Verb.regularSubjunctive('llegar')!,
            'el': 'llege',
          };
        }),
        contains(
          contains('regular subjunctive form for "el" should be "llegue"'),
        ),
      );
      expect(
        await verbIssuesWith((vs) {
          verb(vs, 'hacer')['conditional'] = {
            ...six([
              'haría',
              'harías',
              'haría',
              'haríamos',
              'haríais',
              'harían',
            ]),
          }..remove('tu');
        }),
        contains(contains('missing conditional form for "tu"')),
      );
      expect(
        await verbIssuesWith((vs) {
          verb(vs, 'ser')['subjunctive'] = {
            ...six(['sea', 'seas', 'sea', 'seamos', 'seáis', 'sean']),
            'usted': 'sea',
          };
        }),
        contains(contains('unknown subjunctive person "usted"')),
      );
      expect(
        await verbIssuesWith((vs) {
          verb(vs, 'ir')['imperfect'] = six([
            'iba',
            'ibas',
            'iba',
            'íbamos',
            'ibais',
            'iban',
          ]);
          verb(vs, 'ir')['imperfect_regular'] = true;
        }),
        contains(contains('a regular imperfect needs an -ar, -er or -ir verb')),
      );
    });
  });
}

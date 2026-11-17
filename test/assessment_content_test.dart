import 'dart:convert';
import 'dart:io';

import 'package:espanol_pro/core/content/content_parser.dart';
import 'package:espanol_pro/core/content/content_validator.dart';
import 'package:espanol_pro/core/content/models.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support.dart';

/// Parses the real package, letting a test edit one assessment file first.
Future<List<String>> issuesWith(
  void Function(List<Map<String, dynamic>> assessments) edit, {
  String file = 'assessments/pre_a1.json',
}) async {
  final pack = await parseContentPack((path) async {
    final text = await File('$contentDir/$path').readAsString();
    if (path != file) return text;
    final doc = jsonDecode(text) as Map<String, dynamic>;
    edit((doc['assessments'] as List).cast<Map<String, dynamic>>());
    return jsonEncode(doc);
  });
  return ContentValidator().validate(pack).map((i) => '$i').toList();
}

void main() {
  late ContentPack pack;
  setUpAll(() async => pack = await loadRealContent());

  group('shipped checkpoints', () {
    test('every available unit has exactly one valid checkpoint', () {
      final issues = ContentValidator().validate(pack);
      expect(issues, isEmpty, reason: issues.join('\n'));
      for (final level in pack.levels) {
        for (final unit in level.units.where((u) => u.isAvailable)) {
          expect(pack.checkpointFor(unit.id), isNotNull, reason: unit.id);
        }
      }
    });

    test('never measure speaking and never claim certification', () {
      final claim = RegExp(r'CEFR|DELE|شهادة معتمدة', caseSensitive: false);
      for (final a in pack.assessments) {
        expect(a.questions.any((q) => q.skill == 'speaking'), isFalse);
        expect(claim.hasMatch(a.introAr), isFalse, reason: a.id);
        expect(claim.hasMatch(a.titleAr), isFalse, reason: a.id);
      }
    });

    test('every can-do has at least two questions as evidence', () {
      for (final a in pack.assessments) {
        for (final c in a.canDos) {
          expect(
            a.questions.where((q) => q.canDoId == c.id).length,
            greaterThanOrEqualTo(2),
            reason: c.id,
          );
        }
      }
    });
  });

  group('validator rejects broken checkpoints', () {
    Future<void> rejects(
      void Function(Map<String, dynamic> a) edit,
      String message,
    ) async {
      final issues = await issuesWith((as) => edit(as.first));
      expect(issues.join('\n'), contains(message));
    }

    List<Map<String, dynamic>> qs(Map<String, dynamic> a) =>
        (a['questions'] as List).cast<Map<String, dynamic>>();

    test(
      'version below 1',
      () => rejects((a) => a['version'] = 0, 'version must be ≥ 1'),
    );

    test(
      'missing intro',
      () => rejects((a) => a['intro_ar'] = '', 'needs title_ar and intro_ar'),
    );

    test(
      'unknown unit',
      () => rejects(
        (a) => a['unit'] = 'no_unit',
        'unit checkpoint needs a known "unit"',
      ),
    );

    test(
      'unit from another level',
      () => rejects((a) => a['unit'] = 'a1_u1', 'is not in level "pre_a1"'),
    );

    test('a second checkpoint for the same unit', () async {
      final issues = await issuesWith((as) {
        as[1]['unit'] = as[0]['unit'];
      });
      expect(issues.join('\n'), contains('second checkpoint for unit'));
    });

    test(
      'a level assessment that names a unit',
      () => rejects((a) => a['kind'] = 'level', 'a level assessment has no'),
    );

    test(
      'unknown kind',
      () =>
          rejects((a) => a['kind'] = 'quiz', 'kind must be "unit" or "level"'),
    );

    test(
      'can-do without Arabic text',
      () => rejects(
        (a) => ((a['can_do'] as List).first as Map)['ar'] = 'I can',
        'can-do needs Arabic text',
      ),
    );

    test(
      'can-do pointing at a lesson outside the unit',
      () => rejects(
        (a) => ((a['can_do'] as List).first as Map)['lessons'] = ['pa1_u2_l1'],
        'is outside unit',
      ),
    );

    test(
      'can-do with only one question as evidence',
      () => rejects((a) {
        final id = ((a['can_do'] as List).first as Map)['id'];
        var kept = false;
        for (final q in qs(a)) {
          if (q['can_do'] != id) continue;
          if (kept) q['can_do'] = ((a['can_do'] as List)[1] as Map)['id'];
          kept = true;
        }
      }, 'needs at least 2 questions as evidence'),
    );

    test(
      'fewer than 8 questions',
      () => rejects(
        (a) => (a['questions'] as List).removeRange(0, 3),
        'needs at least 8 questions',
      ),
    );

    test(
      'speaking is not objectively measurable',
      () => rejects(
        (a) => qs(a).first['skill'] = 'speaking',
        'cannot be measured objectively',
      ),
    );

    test(
      'question for an unknown can-do',
      () => rejects(
        (a) => qs(a).first['can_do'] = 'cd_nothing',
        'unknown can-do "cd_nothing"',
      ),
    );

    test(
      'Arabic script inside Spanish audio',
      () => rejects(
        (a) => qs(a).firstWhere((q) => q['type'] == 'dictation')['audio_es'] =
            'مرحبا',
        'contains Arabic script',
      ),
    );

    test(
      'duplicate choices',
      () => rejects((a) {
        final q = qs(a).firstWhere((q) => q['type'] == 'choice');
        final c = (q['choices'] as List);
        c[1] = c[0];
      }, 'choices must be distinct'),
    );

    test(
      'answer index out of range',
      () => rejects(
        (a) => qs(a).firstWhere((q) => q['type'] == 'choice')['answer'] = 9,
        'answer must be a valid index',
      ),
    );

    test(
      'typed question without accepted answers',
      () => rejects(
        (a) => qs(a).firstWhere((q) => q['type'] == 'type')['accepted'] = [],
        'type needs accepted answers',
      ),
    );

    test(
      'dictation without audio',
      () => rejects(
        (a) =>
            qs(a)
                .firstWhere((q) => q['type'] == 'dictation')
                .remove('audio_es'),
        'dictation needs audio_es',
      ),
    );

    test(
      'fewer than three skills',
      () => rejects((a) {
        for (final q in qs(a)) {
          q['skill'] = q['type'] == 'choice' ? 'reading' : 'writing';
        }
      }, 'needs at least 3 different skills'),
    );
  });
}

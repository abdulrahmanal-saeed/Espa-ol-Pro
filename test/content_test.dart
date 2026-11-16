import 'dart:convert';

import 'package:espanol_pro/core/content/content_parser.dart';
import 'package:espanol_pro/core/content/content_validator.dart';
import 'package:espanol_pro/core/content/models.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support.dart';

/// A minimal, fully valid content package used to prove each validator rule
/// fires when (and only when) its rule is broken.
Map<String, dynamic> _curriculum() => {
  'version': '1.0.0',
  'sources': [
    {
      'id': 's',
      'title': 't',
      'license': 'original',
      'attribution': 'a',
      'review_status': 'author_reviewed',
    },
  ],
  'levels': [
    for (final id in cefrOrder)
      {
        'id': id,
        'code': id,
        'title_ar': 'مستوى',
        'preparatory': id == 'pre_a1',
        'can_do_ar': ['أستطيع'],
        'units': [
          {
            'id': '${id}_u',
            'title_ar': 'وحدة',
            'objectives_ar': ['هدف'],
            'status': id == 'pre_a1' ? 'available' : 'planned',
          },
        ],
      },
  ],
};

Map<String, dynamic> _item(String id, String es, String ar) => {
  'id': id,
  'es': es,
  'ar': ar,
  'pos': 'اسم',
  'examples': [
    {'es': '$es.', 'ar': '$ar.'},
  ],
};

Map<String, dynamic> _unit() => {
  'grammar': [],
  'lessons': [
    {
      'id': 'l1',
      'title_ar': 'درس',
      'objectives_ar': ['هدف'],
      'prerequisites': [],
      'minutes': 5,
      'source': 's',
      'items': [
        _item('a', 'casa', 'بيت'),
        _item('b', 'mesa', 'طاولة'),
        _item('c', 'hola', 'مرحباً'),
      ],
      'activities': [
        {'type': 'teach', 'item': 'a'},
        {'type': 'teach', 'item': 'b'},
        {'type': 'teach', 'item': 'c'},
        {'type': 'mcq_meaning', 'item': 'a'},
        {'type': 'mcq_reverse', 'item': 'b'},
        {'type': 'listen_choose', 'item': 'c'},
        {'type': 'type_es', 'item': 'a'},
        {'type': 'dictation', 'item': 'b'},
        {
          'type': 'match',
          'items': ['a', 'b', 'c'],
        },
      ],
    },
  ],
};

Future<List<String>> _issues({
  void Function(Map<String, dynamic> curriculum)? editCurriculum,
  void Function(Map<String, dynamic> unit)? editUnit,
}) async {
  final cur = _curriculum();
  final unit = _unit();
  editCurriculum?.call(cur);
  editUnit?.call(unit);
  final pack = await parseContentPack(
    (path) async => jsonEncode(path == 'curriculum.json' ? cur : unit),
  );
  return ContentValidator().validate(pack).map((i) => i.toString()).toList();
}

Map<String, dynamic> _lesson(Map<String, dynamic> unit) =>
    (unit['lessons'] as List).first as Map<String, dynamic>;

void main() {
  group('shipped content package', () {
    late ContentPack pack;
    setUpAll(() async => pack = await loadRealContent());

    test('passes every validation rule', () {
      final issues = ContentValidator().validate(pack);
      expect(issues, isEmpty, reason: issues.join('\n'));
    });

    test('covers the whole Pre-A1 → C2 roadmap', () {
      expect(pack.levels.map((l) => l.id), cefrOrder);
      expect(pack.levels.first.isPreparatory, isTrue);
      for (final level in pack.levels) {
        expect(level.units, isNotEmpty, reason: level.id);
      }
    });

    test('ships a complete Pre-A1 sequence and initial A1 content', () {
      final preA1 = pack.level('pre_a1')!;
      expect(preA1.units.every((u) => u.isAvailable), isTrue);
      expect(preA1.lessons.length, greaterThanOrEqualTo(9));
      expect(pack.level('a1')!.lessons.length, greaterThanOrEqualTo(3));
    });

    test('lessons form one linear, unlockable chain', () {
      final lessons = pack.orderedLessons;
      expect(lessons.first.prerequisites, isEmpty);
      for (var i = 1; i < lessons.length; i++) {
        expect(lessons[i].prerequisites, [lessons[i - 1].id]);
      }
    });

    test('professional vocabulary starts at Pre-A1/A1', () {
      expect(pack.allItems.where((i) => i.work).length, greaterThan(20));
    });
  });

  group('validator', () {
    test('accepts the minimal valid fixture', () async {
      expect(await _issues(), isEmpty);
    });

    test('rejects duplicate item ids', () async {
      final issues = await _issues(
        editUnit: (u) => (_lesson(u)['items'] as List)[1]['id'] = 'a',
      );
      expect(issues.join('\n'), contains('duplicate item id'));
    });

    test('rejects duplicate Spanish text', () async {
      final issues = await _issues(
        editUnit: (u) => (_lesson(u)['items'] as List)[1]['es'] = 'Casa',
      );
      expect(issues.join('\n'), contains('duplicate Spanish text'));
    });

    test('rejects missing translation', () async {
      final issues = await _issues(
        editUnit: (u) => (_lesson(u)['items'] as List)[0]['ar'] = '',
      );
      expect(issues.join('\n'), contains('missing ar'));
    });

    test('rejects Arabic script inside a Spanish field', () async {
      final issues = await _issues(
        editUnit: (u) => (_lesson(u)['items'] as List)[0]['es'] = 'casa بيت',
      );
      expect(issues.join('\n'), contains('es contains Arabic script'));
    });

    test('rejects unbalanced Spanish question marks', () async {
      final issues = await _issues(
        editUnit: (u) =>
            (_lesson(u)['items'] as List)[0]['examples'][0]['es'] = 'Qué es?',
      );
      expect(issues.join('\n'), contains('unbalanced ¿ ?'));
    });

    test('rejects broken item references', () async {
      final issues = await _issues(
        editUnit: (u) =>
            (_lesson(u)['activities'] as List)[3]['item'] = 'missing',
      );
      expect(issues.join('\n'), contains('unknown or later item'));
    });

    test('rejects practice before teaching', () async {
      final issues = await _issues(
        editUnit: (u) {
          final acts = _lesson(u)['activities'] as List;
          acts.insert(0, acts.removeAt(3));
        },
      );
      expect(issues.join('\n'), contains('before its teach step'));
    });

    test('rejects items that are never practised', () async {
      final issues = await _issues(
        editUnit: (u) {
          final lesson = _lesson(u);
          (lesson['items'] as List).add(_item('d', 'uno', 'واحد'));
          (lesson['activities'] as List).add({'type': 'teach', 'item': 'd'});
        },
      );
      expect(issues.join('\n'), contains('never practised'));
    });

    test('rejects prerequisites that are not earlier lessons', () async {
      final issues = await _issues(
        editUnit: (u) => _lesson(u)['prerequisites'] = ['later_lesson'],
      );
      expect(issues.join('\n'), contains('is not an EARLIER lesson'));
    });

    test('rejects lessons without production practice', () async {
      final issues = await _issues(
        editUnit: (u) {
          final acts = _lesson(u)['activities'] as List;
          acts[6] = {'type': 'mcq_meaning', 'item': 'b', 'id': 'x1'};
          acts[7] = {'type': 'listen_pick_es', 'item': 'a', 'id': 'x2'};
        },
      );
      expect(issues.join('\n'), contains('production activity'));
    });

    test('rejects missing licence metadata', () async {
      final issues = await _issues(
        editCurriculum: (c) => (c['sources'] as List)[0]['license'] = '',
      );
      expect(issues.join('\n'), contains('missing license'));
    });

    test('rejects unknown content source', () async {
      final issues = await _issues(
        editUnit: (u) => _lesson(u)['source'] = 'nope',
      );
      expect(issues.join('\n'), contains('unknown content source'));
    });

    test('rejects a reordered CEFR ladder', () async {
      final issues = await _issues(
        editCurriculum: (c) {
          final levels = c['levels'] as List;
          levels.add(levels.removeAt(1));
        },
      );
      expect(issues.join('\n'), contains('levels must be exactly'));
    });

    test('rejects a malformed choice answer index', () async {
      final issues = await _issues(
        editUnit: (u) => (_lesson(u)['activities'] as List).add({
          'type': 'choice',
          'prompt_ar': 'سؤال',
          'choices': ['a', 'b'],
          'answer': 5,
        }),
      );
      expect(issues.join('\n'), contains('valid index'));
    });
  });
}

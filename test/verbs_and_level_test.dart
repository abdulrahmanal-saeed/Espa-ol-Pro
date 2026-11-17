import 'dart:convert';
import 'dart:io';

import 'package:espanol_pro/core/content/content_parser.dart';
import 'package:espanol_pro/core/content/content_validator.dart';
import 'package:espanol_pro/core/content/models.dart';
import 'package:espanol_pro/core/learning/progress_repository.dart';
import 'package:espanol_pro/core/srs/review_repository.dart';
import 'package:espanol_pro/features/assessment/assessment_screens.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;

import 'support.dart';
import 'widget_support.dart';

Future<List<String>> verbIssuesWith(
  void Function(List<Map<String, dynamic>> verbs) edit,
) async {
  final pack = await parseContentPack((path) async {
    final text = await File('$contentDir/$path').readAsString();
    if (path != 'verbs.json') return text;
    final doc = jsonDecode(text) as Map<String, dynamic>;
    edit((doc['verbs'] as List).cast<Map<String, dynamic>>());
    return jsonEncode(doc);
  });
  return ContentValidator().validate(pack).map((i) => '$i').toList();
}

void main() {
  late ContentPack pack;
  setUpAll(() async {
    pack = await loadRealContent();
    await loadAppFonts();
    tzdata.initializeTimeZones();
  });

  group('verb reference', () {
    test('ships the core A1 verbs, all valid', () {
      final ids = pack.verbs.map((v) => v.id).toSet();
      expect(
        ids,
        containsAll([
          'ser',
          'estar',
          'tener',
          'ir',
          'querer',
          'hablar',
          'comer',
          'vivir',
        ]),
      );
      final issues = ContentValidator().validate(pack);
      expect(issues, isEmpty, reason: issues.join('\n'));
    });

    test('regular verbs follow the -ar / -er / -ir rules exactly', () {
      expect(Verb.regularPresent('hablar'), {
        'yo': 'hablo',
        'tu': 'hablas',
        'el': 'habla',
        'nosotros': 'hablamos',
        'vosotros': 'habláis',
        'ellos': 'hablan',
      });
      expect(Verb.regularPresent('comer')!['vosotros'], 'coméis');
      expect(Verb.regularPresent('vivir')!['nosotros'], 'vivimos');
      expect(Verb.regularPresent('vivir')!['vosotros'], 'vivís');
      expect(Verb.regularPresent('xx'), isNull);
      for (final v in pack.verbs.where((v) => v.regular)) {
        expect(v.forms, Verb.regularPresent(v.infinitive), reason: v.id);
      }
    });

    test('every verb is linked to the lesson that teaches it', () {
      for (final v in pack.verbs) {
        for (final l in v.lessonIds) {
          expect(pack.lesson(l), isNotNull, reason: '${v.id} → $l');
        }
      }
    });

    Future<void> rejects(
      void Function(Map<String, dynamic> v) edit,
      String message,
    ) async {
      final issues = await verbIssuesWith(
        (vs) => edit(vs.firstWhere((v) => v['id'] == 'hablar')),
      );
      expect(issues.join('\n'), contains(message));
    }

    test(
      'a wrong regular form is caught',
      () => rejects(
        (v) => (v['present'] as Map)['nosotros'] = 'hablámos',
        'regular form for "nosotros" should be "hablamos"',
      ),
    );

    test(
      'a missing person is caught',
      () => rejects(
        (v) => (v['present'] as Map).remove('vosotros'),
        'missing form for "vosotros"',
      ),
    );

    test(
      'Arabic in a form is caught',
      () => rejects(
        (v) => (v['present'] as Map)['yo'] = 'أتكلم',
        'contains Arabic script',
      ),
    );

    test(
      'an unknown lesson is caught',
      () => rejects(
        (v) => v['lessons'] = ['no_lesson'],
        'unknown lesson "no_lesson"',
      ),
    );

    testWidgets('the library shows a verb table that can be heard', (
      tester,
    ) async {
      final app = TestApp(pack);
      await app.pump(tester, location: '/library');
      await tester.tapSettled(find.text('الأفعال'));
      await tester.tapKey('verb-hablar');
      for (final p in Verb.persons) {
        expect(
          find.byKey(ValueKey('verb-form-hablar-$p')),
          findsOneWidget,
          reason: p,
        );
      }
      expect(find.text('hablamos'), findsOneWidget);
      await tester.tapSettled(
        find.descendant(
          of: find.byKey(const ValueKey('verb-hablar')),
          matching: find.byIcon(Icons.volume_up_rounded),
        ),
      );
      expect(app.speech.spoken, contains('hablo'));
      await app.dispose(tester);
    });
  });

  group('A1 level assessment', () {
    test('covers every A1 unit, measures 5 skills, opens with the level', () {
      final lvl = pack.levelAssessmentFor('a1')!;
      expect(lvl.kind, 'level');
      expect(lvl.unitId, isNull);
      expect(lvl.questions.length, greaterThanOrEqualTo(20));
      final a1 = pack.levels.firstWhere((l) => l.id == 'a1');
      final covered = {
        for (final c in lvl.canDos)
          for (final l in c.lessonIds) pack.lesson(l)!.unitId,
      };
      expect(covered, {for (final u in a1.units) u.id});
      expect(lvl.questions.map((q) => q.skill).toSet().length, 5);
      expect(lvl.questions.any((q) => q.skill == 'speaking'), isFalse);
      expect(levelCompleted(pack, 'a1', const {}), isFalse);
    });

    Future<void> completeLevel(TestApp app, String levelId) async {
      final repo = ProgressRepository(
        app.db,
        ReviewRepository(app.db, clock: app.clock.call, enableFuzzing: false),
        clock: app.clock.call,
      );
      for (final l in pack.orderedLessons) {
        if (l.levelId == 'a1' && l.id == 'a1_u6_l4') {
          await repo.completeLesson(
            l,
            score: 1,
            seconds: 60,
            contentVersion: pack.version,
          );
          return;
        }
        await repo.completeLesson(
          l,
          score: 1,
          seconds: 60,
          contentVersion: pack.version,
        );
      }
    }

    testWidgets('locked until every A1 lesson is done, then it can start', (
      tester,
    ) async {
      var app = TestApp(pack);
      await app.pump(tester, location: '/assessment/lvl_a1');
      expect(find.byKey(const ValueKey('assessment-locked')), findsOneWidget);
      expect(find.textContaining('اختبار المستوى'), findsWidgets);
      await app.dispose(tester);

      app = TestApp(pack);
      await completeLevel(app, 'a1');
      await app.pump(tester, location: '/path');
      final tile = find.byKey(const ValueKey('checkpoint-lvl_a1'));
      await tester.scrollUntilVisible(tile, 300);
      expect(
        find.descendant(of: tile, matching: find.text('اختبار مستوى A1')),
        findsOneWidget,
      );
      await tester.tapSettled(tile);
      final start = tester.widget<FilledButton>(
        find.byKey(const ValueKey('assessment-start')),
      );
      expect(start.onPressed, isNotNull);
      expect(find.textContaining('ليست شهادة CEFR'), findsOneWidget);
      await app.dispose(tester);
    });
  });
}

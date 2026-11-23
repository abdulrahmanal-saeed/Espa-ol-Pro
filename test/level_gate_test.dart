import 'dart:convert';
import 'dart:io';

import 'package:espanol_pro/core/assessment/assessment_engine.dart';
import 'package:espanol_pro/core/assessment/assessment_repository.dart';
import 'package:espanol_pro/core/backup/backup_service.dart';
import 'package:espanol_pro/core/content/content_parser.dart';
import 'package:espanol_pro/core/content/content_validator.dart';
import 'package:espanol_pro/core/content/models.dart';
import 'package:espanol_pro/core/learning/level_gate.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support.dart';

/// Owner decision (PHASE4-001): B1 opens only after passing `lvl_a2`.
/// A1 → A2 needs no pass. "Passed" = every can-do of the attempt met at the
/// can-do threshold (0.75). Any passing attempt opens B1; a later failed
/// retry never closes it.
void main() {
  late ContentPack pack;
  late Assessment lvl;
  setUpAll(() async {
    pack = await loadRealContent();
    lvl = pack.levelAssessmentFor('a2')!;
  });

  var nextId = 1;

  /// A stored attempt at [a] answering [wrong] question ids wrongly.
  AttemptRecord attempt(
    Assessment a, {
    Set<String> wrong = const {},
    int version = 1,
    int at = 0,
  }) {
    final graded = gradeAssessment(a, {
      for (final q in a.questions)
        q.id: wrong.contains(q.id) ? 'zzz' : q.correctAnswer,
    });
    return AttemptRecord(
      id: nextId++,
      assessmentId: a.id,
      assessmentVersion: version,
      completedAtMs: at,
      localDay: '2026-11-0${1 + at % 9}',
      answers: [
        for (final g in graded)
          AnswerRecord(
            questionId: g.question.id,
            skill: g.question.skill,
            canDoId: g.question.canDoId,
            isCorrect: g.isCorrect,
          ),
      ],
    );
  }

  List<String> questionsOf(String canDoId) => [
    for (final q in lvl.questions)
      if (q.canDoId == canDoId) q.id,
  ];

  group('the pass rule', () {
    test('every can-do must be met at the 0.75 threshold', () {
      expect(CanDoEvidence.threshold, 0.75);
      expect(CanDoEvidence.passed(attempt(lvl)), isTrue);

      // One wrong answer in a can-do of 4–5 questions still meets it.
      final big = lvl.canDos.firstWhere((c) => questionsOf(c.id).length >= 4);
      final one = {questionsOf(big.id).first};
      expect(CanDoEvidence.passed(attempt(lvl, wrong: one)), isTrue);

      // Half of one can-do wrong: that can-do is not met, so no pass, even
      // though the overall score is high.
      final some = questionsOf(big.id);
      final half = some.take((some.length + 1) ~/ 2).toSet();
      final failed = attempt(lvl, wrong: half);
      expect(CanDoEvidence.met(big.id, failed), isFalse);
      expect(CanDoEvidence.passed(failed), isFalse);
      final correct = failed.answers.where((a) => a.isCorrect).length;
      expect(correct / failed.answers.length, greaterThan(0.75));
    });

    test('an attempt without answers is not a pass', () {
      expect(
        CanDoEvidence.passed(
          const AttemptRecord(
            id: 0,
            assessmentId: 'lvl_a2',
            assessmentVersion: 1,
            completedAtMs: 0,
            localDay: '2026-11-01',
            answers: [],
          ),
        ),
        isFalse,
      );
    });
  });

  group('level gates', () {
    test('B1 requires lvl_a2; no other level is gated', () {
      expect(pack.level('b1')!.requiresPass, 'lvl_a2');
      for (final l in pack.levels.where((l) => l.id != 'b1')) {
        expect(l.requiresPass, isNull, reason: l.id);
      }
      final gates = LevelGates.from(pack, const []);
      expect(gates.isOpen('b1'), isFalse);
      expect(gates.requiredAssessment('b1'), 'lvl_a2');
      // A1 → A2 stays as it was: no level test required.
      expect(gates.isOpen('a2'), isTrue);
      expect(gates.isOpen('a1'), isTrue);
      expect(gates.lockedLevels, ['b1']);
    });

    test('a failing attempt keeps B1 locked', () {
      final all = questionsOf(lvl.canDos.first.id).toSet();
      final gates = LevelGates.from(pack, [attempt(lvl, wrong: all)]);
      expect(gates.isOpen('b1'), isFalse);
    });

    test('any passing attempt opens B1; a later failure does not re-lock', () {
      // Every question of one can-do wrong: that can-do is not met.
      final fail = attempt(
        lvl,
        wrong: questionsOf(lvl.canDos.first.id).toSet(),
        at: 1,
      );
      final failHard = attempt(
        lvl,
        wrong: {for (final q in lvl.questions) q.id},
        at: 3,
      );
      expect(CanDoEvidence.passed(fail), isFalse);
      final pass = attempt(lvl, at: 2);
      // Fail, pass, then fail again: still open.
      expect(
        LevelGates.from(pack, [fail, pass, failHard]).isOpen('b1'),
        isTrue,
      );
      expect(passedAssessmentIds([fail, pass, failHard]), {'lvl_a2'});
    });

    test('a pass at an earlier question version still counts', () {
      expect(
        LevelGates.from(pack, [attempt(lvl, version: 0)]).isOpen('b1'),
        isTrue,
      );
    });

    test('passing another assessment does not open B1', () {
      final a1 = pack.levelAssessmentFor('a1')!;
      final chk = pack.checkpointFor('a2_u5')!;
      expect(
        LevelGates.from(pack, [attempt(a1), attempt(chk)]).isOpen('b1'),
        isFalse,
      );
    });
  });

  test(
    'the gate survives a backup and restore (no new stored state)',
    () async {
      final clock = FakeClock();
      final source = memoryDb();
      addTearDown(source.close);
      await AssessmentRepository(source, clock: clock.call).submit(
        assessment: lvl,
        graded: gradeAssessment(lvl, {
          for (final q in lvl.questions) q.id: q.correctAnswer,
        }),
        startedAt: clock(),
        contentVersion: pack.version,
      );
      final json = await BackupService(source)
          .exportJson(now: clock(), contentVersion: pack.version);

      final target = memoryDb();
      addTearDown(target.close);
      final before = await AssessmentRepository(
        target,
        clock: clock.call,
      ).watchRecords().first;
      expect(LevelGates.from(pack, before).isOpen('b1'), isFalse);

      await BackupService(target).restoreJson(json);
      final after = await AssessmentRepository(
        target,
        clock: clock.call,
      ).watchRecords().first;
      expect(LevelGates.from(pack, after).isOpen('b1'), isTrue);
    },
  );

  group('validator: requires_pass', () {
    Future<List<String>> issuesWith(
      void Function(Map<String, dynamic> level) edit, {
      String level = 'b1',
    }) async {
      final broken = await parseContentPack((path) async {
        final text = await File('$contentDir/$path').readAsString();
        if (path != 'curriculum.json') return text;
        final doc = jsonDecode(text) as Map<String, dynamic>;
        edit(
          (doc['levels'] as List).cast<Map<String, dynamic>>().firstWhere(
            (l) => l['id'] == level,
          ),
        );
        return jsonEncode(doc);
      });
      return ContentValidator().validate(broken).map((i) => '$i').toList();
    }

    test('the shipped gate is valid', () async {
      expect(await issuesWith((_) {}), isEmpty);
    });

    test('an unknown assessment is rejected', () async {
      expect(
        await issuesWith((l) => l['requires_pass'] = 'lvl_zz'),
        contains(contains('requires_pass "lvl_zz" is not an assessment')),
      );
    });

    test('a unit checkpoint is rejected', () async {
      expect(
        await issuesWith((l) => l['requires_pass'] = 'chk_a2_u5'),
        contains(contains('must be a level assessment')),
      );
    });

    test('a gate on a level that is not later is rejected', () async {
      // A1 cannot wait for the A2 test, nor A2 for its own.
      expect(
        await issuesWith((l) => l['requires_pass'] = 'lvl_a2', level: 'a1'),
        contains(contains('must belong to an earlier level')),
      );
      expect(
        await issuesWith((l) => l['requires_pass'] = 'lvl_a2', level: 'a2'),
        contains(contains('must belong to an earlier level')),
      );
    });

    test(
      'a curriculum without requires_pass still loads (content < 1.11)',
      () async {
        final open = await parseContentPack((path) async {
          final text = await File('$contentDir/$path').readAsString();
          if (path != 'curriculum.json') return text;
          final doc = jsonDecode(text) as Map<String, dynamic>;
          for (final l
              in (doc['levels'] as List).cast<Map<String, dynamic>>()) {
            l.remove('requires_pass');
          }
          return jsonEncode(doc);
        });
        expect(ContentValidator().validate(open), isEmpty);
        expect(LevelGates.from(open, const []).lockedLevels, isEmpty);
      },
    );
  });
}

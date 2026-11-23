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
      expect(passedAssessmentIds(pack, [fail, pass, failHard]), {'lvl_a2'});
    });

    test('an unknown question version never opens B1', () {
      // Version 0 was never shipped: its question set cannot be checked.
      final r = attempt(lvl, version: 0);
      expect(CanDoEvidence.passed(r), isTrue);
      expect(CanDoEvidence.isComplete(lvl, r), isFalse);
      expect(LevelGates.from(pack, [r]).isOpen('b1'), isFalse);
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

  group('REVIEW-017 P2: only complete evidence opens B1', () {
    AttemptRecord withAnswers(List<AnswerRecord> answers, {int version = 1}) =>
        AttemptRecord(
          id: nextId++,
          assessmentId: lvl.id,
          assessmentVersion: version,
          completedAtMs: 0,
          localDay: '2026-11-01',
          answers: answers,
        );
    List<AnswerRecord> full() => attempt(lvl).answers;
    bool opens(AttemptRecord r) => LevelGates.from(pack, [r]).isOpen('b1');

    test('the reviewer\'s repro: one correct answer is not a pass', () {
      final q = lvl.questions.first;
      final one = withAnswers([
        AnswerRecord(
          questionId: q.id,
          skill: q.skill,
          canDoId: q.canDoId,
          isCorrect: true,
        ),
      ]);
      // The can-do rule alone would accept it…
      expect(CanDoEvidence.passed(one), isTrue);
      // …completeness does not.
      expect(CanDoEvidence.isComplete(lvl, one), isFalse);
      expect(CanDoEvidence.passedComplete(lvl, one), isFalse);
      expect(opens(one), isFalse);
    });

    test('all five can-dos present and answered: a pass', () {
      expect(lvl.canDos, hasLength(5));
      final r = withAnswers(full());
      expect({for (final x in r.answers) x.canDoId}, hasLength(5));
      expect(CanDoEvidence.isComplete(lvl, r), isTrue);
      expect(opens(r), isTrue);
    });

    test('only one complete can-do group is not a pass', () {
      final c = lvl.canDos.first.id;
      final r = withAnswers([
        for (final x in full())
          if (x.canDoId == c) x,
      ]);
      expect(CanDoEvidence.passed(r), isTrue);
      expect(opens(r), isFalse);
    });

    test('a complete attempt missing one answer is not a pass', () {
      final r = withAnswers(full().skip(1).toList());
      expect(CanDoEvidence.passed(r), isTrue);
      expect(opens(r), isFalse);
    });

    test('a duplicated answer row or a relabelled can-do is not a pass', () {
      final answers = full();
      final duplicated = withAnswers([
        ...answers.take(answers.length - 1),
        answers.first,
      ]);
      expect(opens(duplicated), isFalse);
      final relabelled = withAnswers([
        for (final x in answers)
          AnswerRecord(
            questionId: x.questionId,
            skill: x.skill,
            canDoId: lvl.canDos.first.id,
            isCorrect: x.isCorrect,
          ),
      ]);
      expect(opens(relabelled), isFalse);
    });

    test('all answered but one can-do below 0.75 is not a pass', () {
      final c = lvl.canDos.last.id;
      final r = attempt(lvl, wrong: questionsOf(c).toSet());
      expect(CanDoEvidence.isComplete(lvl, r), isTrue);
      expect(opens(r), isFalse);
    });

    test('a complete pass at a retired version still opens B1', () async {
      // A future lvl_a2 v2 changes one question and records v1's set.
      final v2 = await parseContentPack((path) async {
        final text = await File('$contentDir/$path').readAsString();
        if (path != 'assessments/a2.json') return text;
        final doc = jsonDecode(text) as Map<String, dynamic>;
        final a = (doc['assessments'] as List)
            .cast<Map<String, dynamic>>()
            .firstWhere((a) => a['id'] == 'lvl_a2');
        final qs = (a['questions'] as List).cast<Map<String, dynamic>>();
        a['retired_versions'] = [
          {
            'version': 1,
            'questions': {for (final q in qs) q['id']: q['can_do']},
          },
        ];
        a['version'] = 2;
        qs.last['id'] = 'lvl_a2.q26';
        return jsonEncode(doc);
      });
      expect(ContentValidator().validate(v2), isEmpty);
      final newLvl = v2.assessment('lvl_a2')!;
      expect(newLvl.version, 2);
      // The learner passed v1 before the update: still open.
      final old = withAnswers(full());
      expect(CanDoEvidence.isComplete(newLvl, old), isTrue);
      expect(LevelGates.from(v2, [old]).isOpen('b1'), isTrue);
      // A partial v1 attempt still does not count.
      expect(
        LevelGates.from(v2, [
          withAnswers(full().skip(3).toList()),
        ]).isOpen('b1'),
        isFalse,
      );
      // v1 answers presented as v2 do not match v2's questions.
      expect(
        LevelGates.from(v2, [withAnswers(full(), version: 2)]).isOpen('b1'),
        isFalse,
      );
    });
  });

  group('validator: retired_versions', () {
    Future<List<String>> issuesWith(
      void Function(Map<String, dynamic>) edit,
    ) async {
      final broken = await parseContentPack((path) async {
        final text = await File('$contentDir/$path').readAsString();
        if (path != 'assessments/a2.json') return text;
        final doc = jsonDecode(text) as Map<String, dynamic>;
        edit(
          (doc['assessments'] as List).cast<Map<String, dynamic>>().firstWhere(
            (a) => a['id'] == 'lvl_a2',
          ),
        );
        return jsonEncode(doc);
      });
      return ContentValidator().validate(broken).map((i) => '$i').toList();
    }

    test(
      'a retired version must be below the current one and not empty',
      () async {
        expect(
          await issuesWith(
            (a) => a['retired_versions'] = [
              {
                'version': 1,
                'questions': {'lvl_a2.q1': 'cd_x'},
              },
            ],
          ),
          contains(contains('retired version 1 must be ≥ 1 and below 1')),
        );
        expect(
          await issuesWith((a) {
            a['version'] = 2;
            a['retired_versions'] = [
              {'version': 1, 'questions': <String, String>{}},
            ];
          }),
          contains(contains('retired version 1 has no questions')),
        );
      },
    );
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

      await BackupService(target, pack: pack).restoreJson(json);
      final after = await AssessmentRepository(
        target,
        clock: clock.call,
      ).watchRecords().first;
      expect(LevelGates.from(pack, after).isOpen('b1'), isTrue);
    },
  );

  test('an edited backup with a partial lvl_a2 attempt is rejected before '
      'anything is deleted', () async {
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
    final doc = jsonDecode(
      await BackupService(source)
          .exportJson(now: clock(), contentVersion: pack.version),
    ) as Map<String, dynamic>;
    // Keep one correct answer and make the totals agree with it, so the
    // generic score checks pass (the reviewer's restore repro).
    final tables = doc['tables'] as Map<String, dynamic>;
    final answers = (tables['assessment_answers'] as List);
    tables['assessment_answers'] = [answers.first];
    final run = (tables['assessment_attempts'] as List).first as Map;
    run['maxScore'] = 1;
    run['score'] = 1;
    final edited = jsonEncode(doc);

    // The device already holds progress that must survive the rejection.
    final device = memoryDb();
    addTearDown(device.close);
    await AssessmentRepository(device, clock: clock.call).submit(
      assessment: pack.checkpointFor('a2_u5')!,
      graded: gradeAssessment(pack.checkpointFor('a2_u5')!, const {}),
      startedAt: clock(),
      contentVersion: pack.version,
    );
    final before = await device.select(device.assessmentAnswers).get();

    await expectLater(
      BackupService(device, pack: pack).restoreJson(edited),
      throwsA(isA<BackupException>()),
    );
    expect(await device.select(device.assessmentAnswers).get(), before);
    // Without the content the file restores, but the gate still ignores it.
    final other = memoryDb();
    addTearDown(other.close);
    await BackupService(other).restoreJson(edited);
    final records = await AssessmentRepository(
      other,
      clock: clock.call,
    ).watchRecords().first;
    expect(records.single.answers, hasLength(1));
    expect(LevelGates.from(pack, records).isOpen('b1'), isFalse);
  });

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

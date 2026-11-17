import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:espanol_pro/core/assessment/assessment_engine.dart';
import 'package:espanol_pro/core/assessment/assessment_repository.dart';
import 'package:espanol_pro/core/backup/backup_service.dart';
import 'package:espanol_pro/core/content/models.dart';
import 'package:espanol_pro/core/db/database.dart';
import 'package:espanol_pro/core/learning/progress_repository.dart';
import 'package:espanol_pro/core/phrases/saved_phrases_repository.dart';
import 'package:espanol_pro/core/srs/review_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart' as raw;

import 'support.dart';

Map<String, String> allCorrect(Assessment a) => {
  for (final q in a.questions) q.id: q.correctAnswer,
};

Map<String, String> allWrong(Assessment a) => {
  for (final q in a.questions)
    q.id: q.type == 'choice'
        ? q.choices[(q.answer + 1) % q.choices.length]
        : 'xyz',
};

AttemptRecord record(
  int id,
  String day,
  Map<String, bool> byCanDo, {
  int perCanDo = 3,
  int correctWhenMet = 3,
  int correctWhenNot = 1,
}) {
  final date = DateTime.parse('${day}T12:00:00');
  return AttemptRecord(
    id: id,
    assessmentId: 'a',
    completedAtMs: date.millisecondsSinceEpoch,
    localDay: day,
    answers: [
      for (final e in byCanDo.entries)
        for (var i = 0; i < perCanDo; i++)
          AnswerRecord(
            questionId: '${e.key}.$i',
            skill: 'reading',
            canDoId: e.key,
            isCorrect: i < (e.value ? correctWhenMet : correctWhenNot),
          ),
    ],
  );
}

void main() {
  late ContentPack pack;
  late Assessment chk;
  setUpAll(() async {
    pack = await loadRealContent();
    chk = pack.assessment('chk_pa1_u1')!;
  });

  group('grading', () {
    test('all correct answers score full marks', () {
      final g = gradeAssessment(chk, allCorrect(chk));
      expect(g.length, chk.questions.length);
      expect(g.every((x) => x.isCorrect), isTrue);
      for (final x in g) {
        expect(
          x.spelling,
          x.question.type == 'choice' ? isNull : Spelling.exact,
        );
      }
    });

    test('wrong and missing answers are wrong, never partial credit', () {
      final wrong = gradeAssessment(chk, allWrong(chk));
      expect(wrong.where((x) => x.isCorrect), isEmpty);
      final missing = gradeAssessment(chk, const {});
      expect(missing.where((x) => x.isCorrect), isEmpty);
      for (final x in missing.where((x) => x.question.type != 'choice')) {
        expect(x.spelling, Spelling.wrong);
      }
      final blank = gradeAssessment(chk, {
        for (final q in chk.questions) q.id: '   ',
      });
      expect(blank.where((x) => x.isCorrect), isEmpty);
    });

    test('missing accents count as meaning but are recorded apart', () {
      final q = chk.question('chk_pa1_u1.q7')!; // teléfono
      final g = gradeAssessment(chk, {...allCorrect(chk), q.id: 'telefono'});
      final x = g.firstWhere((x) => x.question.id == q.id);
      expect(x.isCorrect, isTrue);
      expect(x.spelling, Spelling.missingAccents);
    });

    test('any accepted alternative is correct', () {
      final g = gradeAssessment(chk, {
        ...allCorrect(chk),
        'chk_pa1_u1.q8': 'amiga',
      });
      expect(
        g.firstWhere((x) => x.question.id == 'chk_pa1_u1.q8').isCorrect,
        isTrue,
      );
    });

    test('a choice is matched by its text, not by position', () {
      final q = chk.questions.firstWhere((q) => q.type == 'choice');
      final g = gradeAssessment(chk, {q.id: '${q.choices[q.answer]} '});
      expect(g.first.isCorrect, isFalse);
    });

    test('skill scores group answers in a fixed order', () {
      final scores = skillScores(const [
        AnswerRecord(
          questionId: '1',
          skill: 'writing',
          canDoId: 'c',
          isCorrect: true,
        ),
        AnswerRecord(
          questionId: '2',
          skill: 'vocabulary',
          canDoId: 'c',
          isCorrect: false,
        ),
        AnswerRecord(
          questionId: '3',
          skill: 'writing',
          canDoId: 'c',
          isCorrect: false,
        ),
      ]);
      expect(scores.map((s) => s.skill), ['vocabulary', 'writing']);
      expect(scores.last.correct, 1);
      expect(scores.last.total, 2);
    });
  });

  group('can-do evidence rule', () {
    test('no covering attempt → not assessed', () {
      expect(CanDoEvidence.state('x', const []), CanDoState.notAssessed);
      expect(
        CanDoEvidence.state('x', [
          record(1, '2026-03-01', {'y': true}),
        ]),
        CanDoState.notAssessed,
      );
    });

    test('threshold boundaries: 2/3 not met, 3/4 met, 2/2 met, 1/2 not', () {
      AttemptRecord r(int per, int correct) => record(
        1,
        '2026-03-01',
        {'c': true},
        perCanDo: per,
        correctWhenMet: correct,
      );
      expect(CanDoEvidence.met('c', r(3, 2)), isFalse);
      expect(CanDoEvidence.met('c', r(3, 3)), isTrue);
      expect(CanDoEvidence.met('c', r(4, 3)), isTrue);
      expect(CanDoEvidence.met('c', r(4, 2)), isFalse);
      expect(CanDoEvidence.met('c', r(2, 2)), isTrue);
      expect(CanDoEvidence.met('c', r(2, 1)), isFalse);
    });

    test('latest attempt decides; a weak retake demotes', () {
      final good = record(1, '2026-03-01', {'c': true});
      final bad = record(2, '2026-03-02', {'c': false});
      expect(CanDoEvidence.state('c', [good]), CanDoState.demonstrated);
      expect(CanDoEvidence.state('c', [good, bad]), CanDoState.needsPractice);
    });

    test('consistent needs two met attempts on different days', () {
      final a = record(1, '2026-03-01', {'c': true});
      final sameDay = record(2, '2026-03-01', {'c': true});
      final nextDay = record(3, '2026-03-02', {'c': true});
      expect(CanDoEvidence.state('c', [a, sameDay]), CanDoState.demonstrated);
      expect(CanDoEvidence.state('c', [a, nextDay]), CanDoState.consistent);
      // Order of the list does not matter, only completion time.
      expect(CanDoEvidence.state('c', [nextDay, a]), CanDoState.consistent);
    });

    test('an earlier fail between does not count as consistent', () {
      final a = record(1, '2026-03-01', {'c': true});
      final fail = record(2, '2026-03-02', {'c': false});
      final pass = record(3, '2026-03-03', {'c': true});
      expect(
        CanDoEvidence.state('c', [a, fail, pass]),
        CanDoState.demonstrated,
      );
    });
  });

  group('repository', () {
    late AppDatabase db;
    late FakeClock clock;
    late AssessmentRepository repo;
    setUp(() {
      db = memoryDb();
      clock = FakeClock();
      repo = AssessmentRepository(db, clock: clock.call);
    });
    tearDown(() => db.close());

    Future<int> submit(Map<String, String> answers) => repo.submit(
      assessment: chk,
      graded: gradeAssessment(chk, answers),
      startedAt: clock().subtract(const Duration(minutes: 4)),
      contentVersion: pack.version,
    );

    test('submit stores the attempt and every answer together', () async {
      final id = await submit({
        ...allCorrect(chk),
        'chk_pa1_u1.q7': 'telefono',
        'chk_pa1_u1.q1': chk
            .question('chk_pa1_u1.q1')!
            .choices
            .firstWhere(
              (c) => c != chk.question('chk_pa1_u1.q1')!.correctAnswer,
            ),
      });
      final a = (await repo.attempt(id))!;
      expect(a.assessmentId, chk.id);
      expect(a.assessmentVersion, chk.version);
      expect(a.contentVersion, pack.version);
      expect(a.maxScore, chk.questions.length);
      expect(a.score, chk.questions.length - 1);
      expect(a.completedAt, clock().millisecondsSinceEpoch);
      expect(
        a.completedAt - a.startedAt,
        const Duration(minutes: 4).inMilliseconds,
      );
      final answers = await repo.answers(id);
      expect(answers.map((x) => x.questionId), chk.questions.map((q) => q.id));
      final q7 = answers.firstWhere((x) => x.questionId == 'chk_pa1_u1.q7');
      expect(q7.spelling, Spelling.missingAccents);
      expect(q7.isCorrect, isTrue);
      expect(q7.userAnswer, 'telefono');
      expect(q7.expected, 'teléfono');
      expect(
        answers.where((x) => !x.isCorrect).single.questionId,
        'chk_pa1_u1.q1',
      );
    });

    test('a failed answer write rolls back the whole submission', () async {
      await db.customStatement('''
        CREATE TEMP TRIGGER fail_answers BEFORE INSERT ON assessment_answers
        BEGIN SELECT RAISE(ABORT, 'test write failure'); END
      ''');
      await expectLater(
        submit(allCorrect(chk)),
        throwsA(isA<raw.SqliteException>()),
      );
      expect(await db.select(db.assessmentAttempts).get(), isEmpty);
      expect(await db.select(db.assessmentAnswers).get(), isEmpty);
      await db.customStatement('DROP TRIGGER fail_answers');
      await submit(allCorrect(chk));
      expect((await db.select(db.assessmentAttempts).get()).length, 1);
      expect(
        (await db.select(db.assessmentAnswers).get()).length,
        chk.questions.length,
      );
    });

    test('an incomplete grading is refused before any write', () async {
      expect(
        () => repo.submit(
          assessment: chk,
          graded: gradeAssessment(chk, const {}).take(3).toList(),
          startedAt: clock(),
          contentVersion: pack.version,
        ),
        throwsArgumentError,
      );
      expect(await db.select(db.assessmentAttempts).get(), isEmpty);
    });

    test(
      'repeated attempts are separate rows and are listed newest first',
      () async {
        final first = await submit(allWrong(chk));
        clock.advance(const Duration(days: 1));
        final second = await submit(allCorrect(chk));
        expect(second, isNot(first));
        final list = await repo.watchAttempts().first;
        expect(list.map((a) => a.id), [second, first]);
        expect(list.first.score, chk.questions.length);
        expect(list.last.score, 0);
        // The earlier result is not overwritten or averaged away.
        expect((await repo.attempt(first))!.score, 0);
      },
    );

    test('records feed the can-do rule per local day', () async {
      await submit(allCorrect(chk));
      clock.advance(const Duration(days: 1));
      await submit(allCorrect(chk));
      final records = await repo.watchRecords().first;
      expect(records.length, 2);
      expect(records.map((r) => r.localDay).toSet().length, 2);
      for (final c in chk.canDos) {
        expect(CanDoEvidence.state(c.id, records), CanDoState.consistent);
      }
    });

    test(
      'an assessment never changes FSRS, lessons, attempts or errors',
      () async {
        final reviews = ReviewRepository(db, clock: clock.call);
        final progress = ProgressRepository(db, reviews, clock: clock.call);
        await progress.completeLesson(
          pack.orderedLessons.first,
          score: 0.8,
          seconds: 60,
          contentVersion: pack.version,
        );
        Future<List<Object>> snapshot() async => [
          ...(await db.select(db.reviewCards).get()),
          ...(await db.select(db.lessonProgress).get()),
          ...(await db.select(db.activityAttempts).get()),
          ...(await db.select(db.errorRecords).get()),
          ...(await db.select(db.studySessions).get()),
        ];
        final before = await snapshot();
        await submit(allWrong(chk));
        await submit(allCorrect(chk));
        expect(await snapshot(), before);
      },
    );

    test('results persist after the app database is reopened', () async {
      final tmp = Directory.systemTemp.createTempSync('espanol_pro_asm');
      addTearDown(() => tmp.deleteSync(recursive: true));
      final file = File('${tmp.path}/app.sqlite');
      var disk = AppDatabase(NativeDatabase(file));
      final id = await AssessmentRepository(disk, clock: clock.call).submit(
        assessment: chk,
        graded: gradeAssessment(chk, allCorrect(chk)),
        startedAt: clock(),
        contentVersion: pack.version,
      );
      await disk.close();
      disk = AppDatabase(NativeDatabase(file));
      final again = AssessmentRepository(disk, clock: clock.call);
      expect((await again.attempt(id))!.score, chk.questions.length);
      expect((await again.answers(id)).length, chk.questions.length);
      await disk.close();
    });
  });

  group('backup of assessment results', () {
    Future<AppDatabase> withResults() async {
      final db = memoryDb();
      final clock = FakeClock();
      final repo = AssessmentRepository(db, clock: clock.call);
      await repo.submit(
        assessment: chk,
        graded: gradeAssessment(chk, {
          ...allCorrect(chk),
          'chk_pa1_u1.q7': 'telefono',
        }),
        startedAt: clock(),
        contentVersion: pack.version,
      );
      clock.advance(const Duration(days: 1));
      await repo.submit(
        assessment: chk,
        graded: gradeAssessment(chk, allWrong(chk)),
        startedAt: clock(),
        contentVersion: pack.version,
      );
      await SavedPhrasesRepository(db, clock: clock.call).save(
        const PhraseDraft(
          es: 'Hola.',
          ar: 'مرحباً.',
          source: PhraseSource(kind: 'vocab', id: 'hola'),
        ),
      );
      return db;
    }

    Future<Map<String, dynamic>> exported(AppDatabase db) async => jsonDecode(
      await BackupService(db)
          .exportJson(now: DateTime.utc(2026), contentVersion: pack.version),
    ) as Map<String, dynamic>;

    Future<List<Object>> results(AppDatabase db) async => [
      ...(await db.select(db.assessmentAttempts).get()),
      ...(await db.select(db.assessmentAnswers).get()),
    ];

    test('a v5 backup round-trips every attempt and answer', () async {
      final source = await withResults();
      final doc = await exported(source);
      expect(doc['schema_version'], 5);
      final target = memoryDb();
      await BackupService(target).restoreJson(jsonEncode(doc));
      expect(await results(target), await results(source));
      expect(
        BackupService.summarize(jsonEncode(doc))['assessment_attempts'],
        2,
      );
      await source.close();
      await target.close();
    });

    Future<void> expectRejected(
      void Function(Map<String, dynamic> tables) corrupt,
    ) async {
      final source = await withResults();
      final device = await withResults();
      final doc = await exported(source);
      corrupt(doc['tables'] as Map<String, dynamic>);
      final before = await results(device);
      await expectLater(
        BackupService(device).restoreJson(jsonEncode(doc)),
        throwsA(isA<BackupException>()),
      );
      expect(await results(device), before);
      await source.close();
      await device.close();
    }

    test('a v5 backup without assessment tables is rejected', () async {
      await expectRejected((t) => t.remove('assessment_answers'));
      await expectRejected((t) => t.remove('assessment_attempts'));
    });

    test('an answer pointing at no attempt is rejected', () async {
      await expectRejected((t) {
        ((t['assessment_answers'] as List).first as Map)['attemptId'] = 999;
      });
    });

    test(
      'a stored score that disagrees with its answers is rejected',
      () async {
        await expectRejected((t) {
          final a = (t['assessment_attempts'] as List).first as Map;
          a['score'] = (a['score'] as int) == 0 ? 1 : (a['score'] as int) - 1;
        });
        await expectRejected((t) {
          ((t['assessment_attempts'] as List).first as Map)['maxScore'] = 11;
        });
      },
    );

    test('invalid versions, times and spellings are rejected', () async {
      await expectRejected((t) {
        ((t['assessment_attempts'] as List).first as Map)['assessmentVersion'] =
            0;
      });
      await expectRejected((t) {
        final a = (t['assessment_attempts'] as List).first as Map;
        a['completedAt'] = (a['startedAt'] as int) - 1;
      });
      await expectRejected((t) {
        ((t['assessment_answers'] as List).first as Map)['spelling'] = 'almost';
      });
      await expectRejected((t) {
        final list = t['assessment_attempts'] as List;
        (list[1] as Map)['id'] = (list[0] as Map)['id'];
      });
    });

    test('a pre-v5 backup keeps the results already on the device', () async {
      final device = await withResults();
      final old = memoryDb();
      final doc = await exported(old);
      doc['schema_version'] = 4;
      (doc['tables'] as Map)
        ..remove('assessment_attempts')
        ..remove('assessment_answers');
      expect(
        BackupService.summarize(jsonEncode(doc))
            .containsKey('assessment_attempts'),
        isFalse,
      );
      final before = await results(device);
      await BackupService(device).restoreJson(jsonEncode(doc));
      expect(await results(device), before);
      await device.close();
      await old.close();
    });

    test('reset clears assessment results but keeps saved phrases', () async {
      final db = await withResults();
      await BackupService(db).resetProgress();
      expect(await results(db), isEmpty);
      expect((await db.select(db.savedPhrases).get()).length, 1);
      await db.close();
    });
  });
}

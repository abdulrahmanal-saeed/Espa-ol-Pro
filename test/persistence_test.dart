import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:espanol_pro/core/backup/backup_service.dart';
import 'package:espanol_pro/core/content/models.dart';
import 'package:espanol_pro/core/db/database.dart';
import 'package:espanol_pro/core/learning/exercises.dart';
import 'package:espanol_pro/core/learning/progress_repository.dart';
import 'package:espanol_pro/core/phrases/saved_phrases_repository.dart';
import 'package:espanol_pro/core/settings.dart';
import 'package:espanol_pro/core/srs/review_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fsrs/fsrs.dart' as fsrs;
import 'package:sqlite3/sqlite3.dart' as raw;

import 'support.dart';

/// The exact DDL of schema version 1 (before the error notebook and the
/// `is_measured` flag existed). Kept verbatim so the upgrade path stays tested.
const _schemaV1 = '''
CREATE TABLE settings (key TEXT NOT NULL, value TEXT NOT NULL, PRIMARY KEY (key));
CREATE TABLE lesson_progress (
  lesson_id TEXT NOT NULL, status TEXT NOT NULL,
  best_score REAL NOT NULL DEFAULT 0, last_score REAL NOT NULL DEFAULT 0,
  completions INTEGER NOT NULL DEFAULT 0, started_at INTEGER NOT NULL,
  first_completed_at INTEGER, last_completed_at INTEGER,
  content_version TEXT NOT NULL DEFAULT '', PRIMARY KEY (lesson_id));
CREATE TABLE activity_attempts (
  id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, activity_id TEXT NOT NULL,
  lesson_id TEXT, item_id TEXT, skill TEXT NOT NULL, exercise_type TEXT NOT NULL,
  context TEXT NOT NULL, is_correct INTEGER NOT NULL CHECK (is_correct IN (0, 1)),
  user_answer TEXT NOT NULL DEFAULT '', expected TEXT NOT NULL DEFAULT '',
  created_at INTEGER NOT NULL);
CREATE TABLE review_cards (
  id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, item_id TEXT NOT NULL,
  card_type TEXT NOT NULL, state INTEGER NOT NULL DEFAULT 1, step INTEGER,
  stability REAL, difficulty REAL, due INTEGER NOT NULL, last_review INTEGER,
  reps INTEGER NOT NULL DEFAULT 0, lapses INTEGER NOT NULL DEFAULT 0,
  source_lesson_id TEXT, created_at INTEGER NOT NULL, UNIQUE (item_id, card_type));
CREATE TABLE review_logs (
  id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
  card_id INTEGER NOT NULL REFERENCES review_cards (id) ON DELETE CASCADE,
  rating INTEGER NOT NULL, state_before INTEGER NOT NULL, reviewed_at INTEGER NOT NULL,
  duration_ms INTEGER, stability_after REAL, difficulty_after REAL,
  due_after INTEGER NOT NULL, retrievability REAL);
CREATE TABLE study_sessions (
  id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, day TEXT NOT NULL, kind TEXT NOT NULL,
  ref_id TEXT, started_at INTEGER NOT NULL, seconds INTEGER NOT NULL);
PRAGMA user_version = 1;
''';

/// The exact statements migration 1 → 2 executed, to build a real v2 file.
const _upgradeV1toV2 = '''
CREATE TABLE error_records (
  id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, signature TEXT NOT NULL UNIQUE,
  incorrect TEXT NOT NULL, correct TEXT NOT NULL, category TEXT NOT NULL,
  prompt_ar TEXT NOT NULL DEFAULT '', lesson_id TEXT, item_id TEXT,
  count INTEGER NOT NULL DEFAULT 1, correct_since INTEGER NOT NULL DEFAULT 0,
  first_seen INTEGER NOT NULL, last_seen INTEGER NOT NULL);
ALTER TABLE activity_attempts ADD COLUMN is_measured INTEGER NOT NULL DEFAULT 1 CHECK (is_measured IN (0, 1));
PRAGMA user_version = 2;
''';

void main() {
  late ContentPack pack;
  late Directory tmp;
  setUpAll(() async => pack = await loadRealContent());
  setUp(() => tmp = Directory.systemTemp.createTempSync('espanol_pro_test'));
  tearDown(() => tmp.deleteSync(recursive: true));

  AppDatabase open(File f) => AppDatabase(NativeDatabase(f));

  group('schema migrations', () {
    test(
      'v1 → latest keeps every learner row and adds the new structures',
      () async {
        final file = File('${tmp.path}/v1.sqlite');
        final v1 = raw.sqlite3.open(file.path);
        v1.execute(_schemaV1);
        v1.execute(
          "INSERT INTO settings VALUES ('dailyMinutes', '45');"
          "INSERT INTO lesson_progress (lesson_id, status, best_score, last_score, completions, started_at, first_completed_at, last_completed_at, content_version)"
          " VALUES ('pa1_u1_l1', 'completed', 0.9, 0.9, 1, 1000, 2000, 2000, '1.0.0');"
          "INSERT INTO activity_attempts (activity_id, lesson_id, item_id, skill, exercise_type, context, is_correct, user_answer, expected, created_at)"
          " VALUES ('pa1_u1_l1#4', 'pa1_u1_l1', 'casa', 'vocabulary', 'mcq_meaning', 'lesson', 1, 'بيت', 'بيت', 1500);"
          "INSERT INTO review_cards (item_id, card_type, state, step, stability, difficulty, due, last_review, reps, lapses, source_lesson_id, created_at)"
          " VALUES ('casa', 'recognition', 2, NULL, 8.5, 5.1, 900000, 100000, 3, 1, 'pa1_u1_l1', 2000);"
          "INSERT INTO review_logs (card_id, rating, state_before, reviewed_at, due_after) VALUES (1, 3, 1, 100000, 900000);"
          "INSERT INTO study_sessions (day, kind, ref_id, started_at, seconds) VALUES ('2026-03-01', 'lesson', 'pa1_u1_l1', 1000, 540);",
        );
        v1.close();

        final db = open(file);
        // Old rows survive untouched.
        expect((await SettingsRepository(db).load()).dailyMinutes, 45);
        final progress = (await db.select(db.lessonProgress).get()).single;
        expect(progress.status, 'completed');
        expect(progress.bestScore, 0.9);
        final card = (await db.select(db.reviewCards).get()).single;
        expect(card.stability, 8.5);
        expect(card.reps, 3);
        expect(card.lapses, 1);
        expect((await db.select(db.reviewLogs).get()).single.rating, 3);
        expect((await db.select(db.studySessions).get()).single.seconds, 540);
        // New column gets a safe default; new table exists and is usable.
        final oldAttempt = (await db.select(db.activityAttempts).get()).single;
        expect(oldAttempt.isMeasured, isTrue);
        expect(oldAttempt.attemptNumber, 1);
        expect(oldAttempt.userAnswer, 'بيت');
        expect(await db.select(db.errorRecords).get(), isEmpty);
        expect(await db.select(db.savedPhrases).get(), isEmpty);
        expect(await db.select(db.assessmentAttempts).get(), isEmpty);
        expect(await db.select(db.assessmentAnswers).get(), isEmpty);

        // The migrated database is fully functional.
        final clock = FakeClock();
        final reviews = ReviewRepository(
          db,
          clock: clock.call,
          enableFuzzing: false,
        );
        final repo = ProgressRepository(db, reviews, clock: clock.call);
        final ex = ExerciseBuilder(pack)
            .buildLesson(pack.orderedLessons.first)
            .whereType<TypeExercise>()
            .first;
        await repo.recordAttempt(
          ex,
          isCorrect: false,
          userAnswer: 'x',
          context: 'lesson',
        );
        expect((await db.select(db.errorRecords).get()).length, 1);
        await reviews.rate(card.id, fsrs.Rating.good);
        await db.close();

        final check = raw.sqlite3.open(file.path);
        expect(
          check.select('PRAGMA user_version').single.values.single,
          AppDatabase.latestSchemaVersion,
        );
        check.close();
      },
    );

    test(
      'v2 → latest keeps attempts and error records, defaults attempt_number',
      () async {
        final file = File('${tmp.path}/v2.sqlite');
        final v2 = raw.sqlite3.open(file.path);
        v2.execute(_schemaV1);
        v2.execute(_upgradeV1toV2);
        v2.execute(
          "INSERT INTO activity_attempts (activity_id, lesson_id, item_id, skill, exercise_type, context, is_correct, is_measured, user_answer, expected, created_at)"
          " VALUES ('pa1_u1_l1#17', 'pa1_u1_l1', 'casa', 'writing', 'type_es', 'lesson', 0, 1, 'caza', 'casa', 1500),"
          " ('pa1_u1_l1#20', 'pa1_u1_l1', NULL, 'speaking', 'speak', 'lesson', 1, 0, 'self-practised', 'Mi casa es tu casa.', 1600);"
          "INSERT INTO error_records (signature, incorrect, correct, category, prompt_ar, lesson_id, item_id, count, correct_since, first_seen, last_seen)"
          " VALUES ('type_es|casa', 'caza', 'casa', 'spelling', 'بيت', 'pa1_u1_l1', 'casa', 3, 1, 1500, 1900);",
        );
        v2.close();

        final db = open(file);
        final attempts = await db.select(db.activityAttempts).get();
        expect(attempts.length, 2);
        expect(attempts.every((a) => a.attemptNumber == 1), isTrue);
        expect(attempts[0].userAnswer, 'caza');
        expect(attempts[0].isMeasured, isTrue);
        expect(attempts[1].isMeasured, isFalse);
        final error = (await db.select(db.errorRecords).get()).single;
        expect(error.count, 3);
        expect(error.correctSince, 1);
        await db.close();

        final check = raw.sqlite3.open(file.path);
        expect(
          check.select('PRAGMA user_version').single.values.single,
          AppDatabase.latestSchemaVersion,
        );
        check.close();
      },
    );

    test(
      'v3 → latest adds saved phrases and keeps every existing row',
      () async {
        // Build a real v3 file with the current code's v3 tables, by creating
        // the latest schema and removing what v4 and v5 added.
        final file = File('${tmp.path}/v3.sqlite');
        final fresh = open(file);
        await fresh.select(fresh.settings).get();
        await fresh.close();
        final v3 = raw.sqlite3.open(file.path);
        v3.execute(
          'DROP TABLE saved_phrases; DROP TABLE assessment_answers; '
          'DROP TABLE assessment_attempts; PRAGMA user_version = 3;',
        );
        v3.execute(
          "INSERT INTO settings VALUES ('dailyMinutes', '60');"
          "INSERT INTO lesson_progress (lesson_id, status, best_score, last_score, completions, started_at, first_completed_at, last_completed_at, content_version)"
          " VALUES ('pa1_u1_l1', 'completed', 0.8, 0.8, 1, 1000, 2000, 2000, '1.0.2');"
          "INSERT INTO activity_attempts (activity_id, lesson_id, item_id, skill, exercise_type, context, is_correct, is_measured, attempt_number, user_answer, expected, created_at)"
          " VALUES ('pa1_u1_l1#17', 'pa1_u1_l1', 'casa', 'writing', 'type_es', 'lesson', 1, 1, 2, 'casa', 'casa', 1500);",
        );
        v3.close();

        final db = open(file);
        expect((await SettingsRepository(db).load()).dailyMinutes, 60);
        expect(
          (await db.select(db.lessonProgress).get()).single.bestScore,
          0.8,
        );
        final attempt = (await db.select(db.activityAttempts).get()).single;
        expect(attempt.attemptNumber, 2);
        expect(await db.select(db.savedPhrases).get(), isEmpty);
        final phrases = SavedPhrasesRepository(db, clock: FakeClock().call);
        expect(
          await phrases.save(
            const PhraseDraft(
              es: 'Buenos días.',
              ar: 'صباح الخير.',
              source: PhraseSource(kind: 'vocab', id: 'buenos_dias'),
            ),
          ),
          isTrue,
        );
        await db.close();

        final check = raw.sqlite3.open(file.path);
        expect(
          check.select('PRAGMA user_version').single.values.single,
          AppDatabase.latestSchemaVersion,
        );
        check.close();
      },
    );

    test(
      'v4 → v5 adds assessment tables and keeps phrases and progress',
      () async {
        // A real v4 file: the latest schema minus what v5 added.
        final file = File('${tmp.path}/v4.sqlite');
        final fresh = open(file);
        await fresh.select(fresh.settings).get();
        await fresh.close();
        final v4 = raw.sqlite3.open(file.path);
        v4.execute(
          'DROP INDEX IF EXISTS idx_assessment_answers_attempt; '
          'DROP TABLE assessment_answers; DROP TABLE assessment_attempts; '
          'PRAGMA user_version = 4;',
        );
        v4.execute(
          "INSERT INTO settings VALUES ('dailyMinutes', '20');"
          "INSERT INTO lesson_progress (lesson_id, status, best_score, last_score, completions, started_at, first_completed_at, last_completed_at, content_version)"
          " VALUES ('pa1_u1_l1', 'completed', 0.7, 0.7, 2, 1000, 2000, 3000, '1.0.3');"
          "INSERT INTO saved_phrases (phrase_key, es, ar, en, source_kind, source_id, source_lesson_id, note, saved_at)"
          " VALUES ('buenos dias', 'Buenos días.', 'صباح الخير.', '', 'vocab', 'buenos_dias', 'pa1_u2_l1', 'مهم', 5000);",
        );
        final tables = v4
            .select("SELECT name FROM sqlite_master WHERE type = 'table'")
            .map((r) => r['name'])
            .toList();
        expect(tables, isNot(contains('assessment_attempts')));
        v4.close();

        final db = open(file);
        expect((await SettingsRepository(db).load()).dailyMinutes, 20);
        final progress = (await db.select(db.lessonProgress).get()).single;
        expect(progress.completions, 2);
        final phrase = (await db.select(db.savedPhrases).get()).single;
        expect(phrase.es, 'Buenos días.');
        expect(phrase.note, 'مهم');
        expect(await db.select(db.assessmentAttempts).get(), isEmpty);

        // The new tables are usable, including the cascade.
        final id = await db
            .into(db.assessmentAttempts)
            .insert(
              AssessmentAttemptsCompanion.insert(
                assessmentId: 'chk_pa1_u1',
                assessmentVersion: 1,
                contentVersion: '1.1.0',
                startedAt: 1,
                completedAt: 2,
                maxScore: 1,
                score: 1,
              ),
            );
        await db
            .into(db.assessmentAnswers)
            .insert(
              AssessmentAnswersCompanion.insert(
                attemptId: id,
                questionId: 'chk_pa1_u1.q1',
                skill: 'vocabulary',
                canDoId: 'cd_pa1_u1_hear',
                isCorrect: true,
              ),
            );
        await (db.delete(
          db.assessmentAttempts,
        )..where((t) => t.id.equals(id))).go();
        expect(await db.select(db.assessmentAnswers).get(), isEmpty);
        await db.close();

        final check = raw.sqlite3.open(file.path);
        expect(check.select('PRAGMA user_version').single.values.single, 5);
        final indexes = check
            .select("SELECT name FROM sqlite_master WHERE type = 'index'")
            .map((r) => r['name'])
            .toList();
        expect(indexes, contains('idx_assessment_answers_attempt'));
        expect(indexes, contains('idx_assessment_answers_question'));
        check.close();
      },
    );

    test('a legacy database with duplicate answers opens, keeps its data '
        'and reports degraded integrity', () async {
      final file = File('${tmp.path}/dup.sqlite');
      final fresh = open(file);
      await fresh.select(fresh.settings).get();
      expect(fresh.assessmentAnswersDegraded, isFalse);
      await fresh.close();
      final legacy = raw.sqlite3.open(file.path);
      legacy.execute(
        'DROP INDEX idx_assessment_answers_question;'
        "INSERT INTO assessment_attempts (id, assessment_id, assessment_version, content_version, started_at, completed_at, max_score, score)"
        " VALUES (1, 'chk_pa1_u1', 1, '1.1.0', 1, 2, 2, 2);"
        "INSERT INTO assessment_answers (attempt_id, question_id, skill, can_do_id, is_correct)"
        " VALUES (1, 'chk_pa1_u1.q1', 'listening', 'cd_pa1_u1_hear', 1),"
        " (1, 'chk_pa1_u1.q1', 'listening', 'cd_pa1_u1_hear', 1);",
      );
      legacy.close();

      final db = open(file);
      expect((await db.select(db.assessmentAnswers).get()).length, 2);
      expect(db.assessmentAnswersDegraded, isTrue);
      await db.close();
      final check = raw.sqlite3.open(file.path);
      final indexes = check
          .select("SELECT name FROM sqlite_master WHERE type = 'index'")
          .map((r) => r['name']);
      expect(indexes, isNot(contains('idx_assessment_answers_question')));
      check.close();
    });

    test('any other failure creating the index is not hidden', () async {
      final file = File('${tmp.path}/broken.sqlite');
      final fresh = open(file);
      await fresh.select(fresh.settings).get();
      await fresh.close();
      final broken = raw.sqlite3.open(file.path);
      // Something else already uses the index's name.
      broken.execute(
        'DROP INDEX idx_assessment_answers_question;'
        'CREATE TABLE idx_assessment_answers_question (x INTEGER);',
      );
      broken.close();

      final db = open(file);
      await expectLater(
        db.select(db.settings).get(),
        throwsA(isA<raw.SqliteException>()),
      );
      await db.close();
    });

    test('a fresh install creates the latest schema directly', () async {
      final file = File('${tmp.path}/fresh.sqlite');
      final db = open(file);
      await db.select(db.errorRecords).get();
      await db.close();
      final check = raw.sqlite3.open(file.path);
      expect(
        check.select('PRAGMA user_version').single.values.single,
        AppDatabase.latestSchemaVersion,
      );
      final indexes = check
          .select("SELECT name FROM sqlite_master WHERE type = 'index'")
          .map((r) => r['name'])
          .toList();
      expect(indexes, contains('idx_review_cards_due'));
      check.close();
    });
  });

  test('progress survives closing and reopening the app database', () async {
    final file = File('${tmp.path}/app.sqlite');
    final clock = FakeClock();
    final lesson = pack.orderedLessons.first;

    // --- first app run ---
    var db = open(file);
    var reviews = ReviewRepository(db, clock: clock.call, enableFuzzing: false);
    var repo = ProgressRepository(db, reviews, clock: clock.call);
    await repo.completeLesson(
      lesson,
      score: 0.85,
      seconds: 420,
      contentVersion: pack.version,
    );
    final first = (await reviews.dueCards()).first;
    final rated = await reviews.rate(first.id, fsrs.Rating.easy);
    await SettingsRepository(db).save(const AppSettings(dailyMinutes: 60));
    await db.close();

    // --- second app run, three days later ---
    clock.advance(const Duration(days: 3));
    db = open(file);
    reviews = ReviewRepository(db, clock: clock.call, enableFuzzing: false);
    repo = ProgressRepository(db, reviews, clock: clock.call);
    final map = await repo.lessonProgressMap();
    expect(ProgressRepository.isCompleted(map[lesson.id]), isTrue);
    expect(map[lesson.id]!.bestScore, 0.85);
    expect(
      ProgressRepository.nextLesson(
        pack,
        map,
        gates: LevelGates.from(pack, const []),
      )!.id,
      pack.orderedLessons[1].id,
    );
    final cards = await reviews.allCards();
    expect(cards.length, lesson.items.length * 2);
    final same = cards.firstWhere((c) => c.id == first.id);
    expect(same.due, rated.due);
    expect(same.stability, rated.stability);
    expect((await db.select(db.reviewLogs).get()).length, 1);
    expect((await db.select(db.studySessions).get()).single.seconds, 420);
    expect((await SettingsRepository(db).load()).dailyMinutes, 60);
    await db.close();
  });

  test('review time commits with a rating and survives interruption', () async {
    final file = File('${tmp.path}/review.sqlite');
    final clock = FakeClock();
    var db = open(file);
    final reviews = ReviewRepository(
      db,
      clock: clock.call,
      enableFuzzing: false,
    );
    final repo = ProgressRepository(db, reviews, clock: clock.call);
    await reviews.ensureCardsForLesson(pack.orderedLessons.first);
    final card = (await reviews.dueCards()).first;
    await db.customStatement('''
      CREATE TEMP TRIGGER fail_study BEFORE INSERT ON study_sessions
      BEGIN SELECT RAISE(ABORT, 'test write failure'); END
    ''');
    await expectLater(
      repo.rateReview(
        card.id,
        fsrs.Rating.good,
        durationMs: 6800,
        activeSeconds: 6,
      ),
      throwsA(isA<raw.SqliteException>()),
    );
    expect(await db.select(db.reviewLogs).get(), isEmpty);
    expect((await reviews.dueCards()).first, card);
    await db.customStatement('DROP TRIGGER fail_study');
    final updated = await repo.rateReview(
      card.id,
      fsrs.Rating.good,
      durationMs: 6800,
      activeSeconds: 6,
    );
    // Close without any end-of-session write.
    await db.close();

    db = open(file);
    final log = (await db.select(db.reviewLogs).get()).single;
    expect(log.cardId, card.id);
    expect(log.dueAfter, updated.due);
    final study = (await db.select(db.studySessions).get()).single;
    expect(study.kind, 'review');
    expect(study.seconds, 6);
    await db.close();
  });

  group('backup', () {
    Future<AppDatabase> seeded() async {
      final db = memoryDb();
      final clock = FakeClock();
      final reviews = ReviewRepository(
        db,
        clock: clock.call,
        enableFuzzing: false,
      );
      final repo = ProgressRepository(db, reviews, clock: clock.call);
      final lesson = pack.orderedLessons.first;
      await repo.completeLesson(
        lesson,
        score: 0.75,
        seconds: 300,
        contentVersion: pack.version,
      );
      final ex = ExerciseBuilder(pack)
          .buildLesson(lesson)
          .whereType<TypeExercise>()
          .first;
      await repo.recordAttempt(
        ex,
        isCorrect: false,
        userAnswer: 'caza',
        context: 'lesson',
        lessonId: lesson.id,
      );
      await reviews.rate((await reviews.dueCards()).first.id, fsrs.Rating.good);
      await SettingsRepository(db).save(const AppSettings(dailyMinutes: 45));
      final phrases = SavedPhrasesRepository(db, clock: clock.call);
      await phrases.save(
        PhraseDraft(
          es: 'Mi casa es tu casa.',
          ar: 'بيتي بيتك.',
          source: PhraseSource(
            kind: 'example',
            id: 'casa',
            lessonId: lesson.id,
          ),
        ),
      );
      await phrases.updateNote((await phrases.all()).single.id, 'ترحيب بضيف');
      return db;
    }

    Future<Map<String, int>> counts(AppDatabase db) async => {
      'settings': (await db.select(db.settings).get()).length,
      'progress': (await db.select(db.lessonProgress).get()).length,
      'attempts': (await db.select(db.activityAttempts).get()).length,
      'cards': (await db.select(db.reviewCards).get()).length,
      'logs': (await db.select(db.reviewLogs).get()).length,
      'sessions': (await db.select(db.studySessions).get()).length,
      'errors': (await db.select(db.errorRecords).get()).length,
      'phrases': (await db.select(db.savedPhrases).get()).length,
    };

    test('export → restore on a new device reproduces all data', () async {
      final source = await seeded();
      final json = await BackupService(source).exportJson(
        now: DateTime.utc(2026, 3, 10),
        contentVersion: pack.version,
      );
      final doc = jsonDecode(json) as Map<String, dynamic>;
      expect(doc['format'], BackupService.format);
      expect(doc['schema_version'], AppDatabase.latestSchemaVersion);

      final target = memoryDb();
      await BackupService(target).restoreJson(json);
      expect(await counts(target), await counts(source));
      final a = await source.select(source.reviewCards).get();
      final b = await target.select(target.reviewCards).get();
      expect(b.map((c) => c.toJson()), a.map((c) => c.toJson()));
      expect((await SettingsRepository(target).load()).dailyMinutes, 45);
      expect(
        (await target.select(target.errorRecords).get()).single.incorrect,
        'caza',
      );
      await source.close();
      await target.close();
    });

    test('restore replaces existing data instead of merging', () async {
      final source = await seeded();
      final json = await BackupService(source)
          .exportJson(now: DateTime.utc(2026), contentVersion: pack.version);
      final target = await seeded();
      final clock = FakeClock();
      await ProgressRepository(
        target,
        ReviewRepository(target, clock: clock.call),
        clock: clock.call,
      ).completeLesson(
        pack.orderedLessons[1],
        score: 1,
        seconds: 60,
        contentVersion: pack.version,
      );
      await BackupService(target).restoreJson(json);
      expect(await counts(target), await counts(source));
      await source.close();
      await target.close();
    });

    /// Every row of every table, as values (not just counts).
    Future<String> snapshot(AppDatabase db) async => jsonEncode(
      (jsonDecode(
        await BackupService(db)
            .exportJson(now: DateTime.utc(2000), contentVersion: 'x'),
      ) as Map)['tables'],
    );

    test(
      'a backup with missing tables is rejected and wipes nothing',
      () async {
        final db = await seeded();
        final before = await snapshot(db);
        expect(jsonDecode(before)['review_cards'], isNotEmpty);
        final service = BackupService(db);
        final doc = jsonDecode(
          await service.exportJson(
            now: DateTime.utc(2026),
            contentVersion: pack.version,
          ),
        ) as Map<String, dynamic>;

        Future<void> rejects(Map<String, dynamic> broken, String why) async {
          await expectLater(
            service.restoreJson(jsonEncode(broken)),
            throwsA(isA<BackupException>()),
            reason: why,
          );
          expect(await snapshot(db), before, reason: '$why changed the data');
        }

        Map<String, dynamic> without(String table) => {
          ...doc,
          'tables': {...(doc['tables'] as Map<String, dynamic>)}..remove(table),
        };

        await rejects({...doc, 'tables': <String, dynamic>{}}, 'tables: {}');
        for (final table in [
          'settings',
          'lesson_progress',
          'activity_attempts',
          'review_cards',
          'review_logs',
          'study_sessions',
          'error_records',
        ]) {
          await rejects(without(table), 'missing $table');
        }
        await rejects({
          ...doc,
          'tables': {
            ...(doc['tables'] as Map<String, dynamic>),
            'review_cards': null,
          },
        }, 'null review_cards');
        await rejects({...doc, 'schema_version': 0}, 'schema 0');
        await rejects({...doc, 'schema_version': '2'}, 'schema as string');
        await rejects({...doc}..remove('schema_version'), 'no schema');
        await db.close();
      },
    );

    test('an inconsistent backup is rejected and wipes nothing', () async {
      final db = await seeded();
      final before = await snapshot(db);
      final service = BackupService(db);
      Future<Map<String, dynamic>> fresh() async => jsonDecode(
        await service.exportJson(
          now: DateTime.utc(2026),
          contentVersion: pack.version,
        ),
      ) as Map<String, dynamic>;
      Future<void> rejects(Map<String, dynamic> broken, String why) async {
        await expectLater(
          service.restoreJson(jsonEncode(broken)),
          throwsA(isA<BackupException>()),
          reason: why,
        );
        expect(await snapshot(db), before, reason: '$why changed the data');
      }

      // Review history pointing at a card that is not in the backup.
      var doc = await fresh();
      ((doc['tables'] as Map)['review_logs'] as List).first['cardId'] = 987654;
      await rejects(doc, 'dangling review log');

      // History without its cards.
      doc = await fresh();
      (doc['tables'] as Map)['review_cards'] = <dynamic>[];
      await rejects(doc, 'logs without cards');

      // Duplicate primary keys.
      doc = await fresh();
      final cards = (doc['tables'] as Map)['review_cards'] as List;
      cards.add(Map<String, dynamic>.from(cards.first as Map));
      await rejects(doc, 'duplicate card');

      // Out-of-range values.
      doc = await fresh();
      ((doc['tables'] as Map)['review_logs'] as List).first['rating'] = 9;
      await rejects(doc, 'rating out of range');
      doc = await fresh();
      ((doc['tables'] as Map)['review_cards'] as List).first['state'] = 0;
      await rejects(doc, 'state out of range');
      await db.close();
    });

    test(
      'invalid or damaged files are rejected and leave data untouched',
      () async {
        final db = await seeded();
        final before = await counts(db);
        final service = BackupService(db);
        final good = await service.exportJson(
          now: DateTime.utc(2026),
          contentVersion: pack.version,
        );
        final doc = jsonDecode(good) as Map<String, dynamic>;

        Future<void> rejects(String json) async {
          await expectLater(
            service.restoreJson(json),
            throwsA(isA<BackupException>()),
          );
          expect(await counts(db), before);
        }

        await rejects('not json at all');
        await rejects(jsonEncode({'format': 'something-else'}));
        await rejects(jsonEncode({...doc, 'schema_version': 99}));
        await rejects(jsonEncode({...doc, 'tables': 'oops'}));
        final broken = jsonDecode(good) as Map<String, dynamic>;
        ((broken['tables'] as Map)['review_cards'] as List).first['due'] =
            'soon';
        await rejects(jsonEncode(broken));
        await db.close();
      },
    );

    test('a schema-v1 backup (no isMeasured) still restores', () async {
      final db = await seeded();
      final service = BackupService(db);
      final doc = jsonDecode(
        await service.exportJson(
          now: DateTime.utc(2026),
          contentVersion: pack.version,
        ),
      ) as Map<String, dynamic>;
      doc['schema_version'] = 1;
      final tables = doc['tables'] as Map<String, dynamic>;
      for (final row in tables['activity_attempts'] as List) {
        (row as Map)
          ..remove('isMeasured')
          ..remove('attemptNumber');
      }
      tables.remove('error_records');
      final target = memoryDb();
      await BackupService(target).restoreJson(jsonEncode(doc));
      final restored =
          (await target.select(target.activityAttempts).get()).single;
      expect(restored.isMeasured, isTrue);
      expect(restored.attemptNumber, 1);
      expect((await target.select(target.reviewCards).get()), isNotEmpty);
      await db.close();
      await target.close();
    });

    test(
      'schema-v2 restores measured flags and defaults attempt numbers',
      () async {
        final db = await seeded();
        final doc = jsonDecode(
          await BackupService(
            db,
          ).exportJson(now: DateTime.utc(2026), contentVersion: pack.version),
        ) as Map<String, dynamic>;
        doc['schema_version'] = 2;
        final row = (doc['tables']['activity_attempts'] as List).single as Map;
        row
          ..remove('attemptNumber')
          ..['isMeasured'] = false;
        final target = memoryDb();
        await BackupService(target).restoreJson(jsonEncode(doc));
        final attempt =
            (await target.select(target.activityAttempts).get()).single;
        expect(attempt.isMeasured, isFalse);
        expect(attempt.attemptNumber, 1);
        expect(await target.select(target.errorRecords).get(), isNotEmpty);
        await db.close();
        await target.close();
      },
    );

    test('invalid schema-defined fields preserve all current rows', () async {
      final db = await seeded();
      final service = BackupService(db);
      final before = await snapshot(db);
      final backup = await service.exportJson(
        now: DateTime.utc(2026),
        contentVersion: pack.version,
      );
      final cases = <(int, String, String, Object?)>[
        (2, 'activity_attempts', 'isMeasured', null),
        (3, 'activity_attempts', 'isMeasured', null),
        (3, 'activity_attempts', 'attemptNumber', null),
        (3, 'activity_attempts', 'attemptNumber', -1),
        (3, 'activity_attempts', 'attemptNumber', 3),
        (3, 'lesson_progress', 'status', 'unknown'),
        (3, 'lesson_progress', 'bestScore', 1.5),
        (3, 'lesson_progress', 'lastScore', -0.1),
        (3, 'review_cards', 'cardType', 'unknown'),
        (3, 'review_cards', 'due', -1),
        (3, 'review_logs', 'dueAfter', 8640000000000001),
      ];
      for (final (version, table, field, value) in cases) {
        final doc = jsonDecode(backup) as Map<String, dynamic>;
        doc['schema_version'] = version;
        final row = (doc['tables'][table] as List).first as Map;
        if (value == null) {
          row.remove(field);
        } else {
          row[field] = value;
        }
        final reason = 'schema $version, $table.$field = $value';
        await expectLater(
          service.restoreJson(jsonEncode(doc)),
          throwsA(isA<BackupException>()),
          reason: reason,
        );
        expect(await snapshot(db), before, reason: reason);
      }
      await db.close();
    });

    test(
      'summarize reports row counts without touching the database',
      () async {
        final db = await seeded();
        final json = await BackupService(db)
            .exportJson(now: DateTime.utc(2026), contentVersion: pack.version);
        final summary = BackupService.summarize(json);
        expect(summary['lesson_progress'], 1);
        expect(
          summary['review_cards'],
          pack.orderedLessons.first.items.length * 2,
        );
        expect(summary['review_logs'], 1);
        expect(BackupService.summarize('garbage'), isEmpty);
        await db.close();
      },
    );

    test(
      'saved phrases round-trip through a backup with their notes',
      () async {
        final source = await seeded();
        final json = await BackupService(source).exportJson(
          now: DateTime.utc(2026, 3, 10),
          contentVersion: pack.version,
        );
        expect(BackupService.summarize(json)['saved_phrases'], 1);
        final target = memoryDb();
        await BackupService(target).restoreJson(json);
        final a = (await source.select(source.savedPhrases).get()).single;
        final b = (await target.select(target.savedPhrases).get()).single;
        expect(b.toJson(), a.toJson());
        await source.close();
        await target.close();
      },
    );

    test(
      'a v4 backup without saved_phrases is rejected, data untouched',
      () async {
        final db = await seeded();
        final before = await snapshot(db);
        final doc = jsonDecode(
          await BackupService(
            db,
          ).exportJson(now: DateTime.utc(2026), contentVersion: pack.version),
        ) as Map<String, dynamic>;
        (doc['tables'] as Map).remove('saved_phrases');
        await expectLater(
          BackupService(db).restoreJson(jsonEncode(doc)),
          throwsA(isA<BackupException>()),
        );
        expect(await snapshot(db), before);
        await db.close();
      },
    );

    test('invalid saved phrases are rejected, data untouched', () async {
      final db = await seeded();
      final before = await snapshot(db);
      Future<void> rejects(
        void Function(Map<String, dynamic> row) corrupt,
        String why, {
        bool duplicate = false,
      }) async {
        final doc = jsonDecode(
          await BackupService(
            db,
          ).exportJson(now: DateTime.utc(2026), contentVersion: pack.version),
        ) as Map<String, dynamic>;
        final rows = (doc['tables'] as Map)['saved_phrases'] as List;
        final row = rows.first as Map<String, dynamic>;
        if (duplicate) {
          rows.add({...row, 'id': 999});
        } else {
          corrupt(row);
        }
        await expectLater(
          BackupService(db).restoreJson(jsonEncode(doc)),
          throwsA(isA<BackupException>()),
          reason: why,
        );
        expect(await snapshot(db), before, reason: '$why changed the data');
      }

      await rejects((r) => r['es'] = '  ', 'empty Spanish');
      await rejects(
        (r) => r['phraseKey'] = 'otra cosa',
        'key not matching text',
      );
      await rejects((r) => r['sourceKind'] = 'telepathy', 'unknown source');
      await rejects((r) => r['savedAt'] = -1, 'negative date');
      await rejects((_) {}, 'duplicate key', duplicate: true);
      await db.close();
    });

    test(
      'restoring a pre-v4 backup keeps the saved phrases already on the device',
      () async {
        final device = await seeded();
        final old = await seeded();
        final doc = jsonDecode(
          await BackupService(
            old,
          ).exportJson(now: DateTime.utc(2026), contentVersion: pack.version),
        ) as Map<String, dynamic>;
        doc['schema_version'] = 3;
        (doc['tables'] as Map).remove('saved_phrases');
        // The restore preview must not report "0 saved phrases" for a file
        // that simply predates them.
        expect(
          BackupService.summarize(jsonEncode(doc)).containsKey('saved_phrases'),
          isFalse,
        );
        final phrasesBefore = (await device.select(device.savedPhrases).get())
            .map((r) => r.toJson())
            .toList();
        await BackupService(device).restoreJson(jsonEncode(doc));
        expect(
          (await device.select(device.savedPhrases).get()).map(
            (r) => r.toJson(),
          ),
          phrasesBefore,
        );
        await device.close();
        await old.close();
      },
    );

    test(
      'reset clears progress but keeps settings and saved phrases',
      () async {
        final db = await seeded();
        await BackupService(db).resetProgress();
        final c = await counts(db);
        expect(c['settings'], greaterThan(0));
        expect(c['phrases'], 1);
        expect(
          (await db.select(db.savedPhrases).get()).single.note,
          'ترحيب بضيف',
        );
        expect(
          (c
                ..remove('settings')
                ..remove('phrases'))
              .values,
          everyElement(0),
        );
        await db.close();
      },
    );
  });
}

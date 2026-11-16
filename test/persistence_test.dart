import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:espanol_pro/core/backup/backup_service.dart';
import 'package:espanol_pro/core/content/models.dart';
import 'package:espanol_pro/core/db/database.dart';
import 'package:espanol_pro/core/learning/exercises.dart';
import 'package:espanol_pro/core/learning/progress_repository.dart';
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

void main() {
  late ContentPack pack;
  late Directory tmp;
  setUpAll(() async => pack = await loadRealContent());
  setUp(() => tmp = Directory.systemTemp.createTempSync('espanol_pro_test'));
  tearDown(() => tmp.deleteSync(recursive: true));

  AppDatabase open(File f) => AppDatabase(NativeDatabase(f));

  group('schema migration v1 → v2', () {
    test('keeps every learner row and adds the new structures', () async {
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
      expect(
        (await db.select(db.activityAttempts).get()).single.isMeasured,
        isTrue,
      );
      expect(await db.select(db.errorRecords).get(), isEmpty);

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
      expect(check.select('PRAGMA user_version').single.values.single, 2);
      check.close();
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
      ProgressRepository.nextLesson(pack, map)!.id,
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
        (row as Map).remove('isMeasured');
      }
      tables.remove('error_records');
      final target = memoryDb();
      await BackupService(target).restoreJson(jsonEncode(doc));
      expect(
        (await target.select(target.activityAttempts).get()).single.isMeasured,
        isTrue,
      );
      await db.close();
      await target.close();
    });

    test('reset clears progress but keeps settings', () async {
      final db = await seeded();
      await BackupService(db).resetProgress();
      final c = await counts(db);
      expect(c['settings'], greaterThan(0));
      expect((c..remove('settings')).values, everyElement(0));
      await db.close();
    });
  });
}

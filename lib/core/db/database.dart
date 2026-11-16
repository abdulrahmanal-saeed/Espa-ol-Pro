import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'database.g.dart';

// ---------------------------------------------------------------------------
// User-data schema.
//
// Only data produced BY THE LEARNER lives in SQLite. Versioned curriculum
// content (levels, units, lessons, vocabulary) ships as read-only JSON assets
// and is referenced here by stable string IDs, so a content update can never
// destroy progress. All timestamps are UTC epoch milliseconds.
// ---------------------------------------------------------------------------

/// Key/value store for user settings.
class Settings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}

/// One row per lesson the learner has started or completed.
class LessonProgress extends Table {
  TextColumn get lessonId => text()();

  /// `started` or `completed`.
  TextColumn get status => text()();

  /// Best first-try accuracy (0..1) over all completed runs.
  RealColumn get bestScore => real().withDefault(const Constant(0))();
  RealColumn get lastScore => real().withDefault(const Constant(0))();
  IntColumn get completions => integer().withDefault(const Constant(0))();
  IntColumn get startedAt => integer()();
  IntColumn get firstCompletedAt => integer().nullable()();
  IntColumn get lastCompletedAt => integer().nullable()();

  /// Content version the lesson was completed against.
  TextColumn get contentVersion => text().withDefault(const Constant(''))();

  @override
  Set<Column> get primaryKey => {lessonId};
}

/// Every graded answer (lesson or practice).
class ActivityAttempts extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get activityId => text()();
  TextColumn get lessonId => text().nullable()();
  TextColumn get itemId => text().nullable()();

  /// reading | listening | writing | speaking | vocabulary | grammar
  TextColumn get skill => text()();
  TextColumn get exerciseType => text()();

  /// lesson | practice
  TextColumn get context => text()();
  BoolColumn get isCorrect => boolean()();

  /// False for self-assessed activities (e.g. listen-and-repeat) that must
  /// never count as measured accuracy.
  BoolColumn get isMeasured => boolean().withDefault(const Constant(true))();

  /// 1 for the first time an exercise is answered inside a run, 2 for the
  /// prompted retry (schema v3). Only first attempts are independent
  /// evidence of ability; retries are remediation.
  IntColumn get attemptNumber => integer().withDefault(const Constant(1))();
  TextColumn get userAnswer => text().withDefault(const Constant(''))();
  TextColumn get expected => text().withDefault(const Constant(''))();
  IntColumn get createdAt => integer()();
}

/// FSRS scheduling state. One card per (item, cardType).
class ReviewCards extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get itemId => text()();

  /// `recognition` (Spanish → meaning) or `production` (Arabic → Spanish).
  TextColumn get cardType => text()();

  /// FSRS state: 1 learning, 2 review, 3 relearning.
  IntColumn get state => integer().withDefault(const Constant(1))();
  IntColumn get step => integer().nullable()();
  RealColumn get stability => real().nullable()();
  RealColumn get difficulty => real().nullable()();
  IntColumn get due => integer()();
  IntColumn get lastReview => integer().nullable()();
  IntColumn get reps => integer().withDefault(const Constant(0))();
  IntColumn get lapses => integer().withDefault(const Constant(0))();
  TextColumn get sourceLessonId => text().nullable()();
  IntColumn get createdAt => integer()();

  @override
  List<Set<Column>> get uniqueKeys => [
    {itemId, cardType},
  ];
}

/// Immutable history of every review rating.
class ReviewLogs extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get cardId =>
      integer().references(ReviewCards, #id, onDelete: KeyAction.cascade)();

  /// 1 again, 2 hard, 3 good, 4 easy.
  IntColumn get rating => integer()();
  IntColumn get stateBefore => integer()();
  IntColumn get reviewedAt => integer()();
  IntColumn get durationMs => integer().nullable()();
  RealColumn get stabilityAfter => real().nullable()();
  RealColumn get difficultyAfter => real().nullable()();
  IntColumn get dueAfter => integer()();

  /// Predicted recall probability at the moment of review (null for new cards).
  RealColumn get retrievability => real().nullable()();
}

/// Time actually spent studying, bucketed by local calendar day.
class StudySessions extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// Local calendar day, `YYYY-MM-DD`, fixed at write time.
  TextColumn get day => text()();

  /// lesson | review | listening | writing | pronunciation | errors
  TextColumn get kind => text()();
  TextColumn get refId => text().nullable()();
  IntColumn get startedAt => integer()();
  IntColumn get seconds => integer()();
}

/// Personal error notebook (added in schema v2). One row per distinct mistake
/// target; repeated mistakes increment [count].
class ErrorRecords extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// Stable identity of the mistake target (normalised expected answer +
  /// exercise type).
  TextColumn get signature => text().unique()();
  TextColumn get incorrect => text()();
  TextColumn get correct => text()();

  /// vocabulary | spelling | word_order | listening | grammar | meaning
  TextColumn get category => text()();
  TextColumn get promptAr => text().withDefault(const Constant(''))();
  TextColumn get lessonId => text().nullable()();
  TextColumn get itemId => text().nullable()();
  IntColumn get count => integer().withDefault(const Constant(1))();

  /// Correct answers given to the same target AFTER the last mistake.
  IntColumn get correctSince => integer().withDefault(const Constant(0))();
  IntColumn get firstSeen => integer()();
  IntColumn get lastSeen => integer()();
}

@DriftDatabase(
  tables: [
    Settings,
    LessonProgress,
    ActivityAttempts,
    ReviewCards,
    ReviewLogs,
    StudySessions,
    ErrorRecords,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  /// Opens the on-device database file.
  factory AppDatabase.onDevice() {
    return AppDatabase(
      LazyDatabase(() async {
        final dir = await getApplicationDocumentsDirectory();
        final file = File(p.join(dir.path, 'espanol_pro.sqlite'));
        return NativeDatabase.createInBackground(file);
      }),
    );
  }

  static const int latestSchemaVersion = 3;

  @override
  int get schemaVersion => latestSchemaVersion;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      await _createIndexes();
    },
    onUpgrade: (m, from, to) async {
      // Migrations are strictly additive: never drop learner data.
      if (from < 2) {
        // v2: personal error notebook + "measured" flag on attempts so that
        // self-assessed speaking practice is never reported as accuracy.
        await m.createTable(errorRecords);
        await m.addColumn(activityAttempts, activityAttempts.isMeasured);
      }
      if (from < 3) {
        // v3: tell first attempts apart from prompted retries. Existing rows
        // default to 1 because earlier versions did not record the difference.
        await m.addColumn(activityAttempts, activityAttempts.attemptNumber);
      }
      await _createIndexes();
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );

  Future<void> _createIndexes() async {
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_review_cards_due ON review_cards (due)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_review_logs_card ON review_logs (card_id)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_attempts_created ON activity_attempts (created_at)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_sessions_day ON study_sessions (day)',
    );
  }
}

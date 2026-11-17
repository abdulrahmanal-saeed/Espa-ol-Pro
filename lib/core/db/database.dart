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

/// Sentences the learner chose to keep (schema v4). Not progress: kept when
/// progress is reset, included in backups.
///
/// Identity is the normalised Spanish text ([phraseKey]), NOT a content id,
/// so a saved phrase survives curriculum edits and the same sentence saved
/// from two screens is one record.
class SavedPhrases extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get phraseKey => text().unique()();
  TextColumn get es => text()();
  TextColumn get ar => text()();
  TextColumn get en => text().withDefault(const Constant(''))();

  /// vocab | example | grammar | lesson_note
  TextColumn get sourceKind => text()();

  /// Content id of the item / grammar note the phrase came from, if any.
  TextColumn get sourceId => text().nullable()();
  TextColumn get sourceLessonId => text().nullable()();
  TextColumn get note => text().withDefault(const Constant(''))();
  IntColumn get savedAt => integer()();
}

/// One submitted checkpoint or level assessment (schema v5).
///
/// Written together with all its [AssessmentAnswers] in one transaction:
/// a row here always means a complete, stored submission. Abandoned or
/// failed attempts leave no row.
class AssessmentAttempts extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get assessmentId => text()();

  /// Version of the assessment definition the learner actually took, so a
  /// later edit of the questions never reinterprets an old result.
  IntColumn get assessmentVersion => integer()();
  TextColumn get contentVersion => text()();
  IntColumn get startedAt => integer()();
  IntColumn get completedAt => integer()();

  /// Objectively scored questions in this attempt.
  IntColumn get maxScore => integer()();

  /// Of those, answered correctly.
  IntColumn get score => integer()();
}

/// One answer within an [AssessmentAttempts] row (schema v5).
class AssessmentAnswers extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get attemptId => integer().references(
    AssessmentAttempts,
    #id,
    onDelete: KeyAction.cascade,
  )();
  TextColumn get questionId => text()();

  /// vocabulary | reading | listening | writing | grammar
  TextColumn get skill => text()();

  /// The "can do" statement this question gives evidence for.
  TextColumn get canDoId => text()();
  BoolColumn get isCorrect => boolean()();

  /// For typed answers: exact | missing_accents | wrong. Null when spelling
  /// does not apply (choices).
  TextColumn get spelling => text().nullable()();
  TextColumn get userAnswer => text().withDefault(const Constant(''))();
  TextColumn get expected => text().withDefault(const Constant(''))();
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
    SavedPhrases,
    AssessmentAttempts,
    AssessmentAnswers,
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

  static const int latestSchemaVersion = 5;

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
      if (from < 4) {
        // v4: personal saved phrases. New table only; nothing else changes.
        await m.createTable(savedPhrases);
      }
      if (from < 5) {
        // v5: checkpoint and level assessment results. New tables only.
        await m.createTable(assessmentAttempts);
        await m.createTable(assessmentAnswers);
      }
      await _createIndexes();
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
      await _ensureOneAnswerPerQuestion();
    },
  );

  /// True when the database holds duplicate answers to one question in one
  /// attempt (possible only in a database written before the restore check
  /// existed). The unique index is then not created, so nothing is deleted;
  /// restore and new submissions still never add duplicates.
  bool assessmentAnswersDegraded = false;

  /// One answer per question per attempt, enforced by the database too.
  ///
  /// Created on every open (not in a migration) so installs already on v5
  /// get it without a schema bump. Only the known legacy case, existing
  /// duplicate rows, is tolerated; any other failure propagates.
  Future<void> _ensureOneAnswerPerQuestion() async {
    final duplicates = await customSelect(
      'SELECT 1 FROM assessment_answers '
      'GROUP BY attempt_id, question_id HAVING COUNT(*) > 1 LIMIT 1',
    ).get();
    assessmentAnswersDegraded = duplicates.isNotEmpty;
    if (assessmentAnswersDegraded) return;
    await customStatement(
      'CREATE UNIQUE INDEX IF NOT EXISTS idx_assessment_answers_question '
      'ON assessment_answers (attempt_id, question_id)',
    );
  }

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
    // Runs after every migration step, so the v5 table always exists here.
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_assessment_answers_attempt '
      'ON assessment_answers (attempt_id)',
    );
  }
}

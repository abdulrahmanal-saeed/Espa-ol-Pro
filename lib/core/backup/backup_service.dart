import 'dart:convert';

import '../db/database.dart';
import '../phrases/saved_phrases_repository.dart';
import '../srs/review_repository.dart';

class BackupException implements Exception {
  BackupException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Full export / restore of all learner data as one JSON document.
class BackupService {
  BackupService(this.db);
  final AppDatabase db;

  static const format = 'espanol-pro-backup';

  /// Tables that have existed since schema version 1.
  static const _tablesV1 = [
    'settings',
    'lesson_progress',
    'activity_attempts',
    'review_cards',
    'review_logs',
    'study_sessions',
  ];

  /// What a backup document contains, for the confirmation dialog. A table
  /// absent from the file (e.g. `saved_phrases` in a pre-v4 backup) is
  /// absent from the result, not reported as 0.
  static Map<String, int> summarize(String json) {
    try {
      final tables = (jsonDecode(json) as Map)['tables'] as Map;
      return {
        for (final e in tables.entries)
          if (e.value is List) e.key as String: (e.value as List).length,
      };
    } catch (_) {
      return const {};
    }
  }

  Future<String> exportJson({
    required DateTime now,
    required String contentVersion,
  }) async {
    final doc = {
      'format': format,
      'schema_version': AppDatabase.latestSchemaVersion,
      'content_version': contentVersion,
      'exported_at': now.toUtc().toIso8601String(),
      'tables': {
        'settings': [
          for (final r in await db.select(db.settings).get()) r.toJson(),
        ],
        'lesson_progress': [
          for (final r in await db.select(db.lessonProgress).get()) r.toJson(),
        ],
        'activity_attempts': [
          for (final r in await db.select(db.activityAttempts).get())
            r.toJson(),
        ],
        'review_cards': [
          for (final r in await db.select(db.reviewCards).get()) r.toJson(),
        ],
        'review_logs': [
          for (final r in await db.select(db.reviewLogs).get()) r.toJson(),
        ],
        'study_sessions': [
          for (final r in await db.select(db.studySessions).get()) r.toJson(),
        ],
        'error_records': [
          for (final r in await db.select(db.errorRecords).get()) r.toJson(),
        ],
        'saved_phrases': [
          for (final r in await db.select(db.savedPhrases).get()) r.toJson(),
        ],
        'assessment_attempts': [
          for (final r in await db.select(db.assessmentAttempts).get())
            r.toJson(),
        ],
        'assessment_answers': [
          for (final r in await db.select(db.assessmentAnswers).get())
            r.toJson(),
        ],
      },
    };
    return const JsonEncoder.withIndent(' ').convert(doc);
  }

  /// Replaces ALL learner data with the backup. The document is fully parsed
  /// and validated before anything is deleted, and the swap is one
  /// transaction: a bad file can never leave the database half-restored.
  Future<void> restoreJson(String json) async {
    final Map<String, dynamic> doc;
    try {
      doc = jsonDecode(json) as Map<String, dynamic>;
    } catch (_) {
      throw BackupException('الملف ليس نسخة احتياطية صالحة (JSON غير سليم).');
    }
    if (doc['format'] != format) {
      throw BackupException('هذا الملف ليس نسخة احتياطية من Español Pro.');
    }
    final schema = doc['schema_version'];
    if (schema is! int || schema < 1) {
      throw BackupException('النسخة الاحتياطية لا تحمل رقم إصدار صالحاً.');
    }
    if (schema > AppDatabase.latestSchemaVersion) {
      throw BackupException(
        'النسخة الاحتياطية من إصدار أحدث من التطبيق. حدّث التطبيق أولاً.',
      );
    }
    final tables = doc['tables'];
    if (tables is! Map<String, dynamic>) {
      throw BackupException('النسخة الاحتياطية ناقصة.');
    }

    // Every table that existed in the backup's schema version MUST be
    // present as a list. A missing table is never read as "empty": that
    // would let a truncated file wipe the learner's data.
    final required = [
      ..._tablesV1,
      if (schema >= 2) 'error_records',
      if (schema >= 4) 'saved_phrases',
      if (schema >= 5) 'assessment_attempts',
      if (schema >= 5) 'assessment_answers',
    ];
    for (final name in required) {
      if (tables[name] is! List) {
        throw BackupException(
          'النسخة الاحتياطية ناقصة: الجدول "$name" غير موجود.',
        );
      }
    }

    List<T> parse<T>(String name, T Function(Map<String, dynamic>) f) {
      final rows = tables[name];
      if (rows == null) return const []; // only tables newer than [schema]
      try {
        return [
          for (final r in rows as List) f((r as Map).cast<String, dynamic>()),
        ];
      } catch (_) {
        throw BackupException('بيانات تالفة في الجدول "$name".');
      }
    }

    final settings = parse('settings', Setting.fromJson);
    final progress = parse('lesson_progress', LessonProgressData.fromJson);
    final attempts = parse('activity_attempts', (j) {
      // Columns added after the backup was written get their defaults.
      if (schema < 2) j.putIfAbsent('isMeasured', () => true);
      if (schema < 3) j.putIfAbsent('attemptNumber', () => 1);
      return ActivityAttempt.fromJson(j);
    });
    final cards = parse('review_cards', ReviewCard.fromJson);
    final logs = parse('review_logs', ReviewLog.fromJson);
    final sessions = parse('study_sessions', StudySession.fromJson);
    final errors = parse('error_records', ErrorRecord.fromJson);
    final phrases = parse('saved_phrases', SavedPhrase.fromJson);
    final assessmentRuns = parse(
      'assessment_attempts',
      AssessmentAttempt.fromJson,
    );
    final assessmentAnswers = parse(
      'assessment_answers',
      AssessmentAnswer.fromJson,
    );

    // Integrity checks, still before anything is deleted.
    void unique(String table, Iterable<Object> keys) {
      final seen = <Object>{};
      for (final k in keys) {
        if (!seen.add(k)) {
          throw BackupException('بيانات مكرّرة في الجدول "$table".');
        }
      }
    }

    unique('settings', settings.map((r) => r.key));
    unique('lesson_progress', progress.map((r) => r.lessonId));
    unique('activity_attempts', attempts.map((r) => r.id));
    unique('review_cards', cards.map((r) => r.id));
    unique('review_cards', cards.map((r) => '${r.itemId}|${r.cardType}'));
    unique('review_logs', logs.map((r) => r.id));
    unique('study_sessions', sessions.map((r) => r.id));
    unique('error_records', errors.map((r) => r.id));
    unique('error_records', errors.map((r) => r.signature));
    unique('saved_phrases', phrases.map((r) => r.id));
    unique('saved_phrases', phrases.map((r) => r.phraseKey));
    unique('assessment_attempts', assessmentRuns.map((r) => r.id));
    unique('assessment_answers', assessmentAnswers.map((r) => r.id));
    // One answer per question per attempt: a duplicated row would count a
    // question twice as evidence even when the totals are adjusted to match.
    unique(
      'assessment_answers',
      assessmentAnswers.map((r) => '${r.attemptId}|${r.questionId}'),
    );
    // Every answer belongs to an attempt in this file, and every attempt's
    // stored score matches its answers: a result can never be inflated or
    // orphaned by an edited backup.
    final runIds = {for (final r in assessmentRuns) r.id};
    if (assessmentAnswers.any((x) => !runIds.contains(x.attemptId))) {
      throw BackupException(
        'النسخة الاحتياطية غير متّسقة: إجابة تقييم بلا محاولة.',
      );
    }
    for (final r in assessmentRuns) {
      final mine = assessmentAnswers.where((x) => x.attemptId == r.id);
      if (r.maxScore < 1 ||
          r.maxScore != mine.length ||
          r.score != mine.where((x) => x.isCorrect).length ||
          r.assessmentVersion < 1 ||
          r.completedAt < r.startedAt ||
          !_validDue(r.completedAt)) {
        throw BackupException(
          'النسخة الاحتياطية غير متّسقة: نتيجة تقييم لا تطابق إجاباتها.',
        );
      }
    }
    const spellings = {null, 'exact', 'missing_accents', 'wrong'};
    if (assessmentAnswers.any(
      (x) =>
          !spellings.contains(x.spelling) ||
          x.questionId.trim().isEmpty ||
          x.canDoId.trim().isEmpty ||
          x.skill.trim().isEmpty,
    )) {
      throw BackupException('قيم غير صالحة في الجدول "assessment_answers".');
    }
    final cardIds = cards.map((c) => c.id).toSet();
    if (logs.any((l) => !cardIds.contains(l.cardId))) {
      throw BackupException(
        'النسخة الاحتياطية غير متّسقة: سجلّ مراجعة يشير إلى بطاقة غير موجودة.',
      );
    }
    if (cards.any((c) => c.state < 1 || c.state > 3) ||
        logs.any((l) => l.rating < 1 || l.rating > 4)) {
      throw BackupException('النسخة الاحتياطية تحتوي قيماً غير صالحة.');
    }
    void validate(String table, bool valid) {
      if (!valid) {
        throw BackupException('قيم غير صالحة في الجدول "$table".');
      }
    }

    validate(
      'activity_attempts',
      attempts.every((a) => a.attemptNumber == 1 || a.attemptNumber == 2),
    );
    validate(
      'lesson_progress',
      progress.every(
        (p) =>
            (p.status == 'started' || p.status == 'completed') &&
            _validScore(p.bestScore) &&
            _validScore(p.lastScore),
      ),
    );
    validate(
      'review_cards',
      cards.every(
        (c) =>
            (c.cardType == cardRecognition || c.cardType == cardProduction) &&
            _validDue(c.due),
      ),
    );
    validate('review_logs', logs.every((l) => _validDue(l.dueAfter)));
    validate(
      'saved_phrases',
      phrases.every(
        (p) =>
            p.es.trim().isNotEmpty &&
            p.phraseKey == SavedPhrasesRepository.keyFor(p.es) &&
            PhraseSource.kinds.contains(p.sourceKind) &&
            _validDue(p.savedAt),
      ),
    );

    await db.transaction(() async {
      await db.delete(db.reviewLogs).go();
      await db.delete(db.reviewCards).go();
      await db.delete(db.activityAttempts).go();
      await db.delete(db.lessonProgress).go();
      await db.delete(db.studySessions).go();
      await db.delete(db.errorRecords).go();
      await db.delete(db.settings).go();
      // Saved phrases are replaced only by a backup that contains them. A
      // backup from before they existed (schema < 4) leaves them untouched
      // rather than silently deleting them.
      if (schema >= 4) await db.delete(db.savedPhrases).go();
      // Same for assessment results (schema 5).
      if (schema >= 5) {
        await db.delete(db.assessmentAnswers).go();
        await db.delete(db.assessmentAttempts).go();
      }
      await db.batch((b) {
        b.insertAll(db.settings, settings);
        b.insertAll(db.lessonProgress, progress);
        b.insertAll(db.activityAttempts, attempts);
        b.insertAll(db.reviewCards, cards);
        b.insertAll(db.reviewLogs, logs);
        b.insertAll(db.studySessions, sessions);
        b.insertAll(db.errorRecords, errors);
        if (schema >= 4) b.insertAll(db.savedPhrases, phrases);
        if (schema >= 5) {
          b.insertAll(db.assessmentAttempts, assessmentRuns);
          b.insertAll(db.assessmentAnswers, assessmentAnswers);
        }
      });
    });
  }

  static bool _validScore(double score) => score >= 0 && score <= 1;

  // Dart DateTime supports up to 100 million days on either side of the epoch.
  static bool _validDue(int millis) =>
      millis >= 0 && millis <= 8640000000000000;

  /// Deletes all learning progress, including assessment results. Settings
  /// and saved phrases (the learner's personal library, not progress) are
  /// kept.
  Future<void> resetProgress() async {
    await db.transaction(() async {
      await db.delete(db.assessmentAnswers).go();
      await db.delete(db.assessmentAttempts).go();
      await db.delete(db.reviewLogs).go();
      await db.delete(db.reviewCards).go();
      await db.delete(db.activityAttempts).go();
      await db.delete(db.lessonProgress).go();
      await db.delete(db.studySessions).go();
      await db.delete(db.errorRecords).go();
    });
  }
}

import 'dart:convert';

import '../db/database.dart';

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

  /// What a backup document contains, for the confirmation dialog.
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
    final required = [..._tablesV1, if (schema >= 2) 'error_records'];
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
      j.putIfAbsent('isMeasured', () => true);
      j.putIfAbsent('attemptNumber', () => 1);
      return ActivityAttempt.fromJson(j);
    });
    final cards = parse('review_cards', ReviewCard.fromJson);
    final logs = parse('review_logs', ReviewLog.fromJson);
    final sessions = parse('study_sessions', StudySession.fromJson);
    final errors = parse('error_records', ErrorRecord.fromJson);

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

    await db.transaction(() async {
      await db.delete(db.reviewLogs).go();
      await db.delete(db.reviewCards).go();
      await db.delete(db.activityAttempts).go();
      await db.delete(db.lessonProgress).go();
      await db.delete(db.studySessions).go();
      await db.delete(db.errorRecords).go();
      await db.delete(db.settings).go();
      await db.batch((b) {
        b.insertAll(db.settings, settings);
        b.insertAll(db.lessonProgress, progress);
        b.insertAll(db.activityAttempts, attempts);
        b.insertAll(db.reviewCards, cards);
        b.insertAll(db.reviewLogs, logs);
        b.insertAll(db.studySessions, sessions);
        b.insertAll(db.errorRecords, errors);
      });
    });
  }

  /// Deletes all learner data (settings are kept).
  Future<void> resetProgress() async {
    await db.transaction(() async {
      await db.delete(db.reviewLogs).go();
      await db.delete(db.reviewCards).go();
      await db.delete(db.activityAttempts).go();
      await db.delete(db.lessonProgress).go();
      await db.delete(db.studySessions).go();
      await db.delete(db.errorRecords).go();
    });
  }
}

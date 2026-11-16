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
    if (schema is! int || schema > AppDatabase.latestSchemaVersion) {
      throw BackupException(
        'النسخة الاحتياطية من إصدار أحدث من التطبيق. حدّث التطبيق أولاً.',
      );
    }
    final tables = doc['tables'];
    if (tables is! Map<String, dynamic>) {
      throw BackupException('النسخة الاحتياطية ناقصة.');
    }

    List<T> parse<T>(String name, T Function(Map<String, dynamic>) f) {
      try {
        return [
          for (final r in tables[name] as List? ?? const [])
            f((r as Map).cast<String, dynamic>()),
        ];
      } catch (_) {
        throw BackupException('بيانات تالفة في الجدول "$name".');
      }
    }

    final settings = parse('settings', Setting.fromJson);
    final progress = parse('lesson_progress', LessonProgressData.fromJson);
    final attempts = parse('activity_attempts', (j) {
      // Backups written by schema v1 predate this flag.
      j.putIfAbsent('isMeasured', () => true);
      return ActivityAttempt.fromJson(j);
    });
    final cards = parse('review_cards', ReviewCard.fromJson);
    final logs = parse('review_logs', ReviewLog.fromJson);
    final sessions = parse('study_sessions', StudySession.fromJson);
    final errors = parse('error_records', ErrorRecord.fromJson);

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

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'backup/backup_service.dart';
import 'content/models.dart';
import 'db/database.dart';
import 'learning/exercises.dart';
import 'learning/progress_repository.dart';
import 'settings.dart';
import 'speech/speech_service.dart';
import 'srs/review_repository.dart';

// Overridden at bootstrap (and in tests).
final databaseProvider = Provider<AppDatabase>(
  (ref) => throw UnimplementedError('databaseProvider must be overridden'),
);
final contentProvider = Provider<ContentPack>(
  (ref) => throw UnimplementedError('contentProvider must be overridden'),
);
final initialSettingsProvider = Provider<AppSettings>(
  (ref) => const AppSettings(),
);
final clockProvider = Provider<Clock>((ref) => DateTime.now);
final speechProvider = Provider<SpeechService>((ref) => DeviceTtsSpeech());

/// Disabled in tests so intervals are exactly reproducible.
final fsrsFuzzProvider = Provider<bool>((ref) => true);

class SettingsNotifier extends Notifier<AppSettings> {
  @override
  AppSettings build() => ref.watch(initialSettingsProvider);

  Future<void> update(AppSettings next) async {
    state = next;
    await SettingsRepository(ref.read(databaseProvider)).save(next);
    await ref
        .read(speechProvider)
        .configure(accent: next.accent, rate: next.speechRate);
  }
}

final settingsProvider = NotifierProvider<SettingsNotifier, AppSettings>(
  SettingsNotifier.new,
);

final reviewRepositoryProvider = Provider<ReviewRepository>((ref) {
  final retention = ref.watch(
    settingsProvider.select((s) => s.desiredRetention),
  );
  return ReviewRepository(
    ref.watch(databaseProvider),
    clock: ref.watch(clockProvider),
    desiredRetention: retention,
    enableFuzzing: ref.watch(fsrsFuzzProvider),
  );
});

final progressRepositoryProvider = Provider<ProgressRepository>(
  (ref) => ProgressRepository(
    ref.watch(databaseProvider),
    ref.watch(reviewRepositoryProvider),
    clock: ref.watch(clockProvider),
  ),
);

final backupServiceProvider = Provider<BackupService>(
  (ref) => BackupService(ref.watch(databaseProvider)),
);

final exerciseBuilderProvider = Provider<ExerciseBuilder>(
  (ref) => ExerciseBuilder(ref.watch(contentProvider)),
);

final lessonProgressProvider = StreamProvider<Map<String, LessonProgressData>>(
  (ref) => ref.watch(progressRepositoryProvider).watchLessonProgress(),
);

final sessionsProvider = StreamProvider<List<StudySession>>(
  (ref) => ref.watch(progressRepositoryProvider).watchSessions(),
);

final cardsProvider = StreamProvider<List<ReviewCard>>(
  (ref) => ref
      .watch(databaseProvider)
      .select(ref.watch(databaseProvider).reviewCards)
      .watch(),
);

final reviewLogsProvider = StreamProvider<List<ReviewLog>>(
  (ref) => ref
      .watch(databaseProvider)
      .select(ref.watch(databaseProvider).reviewLogs)
      .watch(),
);

final errorsProvider = StreamProvider<List<ErrorRecord>>(
  (ref) => ref.watch(progressRepositoryProvider).watchErrors(),
);

final attemptsProvider = StreamProvider<List<ActivityAttempt>>(
  (ref) => ref
      .watch(databaseProvider)
      .select(ref.watch(databaseProvider).activityAttempts)
      .watch(),
);

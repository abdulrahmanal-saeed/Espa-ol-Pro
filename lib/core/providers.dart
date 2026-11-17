import 'dart:async';

import 'package:flutter/widgets.dart' show AppLifecycleListener;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'backup/backup_service.dart';
import 'content/models.dart';
import 'db/database.dart';
import 'learning/exercises.dart';
import 'learning/progress_repository.dart';
import 'phrases/saved_phrases_repository.dart';
import 'settings.dart';
import 'speech/speech_service.dart';
import 'srs/due_counter.dart';
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

/// Live due-card count for the dashboard and practice tab.
///
/// No polling: the count changes only when the cards table changes (handled
/// by [cardsProvider]) or when the next card's due instant arrives. For the
/// latter, ONE timer is set for exactly that instant. The timer exists only
/// while a screen listens (autoDispose), and the value is recomputed when the
/// app returns to the foreground, in case timers were delayed in background.
final dueSummaryProvider = Provider.autoDispose<DueSummary>((ref) {
  final cards = ref.watch(cardsProvider).value ?? const <ReviewCard>[];
  final clock = ref.watch(clockProvider);
  final now = clock();
  final summary = DueSummary.of(cards, now);
  final wait = summary.refreshAfter(now);
  if (wait != null) {
    final timer = Timer(wait, ref.invalidateSelf);
    ref.onDispose(timer.cancel);
  }
  final lifecycle = AppLifecycleListener(onResume: ref.invalidateSelf);
  ref.onDispose(lifecycle.dispose);
  return summary;
});

final savedPhrasesRepositoryProvider = Provider<SavedPhrasesRepository>(
  (ref) => SavedPhrasesRepository(
    ref.watch(databaseProvider),
    clock: ref.watch(clockProvider),
  ),
);

final savedPhrasesProvider = StreamProvider<List<SavedPhrase>>(
  (ref) => ref.watch(savedPhrasesRepositoryProvider).watchAll(),
);

final savedPhraseKeysProvider = Provider<Set<String>>(
  (ref) => {
    for (final p in ref.watch(savedPhrasesProvider).value ?? const [])
      p.phraseKey,
  },
);

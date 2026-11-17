import 'dart:io';

import 'package:espanol_pro/app/app.dart';
import 'package:espanol_pro/core/content/models.dart';
import 'package:espanol_pro/core/db/database.dart';
import 'package:espanol_pro/core/learning/exercises.dart';
import 'package:espanol_pro/core/providers.dart';
import 'package:espanol_pro/core/settings.dart';
import 'package:espanol_pro/core/speech/speech_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'fake_reminders.dart';
import 'support.dart';

/// Loads the real app fonts so layout in tests matches the device (the
/// default test font is a square block that distorts every measurement).
Future<void> loadAppFonts() async {
  Future<void> family(String name, String prefix) async {
    final loader = FontLoader(name);
    for (final w in const [400, 500, 600, 700]) {
      final bytes = File('assets/fonts/$prefix-$w.ttf').readAsBytesSync();
      loader.addFont(Future.value(ByteData.view(bytes.buffer)));
    }
    await loader.load();
  }

  await family('PlexArabic', 'PlexArabic');
  await family('Inter', 'Inter');
  final icons = File(
    '${Platform.environment['FLUTTER_ROOT'] ?? _flutterRoot()}'
    '/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
  );
  if (icons.existsSync()) {
    final loader = FontLoader('MaterialIcons')
      ..addFont(Future.value(ByteData.view(icons.readAsBytesSync().buffer)));
    await loader.load();
  }
}

String _flutterRoot() {
  // `flutter test` runs the Dart binary from <root>/bin/cache/dart-sdk/bin.
  return File(Platform.resolvedExecutable)
      .parent
      .parent
      .parent
      .parent
      .parent
      .path;
}

class TestApp {
  TestApp(this.pack, {bool voice = true, SilentSpeech? speech})
    : db = memoryDb(),
      clock = FakeClock(),
      speech = speech ?? SilentSpeech(available: voice),
      reminders = FakeReminderPlatform();

  final ContentPack pack;
  final AppDatabase db;
  final FakeClock clock;
  final SilentSpeech speech;
  final FakeReminderPlatform reminders;

  Future<void> pump(
    WidgetTester tester, {
    String location = '/home',
    AppSettings settings = const AppSettings(),
    Size size = const Size(412, 915),
  }) async {
    tester.view.physicalSize = size * 2;
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        key: UniqueKey(),
        overrides: [
          databaseProvider.overrideWithValue(db),
          contentProvider.overrideWithValue(pack),
          initialSettingsProvider.overrideWithValue(settings),
          speechProvider.overrideWithValue(speech),
          clockProvider.overrideWithValue(clock.call),
          fsrsFuzzProvider.overrideWithValue(false),
          reminderPlatformProvider.overrideWithValue(reminders),
        ],
        child: EspanolProApp(initialLocation: location),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// Unmounts the app and lets Drift's stream-cleanup timers fire.
  Future<void> dispose(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
    await db.close();
  }
}

extension Robot on WidgetTester {
  Future<void> tapSettled(Finder finder) async {
    await ensureVisible(finder.first);
    await pumpAndSettle();
    await tap(finder.first);
    await pumpAndSettle();
  }

  Future<void> tapKey(String key) => tapSettled(find.byKey(ValueKey(key)));

  /// Answers one step on screen. [correct] = false gives a wrong answer
  /// (supported for choice / typed exercises).
  Future<void> answer(LessonStep step, {bool correct = true}) async {
    switch (step) {
      case TeachStep _:
        await tapSettled(find.text('التالي'));
      case NoteStep _:
        await tapSettled(find.text('فهمت'));
      case ChoiceExercise e:
        final i = correct
            ? e.correctIndex
            : (e.correctIndex + 1) % e.options.length;
        await tapKey('option-$i');
        await tapSettled(find.text('تحقّق'));
        await tapKey('continue-button');
      case TypeExercise e:
        await enterText(
          find.byKey(const ValueKey('answer-field')),
          correct ? e.accepted.first : 'zzz',
        );
        await pumpAndSettle();
        await tapSettled(find.text('تحقّق'));
        await tapKey('continue-button');
      case OrderExercise e:
        final used = <int>{};
        for (final word in e.answer) {
          final i = [for (var k = 0; k < e.tokens.length; k++) k]
              .firstWhere((k) => e.tokens[k] == word && used.add(k));
          await tapKey('bank-$i');
        }
        await tapSettled(find.text('تحقّق'));
        await tapKey('continue-button');
      case MatchExercise e:
        for (final p in e.pairs) {
          await tapKey('es-${p.itemId}');
          await tapKey('ar-${p.itemId}');
        }
        await tapKey('continue-button');
      case SpeakExercise _:
        await tapSettled(find.text('كرّرتها بصوت مسموع'));
    }
  }
}

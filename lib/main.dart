import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;

import 'app/app.dart';
import 'app/theme.dart';
import 'core/content/content_parser.dart';
import 'core/content/models.dart';
import 'core/db/database.dart';
import 'core/providers.dart';
import 'core/reminders/plugin_reminder_platform.dart';
import 'core/reminders/reminder_service.dart';
import 'core/settings.dart';
import 'core/speech/speech_service.dart';

const contentRoot = 'assets/content/v1';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const Bootstrap());
}

class _Boot {
  const _Boot(
    this.db,
    this.content,
    this.settings,
    this.speech,
    this.reminders,
    this.taps,
    this.startRoute,
  );
  final AppDatabase db;
  final ContentPack content;
  final AppSettings settings;
  final SpeechService speech;
  final ReminderPlatform reminders;
  final ValueNotifier<String?> taps;
  final String startRoute;
}

/// Opens the database, loads settings and the bundled content package, then
/// starts the app. Shows a splash while loading and a recoverable error
/// screen if anything fails — never a blank screen.
class Bootstrap extends StatefulWidget {
  const Bootstrap({super.key});

  @override
  State<Bootstrap> createState() => _BootstrapState();
}

class _BootstrapState extends State<Bootstrap> {
  late Future<_Boot> _future = _load();
  AppDatabase? _db;
  final _taps = ValueNotifier<String?>(null);

  Future<_Boot> _load() async {
    final db = _db ??= AppDatabase.onDevice();
    final settings = await SettingsRepository(db).load();
    final content = await parseContentPack(
      (path) => rootBundle.loadString('$contentRoot/$path'),
    );
    final speech = DeviceTtsSpeech();
    await speech.configure(accent: settings.accent, rate: settings.speechRate);

    // Local reminders. A failure here must never stop the app from opening.
    tzdata.initializeTimeZones();
    final reminders = PluginReminderPlatform();
    final taps = _taps;
    var startRoute = '/home';
    try {
      await reminders.initialize(
        onTap: (payload) => taps.value = safeReminderRoute(payload),
      );
      startRoute =
          safeReminderRoute(await reminders.launchPayload()) ?? startRoute;
    } catch (_) {}
    return _Boot(db, content, settings, speech, reminders, taps, startRoute);
  }

  @override
  void dispose() {
    _db?.close();
    _taps.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<_Boot>(
    future: _future,
    builder: (context, snap) {
      if (snap.hasData) {
        final boot = snap.data!;
        return ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(boot.db),
            contentProvider.overrideWithValue(boot.content),
            initialSettingsProvider.overrideWithValue(boot.settings),
            speechProvider.overrideWithValue(boot.speech),
            reminderPlatformProvider.overrideWithValue(boot.reminders),
            notificationTapsProvider.overrideWithValue(boot.taps),
          ],
          child: EspanolProApp(initialLocation: boot.startRoute),
        );
      }
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: buildTheme(Brightness.light),
        darkTheme: buildTheme(Brightness.dark),
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            // Same colour as the native Android splash, so the hand-over
            // from the system splash to Flutter is seamless.
            backgroundColor: snap.hasError
                ? null
                : (MediaQuery.platformBrightnessOf(context) == Brightness.dark
                      ? brandTealNight
                      : brandTeal),
            body: Center(
              child: snap.hasError
                  ? Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.error_outline_rounded, size: 56),
                          const SizedBox(height: 16),
                          const Text(
                            'تعذّر تشغيل التطبيق',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text('${snap.error}', textAlign: TextAlign.center),
                          const SizedBox(height: 20),
                          FilledButton(
                            onPressed: () => setState(() => _future = _load()),
                            child: const Text('أعد المحاولة'),
                          ),
                        ],
                      ),
                    )
                  : const BrandSplash(),
            ),
          ),
        ),
      );
    },
  );
}

/// The «ñ» mark and wordmark, matching the launcher icon and native splash.
class BrandSplash extends StatelessWidget {
  const BrandSplash({super.key});

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Español Pro — جارٍ التحميل',
    child: const Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'ñ',
          style: TextStyle(
            fontFamily: spanishFont,
            fontSize: 96,
            height: 1,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        SizedBox(height: 16),
        Directionality(
          textDirection: TextDirection.ltr,
          child: Text(
            'Español Pro',
            style: TextStyle(
              fontFamily: spanishFont,
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
        ),
        SizedBox(height: 32),
        SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            color: Colors.white,
          ),
        ),
      ],
    ),
  );
}

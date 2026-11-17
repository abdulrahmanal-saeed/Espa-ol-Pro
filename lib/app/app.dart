import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../core/providers.dart';
import '../core/reminders/reminder_service.dart';
import 'router.dart';
import 'theme.dart';

/// Root widget. Arabic (RTL) is the interface language; Spanish content opts
/// into LTR locally through `EsText`.
class EspanolProApp extends ConsumerStatefulWidget {
  const EspanolProApp({super.key, this.initialLocation = '/home'});
  final String initialLocation;

  @override
  ConsumerState<EspanolProApp> createState() => _EspanolProAppState();
}

class _EspanolProAppState extends ConsumerState<EspanolProApp> {
  late final GoRouter _router = buildRouter(
    initialLocation: widget.initialLocation,
  );

  late final AppLifecycleListener _lifecycle;
  late final ValueNotifier<String?> _taps;

  @override
  void initState() {
    super.initState();
    _taps = ref.read(notificationTapsProvider)..addListener(_openTapped);
    // Re-sync on every return to the foreground: the device may have moved
    // to another time zone, or notifications may have been allowed/blocked
    // in system settings meanwhile.
    _lifecycle = AppLifecycleListener(
      onResume: () => ref.read(reminderStateProvider.notifier).sync(),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(reminderStateProvider.notifier).sync();
    });
  }

  void _openTapped() {
    final route = safeReminderRoute(_taps.value);
    if (route != null) _router.go(route);
    _taps.value = null;
  }

  @override
  void dispose() {
    _taps.removeListener(_openTapped);
    _lifecycle.dispose();
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    return MaterialApp.router(
      title: 'Español Pro',
      debugShowCheckedModeBanner: false,
      routerConfig: _router,
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar'), Locale('es'), Locale('en')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
      themeMode: switch (settings.themeMode) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      },
      builder: (context, child) {
        // Combine the learner's in-app text size with the system setting.
        final system = MediaQuery.textScalerOf(context).scale(1);
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(
              (system * settings.textScale).clamp(0.8, 1.8),
            ),
          ),
          child: child!,
        );
      },
    );
  }
}

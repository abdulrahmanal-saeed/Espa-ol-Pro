import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../core/providers.dart';
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

  @override
  void dispose() {
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

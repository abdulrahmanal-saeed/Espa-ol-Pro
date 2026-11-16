import 'package:drift/drift.dart';

import 'db/database.dart';

/// User preferences. Persisted as key/value rows in SQLite.
class AppSettings {
  const AppSettings({
    this.dailyMinutes = 20,
    this.themeMode = 'system',
    this.textScale = 1.0,
    this.accent = 'es-MX',
    this.speechRate = 0.45,
    this.showEnglish = false,
    this.desiredRetention = 0.9,
    this.autoPlayAudio = true,
  });

  /// 20 (quick), 45 (standard) or 60 (intensive).
  final int dailyMinutes;

  /// system | light | dark
  final String themeMode;
  final double textScale;

  /// BCP-47 tag of the preferred Spanish voice.
  final String accent;
  final double speechRate;
  final bool showEnglish;

  /// FSRS target probability of recall (0.80–0.95).
  final double desiredRetention;
  final bool autoPlayAudio;

  static const accents = {
    'es-MX': 'إسبانية المكسيك (أمريكا اللاتينية)',
    'es-ES': 'إسبانية إسبانيا',
    'es-US': 'إسبانية الولايات المتحدة',
  };

  AppSettings copyWith({
    int? dailyMinutes,
    String? themeMode,
    double? textScale,
    String? accent,
    double? speechRate,
    bool? showEnglish,
    double? desiredRetention,
    bool? autoPlayAudio,
  }) => AppSettings(
    dailyMinutes: dailyMinutes ?? this.dailyMinutes,
    themeMode: themeMode ?? this.themeMode,
    textScale: textScale ?? this.textScale,
    accent: accent ?? this.accent,
    speechRate: speechRate ?? this.speechRate,
    showEnglish: showEnglish ?? this.showEnglish,
    desiredRetention: desiredRetention ?? this.desiredRetention,
    autoPlayAudio: autoPlayAudio ?? this.autoPlayAudio,
  );

  Map<String, String> toMap() => {
    'dailyMinutes': '$dailyMinutes',
    'themeMode': themeMode,
    'textScale': '$textScale',
    'accent': accent,
    'speechRate': '$speechRate',
    'showEnglish': '$showEnglish',
    'desiredRetention': '$desiredRetention',
    'autoPlayAudio': '$autoPlayAudio',
  };

  /// Tolerant of missing/corrupt values: anything invalid falls back to the
  /// default instead of breaking startup.
  factory AppSettings.fromMap(Map<String, String> m) {
    const d = AppSettings();
    final minutes = int.tryParse(m['dailyMinutes'] ?? '');
    final retention = double.tryParse(m['desiredRetention'] ?? '');
    final scale = double.tryParse(m['textScale'] ?? '');
    final rate = double.tryParse(m['speechRate'] ?? '');
    return AppSettings(
      dailyMinutes: const [20, 45, 60].contains(minutes)
          ? minutes!
          : d.dailyMinutes,
      themeMode: const ['system', 'light', 'dark'].contains(m['themeMode'])
          ? m['themeMode']!
          : d.themeMode,
      textScale: scale == null ? d.textScale : scale.clamp(0.85, 1.4),
      accent: accents.containsKey(m['accent']) ? m['accent']! : d.accent,
      speechRate: rate == null ? d.speechRate : rate.clamp(0.2, 0.7),
      showEnglish: m['showEnglish'] == 'true',
      desiredRetention: retention == null
          ? d.desiredRetention
          : retention.clamp(0.8, 0.95),
      autoPlayAudio: m['autoPlayAudio'] != 'false',
    );
  }
}

class SettingsRepository {
  SettingsRepository(this.db);
  final AppDatabase db;

  Future<AppSettings> load() async {
    final rows = await db.select(db.settings).get();
    return AppSettings.fromMap({for (final r in rows) r.key: r.value});
  }

  Future<void> save(AppSettings s) async {
    await db.batch((b) {
      for (final e in s.toMap().entries) {
        b.insert(
          db.settings,
          SettingsCompanion.insert(key: e.key, value: e.value),
          mode: InsertMode.insertOrReplace,
        );
      }
    });
  }
}

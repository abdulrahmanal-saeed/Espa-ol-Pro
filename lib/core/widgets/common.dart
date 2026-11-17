import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/theme.dart';
import '../providers.dart';

/// Spanish text: always left-to-right, Latin typeface and `es` locale, no
/// matter how deep it sits inside the right-to-left Arabic interface.
class EsText extends StatelessWidget {
  const EsText(
    this.text, {
    super.key,
    this.style,
    this.size,
    this.weight,
    this.color,
    this.align,
  });

  final String text;
  final TextStyle? style;
  final double? size;
  final FontWeight? weight;
  final Color? color;
  final TextAlign? align;

  @override
  Widget build(BuildContext context) {
    final base = style ?? Theme.of(context).textTheme.bodyLarge!;
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Text(
        text,
        locale: const Locale('es'),
        textAlign: align,
        style: base.copyWith(
          fontFamily: spanishFont,
          fontFamilyFallback: const [arabicFont],
          fontSize: size,
          fontWeight: weight,
          color: color,
          height: 1.35,
        ),
      ),
    );
  }
}

/// Plays Spanish audio through the device TTS engine. When no Spanish voice
/// is installed it says so instead of failing silently.
class SpeakButton extends ConsumerWidget {
  const SpeakButton(
    this.spanish, {
    super.key,
    this.slow = false,
    this.filled = false,
    this.size = 24,
  });

  final String spanish;
  final bool slow;
  final bool filled;
  final double size;

  static Future<void> play(
    BuildContext context,
    WidgetRef ref,
    String spanish, {
    bool slow = false,
    bool announceFailure = true,
  }) async {
    final speech = ref.read(speechProvider);
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (!await speech.isAvailable()) {
      if (announceFailure && messenger != null) {
        messenger
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(
              content: Text(
                'لا يوجد صوت إسباني مثبّت على الجهاز. ثبّت بيانات اللغة الإسبانية من إعدادات «تحويل النص إلى كلام».',
              ),
            ),
          );
      }
      return;
    }
    await speech.speak(spanish, slow: slow);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final icon = Icon(
      slow ? Icons.slow_motion_video_rounded : Icons.volume_up_rounded,
      size: size,
    );
    final tooltip = slow ? 'استمع ببطء' : 'استمع';
    void onTap() => play(context, ref, spanish, slow: slow);
    return filled
        ? IconButton.filledTonal(
            onPressed: onTap,
            icon: icon,
            tooltip: tooltip,
            iconSize: size,
            padding: EdgeInsets.all(size * 0.55),
          )
        : IconButton(onPressed: onTap, icon: icon, tooltip: tooltip);
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key, this.trailing});
  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(4, 20, 4, 10),
    child: Row(
      children: [
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.titleMedium!
                .copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        ?trailing,
      ],
    ),
  );
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: t.colorScheme.outline),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: t.textTheme.titleMedium!.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: t.textTheme.bodyMedium!.copyWith(
                color: t.colorScheme.onSurfaceVariant,
                height: 1.6,
              ),
            ),
            if (action != null) ...[const SizedBox(height: 20), action!],
          ],
        ),
      ),
    );
  }
}

/// Uniform async handling: loading spinner, readable error, then data.
class AsyncView<T> extends StatelessWidget {
  const AsyncView({super.key, required this.value, required this.builder});
  final AsyncValue<T> value;
  final Widget Function(T data) builder;

  @override
  Widget build(BuildContext context) => value.when(
    data: builder,
    loading: () => const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: CircularProgressIndicator(),
      ),
    ),
    error: (e, _) => EmptyState(
      icon: Icons.error_outline_rounded,
      title: 'تعذّر تحميل البيانات',
      message: '$e',
    ),
  );
}

String formatMinutes(int seconds) {
  final m = (seconds / 60).round();
  if (seconds > 0 && m == 0) return 'أقل من دقيقة';
  return '$m د';
}

/// Human-readable Arabic interval until [due].
String formatInterval(DateTime now, DateTime due) {
  final d = due.difference(now);
  if (d.inMinutes < 1) return 'الآن';
  if (d.inMinutes < 60) return '${d.inMinutes} د';
  if (d.inHours < 24) return '${d.inHours} س';
  if (d.inDays < 30) return '${d.inDays} يوم';
  if (d.inDays < 365) return '${(d.inDays / 30).toStringAsFixed(1)} شهر';
  return '${(d.inDays / 365).toStringAsFixed(1)} سنة';
}

/// "a / b" that reads left to right inside Arabic text. Without the isolate
/// (U+2066 … U+2069) an RTL paragraph shows "8 / 10" as "10 / 8".
String fraction(int a, int b) => '\u2066$a / $b\u2069';

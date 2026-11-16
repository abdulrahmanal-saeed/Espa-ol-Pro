import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/backup/backup_service.dart';
import '../../core/providers.dart';
import '../../core/settings.dart';
import '../../core/widgets/common.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context);
    final s = ref.watch(settingsProvider);
    final pack = ref.watch(contentProvider);
    void update(AppSettings next) =>
        ref.read(settingsProvider.notifier).update(next);

    Widget group(String title, List<Widget> children) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionTitle(title),
        Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(children: children),
          ),
        ),
      ],
    );

    Widget padded(Widget child) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: child,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('الإعدادات')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
        children: [
          group('الدراسة اليومية', [
            padded(
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('مدة الجلسة اليومية'),
                  const SizedBox(height: 10),
                  SegmentedButton<int>(
                    segments: const [
                      ButtonSegment(value: 20, label: Text('20 د')),
                      ButtonSegment(value: 45, label: Text('45 د')),
                      ButtonSegment(value: 60, label: Text('60 د')),
                    ],
                    selected: {s.dailyMinutes},
                    onSelectionChanged: (v) =>
                        update(s.copyWith(dailyMinutes: v.first)),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'تُعاد صياغة خطة اليوم فوراً. تغيير المدة لا يمسّ تقدّمك ولا مواعيد المراجعة.',
                    style: t.textTheme.bodySmall!.copyWith(
                      color: t.colorScheme.onSurfaceVariant,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
            padded(
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'نسبة التذكّر المستهدفة: ${(s.desiredRetention * 100).round()}٪',
                  ),
                  Slider(
                    value: s.desiredRetention,
                    min: 0.8,
                    max: 0.95,
                    divisions: 15,
                    label: '${(s.desiredRetention * 100).round()}٪',
                    onChanged: (v) => update(
                      s.copyWith(
                        desiredRetention: double.parse(v.toStringAsFixed(2)),
                      ),
                    ),
                  ),
                  Text(
                    'نسبة أعلى = مراجعات أكثر ونسيان أقل. 90٪ توازن موصى به. يؤثر على المواعيد القادمة فقط.',
                    style: t.textTheme.bodySmall!.copyWith(
                      color: t.colorScheme.onSurfaceVariant,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
          ]),
          group('الصوت', [
            padded(
              DropdownButtonFormField<String>(
                initialValue: s.accent,
                decoration: const InputDecoration(labelText: 'لهجة النطق'),
                items: [
                  for (final e in AppSettings.accents.entries)
                    DropdownMenuItem(value: e.key, child: Text(e.value)),
                ],
                onChanged: (v) => update(s.copyWith(accent: v)),
              ),
            ),
            padded(
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('سرعة النطق'),
                  Slider(
                    value: s.speechRate,
                    min: 0.2,
                    max: 0.7,
                    divisions: 10,
                    onChanged: (v) => update(
                      s.copyWith(
                        speechRate: double.parse(v.toStringAsFixed(2)),
                      ),
                    ),
                  ),
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: OutlinedButton.icon(
                      onPressed: () => SpeakButton.play(
                        context,
                        ref,
                        'Hola, bienvenido a Español Pro.',
                      ),
                      icon: const Icon(Icons.volume_up_rounded),
                      label: const Text('جرّب الصوت'),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'يستعمل التطبيق محرّك النطق المثبّت على جهازك (يعمل دون اتصال). جودة الصوت وتوفّر اللهجة يعتمدان على الجهاز.',
                    style: t.textTheme.bodySmall!.copyWith(
                      color: t.colorScheme.onSurfaceVariant,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
            SwitchListTile(
              title: const Text('تشغيل الصوت تلقائياً'),
              subtitle: const Text('عند عرض عبارة جديدة أو سؤال استماع'),
              value: s.autoPlayAudio,
              onChanged: (v) => update(s.copyWith(autoPlayAudio: v)),
            ),
          ]),
          group('العرض', [
            padded(
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('المظهر'),
                  const SizedBox(height: 10),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'system', label: Text('تلقائي')),
                      ButtonSegment(value: 'light', label: Text('فاتح')),
                      ButtonSegment(value: 'dark', label: Text('داكن')),
                    ],
                    selected: {s.themeMode},
                    onSelectionChanged: (v) =>
                        update(s.copyWith(themeMode: v.first)),
                  ),
                ],
              ),
            ),
            padded(
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('حجم الخط: ${(s.textScale * 100).round()}٪'),
                  Slider(
                    value: s.textScale,
                    min: 0.85,
                    max: 1.4,
                    divisions: 11,
                    onChanged: (v) => update(
                      s.copyWith(textScale: double.parse(v.toStringAsFixed(2))),
                    ),
                  ),
                ],
              ),
            ),
            SwitchListTile(
              title: const Text('إظهار المقابل الإنجليزي'),
              subtitle: const Text('بجانب المعنى العربي في بطاقات المفردات'),
              value: s.showEnglish,
              onChanged: (v) => update(s.copyWith(showEnglish: v)),
            ),
          ]),
          group('بياناتك', [
            ListTile(
              leading: const Icon(Icons.upload_file_rounded),
              title: const Text('تصدير نسخة احتياطية'),
              subtitle: const Text('ملف JSON يضم كل تقدّمك ومراجعاتك'),
              onTap: () => _export(context, ref),
            ),
            ListTile(
              leading: const Icon(Icons.download_rounded),
              title: const Text('استعادة نسخة احتياطية'),
              subtitle: const Text('تستبدل كل البيانات الحالية'),
              onTap: () => _import(context, ref),
            ),
            ListTile(
              leading: Icon(
                Icons.delete_forever_rounded,
                color: t.colorScheme.error,
              ),
              title: Text(
                'حذف كل التقدّم',
                style: TextStyle(color: t.colorScheme.error),
              ),
              subtitle: const Text('يحذف الدروس المكتملة والمراجعات والأخطاء'),
              onTap: () => _reset(context, ref),
            ),
          ]),
          group('الخصوصية والذكاء الاصطناعي', [
            const ListTile(
              leading: Icon(Icons.lock_outline_rounded),
              title: Text('كل بياناتك على جهازك فقط'),
              subtitle: Text(
                'لا حساب، لا تتبّع، لا إعلانات. لا يُرسَل أي شيء إلى الإنترنت.',
              ),
            ),
            const ListTile(
              leading: Icon(Icons.smart_toy_outlined),
              title: Text('ميزات الذكاء الاصطناعي: غير مفعّلة'),
              subtitle: Text(
                'مخططة للمرحلة الثانية مع حدّ يومي وشهري للتكلفة. لا تكلفة حالياً.',
              ),
            ),
          ]),
          group('عن المحتوى', [
            ListTile(
              leading: const Icon(Icons.inventory_2_outlined),
              title: Text('إصدار المحتوى ${pack.version}'),
              subtitle: Text(
                '${pack.orderedLessons.length} درساً · ${pack.allItems.length} عبارة',
              ),
            ),
            for (final src in pack.sources)
              ListTile(
                leading: const Icon(Icons.fact_check_outlined),
                title: Text(src.title),
                subtitle: Text(
                  src.reviewStatus == 'native_reviewed'
                      ? 'راجعه مدرّس لغته الأم الإسبانية.'
                      : 'محتوى أصلي أُعدّ ودُقّق آلياً وتحريرياً، ولم يراجعه بعد مدرّس لغته الأم الإسبانية.',
                ),
              ),
          ]),
        ],
      ),
    );
  }

  Future<void> _export(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final now = ref.read(clockProvider)();
      final json = await ref
          .read(backupServiceProvider)
          .exportJson(
            now: now,
            contentVersion: ref.read(contentProvider).version,
          );
      final stamp = now
          .toLocal()
          .toIso8601String()
          .substring(0, 16)
          .replaceAll(':', '')
          .replaceAll('T', '-');
      final uri = await FilePicker.saveFile(
        fileName: 'espanol-pro-backup-$stamp.json',
        bytes: Uint8List.fromList(utf8.encode(json)),
        mimeType: 'application/json',
        dialogTitle: 'حفظ النسخة الاحتياطية',
      );
      if (uri != null) {
        messenger.showSnackBar(
          const SnackBar(content: Text('تم حفظ النسخة الاحتياطية.')),
        );
      }
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('تعذّر التصدير: $e')));
    }
  }

  Future<void> _import(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await _confirm(
      context,
      title: 'استعادة نسخة احتياطية؟',
      body: 'ستُستبدل كل بياناتك الحالية بمحتوى الملف. يُفضّل تصدير نسخة من الوضع الحالي أولاً.',
      action: 'اختر الملف',
    );
    if (!confirmed) return;
    try {
      final files = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['json'],
      );
      if (files.isEmpty) return;
      final json = utf8.decode(await files.first.readAsBytes());
      await ref.read(backupServiceProvider).restoreJson(json);
      final restored = await SettingsRepository(ref.read(databaseProvider))
          .load();
      await ref.read(settingsProvider.notifier).update(restored);
      messenger.showSnackBar(
        const SnackBar(content: Text('تمت استعادة بياناتك.')),
      );
    } on BackupException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('تعذّرت الاستعادة: $e')));
    }
  }

  Future<void> _reset(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await _confirm(
      context,
      title: 'حذف كل التقدّم؟',
      body: 'سيُحذف نهائياً: الدروس المكتملة، بطاقات المراجعة وسجلّها، وقت الدراسة، ودفتر الأخطاء. لا يمكن التراجع إلا من نسخة احتياطية.',
      action: 'احذف',
      destructive: true,
    );
    if (!confirmed) return;
    await ref.read(backupServiceProvider).resetProgress();
    messenger.showSnackBar(const SnackBar(content: Text('تم حذف التقدّم.')));
  }

  Future<bool> _confirm(
    BuildContext context, {
    required String title,
    required String body,
    required String action,
    bool destructive = false,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(body, style: const TextStyle(height: 1.7)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            key: const ValueKey('confirm-action'),
            onPressed: () => Navigator.pop(ctx, true),
            style: destructive
                ? TextButton.styleFrom(
                    foregroundColor: Theme.of(ctx).colorScheme.error,
                  )
                : null,
            child: Text(action),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}

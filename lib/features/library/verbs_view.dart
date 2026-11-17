import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/theme.dart';
import '../../core/content/models.dart';
import '../../core/learning/progress_repository.dart';
import '../../core/providers.dart';
import '../../core/widgets/common.dart';
import '../lesson/exercise_widgets.dart';

/// Present-tense conjugation reference for the verbs taught so far.
class VerbsView extends ConsumerWidget {
  const VerbsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context);
    final pack = ref.watch(contentProvider);
    final progress = ref.watch(lessonProgressProvider).value ?? const {};
    if (pack.verbs.isEmpty) {
      return const EmptyState(
        icon: Icons.table_chart_outlined,
        title: 'لا أفعال بعد',
        message: 'سيظهر هنا تصريف الأفعال التي تتعلّمها.',
      );
    }
    bool learned(Verb v) =>
        v.lessonIds.any((l) => ProgressRepository.isCompleted(progress[l]));
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        Text(
          'تصريف المضارع للأفعال التي تتعلّمها. vosotros يُستعمل في إسبانيا '
          'للجمع غير الرسمي؛ وفي أمريكا اللاتينية يُستعمل ustedes لكل الجمع.',
          style: t.textTheme.bodySmall!.copyWith(height: 1.7),
        ),
        const SizedBox(height: 8),
        for (final v in pack.verbs)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Card(
              clipBehavior: Clip.antiAlias,
              child: Theme(
                data: t.copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  key: ValueKey('verb-${v.id}'),
                  title: Row(
                    children: [
                      EsText(v.infinitive, size: 18, weight: FontWeight.w700),
                      const SizedBox(width: 10),
                      Expanded(child: Text(v.ar)),
                    ],
                  ),
                  subtitle: Text(
                    [
                      v.regular ? 'منتظم' : 'شاذّ',
                      if (learned(v)) 'درستَه',
                    ].join(' · '),
                    style: t.textTheme.bodySmall,
                  ),
                  childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final p in Verb.persons)
                      Directionality(
                        textDirection: TextDirection.ltr,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 170,
                                child: Text(
                                  Verb.personLabels[p]!,
                                  style: TextStyle(
                                    fontFamily: spanishFont,
                                    color: t.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: EsText(
                                  v.forms[p] ?? '',
                                  key: ValueKey('verb-form-${v.id}-$p'),
                                  size: 17,
                                  weight: FontWeight.w600,
                                ),
                              ),
                              SpeakButton(v.forms[p] ?? '', size: 20),
                            ],
                          ),
                        ),
                      ),
                    if (v.noteAr.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(v.noteAr, style: const TextStyle(height: 1.7)),
                    ],
                    const SizedBox(height: 8),
                    for (final e in v.examples) ExampleTile(e),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

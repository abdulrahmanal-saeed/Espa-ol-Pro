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
                      if (v.preterite.isNotEmpty &&
                          v.regular != v.preteriteRegular)
                        v.preteriteRegular
                            ? 'منتظم في الماضي'
                            : 'شاذّ في الماضي',
                      if (learned(v)) 'درستَه',
                    ].join(' · '),
                    style: t.textTheme.bodySmall,
                  ),
                  childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _TenseHeader('المضارع · presente'),
                    for (final p in Verb.persons)
                      _FormRow(
                        person: p,
                        form: v.forms[p] ?? '',
                        formKey: 'verb-form-${v.id}-$p',
                      ),
                    if (v.preterite.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      _TenseHeader(
                        'الماضي البسيط · pretérito indefinido',
                        key: ValueKey('verb-past-${v.id}'),
                      ),
                      for (final p in Verb.persons)
                        _FormRow(
                          person: p,
                          form: v.preterite[p] ?? '',
                          formKey: 'verb-past-${v.id}-$p',
                        ),
                    ],
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

class _TenseHeader extends StatelessWidget {
  const _TenseHeader(this.label, {super.key});
  final String label;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 4, bottom: 2),
    child: Text(
      label,
      style: Theme.of(context).textTheme.labelLarge!
          .copyWith(color: Theme.of(context).colorScheme.primary),
    ),
  );
}

/// One person and its form, always left-to-right.
class _FormRow extends StatelessWidget {
  const _FormRow({
    required this.person,
    required this.form,
    required this.formKey,
  });
  final String person;
  final String form;
  final String formKey;

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: TextDirection.ltr,
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 170,
            child: Text(
              Verb.personLabels[person]!,
              style: TextStyle(
                fontFamily: spanishFont,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: EsText(
              form,
              key: ValueKey(formKey),
              size: 17,
              weight: FontWeight.w600,
            ),
          ),
          SpeakButton(form, size: 20),
        ],
      ),
    ),
  );
}

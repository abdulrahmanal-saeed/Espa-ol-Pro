import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/theme.dart';
import '../../core/assessment/assessment_engine.dart';
import '../../core/providers.dart';
import 'assessment_screens.dart';

/// "What I can do", with the evidence behind every state. Only checkpoint
/// answers count (rule documented on [CanDoEvidence]); lessons never do.
class CanDoSection extends ConsumerWidget {
  const CanDoSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context);
    final pack = ref.watch(contentProvider);
    final records = ref.watch(assessmentRecordsProvider).value ?? const [];
    final colors = AppColors.of(context);
    Color colorOf(CanDoState s) => switch (s) {
      CanDoState.notAssessed => t.colorScheme.outline,
      CanDoState.needsPractice => colors.warning,
      CanDoState.demonstrated => t.colorScheme.primary,
      CanDoState.consistent => colors.success,
    };
    if (pack.assessments.isEmpty) return const SizedBox.shrink();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'تتغيّر هذه الحالات بنتائج نقاط التحقق فقط، لا بفتح الدروس أو '
              'إكمالها. «ظهر» = أجبت عن 75٪ على الأقل من أسئلتها صحيحاً في آخر '
              'محاولة؛ «ثابت» = حدث ذلك في آخر محاولتين في يومين مختلفين.',
              style: t.textTheme.bodySmall!.copyWith(height: 1.7),
            ),
            for (final a in pack.assessments) ...[
              const SizedBox(height: 12),
              InkWell(
                onTap: () => context.push('/assessment/${a.id}'),
                child: Text(
                  a.titleAr,
                  style: t.textTheme.titleSmall!.copyWith(
                    fontWeight: FontWeight.w700,
                    color: t.colorScheme.primary,
                  ),
                ),
              ),
              for (final c in a.canDos)
                Builder(
                  builder: (context) {
                    final mine = [
                      for (final r in records)
                        if (r.assessmentId == a.id) r,
                    ];
                    final state = CanDoEvidence.state(c.id, mine);
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.circle, size: 10, color: colorOf(state)),
                          const SizedBox(width: 8),
                          Expanded(child: Text(c.ar)),
                          const SizedBox(width: 8),
                          Text(
                            canDoLabels[state]!,
                            key: ValueKey('cando-${c.id}'),
                            style: t.textTheme.labelSmall!.copyWith(
                              color: colorOf(state),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
            ],
          ],
        ),
      ),
    );
  }
}

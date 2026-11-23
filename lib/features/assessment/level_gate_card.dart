import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/assessment/assessment_engine.dart';
import '../../core/content/models.dart';
import '../../core/providers.dart';

/// Percentage shown to the learner for the pass rule.
final passPercent = (CanDoEvidence.threshold * 100).round();

/// The levels that [assessmentId] opens when passed.
List<Level> levelsOpenedBy(ContentPack pack, String assessmentId) => [
  for (final l in pack.levels)
    if (l.requiresPass == assessmentId) l,
];

/// Why [level] is locked, in Arabic.
String levelGateMessageAr(Level level, Assessment test) =>
    'مستوى ${level.code} مقفل حتى تنجح في «${test.titleAr}». '
    'تنجح حين تجيب صحيحاً عن $passPercent٪ على الأقل من أسئلة كل قدرة '
    '«أستطيع» في الاختبار. محاولة ناجحة واحدة تفتحه نهائياً، ولا تقفله '
    'محاولة لاحقة غير ناجحة.';

/// A short line for snack bars and subtitles.
String levelGateShortAr(Level level, Assessment test) =>
    'يُفتح ${level.code} بعد النجاح في «${test.titleAr}»';

/// Explains a level gate and opens the assessment that lifts it.
class LevelGateCard extends ConsumerWidget {
  const LevelGateCard({super.key, required this.level});
  final Level level;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context);
    final pack = ref.watch(contentProvider);
    final testId = ref.watch(levelGatesProvider).requiredAssessment(level.id);
    final test = testId == null ? null : pack.assessment(testId);
    if (test == null) return const SizedBox.shrink();
    return Container(
      key: ValueKey('level-gate-${level.id}'),
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: t.colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.lock_outline_rounded,
                color: t.colorScheme.onSecondaryContainer,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  levelGateMessageAr(level, test),
                  style: TextStyle(
                    color: t.colorScheme.onSecondaryContainer,
                    height: 1.7,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: FilledButton.tonalIcon(
              key: ValueKey('level-gate-${level.id}-test'),
              onPressed: () => context.push('/assessment/${test.id}'),
              icon: const Icon(Icons.fact_check_outlined),
              label: Text('اذهب إلى «${test.titleAr}»'),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/theme.dart';
import '../../core/content/models.dart';
import '../../core/learning/difficulty.dart';
import '../../core/learning/progress_repository.dart';
import '../../core/providers.dart';

/// Everything the learner has been taught, from completed lessons.
final learnerExposureProvider = Provider<LearnerExposure>((ref) {
  final pack = ref.watch(contentProvider);
  final progress = ref.watch(lessonProgressProvider).value ?? const {};
  return LearnerExposure.from(pack, [
    for (final e in progress.entries)
      if (ProgressRepository.isCompleted(e.value)) e.key,
  ]);
});

/// "How hard is this for me now?" for a dialogue, with the reasons on
/// demand. The estimate is deterministic (see [DifficultyRules]).
class DifficultyBadge extends ConsumerWidget {
  const DifficultyBadge({
    super.key,
    required this.dialogue,
    this.showReasons = false,
  });

  final Dialogue dialogue;
  final bool showReasons;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context);
    final colors = AppColors.of(context);
    final e = estimateDialogue(dialogue, ref.watch(learnerExposureProvider));
    final color = switch (e.band) {
      DifficultyBand.veryEasy || DifficultyBand.appropriate => colors.success,
      DifficultyBand.challenging => colors.warning,
      DifficultyBand.tooDifficult => t.colorScheme.error,
    };
    final label = Container(
      key: ValueKey('difficulty-${dialogue.id}'),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        difficultyLabelsAr[e.band]!,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
    if (!showReasons) return label;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('الصعوبة الآن: ', style: t.textTheme.bodySmall),
            label,
          ],
        ),
        const SizedBox(height: 4),
        Text(
          e.reasonsAr.join(' · '),
          key: const ValueKey('difficulty-reasons'),
          style: t.textTheme.bodySmall!.copyWith(height: 1.6),
        ),
      ],
    );
  }
}

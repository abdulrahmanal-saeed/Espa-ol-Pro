import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/theme.dart';
import '../../core/content/models.dart';
import '../../core/db/database.dart';
import '../../core/learning/progress_repository.dart';
import '../../core/providers.dart';
import '../../core/widgets/common.dart';
import '../assessment/assessment_screens.dart';

class PathScreen extends ConsumerWidget {
  const PathScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pack = ref.watch(contentProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('مسار التعلّم')),
      body: AsyncView(
        value: ref.watch(lessonProgressProvider),
        builder: (progress) {
          final next = ProgressRepository.nextLesson(pack, progress);
          // With nothing left to do, open the furthest level with lessons:
          // that is where its level assessment waits.
          final focus =
              next?.levelId ??
              pack.levels
                  .lastWhere(
                    (l) => l.lessons.isNotEmpty,
                    orElse: () => pack.levels.first,
                  )
                  .id;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            children: [
              for (final level in pack.levels)
                _LevelSection(
                  level: level,
                  progress: progress,
                  nextLessonId: next?.id,
                  initiallyExpanded: level.id == focus,
                ),
            ],
          );
        },
      ),
    );
  }
}

class _LevelSection extends ConsumerWidget {
  const _LevelSection({
    required this.level,
    required this.progress,
    required this.nextLessonId,
    required this.initiallyExpanded,
  });

  final Level level;
  final Map<String, LessonProgressData> progress;
  final String? nextLessonId;
  final bool initiallyExpanded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context);
    final pack = ref.watch(contentProvider);
    final lessons = level.lessons.toList();
    final done = lessons
        .where((l) => ProgressRepository.isCompleted(progress[l.id]))
        .length;
    final hasContent = lessons.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Theme(
          data: t.copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            key: PageStorageKey('level-${level.id}'),
            initiallyExpanded: initiallyExpanded,
            tilePadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 6,
            ),
            childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            leading: Container(
              width: 56,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: hasContent
                    ? t.colorScheme.primary
                    : t.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                level.code,
                style: TextStyle(
                  fontFamily: spanishFont,
                  fontWeight: FontWeight.w700,
                  fontSize: level.code.length > 2 ? 12 : 15,
                  color: hasContent
                      ? t.colorScheme.onPrimary
                      : t.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            title: Text(
              level.titleAr,
              style: const TextStyle(fontWeight: FontWeight.w700, height: 1.4),
            ),
            subtitle: Text(
              hasContent
                  ? '$done من ${lessons.length} درساً متاحاً'
                  : 'خريطة المنهج جاهزة — الدروس قيد الإعداد',
            ),
            children: [
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  level.descriptionAr,
                  style: t.textTheme.bodyMedium!.copyWith(
                    color: t.colorScheme.onSurfaceVariant,
                    height: 1.7,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              for (final c in level.canDoAr)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.check_rounded,
                        size: 18,
                        color: t.colorScheme.tertiary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(c, style: const TextStyle(height: 1.5)),
                      ),
                    ],
                  ),
                ),
              for (final unit in level.units)
                _UnitBlock(
                  unit: unit,
                  progress: progress,
                  nextLessonId: nextLessonId,
                ),
              if (pack.levelAssessmentFor(level.id) != null)
                _CheckpointTile(
                  assessment: pack.levelAssessmentFor(level.id)!,
                  open: levelCompleted(pack, level.id, progress),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UnitBlock extends ConsumerWidget {
  const _UnitBlock({
    required this.unit,
    required this.progress,
    required this.nextLessonId,
  });
  final Unit unit;
  final Map<String, LessonProgressData> progress;
  final String? nextLessonId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context);
    final pack = ref.watch(contentProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: Text(
                unit.titleAr,
                style: t.textTheme.titleSmall!.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (!unit.isAvailable)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: t.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('قيد الإعداد', style: t.textTheme.labelSmall),
              ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          unit.descriptionAr,
          style: t.textTheme.bodySmall!.copyWith(
            color: t.colorScheme.onSurfaceVariant,
            height: 1.6,
          ),
        ),
        const SizedBox(height: 6),
        for (final lesson in unit.lessons)
          _LessonTile(
            lesson: lesson,
            data: progress[lesson.id],
            unlocked: ProgressRepository.isUnlocked(lesson, progress),
            isNext: lesson.id == nextLessonId,
            onLocked: () {
              final missing = lesson.prerequisites
                  .where((id) => !ProgressRepository.isCompleted(progress[id]))
                  .map((id) => pack.lesson(id)?.titleAr ?? id)
                  .join('، ');
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(SnackBar(content: Text('أكمل أولاً: $missing')));
            },
          ),
        if (pack.checkpointFor(unit.id) != null)
          _CheckpointTile(
            assessment: pack.checkpointFor(unit.id)!,
            open: unitCompleted(pack, unit.id, progress),
          ),
      ],
    );
  }
}

/// The unit checkpoint: opens once every lesson of the unit is completed.
class _CheckpointTile extends ConsumerWidget {
  const _CheckpointTile({required this.assessment, required this.open});
  final Assessment assessment;
  final bool open;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context);
    final attempts = [
      for (final x in ref.watch(assessmentAttemptsProvider).value ?? const [])
        if (x.assessmentId == assessment.id) x,
    ];
    final last = attempts.isEmpty ? null : attempts.first;
    final level = assessment.kind == 'level';
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Material(
        color: t.colorScheme.tertiaryContainer.withValues(
          alpha: open ? 0.6 : 0.25,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          key: ValueKey('checkpoint-${assessment.id}'),
          leading: Icon(
            open ? Icons.fact_check_outlined : Icons.lock_outline_rounded,
            color: open ? t.colorScheme.tertiary : t.colorScheme.outline,
          ),
          title: Text(
            level ? assessment.titleAr : 'نقطة تحقق الوحدة',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Text(
            !open
                ? (level
                      ? 'يُفتح بعد إكمال كل دروس المستوى'
                      : 'تُفتح بعد إكمال كل دروس الوحدة')
                : last == null
                ? '${assessment.questions.length} أسئلة بلا تلميحات'
                : 'آخر نتيجة: ${fraction(last.score, last.maxScore)} · المحاولات: ${attempts.length}',
          ),
          onTap: () => context.push('/assessment/${assessment.id}'),
        ),
      ),
    );
  }
}

class _LessonTile extends StatelessWidget {
  const _LessonTile({
    required this.lesson,
    required this.data,
    required this.unlocked,
    required this.isNext,
    required this.onLocked,
  });
  final Lesson lesson;
  final LessonProgressData? data;
  final bool unlocked;
  final bool isNext;
  final VoidCallback onLocked;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final done = ProgressRepository.isCompleted(data);
    final (icon, color) = done
        ? (Icons.check_circle_rounded, AppColors.of(context).success)
        : unlocked
        ? (Icons.play_circle_fill_rounded, t.colorScheme.primary)
        : (Icons.lock_outline_rounded, t.colorScheme.outline);
    return Semantics(
      label: done
          ? 'مكتمل'
          : unlocked
          ? 'متاح'
          : 'مقفل',
      child: Padding(
        padding: const EdgeInsets.only(top: 8),
        // Material (not a DecoratedBox) so the tile's ink is painted on it.
        child: Material(
          color: isNext
              ? t.colorScheme.primaryContainer.withValues(alpha: 0.5)
              : Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(
              color: isNext
                  ? t.colorScheme.primary
                  : t.colorScheme.outlineVariant,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: ListTile(
            key: ValueKey('lesson-${lesson.id}'),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            leading: Icon(icon, color: color, size: 28),
            title: Text(
              lesson.titleAr,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                height: 1.4,
                color: unlocked ? null : t.colorScheme.onSurfaceVariant,
              ),
            ),
            subtitle: Text(
              done
                  ? 'أفضل دقة: ${(data!.bestScore * 100).round()}٪ · ${lesson.minutes} د'
                  : '${lesson.items.length} عبارة · ${lesson.minutes} د',
            ),
            trailing: unlocked
                ? const Icon(Icons.arrow_forward_ios_rounded, size: 16)
                : null,
            onTap: unlocked
                ? () => context.push('/lesson/${lesson.id}')
                : onLocked,
          ),
        ),
      ),
    );
  }
}

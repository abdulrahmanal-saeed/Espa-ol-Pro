import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/theme.dart';
import '../../core/learning/daily_planner.dart';
import '../../core/learning/progress_repository.dart';
import '../../core/providers.dart';
import '../../core/widgets/common.dart';
import '../library/vocab_sheet.dart';

const _kindIcons = {
  'review': Icons.style_rounded,
  'lesson': Icons.menu_book_rounded,
  'errors': Icons.healing_rounded,
  'listening': Icons.headphones_rounded,
  'writing': Icons.edit_rounded,
  'pronunciation': Icons.record_voice_over_rounded,
};

const sessionNames = {20: 'جلسة سريعة', 45: 'جلسة قياسية', 60: 'جلسة مكثّفة'};

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context);
    final pack = ref.watch(contentProvider);
    final settings = ref.watch(settingsProvider);
    final clock = ref.watch(clockProvider);
    final progressAsync = ref.watch(lessonProgressProvider);
    final sessions = ref.watch(sessionsProvider).value ?? const [];
    final cards = ref.watch(cardsProvider).value ?? const [];
    final logs = ref.watch(reviewLogsProvider).value ?? const [];
    final errors = ref.watch(errorsProvider).value ?? const [];

    return Scaffold(
      appBar: AppBar(
        title: const Directionality(
          textDirection: TextDirection.ltr,
          child: Text(
            'Español Pro',
            style: TextStyle(
              fontFamily: spanishFont,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        actions: [
          IconButton(
            onPressed: () => context.push('/settings'),
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'الإعدادات',
          ),
        ],
      ),
      body: AsyncView(
        value: progressAsync,
        builder: (progress) {
          final now = clock();
          final today = dayKey(now.toLocal());
          final nowMs = now.toUtc().millisecondsSinceEpoch;
          final startOfDay = DateTime(
            now.toLocal().year,
            now.toLocal().month,
            now.toLocal().day,
          ).toUtc().millisecondsSinceEpoch;
          final next = ProgressRepository.nextLesson(pack, progress);
          final completed = pack.orderedLessons
              .where((l) => ProgressRepository.isCompleted(progress[l.id]))
              .toList();
          final learned = completed.expand((l) => l.items).toList();
          final todaySessions = sessions.where((s) => s.day == today).toList();
          final secondsToday = ProgressRepository.secondsOn(sessions, today);
          final due = cards.where((c) => c.due <= nowMs).length;
          final plan = buildDailyPlan(
            PlannerInput(
              dailyMinutes: settings.dailyMinutes,
              dueCards: due,
              reviewedToday: logs
                  .where((l) => l.reviewedAt >= startOfDay)
                  .length,
              nextLesson: next,
              // From completion timestamps, not from study-time rows.
              lessonsCompletedToday: progress.values
                  .where(
                    (p) =>
                        ProgressRepository.isCompleted(p) &&
                        (p.lastCompletedAt ?? 0) >= startOfDay,
                  )
                  .length,
              learnedItems: learned.length,
              openErrors: errors.where(ProgressRepository.isOpenError).length,
              practiceKindsToday: todaySessions.map((s) => s.kind).toSet(),
            ),
          );
          final currentLevel = pack.level(
            (next ??
                    (completed.isEmpty
                        ? pack.orderedLessons.first
                        : completed.last))
                .levelId,
          )!;
          final streak = ProgressRepository.streak(sessions, now.toLocal());
          final target = settings.dailyMinutes * 60;
          final recent = learned.reversed.take(8).toList();

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            children: [
              // ---- status card ------------------------------------------
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: t.colorScheme.primary,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: t.colorScheme.onPrimary.withValues(
                              alpha: 0.16,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            currentLevel.code,
                            style: TextStyle(
                              fontFamily: spanishFont,
                              color: t.colorScheme.onPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'مستواك الحالي: ${currentLevel.titleAr}',
                            style: TextStyle(
                              color: t.colorScheme.onPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (streak > 0)
                          Row(
                            children: [
                              Icon(
                                Icons.local_fire_department_rounded,
                                size: 18,
                                color: t.colorScheme.onPrimary,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                '$streak يوم',
                                style: TextStyle(
                                  color: t.colorScheme.onPrimary,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Text(
                      '${sessionNames[settings.dailyMinutes]} · ${settings.dailyMinutes} دقيقة',
                      style: TextStyle(
                        color: t.colorScheme.onPrimary.withValues(alpha: 0.85),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'درست اليوم ${formatMinutes(secondsToday)}',
                      style: t.textTheme.headlineSmall!.copyWith(
                        color: t.colorScheme.onPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: (secondsToday / target).clamp(0, 1).toDouble(),
                        minHeight: 8,
                        backgroundColor: t.colorScheme.onPrimary.withValues(
                          alpha: 0.2,
                        ),
                        color: t.colorScheme.onPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        key: const ValueKey('continue-learning'),
                        style: FilledButton.styleFrom(
                          backgroundColor: t.colorScheme.onPrimary,
                          foregroundColor: t.colorScheme.primary,
                        ),
                        onPressed: due > 0
                            ? () => context.push('/review')
                            : next != null
                            ? () => context.push('/lesson/${next.id}')
                            : () => context.go('/practice'),
                        icon: const Icon(Icons.play_arrow_rounded),
                        label: Text(
                          due > 0
                              ? 'ابدأ بمراجعة $due بطاقة'
                              : next != null
                              ? (completed.isEmpty
                                    ? 'ابدأ درسك الأول'
                                    : 'تابع التعلّم')
                              : 'تدرّب على ما تعلّمته',
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ---- today's plan -----------------------------------------
              const SectionTitle('خطة اليوم'),
              if (plan.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(18),
                    child: Text(
                      'أكملت كل الدروس المتاحة ولا مراجعات مستحقة الآن. عُد لاحقاً للمراجعة.',
                      style: TextStyle(height: 1.6),
                    ),
                  ),
                ),
              for (final item in plan)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Card(
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: item.route == null || item.done
                          ? null
                          : () => context.push(item.route!),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: item.done
                                  ? AppColors.of(context).successContainer
                                  : t.colorScheme.primaryContainer,
                              foregroundColor: item.done
                                  ? AppColors.of(context).onSuccessContainer
                                  : t.colorScheme.onPrimaryContainer,
                              child: Icon(
                                item.done
                                    ? Icons.check_rounded
                                    : _kindIcons[item.kind],
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.titleAr,
                                    style: t.textTheme.titleSmall!.copyWith(
                                      fontWeight: FontWeight.w700,
                                      height: 1.4,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    item.reasonAr,
                                    style: t.textTheme.bodySmall!.copyWith(
                                      color: t.colorScheme.onSurfaceVariant,
                                      height: 1.6,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (!item.done && item.minutes > 0)
                              Padding(
                                padding: const EdgeInsetsDirectional.only(
                                  start: 8,
                                ),
                                child: Text(
                                  '${item.minutes} د',
                                  style: t.textTheme.labelLarge!.copyWith(
                                    color: t.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

              // ---- snapshot ---------------------------------------------
              const SectionTitle('لمحة عن تقدّمك'),
              Row(
                children: [
                  _Stat(
                    value: '${completed.length}',
                    label: 'درس مكتمل',
                    icon: Icons.menu_book_rounded,
                  ),
                  const SizedBox(width: 10),
                  _Stat(
                    value: '${learned.length}',
                    label: 'عبارة متعلَّمة',
                    icon: Icons.translate_rounded,
                  ),
                  const SizedBox(width: 10),
                  _Stat(
                    value: '$due',
                    label: 'مراجعة مستحقة',
                    icon: Icons.style_rounded,
                  ),
                ],
              ),

              if (recent.isNotEmpty) ...[
                const SectionTitle('تعلّمت مؤخراً'),
                Directionality(
                  textDirection: TextDirection.ltr,
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.end,
                    children: [
                      for (final item in recent)
                        ActionChip(
                          label: Text(
                            item.es,
                            style: const TextStyle(fontFamily: spanishFont),
                          ),
                          onPressed: () => showVocabSheet(context, item),
                        ),
                    ],
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label, required this.icon});
  final String value;
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          child: Column(
            children: [
              Icon(icon, size: 20, color: t.colorScheme.primary),
              const SizedBox(height: 6),
              Text(
                value,
                style: t.textTheme.titleLarge!.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                label,
                textAlign: TextAlign.center,
                style: t.textTheme.bodySmall!.copyWith(
                  color: t.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

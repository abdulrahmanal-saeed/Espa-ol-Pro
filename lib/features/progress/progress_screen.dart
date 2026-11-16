import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/theme.dart';
import '../../core/content/models.dart';
import '../../core/learning/progress_repository.dart';
import '../../core/providers.dart';
import '../../core/widgets/common.dart';

const skillLabels = {
  'vocabulary': 'المفردات',
  'listening': 'الاستماع',
  'reading': 'القراءة',
  'writing': 'الكتابة',
  'speaking': 'التحدث',
  'grammar': 'القواعد',
};

class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context);
    final pack = ref.watch(contentProvider);
    final progress = ref.watch(lessonProgressProvider).value ?? const {};
    final sessions = ref.watch(sessionsProvider).value ?? const [];
    final cards = ref.watch(cardsProvider).value ?? const [];
    final logs = ref.watch(reviewLogsProvider).value ?? const [];
    final attempts = ref.watch(attemptsProvider).value ?? const [];
    final now = ref.watch(clockProvider)();
    final nowMs = now.toUtc().millisecondsSinceEpoch;

    final days = [
      for (var i = 13; i >= 0; i--)
        DateTime(
          now.toLocal().year,
          now.toLocal().month,
          now.toLocal().day - i,
        ),
    ];
    final perDay = [
      for (final d in days) ProgressRepository.secondsOn(sessions, dayKey(d)),
    ];
    final maxDay = perDay.fold<int>(60, (m, v) => v > m ? v : m);
    final activeDays = perDay.where((s) => s > 0).length;
    final totalSeconds = sessions.fold<int>(0, (s, e) => s + e.seconds);

    final mature = logs.where((l) => l.stateBefore == 2).toList();
    final recalled = mature.where((l) => l.rating > 1).length;
    // First attempts only: prompted retries are remediation, not evidence.
    final measured = attempts
        .where((a) => a.isMeasured && a.attemptNumber == 1)
        .toList();

    Widget kv(String k, String v) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(child: Text(k)),
          const SizedBox(width: 12),
          Text(v, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('التقدّم')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          // ---- CEFR honesty note ----------------------------------------
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: t.colorScheme.secondaryContainer,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  color: t.colorScheme.onSecondaryContainer,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'الأرقام هنا دلائل تدريب فعلية، وليست تقديراً لمستواك وفق CEFR. تقدير المستوى يتطلب اختبارات مهام حقيقية (مخطط لها)، وإكمال الدروس وحده لا يثبت المستوى.',
                    style: TextStyle(
                      color: t.colorScheme.onSecondaryContainer,
                      height: 1.7,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ---- curriculum -------------------------------------------------
          const SectionTitle('المنهج'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  for (final Level level in pack.levels)
                    if (level.lessons.isNotEmpty)
                      _LevelBar(
                        code: level.code,
                        done: level.lessons
                            .where(
                              (l) => ProgressRepository.isCompleted(
                                progress[l.id],
                              ),
                            )
                            .length,
                        total: level.lessons.length,
                      ),
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Text(
                      'تُحتسب الدروس المتاحة حالياً فقط. المستويات الأخرى قيد الإعداد.',
                      style: t.textTheme.bodySmall!.copyWith(
                        color: t.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ---- consistency -----------------------------------------------
          const SectionTitle('الانتظام — آخر 14 يوماً'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  SizedBox(
                    height: 96,
                    child: Directionality(
                      textDirection: TextDirection.ltr,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          for (var i = 0; i < days.length; i++)
                            Expanded(
                              child: Semantics(
                                label:
                                    '${dayKey(days[i])}: ${formatMinutes(perDay[i])}',
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 2,
                                  ),
                                  child: Container(
                                    height: perDay[i] == 0
                                        ? 4
                                        : 8 + 88 * perDay[i] / maxDay,
                                    decoration: BoxDecoration(
                                      color: perDay[i] == 0
                                          ? t
                                                .colorScheme
                                                .surfaceContainerHighest
                                          : (i == days.length - 1
                                                ? t.colorScheme.tertiary
                                                : t.colorScheme.primary),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  kv('أيام الدراسة (من 14)', '$activeDays'),
                  kv(
                    'سلسلة الأيام المتتالية',
                    '${ProgressRepository.streak(sessions, now.toLocal())}',
                  ),
                  kv('إجمالي وقت الدراسة', formatMinutes(totalSeconds)),
                ],
              ),
            ),
          ),

          // ---- FSRS ---------------------------------------------------------
          const SectionTitle('المراجعة المتباعدة (FSRS)'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: cards.isEmpty
                  ? Text(
                      'لا بطاقات بعد. تُنشأ البطاقات عند إكمال الدروس.',
                      style: TextStyle(color: t.colorScheme.onSurfaceVariant),
                    )
                  : Column(
                      children: [
                        kv('إجمالي البطاقات', '${cards.length}'),
                        kv(
                          'مستحقة الآن',
                          '${cards.where((c) => c.due <= nowMs).length}',
                        ),
                        kv(
                          'لم تُراجَع بعد',
                          '${cards.where((c) => c.reps == 0).length}',
                        ),
                        kv(
                          'قيد التعلّم',
                          '${cards.where((c) => c.reps > 0 && c.state != 2).length}',
                        ),
                        kv(
                          'في المراجعة طويلة المدى',
                          '${cards.where((c) => c.state == 2).length}',
                        ),
                        kv('إجمالي المراجعات', '${logs.length}'),
                        kv(
                          'نسبة التذكّر الفعلية',
                          mature.length < 10
                              ? 'بيانات غير كافية (${mature.length}/10)'
                              : '${(100 * recalled / mature.length).round()}٪ من ${mature.length}',
                        ),
                        Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: Text(
                            'تُحسب نسبة التذكّر من مراجعات البطاقات الناضجة فقط، ولا تُعرض قبل 10 مراجعات على الأقل.',
                            style: t.textTheme.bodySmall!.copyWith(
                              color: t.colorScheme.onSurfaceVariant,
                              height: 1.6,
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ),

          // ---- skills -------------------------------------------------------
          const SectionTitle('دلائل المهارات — المحاولة الأولى فقط'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: measured.isEmpty
                  ? Text(
                      'لا إجابات مسجّلة بعد.',
                      style: TextStyle(color: t.colorScheme.onSurfaceVariant),
                    )
                  : Column(
                      children: [
                        for (final s in skills)
                          if (s != 'speaking')
                            _SkillRow(
                              label: skillLabels[s]!,
                              attempts: measured
                                  .where((a) => a.skill == s)
                                  .length,
                              correct: measured
                                  .where((a) => a.skill == s && a.isCorrect)
                                  .length,
                            ),
                        kv(
                          'التحدث (ترديد ذاتي غير مقيَّم)',
                          '${attempts.where((a) => a.skill == 'speaking').length} مرة',
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LevelBar extends StatelessWidget {
  const _LevelBar({
    required this.code,
    required this.done,
    required this.total,
  });
  final String code;
  final int done;
  final int total;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Row(
      children: [
        SizedBox(
          width: 58,
          child: Text(
            code,
            style: const TextStyle(
              fontFamily: spanishFont,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(value: done / total, minHeight: 8),
          ),
        ),
        const SizedBox(width: 12),
        Text('$done / $total'),
      ],
    ),
  );
}

class _SkillRow extends StatelessWidget {
  const _SkillRow({
    required this.label,
    required this.attempts,
    required this.correct,
  });
  final String label;
  final int attempts;
  final int correct;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
              Text(
                attempts == 0
                    ? 'لا بيانات'
                    : '${(100 * correct / attempts).round()}٪ · $attempts إجابة',
                style: t.textTheme.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: attempts == 0 ? 0 : correct / attempts,
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }
}

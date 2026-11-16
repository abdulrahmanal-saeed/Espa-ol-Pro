import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/theme.dart';
import '../../core/content/models.dart';
import '../../core/learning/exercises.dart';
import '../../core/learning/progress_repository.dart';
import '../../core/providers.dart';
import '../../core/widgets/common.dart';
import 'exercise_runner.dart';

enum _Phase { intro, running, saving, done }

class LessonScreen extends ConsumerStatefulWidget {
  const LessonScreen({super.key, required this.lessonId});
  final String lessonId;

  @override
  ConsumerState<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends ConsumerState<LessonScreen> {
  _Phase _phase = _Phase.intro;
  List<LessonStep> _steps = const [];
  RunResult? _result;
  LessonOutcome? _outcome;
  String? _error;

  void _leave() => context.canPop() ? context.pop() : context.go('/home');

  Future<void> _start(Lesson lesson) async {
    await ref.read(progressRepositoryProvider).markStarted(lesson.id);
    setState(() {
      _steps = ref.read(exerciseBuilderProvider).buildLesson(lesson);
      _phase = _Phase.running;
    });
  }

  Future<void> _finish(Lesson lesson, RunResult result) async {
    setState(() {
      _phase = _Phase.saving;
      _result = result;
    });
    try {
      final outcome = await ref
          .read(progressRepositoryProvider)
          .completeLesson(
            lesson,
            score: result.score,
            seconds: result.seconds,
            contentVersion: ref.read(contentProvider).version,
          );
      if (!mounted) return;
      setState(() {
        _outcome = outcome;
        _phase = _Phase.done;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '$e';
        _phase = _Phase.done;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final pack = ref.watch(contentProvider);
    final lesson = pack.lesson(widget.lessonId);
    if (lesson == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const EmptyState(
          icon: Icons.search_off_rounded,
          title: 'الدرس غير موجود',
          message: 'قد يكون هذا الدرس من إصدار محتوى مختلف.',
        ),
      );
    }
    final progress = ref.watch(lessonProgressProvider).value ?? const {};
    final unlocked = ProgressRepository.isUnlocked(lesson, progress);

    return switch (_phase) {
      _Phase.intro => _Intro(
        lesson: lesson,
        unit: pack.unit(lesson.unitId)!,
        level: pack.level(lesson.levelId)!,
        unlocked: unlocked,
        completed: ProgressRepository.isCompleted(progress[lesson.id]),
        missingPrerequisites: [
          for (final id in lesson.prerequisites)
            if (!ProgressRepository.isCompleted(progress[id]))
              pack.lesson(id)?.titleAr ?? id,
        ],
        onStart: () => _start(lesson),
      ),
      _Phase.running => Scaffold(
        body: ExerciseRunner(
          steps: _steps,
          onExit: _leave,
          onAttempt: (ex, s, attemptNumber) => ref
              .read(progressRepositoryProvider)
              .recordAttempt(
                ex,
                isCorrect: s.correct,
                userAnswer: s.answer,
                context: 'lesson',
                lessonId: lesson.id,
                attemptNumber: attemptNumber,
              ),
          onFinished: (r) => _finish(lesson, r),
        ),
      ),
      _Phase.saving => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      _Phase.done => _Summary(
        lesson: lesson,
        result: _result!,
        outcome: _outcome,
        error: _error,
        onRetrySave: () => _finish(lesson, _result!),
        onDone: _leave,
      ),
    };
  }
}

class _Intro extends StatelessWidget {
  const _Intro({
    required this.lesson,
    required this.unit,
    required this.level,
    required this.unlocked,
    required this.completed,
    required this.missingPrerequisites,
    required this.onStart,
  });

  final Lesson lesson;
  final Unit unit;
  final Level level;
  final bool unlocked;
  final bool completed;
  final List<String> missingPrerequisites;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final graded = lesson.activities
        .where((a) => a.type != 'teach' && a.type != 'note')
        .length;
    return Scaffold(
      appBar: AppBar(title: Text('${level.code} · ${unit.titleAr}')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          Text(
            lesson.titleAr,
            style: t.textTheme.headlineSmall!.copyWith(
              fontWeight: FontWeight.w700,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 4),
          EsText(
            lesson.titleEs,
            size: 16,
            color: t.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Chip(
                avatar: const Icon(Icons.schedule_rounded, size: 18),
                label: Text('نحو ${lesson.minutes} دقيقة'),
              ),
              Chip(
                avatar: const Icon(Icons.translate_rounded, size: 18),
                label: Text('${lesson.items.length} عبارة جديدة'),
              ),
              Chip(
                avatar: const Icon(Icons.edit_note_rounded, size: 18),
                label: Text('$graded تمريناً'),
              ),
              if (completed)
                Chip(
                  avatar: Icon(
                    Icons.check_circle_rounded,
                    size: 18,
                    color: AppColors.of(context).success,
                  ),
                  label: const Text('مكتمل'),
                ),
            ],
          ),
          const SectionTitle('ستتمكن بعد هذا الدرس من'),
          for (final o in lesson.objectivesAr)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.flag_outlined,
                    size: 20,
                    color: t.colorScheme.primary,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      o,
                      style: t.textTheme.bodyLarge!.copyWith(height: 1.5),
                    ),
                  ),
                ],
              ),
            ),
          if (lesson.workRelevanceAr.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: t.colorScheme.tertiaryContainer,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.work_outline_rounded,
                    color: t.colorScheme.onTertiaryContainer,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      lesson.workRelevanceAr,
                      style: TextStyle(
                        color: t.colorScheme.onTertiaryContainer,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (!unlocked) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: t.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  const Icon(Icons.lock_outline_rounded),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'أكمل أولاً: ${missingPrerequisites.join('، ')}',
                      style: const TextStyle(height: 1.5),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: FilledButton(
            key: const ValueKey('start-lesson'),
            onPressed: unlocked ? onStart : null,
            child: Text(completed ? 'أعد الدرس' : 'ابدأ الدرس'),
          ),
        ),
      ),
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({
    required this.lesson,
    required this.result,
    required this.outcome,
    required this.error,
    required this.onRetrySave,
    required this.onDone,
  });

  final Lesson lesson;
  final RunResult result;
  final LessonOutcome? outcome;
  final String? error;
  final VoidCallback onRetrySave;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final colors = AppColors.of(context);
    if (error != null) {
      return Scaffold(
        body: EmptyState(
          icon: Icons.error_outline_rounded,
          title: 'تعذّر حفظ نتيجة الدرس',
          message: error!,
          action: FilledButton(
            onPressed: onRetrySave,
            child: const Text('أعد المحاولة'),
          ),
        ),
      );
    }
    final pct = (result.score * 100).round();
    final strong = result.score >= 0.8;
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 32, 20, 24),
          children: [
            Icon(
              strong ? Icons.emoji_events_rounded : Icons.task_alt_rounded,
              size: 64,
              color: strong ? t.colorScheme.tertiary : t.colorScheme.primary,
            ),
            const SizedBox(height: 12),
            Text(
              'أكملت الدرس',
              textAlign: TextAlign.center,
              style: t.textTheme.headlineSmall!.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              lesson.titleAr,
              textAlign: TextAlign.center,
              style: t.textTheme.bodyLarge!.copyWith(
                color: t.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  children: [
                    _row(
                      context,
                      'الدقة من المحاولة الأولى',
                      '$pct٪  (${result.firstTryCorrect} من ${result.measured})',
                    ),
                    const Divider(height: 24),
                    _row(context, 'الوقت', formatMinutes(result.seconds)),
                    const Divider(height: 24),
                    _row(
                      context,
                      'بطاقات مراجعة جديدة',
                      '${outcome?.newCards ?? 0}',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              (outcome?.newCards ?? 0) > 0
                  ? 'أُضيفت عبارات هذا الدرس إلى جدول المراجعة المتباعدة (FSRS). بطاقات التعرّف متاحة الآن، وبطاقات الكتابة من الذاكرة تبدأ غداً.'
                  : 'عبارات هذا الدرس موجودة مسبقاً في جدول مراجعتك، ولم يتغيّر موعدها.',
              style: t.textTheme.bodyMedium!.copyWith(
                color: t.colorScheme.onSurfaceVariant,
                height: 1.7,
              ),
            ),
            if (!strong) ...[
              const SizedBox(height: 12),
              Text(
                'الدقة أقل من 80٪. يُستحسن إعادة الدرس لاحقاً قبل الاعتماد على هذه العبارات.',
                style: t.textTheme.bodyMedium!.copyWith(
                  color: colors.warning,
                  height: 1.7,
                ),
              ),
            ],
            if (result.missed.isNotEmpty) ...[
              const SectionTitle('راجع ما أخطأت فيه'),
              for (final ex in result.missed)
                Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(16, 8, 4, 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: ex.expected.contains(RegExp(r'[؀-ۿ]'))
                              ? Text(ex.expected)
                              : EsText(ex.expected, weight: FontWeight.w600),
                        ),
                        if (!ex.expected.contains(RegExp(r'[؀-ۿ]')))
                          SpeakButton(ex.expected),
                      ],
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: FilledButton(
            key: const ValueKey('finish-lesson'),
            onPressed: onDone,
            child: const Text('تم'),
          ),
        ),
      ),
    );
  }

  Widget _row(BuildContext context, String label, String value) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(label),
      Text(
        value,
        style: Theme.of(context).textTheme.titleMedium!
            .copyWith(fontWeight: FontWeight.w700),
      ),
    ],
  );
}

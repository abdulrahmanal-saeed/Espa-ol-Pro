import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/content/models.dart';
import '../../core/learning/exercises.dart';
import '../../core/learning/progress_repository.dart';
import '../../core/providers.dart';
import '../../core/widgets/common.dart';
import '../lesson/exercise_runner.dart';

/// Items of every completed lesson, in curriculum order.
List<VocabItem> learnedItems(WidgetRef ref) {
  final pack = ref.watch(contentProvider);
  final progress = ref.watch(lessonProgressProvider).value ?? const {};
  return [
    for (final l in pack.orderedLessons)
      if (ProgressRepository.isCompleted(progress[l.id])) ...l.items,
  ];
}

class PracticeMode {
  const PracticeMode(this.id, this.title, this.subtitle, this.icon);
  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
}

const practiceModes = [
  PracticeMode(
    'listening',
    'الاستماع',
    'استمع واختر المعنى، أو اكتب ما تسمعه',
    Icons.headphones_rounded,
  ),
  PracticeMode(
    'writing',
    'الكتابة من الذاكرة',
    'ترجم من العربية إلى الإسبانية دون اختيارات',
    Icons.edit_rounded,
  ),
  PracticeMode(
    'pronunciation',
    'النطق والترديد',
    'استمع للنموذج وكرّر بصوت مسموع (تدريب ذاتي)',
    Icons.record_voice_over_rounded,
  ),
  PracticeMode(
    'errors',
    'تدريب على أخطائك',
    'أسئلة مبنية على دفتر أخطائك الشخصي',
    Icons.healing_rounded,
  ),
];

class PracticeScreen extends ConsumerWidget {
  const PracticeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context);
    final cards = ref.watch(cardsProvider).value ?? const [];
    final now = ref.watch(clockProvider)().toUtc().millisecondsSinceEpoch;
    final due = cards.where((c) => c.due <= now).length;
    final learned = learnedItems(ref).length;
    final openErrors = (ref.watch(errorsProvider).value ?? const [])
        .where(ProgressRepository.isOpenError)
        .length;

    Widget tile({
      required IconData icon,
      required String title,
      required String subtitle,
      required VoidCallback? onTap,
      String? badge,
      Key? key,
    }) => Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          key: key,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          leading: CircleAvatar(
            backgroundColor: t.colorScheme.primaryContainer,
            foregroundColor: t.colorScheme.onPrimaryContainer,
            child: Icon(icon),
          ),
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(subtitle),
          ),
          trailing: badge == null
              ? const Icon(Icons.arrow_forward_ios_rounded, size: 16)
              : Badge(label: Text(badge), child: const SizedBox(width: 8)),
          enabled: onTap != null,
          onTap: onTap,
        ),
      ),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('مركز التدريب')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          tile(
            key: const ValueKey('practice-review'),
            icon: Icons.style_rounded,
            title: 'مراجعة المفردات (FSRS)',
            subtitle: due == 0
                ? 'لا بطاقات مستحقة الآن'
                : '$due بطاقة مستحقة للمراجعة',
            badge: due == 0 ? null : '$due',
            onTap: () => context.push('/review'),
          ),
          if (learned == 0)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              child: Text(
                'تمارين التدريب أدناه تُبنى من العبارات التي تعلّمتها. أكمل درسك الأول لتفعيلها.',
                style: t.textTheme.bodyMedium!.copyWith(
                  color: t.colorScheme.onSurfaceVariant,
                  height: 1.6,
                ),
              ),
            ),
          for (final m in practiceModes)
            tile(
              key: ValueKey('practice-${m.id}'),
              icon: m.icon,
              title: m.title,
              subtitle: m.id == 'errors'
                  ? (openErrors == 0
                        ? 'لا أخطاء مفتوحة في دفترك'
                        : '$openErrors خطأ بحاجة إلى تثبيت')
                  : m.subtitle,
              onTap: learned == 0 || (m.id == 'errors' && openErrors == 0)
                  ? null
                  : () => context.push('/practice/${m.id}'),
            ),
          const SectionTitle('المعلّم الذكي'),
          tile(
            icon: Icons.smart_toy_outlined,
            title: 'المعلّم الذكي (AI Tutor)',
            subtitle: 'غير مفعّل بعد — مخطط للمرحلة الثانية',
            onTap: () => context.push('/tutor'),
          ),
        ],
      ),
    );
  }
}

/// One practice run over learned material.
class PracticeRunScreen extends ConsumerStatefulWidget {
  const PracticeRunScreen({super.key, required this.mode});
  final String mode;

  @override
  ConsumerState<PracticeRunScreen> createState() => _PracticeRunScreenState();
}

class _PracticeRunScreenState extends ConsumerState<PracticeRunScreen> {
  List<Exercise>? _exercises;
  RunResult? _result;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _prepare());
  }

  Future<void> _prepare() async {
    final pack = ref.read(contentProvider);
    final progress = await ref
        .read(progressRepositoryProvider)
        .lessonProgressMap();
    var items = [
      for (final l in pack.orderedLessons)
        if (ProgressRepository.isCompleted(progress[l.id])) ...l.items,
    ];
    if (widget.mode == 'errors') {
      final open = await ref.read(progressRepositoryProvider).openErrors();
      final ids = open.map((e) => e.itemId).whereType<String>().toSet();
      items = items.where((i) => ids.contains(i.id)).toList();
    }
    final salt = ref.read(clockProvider)().toIso8601String();
    if (!mounted) return;
    setState(() {
      _exercises = ref
          .read(exerciseBuilderProvider)
          .buildPractice(mode: widget.mode, items: items, salt: salt);
    });
  }

  void _leave() => context.canPop() ? context.pop() : context.go('/practice');

  @override
  Widget build(BuildContext context) {
    final mode = practiceModes.firstWhere(
      (m) => m.id == widget.mode,
      orElse: () => practiceModes.first,
    );
    final exercises = _exercises;
    if (exercises == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (exercises.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(mode.title)),
        body: EmptyState(
          icon: mode.icon,
          title: 'لا يوجد ما تتدرب عليه بعد',
          message: widget.mode == 'errors'
              ? 'الأخطاء المفتوحة في دفترك غير مرتبطة بمفردات محدّدة، أو صُحّحت كلها.'
              : 'أكمل درساً واحداً على الأقل لتفعيل هذا التدريب.',
        ),
      );
    }
    final result = _result;
    if (result != null) {
      final t = Theme.of(context);
      return Scaffold(
        appBar: AppBar(title: Text(mode.title)),
        body: EmptyState(
          icon: Icons.task_alt_rounded,
          title: 'انتهى التدريب',
          message: result.measured == 0
              ? 'أكملت ${exercises.length} عبارة ترديداً. هذا تدريب ذاتي لا يُحتسب كدقة.'
              : 'الدقة من المحاولة الأولى: ${(result.score * 100).round()}٪ '
                    '(${result.firstTryCorrect} من ${result.measured})\n'
                    'الوقت: ${formatMinutes(result.seconds)}',
          action: FilledButton(
            key: const ValueKey('practice-done'),
            onPressed: _leave,
            style: FilledButton.styleFrom(
              backgroundColor: t.colorScheme.primary,
            ),
            child: const Text('تم'),
          ),
        ),
      );
    }
    return Scaffold(
      body: ExerciseRunner(
        steps: exercises,
        onExit: _leave,
        onAttempt: (ex, s) => ref
            .read(progressRepositoryProvider)
            .recordAttempt(
              ex,
              isCorrect: s.correct,
              userAnswer: s.answer,
              context: 'practice',
            ),
        onFinished: (r) async {
          await ref
              .read(progressRepositoryProvider)
              .logStudy(kind: widget.mode, seconds: r.seconds);
          if (mounted) setState(() => _result = r);
        },
      ),
    );
  }
}

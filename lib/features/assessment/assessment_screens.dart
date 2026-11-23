import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/theme.dart';
import '../../core/assessment/assessment_engine.dart';
import '../../core/content/models.dart';
import '../../core/db/database.dart';
import '../../core/learning/progress_repository.dart';
import '../../core/providers.dart';
import '../../core/widgets/common.dart';
import 'level_gate_card.dart';

const skillNamesAr = {
  'vocabulary': 'المفردات',
  'reading': 'القراءة',
  'listening': 'الاستماع',
  'writing': 'الكتابة',
  'grammar': 'القواعد في سياق',
};

const canDoLabels = {
  CanDoState.notAssessed: 'لم يُقيَّم بعد',
  CanDoState.needsPractice: 'يحتاج تدريباً',
  CanDoState.demonstrated: 'ظهر في نقطة تحقق',
  CanDoState.consistent: 'ثابت (مرتان في يومين مختلفين)',
};

/// Whether every available lesson of [levelId] is completed.
bool levelCompleted(
  ContentPack pack,
  String levelId,
  Map<String, LessonProgressData> progress,
) {
  final lessons = pack.levels
      .where((l) => l.id == levelId)
      .expand((l) => l.lessons)
      .toList();
  if (lessons.isEmpty) return false;
  return lessons.every((l) => ProgressRepository.isCompleted(progress[l.id]));
}

/// Whether every lesson of [unitId] is completed.
bool unitCompleted(
  ContentPack pack,
  String unitId,
  Map<String, LessonProgressData> progress,
) {
  final unit = pack.unit(unitId);
  if (unit == null || unit.lessons.isEmpty) return false;
  return unit.lessons.every(
    (l) => ProgressRepository.isCompleted(progress[l.id]),
  );
}

// ---------------------------------------------------------------------------
// Taking an assessment
// ---------------------------------------------------------------------------

class AssessmentScreen extends ConsumerStatefulWidget {
  const AssessmentScreen({super.key, required this.assessmentId});
  final String assessmentId;

  @override
  ConsumerState<AssessmentScreen> createState() => _AssessmentScreenState();
}

class _AssessmentScreenState extends ConsumerState<AssessmentScreen> {
  bool _started = false;
  int _index = 0;
  final Map<String, String> _answers = {};

  /// Questions whose audio was actually played in this attempt.
  final Set<String> _heard = {};
  DateTime? _startedAt;
  bool _submitting = false;
  String? _submitError;

  void _leave() => context.canPop() ? context.pop() : context.go('/path');

  Future<void> _submit(Assessment a) async {
    setState(() {
      _submitting = true;
      _submitError = null;
    });
    try {
      final graded = gradeAssessment(a, _answers);
      final id = await ref
          .read(assessmentRepositoryProvider)
          .submit(
            assessment: a,
            graded: graded,
            startedAt: _startedAt!,
            contentVersion: ref.read(contentProvider).version,
          );
      if (!mounted) return;
      context.pushReplacement('/assessment/${a.id}/result/$id');
    } catch (e) {
      // Nothing was stored (one transaction). Answers stay in memory, so
      // the learner can retry without retaking anything.
      if (mounted) {
        setState(() {
          _submitting = false;
          _submitError = '$e';
        });
      }
    }
  }

  Future<void> _confirmExit() async {
    final leave = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('الخروج من نقطة التحقق؟'),
        content: const Text(
          'لن تُحفظ هذه المحاولة. يمكنك البدء من جديد لاحقاً.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('متابعة'),
          ),
          TextButton(
            key: const ValueKey('assessment-exit-confirm'),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('خروج'),
          ),
        ],
      ),
    );
    if (leave == true) _leave();
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final pack = ref.watch(contentProvider);
    final a = pack.assessment(widget.assessmentId);
    if (a == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const EmptyState(
          icon: Icons.search_off_rounded,
          title: 'نقطة التحقق غير موجودة',
          message: 'قد تكون من إصدار محتوى مختلف.',
        ),
      );
    }
    final progress = ref.watch(lessonProgressProvider).value ?? const {};
    // A unit checkpoint opens with its unit; a level assessment only once
    // every lesson of the level is completed.
    final open = a.unitId == null
        ? levelCompleted(pack, a.levelId, progress)
        : unitCompleted(pack, a.unitId!, progress);
    final needsAudio = a.questions.any((q) => q.audioEs != null);
    final voice = needsAudio ? ref.watch(spanishVoiceProvider).value : true;
    final canStart = open && voice == true;

    if (!_started) {
      return Scaffold(
        appBar: AppBar(title: Text(a.titleAr)),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            Text(a.introAr, style: const TextStyle(height: 1.8)),
            const SectionTitle('ما الذي تقيسه'),
            for (final c in a.canDos)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      size: 18,
                      color: t.colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: Text(c.ar)),
                  ],
                ),
              ),
            const SizedBox(height: 8),
            Text(
              '${a.questions.length} أسئلة · المهارات المقيسة: '
              '${{for (final q in a.questions) skillNamesAr[q.skill]}.join('، ')}.\n'
              'التحدث غير مُقاس هنا: لا توجد في التطبيق وسيلة موثوقة لتقييمه.',
              style: t.textTheme.bodySmall!.copyWith(height: 1.7),
            ),
            for (final opened in levelsOpenedBy(pack, a.id)) ...[
              const SizedBox(height: 12),
              Text(
                'النجاح في هذا الاختبار يفتح مستوى ${opened.code}: أجب صحيحاً '
                'عن $passPercent٪ على الأقل من أسئلة كل قدرة «أستطيع». '
                'المحاولة الناجحة تفتحه نهائياً.',
                key: ValueKey('assessment-opens-${opened.id}'),
                style: t.textTheme.bodyMedium!.copyWith(height: 1.7),
              ),
            ],
            if (!open) ...[
              const SizedBox(height: 16),
              Text(
                a.unitId == null
                    ? 'يُفتح اختبار المستوى بعد إكمال كل دروس المستوى.'
                    : 'تُفتح نقطة التحقق بعد إكمال كل دروس الوحدة.',
                key: const ValueKey('assessment-locked'),
                style: TextStyle(color: t.colorScheme.error),
              ),
            ],
            if (voice == false) ...[
              const SizedBox(height: 16),
              Text(
                'فيها أسئلة استماع، ولا يوجد صوت إسباني على الجهاز. لن تبدأ '
                'حتى لا تُحسب إجابة على جملة لم تسمعها. ثبّت بيانات اللغة '
                'الإسبانية من إعدادات «تحويل النص إلى كلام» ثم عُد.',
                key: const ValueKey('assessment-no-voice'),
                style: TextStyle(color: t.colorScheme.error, height: 1.6),
              ),
            ],
          ],
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: FilledButton(
              key: const ValueKey('assessment-start'),
              onPressed: canStart
                  ? () => setState(() {
                      _started = true;
                      _startedAt = ref.read(clockProvider)();
                    })
                  : null,
              child: const Text('ابدأ'),
            ),
          ),
        ),
      );
    }

    final q = a.questions[_index];
    final last = _index == a.questions.length - 1;
    final answer = _answers[q.id] ?? '';
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmExit();
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            tooltip: 'خروج',
            icon: const Icon(Icons.close_rounded),
            onPressed: _confirmExit,
          ),
          title: Text(fraction(_index + 1, a.questions.length)),
        ),
        body: _AssessmentQuestionView(
          key: ValueKey(q.id),
          question: q,
          choices: displayedChoices(q, attemptSeed(_startedAt!)),
          answer: answer,
          onChanged: (v) => setState(() => _answers[q.id] = v),
          heard: _heard.contains(q.id),
          onHeard: () => setState(() => _heard.add(q.id)),
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_submitError != null)
                  Container(
                    key: const ValueKey('assessment-submit-error'),
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: t.colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'لم تُحفظ النتيجة، فلم تُسجَّل المحاولة. إجاباتك ما زالت '
                      'هنا؛ أعد المحاولة.\n$_submitError',
                      style: TextStyle(color: t.colorScheme.onErrorContainer),
                    ),
                  ),
                Row(
                  children: [
                    if (_index > 0)
                      Expanded(
                        child: OutlinedButton(
                          key: const ValueKey('assessment-prev'),
                          onPressed: _submitting
                              ? null
                              : () => setState(() => _index--),
                          child: const Text('السابق'),
                        ),
                      ),
                    if (_index > 0) const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: FilledButton(
                        key: ValueKey(
                          last ? 'assessment-submit' : 'assessment-next',
                        ),
                        onPressed: _submitting || answer.trim().isEmpty
                            ? null
                            : last
                            ? () => _submit(a)
                            : () => setState(() => _index++),
                        child: Text(
                          _submitting
                              ? 'جارٍ الحفظ…'
                              : last
                              ? (_submitError == null
                                    ? 'سلّم الإجابات'
                                    : 'أعد محاولة الحفظ')
                              : 'التالي',
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Shows one question and reports the answer. Never reveals whether it is
/// right: there is no feedback until the results screen.
class _AssessmentQuestionView extends ConsumerStatefulWidget {
  const _AssessmentQuestionView({
    super.key,
    required this.question,
    required this.choices,
    required this.answer,
    required this.onChanged,
    required this.heard,
    required this.onHeard,
  });

  final AssessmentQuestion question;

  /// The options in this attempt's display order (see [displayedChoices]).
  final List<String> choices;
  final String answer;
  final ValueChanged<String> onChanged;

  /// Whether this question's audio has actually been played. A question
  /// with audio cannot be answered before, so a guess at an unheard
  /// sentence can never become listening evidence.
  final bool heard;
  final VoidCallback onHeard;

  @override
  ConsumerState<_AssessmentQuestionView> createState() =>
      _AssessmentQuestionViewState();
}

class _AssessmentQuestionViewState
    extends ConsumerState<_AssessmentQuestionView> {
  late final _controller = TextEditingController(text: widget.answer);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _insert(String ch) {
    final sel = _controller.selection;
    final text = _controller.text;
    final start = sel.isValid ? sel.start : text.length;
    final end = sel.isValid ? sel.end : text.length;
    _controller.value = TextEditingValue(
      text: text.replaceRange(start, end, ch),
      selection: TextSelection.collapsed(offset: start + ch.length),
    );
    widget.onChanged(_controller.text);
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final q = widget.question;
    final locked = q.audioEs != null && !widget.heard;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: [
        Text(
          q.type == 'dictation' ? 'استمع واكتب ما تسمعه' : q.promptAr,
          style: t.textTheme.titleMedium!.copyWith(
            fontWeight: FontWeight.w700,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 16),
        if (q.audioEs != null)
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SpeakButton(
                  q.audioEs!,
                  key: const ValueKey('assessment-play'),
                  filled: true,
                  size: 34,
                  onResult: (ok) {
                    if (ok) widget.onHeard();
                  },
                ),
                const SizedBox(width: 12),
                SpeakButton(
                  q.audioEs!,
                  slow: true,
                  filled: true,
                  size: 22,
                  onResult: (ok) {
                    if (ok) widget.onHeard();
                  },
                ),
              ],
            ),
          ),
        if (q.audioEs != null && !widget.heard)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Text(
              'استمع أولاً، ثم أجب.',
              key: const ValueKey('assessment-listen-first'),
              textAlign: TextAlign.center,
              style: t.textTheme.bodySmall,
            ),
          ),
        if (q.stimulusEs != null)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: EsText(q.stimulusEs!, size: 20, weight: FontWeight.w600),
            ),
          ),
        if (q.stimulusAr != null)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                q.stimulusAr!,
                style: t.textTheme.titleLarge!.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        const SizedBox(height: 16),
        if (q.type == 'choice')
          for (final (i, choice) in widget.choices.indexed)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _Choice(
                key: ValueKey('assessment-option-$i'),
                text: choice,
                spanish: q.choicesEs,
                selected: widget.answer == choice,
                onTap: locked ? null : () => widget.onChanged(choice),
              ),
            )
        else ...[
          Directionality(
            textDirection: TextDirection.ltr,
            child: TextField(
              key: const ValueKey('assessment-answer'),
              controller: _controller,
              enabled: !locked,
              autocorrect: false,
              enableSuggestions: false,
              onChanged: widget.onChanged,
              style: const TextStyle(fontFamily: spanishFont, fontSize: 20),
              decoration: const InputDecoration(hintText: 'Escribe aquí…'),
            ),
          ),
          const SizedBox(height: 10),
          Directionality(
            textDirection: TextDirection.ltr,
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final ch in const [
                  'á',
                  'é',
                  'í',
                  'ó',
                  'ú',
                  'ñ',
                  'ü',
                  '¿',
                  '¡',
                ])
                  SizedBox(
                    width: 44,
                    height: 44,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(44, 44),
                      ),
                      onPressed: locked ? null : () => _insert(ch),
                      child: Text(
                        ch,
                        style: const TextStyle(
                          fontFamily: spanishFont,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _Choice extends StatelessWidget {
  const _Choice({
    super.key,
    required this.text,
    required this.spanish,
    required this.selected,
    required this.onTap,
  });

  final String text;
  final bool spanish;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected
            ? c.primaryContainer
            : Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 56),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selected ? c.primary : c.outlineVariant,
                width: selected ? 2 : 1,
              ),
            ),
            alignment: AlignmentDirectional.centerStart,
            child: spanish
                ? SizedBox(
                    width: double.infinity,
                    child: EsText(text, size: 18, weight: FontWeight.w500),
                  )
                : Text(text, style: const TextStyle(fontSize: 17)),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Results
// ---------------------------------------------------------------------------

class AssessmentResultScreen extends ConsumerWidget {
  const AssessmentResultScreen({
    super.key,
    required this.assessmentId,
    required this.attemptId,
  });

  final String assessmentId;
  final int attemptId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context);
    final pack = ref.watch(contentProvider);
    final a = pack.assessment(assessmentId);
    final repo = ref.watch(assessmentRepositoryProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('نتيجة نقطة التحقق')),
      body: FutureBuilder(
        future: Future.wait([repo.attempt(attemptId), repo.answers(attemptId)]),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final attempt = snap.data![0] as AssessmentAttempt?;
          final answers = (snap.data![1] as List).cast<AssessmentAnswer>();
          if (a == null || attempt == null) {
            return const EmptyState(
              icon: Icons.search_off_rounded,
              title: 'النتيجة غير موجودة',
              message: 'ربما حُذفت مع إعادة ضبط التقدّم.',
            );
          }
          final records = [
            for (final x in answers)
              AnswerRecord(
                questionId: x.questionId,
                skill: x.skill,
                canDoId: x.canDoId,
                isCorrect: x.isCorrect,
              ),
          ];
          final run = AttemptRecord(
            id: attempt.id,
            assessmentId: attempt.assessmentId,
            assessmentVersion: attempt.assessmentVersion,
            completedAtMs: attempt.completedAt,
            localDay: '',
            answers: records,
          );
          final weak = [
            for (final c in a.canDos)
              if (!CanDoEvidence.met(c.id, run)) c,
          ];
          final date = DateTime.fromMillisecondsSinceEpoch(
            attempt.completedAt,
            isUtc: true,
          ).toLocal();
          final stale = attempt.assessmentVersion != a.version;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              Text(
                a.titleAr,
                style: t.textTheme.titleLarge!.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${dayKey(date)} · الإصدار ${attempt.assessmentVersion} · المحتوى ${attempt.contentVersion}',
                style: t.textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text(
                        fraction(attempt.score, attempt.maxScore),
                        key: const ValueKey('assessment-score'),
                        style: t.textTheme.displaySmall!.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Text('إجابات صحيحة'),
                      const Divider(height: 24),
                      for (final s in skillScores(records))
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Expanded(child: Text(skillNamesAr[s.skill]!)),
                              Text(fraction(s.correct, s.total)),
                            ],
                          ),
                        ),
                      const Padding(
                        padding: EdgeInsets.only(top: 6),
                        child: Text(
                          'التحدث: غير مُقاس.',
                          style: TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                margin: const EdgeInsets.only(top: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: t.colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'هذه نتيجة تدريبية داخل التطبيق، دليل على ما تستطيعه الآن. '
                  'ليست شهادة CEFR ولا امتحان DELE.',
                  key: const ValueKey('assessment-disclaimer'),
                  style: TextStyle(
                    color: t.colorScheme.onSecondaryContainer,
                    height: 1.6,
                  ),
                ),
              ),
              for (final opened in levelsOpenedBy(pack, a.id))
                _GateOutcome(
                  level: opened,
                  passedNow: CanDoEvidence.passed(run),
                  open: ref.watch(levelGatesProvider).isOpen(opened.id),
                ),
              if (stale)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'تغيّرت أسئلة نقطة التحقق بعد هذه المحاولة؛ تُعرض الإجابات كما سُجّلت.',
                    style: t.textTheme.bodySmall,
                  ),
                ),
              if (weak.isNotEmpty) ...[
                const SectionTitle('يحتاج تدريباً'),
                for (final c in weak)
                  Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            c.ar,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            children: [
                              for (final l in c.lessonIds)
                                if (pack.lesson(l) != null)
                                  ActionChip(
                                    key: ValueKey('revisit-$l'),
                                    avatar: const Icon(
                                      Icons.replay_rounded,
                                      size: 16,
                                    ),
                                    label: Text(pack.lesson(l)!.titleAr),
                                    onPressed: () => context.push('/lesson/$l'),
                                  ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
              const SectionTitle('الإجابات'),
              for (final x in answers)
                _AnswerRow(answer: x, question: a.question(x.questionId)),
            ],
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: FilledButton(
            key: const ValueKey('assessment-done'),
            onPressed: () =>
                context.canPop() ? context.pop() : context.go('/progress'),
            child: const Text('تم'),
          ),
        ),
      ),
    );
  }
}

/// What this attempt means for a level it gates (B1 after `lvl_a2`).
class _GateOutcome extends StatelessWidget {
  const _GateOutcome({
    required this.level,
    required this.passedNow,
    required this.open,
  });
  final Level level;
  final bool passedNow;

  /// Whether the level is open now (this attempt or an earlier pass).
  final bool open;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final (key, text, ok) = passedNow
        ? (
            'gate-opened-${level.id}',
            'نجحت في كل القدرات: فُتح مستوى ${level.code} (${level.titleAr}). '
                'يبقى مفتوحاً حتى لو أعدت الاختبار لاحقاً.',
            true,
          )
        : open
        ? (
            'gate-still-open-${level.id}',
            'لم تنجح في كل القدرات هذه المرة، لكن مستوى ${level.code} يبقى '
                'مفتوحاً لأنك نجحت في محاولة سابقة.',
            true,
          )
        : (
            'gate-still-locked-${level.id}',
            'مستوى ${level.code} ما زال مقفلاً: يلزم $passPercent٪ على الأقل '
                'في كل قدرة «أستطيع». راجع الدروس المقترحة أدناه ثم أعد '
                'الاختبار.',
            false,
          );
    final colors = AppColors.of(context);
    return Container(
      key: ValueKey(key),
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ok ? colors.successContainer : t.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            ok ? Icons.lock_open_rounded : Icons.lock_outline_rounded,
            color: ok
                ? colors.onSuccessContainer
                : t.colorScheme.onErrorContainer,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                height: 1.6,
                color: ok
                    ? colors.onSuccessContainer
                    : t.colorScheme.onErrorContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AnswerRow extends StatelessWidget {
  const _AnswerRow({required this.answer, required this.question});
  final AssessmentAnswer answer;
  final AssessmentQuestion? question;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final ok = AppColors.of(context).success;
    final arabic = RegExp(r'[؀-ۿ]');
    Widget text(String s, {Color? color, TextDecoration? deco}) {
      final style = TextStyle(color: color, decoration: deco);
      return arabic.hasMatch(s)
          ? Text(s, style: style)
          : EsText(s, style: t.textTheme.bodyLarge!.merge(style));
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  answer.isCorrect
                      ? Icons.check_circle_rounded
                      : Icons.cancel_rounded,
                  size: 20,
                  color: answer.isCorrect ? ok : t.colorScheme.error,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    question?.promptAr.isNotEmpty == true
                        ? question!.promptAr
                        : 'إملاء',
                    style: t.textTheme.bodySmall,
                  ),
                ),
                Text(
                  skillNamesAr[answer.skill] ?? '',
                  style: t.textTheme.labelSmall,
                ),
              ],
            ),
            const SizedBox(height: 6),
            if (!answer.isCorrect) ...[
              text(
                answer.userAnswer.isEmpty ? '—' : answer.userAnswer,
                color: t.colorScheme.error,
                deco: TextDecoration.lineThrough,
              ),
              const SizedBox(height: 2),
            ],
            text(answer.expected, color: ok),
            if (!answer.isCorrect && (question?.explainAr ?? '').isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  question!.explainAr,
                  key: ValueKey('explain-${answer.questionId}'),
                  style: t.textTheme.bodySmall!.copyWith(height: 1.6),
                ),
              ),
            if (Spelling.labelAr(answer.spelling).isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  answer.isCorrect
                      // A wrong answer is already shown above, struck out.
                      ? '${Spelling.labelAr(answer.spelling)}: ${answer.userAnswer}'
                      : Spelling.labelAr(answer.spelling),
                  key: ValueKey(
                    answer.spelling == Spelling.missingAccents
                        ? 'accent-note-${answer.questionId}'
                        : 'outcome-${answer.questionId}',
                  ),
                  style: TextStyle(
                    color: answer.isCorrect
                        ? AppColors.of(context).warning
                        : t.colorScheme.error,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

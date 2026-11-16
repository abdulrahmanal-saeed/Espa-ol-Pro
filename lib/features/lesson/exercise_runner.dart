import 'package:material_ui/material_ui.dart';

import '../../app/theme.dart';
import '../../core/learning/exercises.dart';
import '../../core/widgets/common.dart';
import 'exercise_widgets.dart';

class RunResult {
  const RunResult({
    required this.measured,
    required this.firstTryCorrect,
    required this.seconds,
    required this.missed,
  });

  /// Number of objectively graded exercises.
  final int measured;
  final int firstTryCorrect;
  final int seconds;

  /// Exercises answered wrong on the first try.
  final List<Exercise> missed;

  double get score => measured == 0 ? 1 : firstTryCorrect / measured;
}

/// Drives a sequence of teaching steps and exercises.
///
/// Mastery loop: an exercise answered wrong is shown once more at the end.
/// The score only counts FIRST attempts, so retries cannot inflate it.
class ExerciseRunner extends StatefulWidget {
  const ExerciseRunner({
    super.key,
    required this.steps,
    required this.onAttempt,
    required this.onFinished,
    required this.onExit,
  });

  final List<LessonStep> steps;
  final void Function(Exercise ex, Submission s) onAttempt;
  final void Function(RunResult result) onFinished;
  final VoidCallback onExit;

  @override
  State<ExerciseRunner> createState() => _ExerciseRunnerState();
}

class _ExerciseRunnerState extends State<ExerciseRunner> {
  late final List<LessonStep> _queue = [...widget.steps];
  final Map<String, bool> _firstTry = {};
  final Set<String> _retried = {};
  final Stopwatch _watch = Stopwatch()..start();
  int _index = 0;
  Submission? _feedback;

  LessonStep get _step => _queue[_index];

  void _next() {
    if (_index + 1 >= _queue.length) {
      _watch.stop();
      final exercises = widget.steps.whereType<Exercise>().toList();
      final measured = exercises.where((e) => e.isMeasured).toList();
      widget.onFinished(
        RunResult(
          measured: measured.length,
          firstTryCorrect: measured
              .where((e) => _firstTry[e.id] == true)
              .length,
          seconds: _watch.elapsed.inSeconds,
          missed: measured.where((e) => _firstTry[e.id] == false).toList(),
        ),
      );
      return;
    }
    setState(() {
      _index++;
      _feedback = null;
    });
  }

  void _submitted(Exercise ex, Submission s) {
    widget.onAttempt(ex, s);
    if (!ex.isMeasured) {
      _next();
      return;
    }
    _firstTry.putIfAbsent(ex.id, () => s.correct);
    if (!s.correct && _retried.add(ex.id)) _queue.add(ex);
    setState(() => _feedback = s);
  }

  Future<void> _confirmExit() async {
    final leave = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('الخروج الآن؟'),
        content: const Text(
          'إجاباتك حتى الآن محفوظة في سجلّ المحاولات، لكن هذه الجلسة لن تُحتسب مكتملة.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('متابعة التعلّم'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('خروج'),
          ),
        ],
      ),
    );
    if (leave == true) widget.onExit();
  }

  @override
  Widget build(BuildContext context) {
    final step = _step;
    // A retried exercise needs a fresh State, hence the index in the key.
    final key = ValueKey('${step.id}@$_index');
    final Widget view = switch (step) {
      TeachStep s => TeachView(s, key: key, onNext: _next),
      NoteStep s => NoteView(s, key: key, onNext: _next),
      ChoiceExercise e => ChoiceView(
        e,
        key: key,
        onSubmit: (s) => _submitted(e, s),
      ),
      TypeExercise e => TypeView(
        e,
        key: key,
        onSubmit: (s) => _submitted(e, s),
      ),
      OrderExercise e => OrderView(
        e,
        key: key,
        onSubmit: (s) => _submitted(e, s),
      ),
      MatchExercise e => MatchView(
        e,
        key: key,
        onSubmit: (s) => _submitted(e, s),
      ),
      SpeakExercise e => SpeakView(
        e,
        key: key,
        onSubmit: (s) => _submitted(e, s),
      ),
    };

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmExit();
      },
      child: Column(
        children: [
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(4, 4, 20, 4),
              child: Row(
                children: [
                  IconButton(
                    onPressed: _confirmExit,
                    icon: const Icon(Icons.close_rounded),
                    tooltip: 'خروج',
                  ),
                  Expanded(
                    child: Semantics(
                      label: 'التقدّم ${_index + 1} من ${_queue.length}',
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: _index / _queue.length,
                          minHeight: 8,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(child: view),
                if (_feedback != null && step is Exercise)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: _FeedbackPanel(
                      exercise: step,
                      submission: _feedback!,
                      onContinue: _next,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FeedbackPanel extends StatelessWidget {
  const _FeedbackPanel({
    required this.exercise,
    required this.submission,
    required this.onContinue,
  });
  final Exercise exercise;
  final Submission submission;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final colors = AppColors.of(context);
    final ok = submission.correct;
    final bg = ok ? colors.successContainer : t.colorScheme.errorContainer;
    final fg = ok ? colors.onSuccessContainer : t.colorScheme.onErrorContainer;
    // Arabic-option questions already show the right answer highlighted.
    final showsSpanishAnswer =
        !ok &&
        exercise is! MatchExercise &&
        !(exercise is ChoiceExercise &&
            !(exercise as ChoiceExercise).optionsAreSpanish);
    return Semantics(
      liveRegion: true,
      child: Material(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(
                      ok ? Icons.check_circle_rounded : Icons.cancel_rounded,
                      color: fg,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      ok ? 'إجابة صحيحة' : 'إجابة غير صحيحة',
                      style: t.textTheme.titleMedium!.copyWith(
                        color: fg,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                if (showsSpanishAnswer) ...[
                  const SizedBox(height: 10),
                  Text('الإجابة الصحيحة:', style: TextStyle(color: fg)),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Expanded(
                        child: EsText(
                          exercise.expected,
                          size: 19,
                          weight: FontWeight.w700,
                          color: fg,
                        ),
                      ),
                      IconTheme(
                        data: IconThemeData(color: fg),
                        child: SpeakButton(exercise.expected),
                      ),
                    ],
                  ),
                ],
                if (submission.noteAr.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    submission.noteAr,
                    style: TextStyle(color: fg, height: 1.6),
                  ),
                ],
                if (!ok) ...[
                  const SizedBox(height: 6),
                  Text(
                    'سيظهر هذا السؤال مرة أخرى في نهاية الجلسة.',
                    style: t.textTheme.bodySmall!.copyWith(color: fg),
                  ),
                ],
                const SizedBox(height: 14),
                FilledButton(
                  key: const ValueKey('continue-button'),
                  style: FilledButton.styleFrom(
                    backgroundColor: fg,
                    foregroundColor: bg,
                  ),
                  onPressed: onContinue,
                  child: const Text('متابعة'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/theme.dart';
import '../../core/content/models.dart';
import '../../core/learning/answer_evaluator.dart';
import '../../core/learning/exercises.dart';
import '../../core/providers.dart';
import '../../core/widgets/common.dart';

/// Outcome of one answered exercise.
class Submission {
  const Submission({
    required this.correct,
    required this.answer,
    this.noteAr = '',
  });
  final bool correct;
  final String answer;

  /// Extra feedback, e.g. an accent reminder.
  final String noteAr;
}

typedef OnSubmit = void Function(Submission s);

const connectionLabels = {
  'arabic_origin': 'أصل عربي',
  'cognate': 'شبيهة بالإنجليزية',
  'false_friend': 'تشابه خادع',
  'pronunciation': 'نطق',
  'grammar': 'مقارنة نحوية',
  'usage': 'استعمال',
};

const connectionIcons = {
  'arabic_origin': Icons.account_balance_rounded,
  'cognate': Icons.link_rounded,
  'false_friend': Icons.warning_amber_rounded,
  'pronunciation': Icons.record_voice_over_rounded,
  'grammar': Icons.compare_arrows_rounded,
  'usage': Icons.lightbulb_outline_rounded,
};

Widget _prompt(BuildContext context, String text) => Padding(
  padding: const EdgeInsets.only(bottom: 16),
  child: Text(
    text,
    style: Theme.of(context).textTheme.titleMedium!
        .copyWith(fontWeight: FontWeight.w700, height: 1.5),
  ),
);

class _AutoPlay extends ConsumerStatefulWidget {
  const _AutoPlay({required this.spanish, required this.child});
  final String? spanish;
  final Widget child;

  @override
  ConsumerState<_AutoPlay> createState() => _AutoPlayState();
}

class _AutoPlayState extends ConsumerState<_AutoPlay> {
  @override
  void initState() {
    super.initState();
    final text = widget.spanish;
    if (text == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (ref.read(settingsProvider).autoPlayAudio) {
        SpeakButton.play(context, ref, text, announceFailure: false);
      }
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class _AudioPanel extends StatelessWidget {
  const _AudioPanel(this.spanish);
  final String spanish;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 20),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SpeakButton(spanish, filled: true, size: 36),
        const SizedBox(width: 12),
        SpeakButton(spanish, slow: true, filled: true, size: 24),
      ],
    ),
  );
}

// ---------------------------------------------------------------------------
// Teaching steps
// ---------------------------------------------------------------------------

class VocabDetail extends ConsumerWidget {
  const VocabDetail(this.item, {super.key});
  final VocabItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context);
    final showEn = ref.watch(settingsProvider.select((s) => s.showEnglish));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Chip(
                      label: Text(item.pos),
                      visualDensity: VisualDensity.compact,
                    ),
                    if (item.work)
                      Chip(
                        avatar: const Icon(
                          Icons.work_outline_rounded,
                          size: 16,
                        ),
                        label: const Text('للعمل'),
                        visualDensity: VisualDensity.compact,
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                EsText(
                  item.es,
                  size: 32,
                  weight: FontWeight.w700,
                  align: TextAlign.center,
                  color: t.colorScheme.primary,
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SpeakButton(item.es, filled: true, size: 28),
                    const SizedBox(width: 12),
                    SpeakButton(item.es, slow: true, filled: true, size: 20),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  item.ar,
                  textAlign: TextAlign.center,
                  style: t.textTheme.titleLarge!.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (showEn && item.en.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  EsText(
                    item.en,
                    size: 14,
                    align: TextAlign.center,
                    color: t.colorScheme.onSurfaceVariant,
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        for (final e in item.examples) ExampleTile(e),
        if (item.noteAr.isNotEmpty)
          _InfoTile(
            icon: Icons.sticky_note_2_outlined,
            label: 'ملاحظة',
            text: item.noteAr,
          ),
        for (final c in item.connections)
          _InfoTile(
            icon: connectionIcons[c.type] ?? Icons.link_rounded,
            label: connectionLabels[c.type] ?? c.type,
            text: c.noteAr,
            highlight: true,
          ),
      ],
    );
  }
}

class ExampleTile extends StatelessWidget {
  const ExampleTile(this.example, {super.key});
  final Example example;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(16, 10, 6, 10),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  EsText(example.es, size: 17, weight: FontWeight.w500),
                  const SizedBox(height: 4),
                  Text(
                    example.ar,
                    style: t.textTheme.bodyMedium!.copyWith(
                      color: t.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            SpeakButton(example.es),
          ],
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.text,
    this.highlight = false,
  });
  final IconData icon;
  final String label;
  final String text;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: highlight ? c.tertiaryContainer : c.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 20,
            color: highlight ? c.onTertiaryContainer : c.onSurfaceVariant,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: highlight
                        ? c.onTertiaryContainer
                        : c.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  text,
                  style: TextStyle(
                    height: 1.6,
                    color: highlight ? c.onTertiaryContainer : c.onSurface,
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

class TeachView extends StatelessWidget {
  const TeachView(this.step, {super.key, required this.onNext});
  final TeachStep step;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) => _AutoPlay(
    spanish: step.item.es,
    child: _StepScaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'عبارة جديدة',
            style: Theme.of(context).textTheme.labelLarge!.copyWith(
              color: Theme.of(context).colorScheme.tertiary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          VocabDetail(step.item),
        ],
      ),
      action: FilledButton(onPressed: onNext, child: const Text('التالي')),
    ),
  );
}

class NoteView extends StatelessWidget {
  const NoteView(this.step, {super.key, required this.onNext});
  final NoteStep step;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return _StepScaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.school_outlined, color: t.colorScheme.tertiary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  step.titleAr,
                  style: t.textTheme.titleLarge!.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            step.bodyAr,
            style: t.textTheme.bodyLarge!.copyWith(height: 1.8),
          ),
          const SizedBox(height: 16),
          for (final e in step.examples) ExampleTile(e),
        ],
      ),
      action: FilledButton(onPressed: onNext, child: const Text('فهمت')),
    );
  }
}

class _StepScaffold extends StatelessWidget {
  const _StepScaffold({required this.body, required this.action});
  final Widget body;
  final Widget action;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Expanded(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: body,
        ),
      ),
      SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: SizedBox(width: double.infinity, child: action),
        ),
      ),
    ],
  );
}

// ---------------------------------------------------------------------------
// Exercises. Each calls [onSubmit] exactly once; the runner then locks it.
// ---------------------------------------------------------------------------

class ChoiceView extends StatefulWidget {
  const ChoiceView(
    this.ex, {
    super.key,
    required this.onSubmit,
    required this.showResult,
  });
  final ChoiceExercise ex;
  final OnSubmit onSubmit;
  final bool showResult;

  @override
  State<ChoiceView> createState() => _ChoiceViewState();
}

class _ChoiceViewState extends State<ChoiceView> {
  int? _selected;
  bool _submitted = false;

  @override
  Widget build(BuildContext context) {
    final ex = widget.ex;
    final t = Theme.of(context);
    final colors = AppColors.of(context);
    return _AutoPlay(
      spanish: ex.audioEs,
      child: _StepScaffold(
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _prompt(context, ex.promptAr),
            if (ex.audioEs != null) _AudioPanel(ex.audioEs!),
            if (ex.stimulusEs != null)
              Card(
                margin: const EdgeInsets.only(bottom: 20),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Row(
                    children: [
                      Expanded(
                        child: EsText(
                          ex.stimulusEs!,
                          size: ex.stimulusEs!.length > 40 ? 17 : 24,
                          weight: FontWeight.w600,
                        ),
                      ),
                      if (!ex.stimulusEs!.contains('___'))
                        SpeakButton(ex.stimulusEs!),
                    ],
                  ),
                ),
              ),
            for (var i = 0; i < ex.options.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _OptionTile(
                  key: ValueKey('option-$i'),
                  text: ex.options[i],
                  isSpanish: ex.optionsAreSpanish,
                  selected: _selected == i,
                  color: !widget.showResult
                      ? null
                      : i == ex.correctIndex
                      ? colors.success
                      : (_selected == i ? t.colorScheme.error : null),
                  onTap: _submitted
                      ? null
                      : () => setState(() => _selected = i),
                ),
              ),
          ],
        ),
        action: FilledButton(
          onPressed: _selected == null || _submitted
              ? null
              : () {
                  setState(() => _submitted = true);
                  widget.onSubmit(
                    Submission(
                      correct: _selected == ex.correctIndex,
                      answer: ex.options[_selected!],
                      noteAr: ex.explainAr,
                    ),
                  );
                },
          child: const Text('تحقّق'),
        ),
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    super.key,
    required this.text,
    required this.isSpanish,
    required this.selected,
    required this.onTap,
    this.color,
  });
  final String text;
  final bool isSpanish;
  final bool selected;
  final VoidCallback? onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    final border = color ?? (selected ? c.primary : c.outlineVariant);
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected && color == null
            ? c.primaryContainer.withValues(alpha: 0.55)
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
                color: border,
                width: selected || color != null ? 2 : 1,
              ),
            ),
            alignment: AlignmentDirectional.centerStart,
            child: isSpanish
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

class TypeView extends StatefulWidget {
  const TypeView(this.ex, {super.key, required this.onSubmit});
  final TypeExercise ex;
  final OnSubmit onSubmit;

  @override
  State<TypeView> createState() => _TypeViewState();
}

class _TypeViewState extends State<TypeView> {
  final _controller = TextEditingController();
  final _focus = FocusNode();
  bool _submitted = false;

  static const _special = ['á', 'é', 'í', 'ó', 'ú', 'ñ', 'ü', '¿', '¡'];

  @override
  void initState() {
    super.initState();
    _controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
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
    _focus.requestFocus();
  }

  void _submit() {
    if (_submitted || _controller.text.trim().isEmpty) return;
    final ex = widget.ex;
    final result = evaluateAnswer(_controller.text, ex.accepted);
    setState(() => _submitted = true);
    _focus.unfocus();
    widget.onSubmit(
      Submission(
        correct: result.isCorrect,
        answer: _controller.text.trim(),
        noteAr: result.verdict == AnswerVerdict.correctMissingAccents
            ? 'صحيح، لكن انتبه لعلامات النبر: ${result.bestMatch}'
            : '',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ex = widget.ex;
    final t = Theme.of(context);
    return _AutoPlay(
      spanish: ex.audioEs,
      child: _StepScaffold(
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _prompt(context, ex.promptAr),
            if (ex.audioEs != null) _AudioPanel(ex.audioEs!),
            if (ex.stimulusAr != null)
              Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Text(
                    ex.stimulusAr!,
                    style: t.textTheme.titleMedium!.copyWith(height: 1.6),
                  ),
                ),
              ),
            if (ex.templateEs != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: EsText(
                  ex.templateEs!,
                  size: 24,
                  weight: FontWeight.w600,
                ),
              ),
            Directionality(
              textDirection: TextDirection.ltr,
              child: TextField(
                key: const ValueKey('answer-field'),
                controller: _controller,
                focusNode: _focus,
                enabled: !_submitted,
                autocorrect: false,
                enableSuggestions: false,
                textCapitalization: TextCapitalization.none,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _submit(),
                style: const TextStyle(fontFamily: spanishFont, fontSize: 20),
                decoration: const InputDecoration(hintText: 'Escribe aquí…'),
              ),
            ),
            const SizedBox(height: 12),
            Directionality(
              textDirection: TextDirection.ltr,
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final ch in _special)
                    Semantics(
                      label: 'أدخل الحرف $ch',
                      button: true,
                      child: SizedBox(
                        width: 44,
                        height: 44,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: const Size(44, 44),
                          ),
                          onPressed: _submitted ? null : () => _insert(ch),
                          child: Text(
                            ch,
                            style: const TextStyle(
                              fontFamily: spanishFont,
                              fontSize: 18,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        action: FilledButton(
          onPressed: _submitted || _controller.text.trim().isEmpty
              ? null
              : _submit,
          child: const Text('تحقّق'),
        ),
      ),
    );
  }
}

class OrderView extends StatefulWidget {
  const OrderView(this.ex, {super.key, required this.onSubmit});
  final OrderExercise ex;
  final OnSubmit onSubmit;

  @override
  State<OrderView> createState() => _OrderViewState();
}

class _OrderViewState extends State<OrderView> {
  /// Indices into `ex.tokens`, in the order the learner picked them.
  final List<int> _picked = [];
  bool _submitted = false;

  @override
  Widget build(BuildContext context) {
    final ex = widget.ex;
    final c = Theme.of(context).colorScheme;
    Widget chip(int i, {required bool inAnswer}) => ActionChip(
      key: ValueKey('${inAnswer ? 'picked' : 'bank'}-$i'),
      label: Text(
        ex.tokens[i],
        style: const TextStyle(fontFamily: spanishFont, fontSize: 18),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      backgroundColor: inAnswer ? c.primaryContainer : null,
      onPressed: _submitted
          ? null
          : () => setState(() => inAnswer ? _picked.remove(i) : _picked.add(i)),
    );
    return _StepScaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _prompt(context, ex.promptAr),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                ex.targetAr,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            constraints: const BoxConstraints(minHeight: 76),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              border: Border.all(color: c.outlineVariant),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [for (final i in _picked) chip(i, inAnswer: true)],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Directionality(
            textDirection: TextDirection.ltr,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                for (var i = 0; i < ex.tokens.length; i++)
                  if (!_picked.contains(i)) chip(i, inAnswer: false),
              ],
            ),
          ),
        ],
      ),
      action: FilledButton(
        onPressed: _picked.isEmpty || _submitted
            ? null
            : () {
                final words = [for (final i in _picked) ex.tokens[i]];
                setState(() => _submitted = true);
                widget.onSubmit(
                  Submission(correct: ex.check(words), answer: words.join(' ')),
                );
              },
        child: const Text('تحقّق'),
      ),
    );
  }
}

class MatchView extends StatefulWidget {
  const MatchView(this.ex, {super.key, required this.onSubmit});
  final MatchExercise ex;
  final OnSubmit onSubmit;

  @override
  State<MatchView> createState() => _MatchViewState();
}

class _MatchViewState extends State<MatchView> {
  int? _es;
  int? _ar;
  final Set<int> _done = {};
  final List<String> _mistakes = [];
  int? _wrongEs;
  int? _wrongAr;

  void _tryPair() {
    final es = _es, ar = _ar;
    if (es == null || ar == null) return;
    if (es == ar) {
      setState(() {
        _done.add(es);
        _es = _ar = null;
      });
      if (_done.length == widget.ex.pairs.length) {
        widget.onSubmit(
          Submission(
            correct: _mistakes.isEmpty,
            answer: _mistakes.isEmpty ? 'all matched' : _mistakes.join('; '),
            noteAr: _mistakes.isEmpty
                ? ''
                : 'أكملت المطابقة بعد ${_mistakes.length} محاولة خاطئة.',
          ),
        );
      }
    } else {
      final p = widget.ex.pairs;
      _mistakes.add('${p[es].es} ≠ ${p[ar].ar}');
      setState(() {
        _wrongEs = es;
        _wrongAr = ar;
        _es = _ar = null;
      });
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted) setState(() => _wrongEs = _wrongAr = null);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final ex = widget.ex;
    final t = Theme.of(context);
    final ok = AppColors.of(context).success;
    Widget tile(int i, {required bool spanish}) {
      final done = _done.contains(i);
      final selected = (spanish ? _es : _ar) == i;
      final wrong = (spanish ? _wrongEs : _wrongAr) == i;
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Opacity(
          opacity: done ? 0.45 : 1,
          child: _OptionTile(
            key: ValueKey('${spanish ? 'es' : 'ar'}-${ex.pairs[i].itemId}'),
            text: spanish ? ex.pairs[i].es : ex.pairs[i].ar,
            isSpanish: spanish,
            selected: selected,
            color: done ? ok : (wrong ? t.colorScheme.error : null),
            onTap: done
                ? null
                : () {
                    setState(() => spanish ? _es = i : _ar = i);
                    _tryPair();
                  },
          ),
        ),
      );
    }

    return _StepScaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _prompt(context, ex.promptAr),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  children: [
                    for (final i in ex.shuffledAr) tile(i, spanish: false),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  children: [
                    for (var i = 0; i < ex.pairs.length; i++)
                      tile(i, spanish: true),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      action: Text(
        '${_done.length} / ${ex.pairs.length}',
        textAlign: TextAlign.center,
        style: t.textTheme.titleMedium,
      ),
    );
  }
}

class SpeakView extends StatelessWidget {
  const SpeakView(this.ex, {super.key, required this.onSubmit});
  final SpeakExercise ex;
  final OnSubmit onSubmit;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return _AutoPlay(
      spanish: ex.expected,
      child: _StepScaffold(
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _prompt(context, ex.promptAr),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(22),
                child: Column(
                  children: [
                    EsText(
                      ex.expected,
                      size: 26,
                      weight: FontWeight.w700,
                      align: TextAlign.center,
                      color: t.colorScheme.primary,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      ex.ar,
                      textAlign: TextAlign.center,
                      style: t.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 18),
                    _AudioPanel(ex.expected),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '١. استمع للنموذج.\n٢. كرّر الجملة بصوت مسموع ثلاث مرات.\n٣. استمع ببطء وقارن نطقك بالنموذج.',
              style: t.textTheme.bodyLarge!.copyWith(height: 1.8),
            ),
            const SizedBox(height: 12),
            Text(
              'هذا تدريب ذاتي: التطبيق لا يسجّل صوتك ولا يقيّم نطقك في هذه المرحلة، ولذلك لا يُحتسب في نتيجتك.',
              style: t.textTheme.bodySmall!.copyWith(
                color: t.colorScheme.onSurfaceVariant,
                height: 1.6,
              ),
            ),
          ],
        ),
        action: FilledButton.icon(
          onPressed: () => onSubmit(
            const Submission(correct: true, answer: 'self-practised'),
          ),
          icon: const Icon(Icons.check_rounded),
          label: const Text('كرّرتها بصوت مسموع'),
        ),
      ),
    );
  }
}

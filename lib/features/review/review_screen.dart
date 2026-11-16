import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fsrs/fsrs.dart' as fsrs;
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/theme.dart';
import '../../core/content/models.dart';
import '../../core/db/database.dart';
import '../../core/learning/answer_evaluator.dart';
import '../../core/learning/progress_repository.dart';
import '../../core/providers.dart';
import '../../core/srs/review_repository.dart';
import '../../core/widgets/common.dart';
import '../lesson/exercise_widgets.dart';

const _ratingLabels = {
  fsrs.Rating.again: 'نسيت',
  fsrs.Rating.hard: 'صعب',
  fsrs.Rating.good: 'جيد',
  fsrs.Rating.easy: 'سهل',
};

/// Spaced-repetition session over all due cards.
class ReviewScreen extends ConsumerStatefulWidget {
  const ReviewScreen({super.key});

  @override
  ConsumerState<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends ConsumerState<ReviewScreen> {
  final List<ReviewCard> _queue = [];
  final Stopwatch _session = Stopwatch();
  final Stopwatch _card = Stopwatch();
  final _controller = TextEditingController();
  bool _loading = true;
  String? _error;
  bool _revealed = false;
  AnswerResult? _typed;
  int _reviewed = 0;
  int _again = 0;
  bool _logged = false;
  bool _busy = false;

  // Captured up front: `ref` must not be used while the widget is disposing.
  late final ProgressRepository _progress = ref.read(
    progressRepositoryProvider,
  );

  @override
  void initState() {
    super.initState();
    _progress;
    _load();
  }

  @override
  void dispose() {
    _logSession();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final due = await ref.read(reviewRepositoryProvider).dueCards(limit: 60);
      final pack = ref.read(contentProvider);
      if (!mounted) return;
      setState(() {
        // Cards whose item no longer exists in the content pack are skipped,
        // never deleted: a later content version may bring the item back.
        _queue.addAll(due.where((c) => pack.item(c.itemId) != null));
        _loading = false;
      });
      _session.start();
      _card
        ..reset()
        ..start();
      _autoPlay();
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = '$e';
          _loading = false;
        });
      }
    }
  }

  void _logSession() {
    if (_logged || _reviewed == 0) return;
    _logged = true;
    _session.stop();
    _progress.logStudy(kind: 'review', seconds: _session.elapsed.inSeconds);
  }

  void _autoPlay() {
    if (_queue.isEmpty) return;
    final card = _queue.first;
    if (card.cardType != cardRecognition) return;
    if (!ref.read(settingsProvider).autoPlayAudio) return;
    final item = ref.read(contentProvider).item(card.itemId)!;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        SpeakButton.play(context, ref, item.es, announceFailure: false);
      }
    });
  }

  void _checkTyped(VocabItem item) {
    if (_controller.text.trim().isEmpty) return;
    final result = evaluateAnswer(_controller.text, item.acceptedAnswers);
    setState(() {
      _typed = result;
      _revealed = true;
    });
    FocusScope.of(context).unfocus();
    SpeakButton.play(context, ref, item.es, announceFailure: false);
  }

  Future<void> _rate(fsrs.Rating rating) async {
    if (_busy) return;
    _busy = true;
    final card = _queue.first;
    try {
      final repo = ref.read(reviewRepositoryProvider);
      final updated = await repo.rate(
        card.id,
        rating,
        durationMs: _card.elapsedMilliseconds,
      );
      if (!mounted) return;
      final now = ref.read(clockProvider)().toUtc();
      final dueSoon = DateTime.fromMillisecondsSinceEpoch(
        updated.due,
        isUtc: true,
      ).isBefore(now.add(const Duration(minutes: 10, seconds: 1)));
      setState(() {
        _queue.removeAt(0);
        // Short learning steps are finished inside the same session.
        if (dueSoon) _queue.add(updated);
        _reviewed++;
        if (rating == fsrs.Rating.again) _again++;
        _revealed = false;
        _typed = null;
        _controller.clear();
      });
      _card
        ..reset()
        ..start();
      if (_queue.isEmpty) {
        _logSession();
      } else {
        _autoPlay();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('تعذّر حفظ التقييم: $e')));
      }
    } finally {
      _busy = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    Widget body;
    if (_loading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (_error != null) {
      body = EmptyState(
        icon: Icons.error_outline_rounded,
        title: 'تعذّر تحميل المراجعات',
        message: _error!,
      );
    } else if (_queue.isEmpty) {
      body = _reviewed == 0
          ? EmptyState(
              icon: Icons.inbox_outlined,
              title: 'لا مراجعات مستحقة الآن',
              message: 'تظهر البطاقات هنا عندما يحين موعدها. أكمل درساً جديداً لإضافة عبارات إلى جدول المراجعة.',
              action: OutlinedButton(
                onPressed: () => context.go('/path'),
                child: const Text('اذهب إلى المسار'),
              ),
            )
          : EmptyState(
              icon: Icons.task_alt_rounded,
              title: 'انتهت مراجعة اليوم',
              message:
                  'راجعت $_reviewed بطاقة، منها $_again احتاجت إعادة.\nالبطاقات التالية ستظهر في موعدها.',
              action: FilledButton(
                key: const ValueKey('review-done'),
                onPressed: () =>
                    context.canPop() ? context.pop() : context.go('/home'),
                child: const Text('تم'),
              ),
            );
    } else {
      body = _cardView(context, _queue.first);
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('المراجعة'),
        actions: [
          if (_queue.isNotEmpty)
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 16),
              child: Center(
                child: Text(
                  'المتبقي: ${_queue.length}',
                  style: t.textTheme.labelLarge,
                ),
              ),
            ),
        ],
      ),
      body: body,
    );
  }

  Widget _cardView(BuildContext context, ReviewCard card) {
    final t = Theme.of(context);
    final item = ref.watch(contentProvider).item(card.itemId)!;
    final production = card.cardType == cardProduction;
    final repo = ref.watch(reviewRepositoryProvider);
    final now = ref.watch(clockProvider)().toUtc();
    final wrongTyped = _typed != null && !_typed!.isCorrect;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Chip(
                    avatar: Icon(
                      production
                          ? Icons.edit_outlined
                          : Icons.visibility_outlined,
                      size: 16,
                    ),
                    label: Text(
                      production
                          ? 'استدعاء نشط: اكتب بالإسبانية'
                          : 'تعرّف: ما المعنى؟',
                    ),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
                const SizedBox(height: 12),
                if (!production && !_revealed)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 44,
                        horizontal: 20,
                      ),
                      child: Column(
                        children: [
                          EsText(
                            item.es,
                            size: 32,
                            weight: FontWeight.w700,
                            align: TextAlign.center,
                            color: t.colorScheme.primary,
                          ),
                          const SizedBox(height: 16),
                          SpeakButton(item.es, filled: true, size: 28),
                        ],
                      ),
                    ),
                  ),
                if (production && !_revealed) ...[
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 36,
                        horizontal: 20,
                      ),
                      child: Text(
                        item.ar,
                        textAlign: TextAlign.center,
                        style: t.textTheme.headlineSmall!.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Directionality(
                    textDirection: TextDirection.ltr,
                    child: TextField(
                      key: const ValueKey('review-answer'),
                      controller: _controller,
                      autocorrect: false,
                      enableSuggestions: false,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _checkTyped(item),
                      style: const TextStyle(
                        fontFamily: spanishFont,
                        fontSize: 20,
                      ),
                      decoration: const InputDecoration(
                        hintText: 'Escribe aquí…',
                      ),
                    ),
                  ),
                ],
                if (_revealed) ...[
                  if (_typed != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: wrongTyped
                            ? t.colorScheme.errorContainer
                            : AppColors.of(context).successContainer,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        wrongTyped
                            ? 'كتبت: ${_controller.text.trim()}'
                            : _typed!.verdict ==
                                  AnswerVerdict.correctMissingAccents
                            ? 'صحيح — لكن انتبه لعلامات النبر.'
                            : 'صحيح.',
                        style: TextStyle(
                          color: wrongTyped
                              ? t.colorScheme.onErrorContainer
                              : AppColors.of(context).onSuccessContainer,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  VocabDetail(item),
                ],
              ],
            ),
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: !_revealed
                ? SizedBox(
                    width: double.infinity,
                    child: production
                        ? FilledButton(
                            key: const ValueKey('review-check'),
                            onPressed: () => _checkTyped(item),
                            child: const Text('تحقّق'),
                          )
                        : FilledButton(
                            key: const ValueKey('review-reveal'),
                            onPressed: () => setState(() => _revealed = true),
                            child: const Text('أظهر الإجابة'),
                          ),
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          wrongTyped
                              ? 'الإجابة خاطئة، لذلك تُسجَّل «نسيت» وتعود البطاقة قريباً.'
                              : 'قيّم بصدق مدى سهولة التذكّر — هذا ما يضبط موعد المراجعة القادمة.',
                          textAlign: TextAlign.center,
                          style: t.textTheme.bodySmall!.copyWith(
                            color: t.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          for (final p in repo.preview(card))
                            // A wrong typed answer is objectively a lapse.
                            if (!wrongTyped || p.rating == fsrs.Rating.again)
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                  ),
                                  child: _RatingButton(
                                    key: ValueKey('rate-${p.rating.name}'),
                                    label: _ratingLabels[p.rating]!,
                                    interval: formatInterval(now, p.due),
                                    rating: p.rating,
                                    onTap: () => _rate(p.rating),
                                  ),
                                ),
                              ),
                        ],
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}

class _RatingButton extends StatelessWidget {
  const _RatingButton({
    super.key,
    required this.label,
    required this.interval,
    required this.rating,
    required this.onTap,
  });
  final String label;
  final String interval;
  final fsrs.Rating rating;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    final colors = AppColors.of(context);
    final color = switch (rating) {
      fsrs.Rating.again => c.error,
      fsrs.Rating.hard => colors.warning,
      fsrs.Rating.good => colors.success,
      fsrs.Rating.easy => c.primary,
    };
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: color),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
        minimumSize: const Size(0, 60),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label),
          const SizedBox(height: 2),
          Text(
            interval,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w400),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/theme.dart';
import '../../core/content/models.dart';
import '../../core/learning/exercises.dart';
import '../../core/learning/progress_repository.dart';
import '../../core/phrases/saved_phrases_repository.dart';
import '../../core/providers.dart';
import '../../core/widgets/common.dart';
import '../lesson/exercise_runner.dart';
import '../lesson/exercise_widgets.dart';
import '../library/vocab_sheet.dart';
import '../phrases/save_phrase_button.dart';
import 'dialogue_player.dart';
import 'listening_progress.dart';

// ---------------------------------------------------------------------------
// Library
// ---------------------------------------------------------------------------

class ListeningLibraryScreen extends ConsumerWidget {
  const ListeningLibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context);
    final pack = ref.watch(contentProvider);
    final attempts = ref.watch(attemptsProvider).value ?? const [];
    return Scaffold(
      appBar: AppBar(title: const Text('مكتبة الاستماع')),
      body: AsyncView(
        value: ref.watch(lessonProgressProvider),
        builder: (lessons) {
          if (pack.dialogues.isEmpty) {
            return const EmptyState(
              icon: Icons.headphones_rounded,
              title: 'لا حوارات بعد',
              message: 'ستظهر هنا حوارات الاستماع المتدرّجة.',
            );
          }
          final byLevel = <String, List<Dialogue>>{};
          for (final d in pack.dialogues) {
            byLevel.putIfAbsent(d.levelId, () => []).add(d);
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            children: [
              Text(
                'حوارات قصيرة أصلية تُسمع بصوت الإسبانية على جهازك. يُفتح كل '
                'حوار بعد إكمال الدروس التي يعتمد عليها.',
                style: t.textTheme.bodyMedium!.copyWith(
                  color: t.colorScheme.onSurfaceVariant,
                  height: 1.6,
                ),
              ),
              for (final level in pack.levels)
                if (byLevel[level.id] != null) ...[
                  SectionTitle('${level.code} · ${level.titleAr}'),
                  for (final d in byLevel[level.id]!)
                    _DialogueTile(
                      dialogue: d,
                      unlocked: DialogueProgress.isUnlocked(d, lessons),
                      progress: DialogueProgress.of(d, attempts),
                      missing: [
                        for (final id in d.lessonIds)
                          if (!ProgressRepository.isCompleted(lessons[id]))
                            pack.lesson(id)?.titleAr ?? id,
                      ],
                    ),
                ],
            ],
          );
        },
      ),
    );
  }
}

class _DialogueTile extends StatelessWidget {
  const _DialogueTile({
    required this.dialogue,
    required this.unlocked,
    required this.progress,
    required this.missing,
  });

  final Dialogue dialogue;
  final bool unlocked;
  final DialogueProgress progress;
  final List<String> missing;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final ok = AppColors.of(context).success;
    final status = !unlocked
        ? 'أكمل أولاً: ${missing.join('، ')}'
        : progress.completed
        ? 'أُجيب عن الأسئلة · ${progress.correct} من ${progress.total} صحيحة من المحاولة الأولى'
        : progress.started
        ? 'بدأت: ${progress.answered} من ${progress.total} أسئلة'
        : '${dialogue.turns.length} جمل · ${dialogue.questions.length} أسئلة فهم';
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          key: ValueKey('dialogue-${dialogue.id}'),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          leading: Icon(
            !unlocked
                ? Icons.lock_outline_rounded
                : progress.completed
                ? Icons.check_circle_rounded
                : Icons.headphones_rounded,
            color: !unlocked
                ? t.colorScheme.outline
                : progress.completed
                ? ok
                : t.colorScheme.primary,
          ),
          title: Text(
            dialogue.titleAr,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              EsText(dialogue.titleEs, size: 14),
              const SizedBox(height: 2),
              Text(status, style: t.textTheme.bodySmall),
            ],
          ),
          onTap: unlocked
              ? () => context.push('/listening/${dialogue.id}')
              : () => ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(
                    SnackBar(
                      content: Text('أكمل أولاً: ${missing.join('، ')}'),
                    ),
                  ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Player
// ---------------------------------------------------------------------------

class DialogueScreen extends ConsumerStatefulWidget {
  const DialogueScreen({super.key, required this.dialogueId});
  final String dialogueId;

  @override
  ConsumerState<DialogueScreen> createState() => _DialogueScreenState();
}

class _DialogueScreenState extends ConsumerState<DialogueScreen> {
  DialoguePlayer? _player;

  /// Hidden by default: listen first, then check the text.
  bool _transcript = false;
  bool _translation = false;

  @override
  void initState() {
    super.initState();
    final d = ref.read(contentProvider).dialogue(widget.dialogueId);
    if (d != null) {
      _player = DialoguePlayer(ref.read(speechProvider), [
        for (final t in d.turns) t.es,
      ])..addListener(_onPlayer);
    }
  }

  void _onPlayer() {
    if (!mounted) return;
    // Without a voice the transcript is the only way to study the dialogue.
    if (_player!.status == PlayerStatus.unavailable && !_transcript) {
      _transcript = true;
    }
    setState(() {});
  }

  @override
  void dispose() {
    _player?.removeListener(_onPlayer);
    _player?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final pack = ref.watch(contentProvider);
    final d = pack.dialogue(widget.dialogueId);
    final player = _player;
    if (d == null || player == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const EmptyState(
          icon: Icons.search_off_rounded,
          title: 'الحوار غير موجود',
          message: 'قد يكون من إصدار محتوى مختلف.',
        ),
      );
    }
    final showEn = ref.watch(settingsProvider.select((s) => s.showEnglish));
    final playing = player.status == PlayerStatus.playing;
    // Known before anything is played, so the questions are never offered
    // on a device that cannot speak them.
    final noVoice =
        player.status == PlayerStatus.unavailable ||
        ref.watch(spanishVoiceProvider).value == false;
    final paused = player.status == PlayerStatus.paused;

    return Scaffold(
      appBar: AppBar(title: Text(d.titleAr)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          EsText(
            d.titleEs,
            size: 22,
            weight: FontWeight.w700,
            color: t.colorScheme.primary,
          ),
          const SizedBox(height: 6),
          Text(d.scenarioAr, style: const TextStyle(height: 1.6)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              for (final sp in d.speakers)
                Chip(
                  avatar: const Icon(Icons.person_outline_rounded, size: 18),
                  label: Text('${sp.name} · ${sp.roleAr}'),
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),
          if (noVoice)
            Container(
              key: const ValueKey('no-voice'),
              margin: const EdgeInsets.only(top: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: t.colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'لا يوجد صوت إسباني مثبّت على الجهاز، فلا يمكن تشغيل الحوار. '
                'النص ظاهر لتدرسه قراءةً، أما أسئلة الفهم فتحتاج الصوت. '
                'لتفعيل الصوت ثبّت بيانات اللغة الإسبانية من إعدادات «تحويل '
                'النص إلى كلام» في أندرويد.',
                style: TextStyle(
                  color: t.colorScheme.onErrorContainer,
                  height: 1.6,
                ),
              ),
            ),

          // ---- controls ----------------------------------------------------
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          key: const ValueKey('play-all'),
                          onPressed: playing
                              ? player.pause
                              : paused
                              ? player.resume
                              : () => player.playAll(),
                          icon: Icon(
                            playing
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                          ),
                          label: Text(
                            playing
                                ? 'إيقاف مؤقت'
                                : paused
                                ? 'تابع'
                                : player.status == PlayerStatus.finished
                                ? 'أعد الحوار'
                                : 'شغّل الحوار',
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.outlined(
                        key: const ValueKey('stop'),
                        tooltip: 'إيقاف',
                        onPressed: playing || paused ? player.stop : null,
                        icon: const Icon(Icons.stop_rounded),
                      ),
                    ],
                  ),
                  if (paused)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        'عند المتابعة تبدأ الجملة المتوقفة من أولها.',
                        style: t.textTheme.bodySmall,
                      ),
                    ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Text('السرعة'),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SegmentedButton<double>(
                          key: const ValueKey('speed'),
                          segments: [
                            for (final s in DialoguePlayer.speeds)
                              ButtonSegment(
                                value: s,
                                label: Text(
                                  s == 1.0 ? 'عادية' : '${(s * 100).round()}٪',
                                ),
                              ),
                          ],
                          selected: {player.speed},
                          onSelectionChanged: (v) => player.setSpeed(v.first),
                        ),
                      ),
                    ],
                  ),
                  SwitchListTile(
                    key: const ValueKey('toggle-transcript'),
                    contentPadding: EdgeInsets.zero,
                    title: const Text('إظهار النص الإسباني'),
                    value: _transcript,
                    onChanged: (v) => setState(() => _transcript = v),
                  ),
                  SwitchListTile(
                    key: const ValueKey('toggle-translation'),
                    contentPadding: EdgeInsets.zero,
                    title: const Text('إظهار الترجمة العربية'),
                    value: _translation,
                    onChanged: (v) => setState(() => _translation = v),
                  ),
                ],
              ),
            ),
          ),

          // ---- turns -------------------------------------------------------
          const SectionTitle('الحوار'),
          for (var i = 0; i < d.turns.length; i++)
            _TurnCard(
              dialogue: d,
              index: i,
              active: player.current == i && (playing || paused),
              // Without a voice the transcript is the only way to study.
              showEs: _transcript || noVoice,
              showAr: _translation,
              showEn: showEn,
              onReplay: () => player.playTurn(i),
            ),

          // ---- language support -------------------------------------------
          if (d.items.isNotEmpty) ...[
            const SectionTitle('مفردات الحوار'),
            Directionality(
              textDirection: TextDirection.ltr,
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final id in d.items)
                    if (pack.item(id) != null)
                      ActionChip(
                        key: ValueKey('vocab-$id'),
                        label: Text(
                          pack.item(id)!.es,
                          style: const TextStyle(fontFamily: spanishFont),
                        ),
                        onPressed: () =>
                            showVocabSheet(context, pack.item(id)!),
                      ),
                ],
              ),
            ),
          ],
          if (d.grammarIds.isNotEmpty) ...[
            const SectionTitle('قواعد مرتبطة'),
            for (final id in d.grammarIds)
              if (pack.grammarNote(id) != null)
                Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    key: ValueKey('grammar-$id'),
                    leading: const Icon(Icons.school_outlined),
                    title: Text(pack.grammarNote(id)!.titleAr),
                    onTap: () => _showGrammar(context, pack.grammarNote(id)!),
                  ),
                ),
          ],
          const SectionTitle('ما ستتدرب عليه'),
          for (final o in d.objectivesAr)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.flag_outlined,
                    size: 18,
                    color: t.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: Text(o)),
                ],
              ),
            ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: FilledButton.icon(
            key: const ValueKey('start-quiz'),
            onPressed: noVoice
                ? null
                : () {
                    player.stop();
                    context.push('/listening/${d.id}/questions');
                  },
            icon: const Icon(Icons.quiz_outlined),
            label: Text('أسئلة الفهم (${d.questions.length})'),
          ),
        ),
      ),
    );
  }

  void _showGrammar(BuildContext context, GrammarNote g) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        maxChildSize: 0.95,
        builder: (_, controller) => ListView(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          children: [
            Text(
              g.titleAr,
              style: Theme.of(ctx).textTheme.titleLarge!
                  .copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            Text(g.bodyAr, style: const TextStyle(height: 1.8)),
            const SizedBox(height: 12),
            for (final e in g.examples)
              ExampleTile(
                e,
                source: PhraseSource(kind: 'grammar', id: g.id),
              ),
          ],
        ),
      ),
    );
  }
}

class _TurnCard extends StatelessWidget {
  const _TurnCard({
    required this.dialogue,
    required this.index,
    required this.active,
    required this.showEs,
    required this.showAr,
    required this.showEn,
    required this.onReplay,
  });

  final Dialogue dialogue;
  final int index;
  final bool active;
  final bool showEs;
  final bool showAr;
  final bool showEn;
  final VoidCallback onReplay;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final turn = dialogue.turns[index];
    final speaker = dialogue.speaker(turn.speaker);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Semantics(
        selected: active,
        child: Container(
          key: ValueKey('turn-$index'),
          decoration: BoxDecoration(
            color: active
                ? t.colorScheme.primaryContainer.withValues(alpha: 0.6)
                : t.cardTheme.color,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: active
                  ? t.colorScheme.primary
                  : t.colorScheme.outlineVariant,
              width: active ? 2 : 1,
            ),
          ),
          padding: const EdgeInsetsDirectional.fromSTEB(14, 10, 4, 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      speaker?.name ?? turn.speaker,
                      style: t.textTheme.labelLarge!.copyWith(
                        color: t.colorScheme.tertiary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (showEs)
                      SizedBox(
                        width: double.infinity,
                        child: EsText(
                          turn.es,
                          size: 17,
                          weight: FontWeight.w500,
                        ),
                      )
                    else
                      Text(
                        '• • •  (النص مخفي — استمع أولاً)',
                        style: t.textTheme.bodyMedium!.copyWith(
                          color: t.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    if (showAr) ...[
                      const SizedBox(height: 4),
                      Text(
                        turn.ar,
                        style: t.textTheme.bodyMedium!.copyWith(
                          color: t.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                    if (showEn && turn.en.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      EsText(
                        turn.en,
                        size: 13,
                        color: t.colorScheme.onSurfaceVariant,
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                key: ValueKey('replay-$index'),
                tooltip: 'أعد هذه الجملة',
                onPressed: onReplay,
                icon: const Icon(Icons.replay_rounded),
              ),
              SavePhraseButton(
                PhraseDraft(
                  es: turn.es,
                  ar: turn.ar,
                  en: turn.en,
                  source: PhraseSource(
                    kind: 'dialogue',
                    id: turn.id,
                    lessonId: dialogue.lessonIds.isEmpty
                        ? null
                        : dialogue.lessonIds.last,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Comprehension questions (guided practice, not an assessment)
// ---------------------------------------------------------------------------

class DialogueQuestionsScreen extends ConsumerStatefulWidget {
  const DialogueQuestionsScreen({super.key, required this.dialogueId});
  final String dialogueId;

  @override
  ConsumerState<DialogueQuestionsScreen> createState() =>
      _DialogueQuestionsScreenState();
}

class _DialogueQuestionsScreenState
    extends ConsumerState<DialogueQuestionsScreen> {
  RunResult? _result;
  List<Exercise>? _questions;

  /// Delivery-log position when the questions screen opened.
  late final int _mark;

  @override
  void initState() {
    super.initState();
    _mark = ref.read(speechDeliveryLogProvider).mark();
  }

  /// Questions answered without their audio having been heard.
  final Set<String> _unheard = {};

  void _leave() => context.canPop() ? context.pop() : context.go('/listening');

  @override
  Widget build(BuildContext context) {
    final d = ref.watch(contentProvider).dialogue(widget.dialogueId);
    if (d == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const EmptyState(
          icon: Icons.search_off_rounded,
          title: 'الحوار غير موجود',
          message: 'قد يكون من إصدار محتوى مختلف.',
        ),
      );
    }
    // Every question depends on hearing the dialogue. Without a Spanish
    // voice an answer would be a guess, so nothing is asked or recorded.
    final voice = ref.watch(spanishVoiceProvider);
    if (_questions == null && voice.value != true) {
      return Scaffold(
        appBar: AppBar(title: Text(d.titleAr)),
        body: voice.isLoading
            ? const Center(child: CircularProgressIndicator())
            : const EmptyState(
                key: ValueKey('questions-no-voice'),
                icon: Icons.volume_off_rounded,
                title: 'أسئلة الفهم تحتاج صوتاً إسبانياً',
                message:
                    'تعتمد الأسئلة على سماع الحوار، فلا تُطرح ولا تُسجَّل '
                    'بدون صوت. ثبّت بيانات اللغة الإسبانية من إعدادات «تحويل '
                    'النص إلى كلام» ثم عُد. يمكنك قراءة نص الحوار في الأثناء.',
              ),
      );
    }
    final questions = _questions ??= ref
        .read(exerciseBuilderProvider)
        .buildDialogueQuestions(d);
    final result = _result;
    if (result != null) {
      return Scaffold(
        appBar: AppBar(title: Text(d.titleAr)),
        body: EmptyState(
          icon: Icons.task_alt_rounded,
          title: 'انتهت أسئلة الفهم',
          message:
              'الصحيح من المحاولة الأولى: ${result.firstTryCorrect} من ${result.measured}\n'
              '${_unheard.isEmpty ? '' : 'لم يُشغَّل الصوت في ${_unheard.length} من الأسئلة، فلم تُحتسب إجاباتها في تقدّمك.\n'}'
              'هذا تدريب موجّه، وليس اختباراً لمستواك.',
          action: FilledButton(
            key: const ValueKey('questions-done'),
            onPressed: _leave,
            child: const Text('تم'),
          ),
        ),
      );
    }
    return Scaffold(
      body: ExerciseRunner(
        steps: questions,
        onExit: _leave,
        onAttempt: (ex, s, attemptNumber) {
          // Listening evidence only counts when this question's sentence
          // was actually spoken in this session. A voice that fails after
          // the session started leaves an unmeasured practice record.
          final audio = audioOf(ex);
          final heard =
              audio == null ||
              ref.read(speechDeliveryLogProvider).deliveredSince(audio, _mark);
          if (!heard && attemptNumber == 1) _unheard.add(ex.id);
          return ref
              .read(progressRepositoryProvider)
              .recordAttempt(
                ex,
                isCorrect: s.correct,
                userAnswer: s.answer,
                context: DialogueProgress.context,
                lessonId: d.lessonIds.isEmpty ? null : d.lessonIds.last,
                attemptNumber: attemptNumber,
                measured: heard,
              );
        },
        onFinished: (r) async {
          await ref
              .read(progressRepositoryProvider)
              // A finished run always leaves a record, so today's plan
              // sees the listening practice even after a very fast run.
              .logStudy(
                kind: 'listening',
                refId: d.id,
                seconds: r.seconds < 1 ? 1 : r.seconds,
              );
          if (mounted) setState(() => _result = r);
        },
      ),
    );
  }
}

/// The sentence an exercise plays, if it depends on hearing one.
String? audioOf(Exercise ex) => switch (ex) {
  ChoiceExercise e => e.audioEs,
  TypeExercise e => e.audioEs,
  _ => null,
};

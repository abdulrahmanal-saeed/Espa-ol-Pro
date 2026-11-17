import 'dart:math';

import '../content/models.dart';
import 'answer_evaluator.dart';

/// A single screen in a lesson or practice run.
sealed class LessonStep {
  const LessonStep(this.id);
  final String id;
}

class TeachStep extends LessonStep {
  const TeachStep(super.id, this.item);
  final VocabItem item;
}

class NoteStep extends LessonStep {
  const NoteStep(super.id, this.titleAr, this.bodyAr, this.examples);
  final String titleAr;
  final String bodyAr;
  final List<Example> examples;
}

sealed class Exercise extends LessonStep {
  const Exercise(
    super.id, {
    required this.type,
    required this.skill,
    required this.promptAr,
    required this.expected,
    this.itemId,
  });

  final String type;
  final String skill;
  final String promptAr;

  /// Canonical correct answer, stored with the attempt.
  final String expected;
  final String? itemId;

  /// Whether the app can grade this objectively.
  bool get isMeasured => true;
}

class ChoiceExercise extends Exercise {
  const ChoiceExercise(
    super.id, {
    required super.type,
    required super.skill,
    required super.promptAr,
    required super.expected,
    super.itemId,
    required this.options,
    required this.correctIndex,
    required this.optionsAreSpanish,
    this.stimulusEs,
    this.audioEs,
    this.explainAr = '',
  });

  final List<String> options;
  final int correctIndex;
  final bool optionsAreSpanish;

  /// Spanish text shown above the options.
  final String? stimulusEs;

  /// Spanish text spoken (and NOT shown) for listening items.
  final String? audioEs;
  final String explainAr;
}

class TypeExercise extends Exercise {
  const TypeExercise(
    super.id, {
    required super.type,
    required super.skill,
    required super.promptAr,
    required super.expected,
    super.itemId,
    required this.accepted,
    this.stimulusAr,
    this.templateEs,
    this.audioEs,
  });

  final List<String> accepted;
  final String? stimulusAr;

  /// Sentence with a `___` blank (fill-in-the-blank).
  final String? templateEs;
  final String? audioEs;
}

class OrderExercise extends Exercise {
  const OrderExercise(
    super.id, {
    required super.type,
    required super.skill,
    required super.promptAr,
    required super.expected,
    super.itemId,
    required this.targetAr,
    required this.tokens,
    required this.answer,
  });

  final String targetAr;

  /// Shuffled word bank (may include distractors).
  final List<String> tokens;
  final List<String> answer;

  bool check(List<String> picked) =>
      normalizeAnswer(picked.join(' ')) == normalizeAnswer(answer.join(' '));
}

class MatchPair {
  const MatchPair(this.itemId, this.es, this.ar);
  final String itemId;
  final String es;
  final String ar;
}

class MatchExercise extends Exercise {
  const MatchExercise(
    super.id, {
    required super.type,
    required super.skill,
    required super.promptAr,
    required super.expected,
    required this.pairs,
    required this.shuffledAr,
  });

  final List<MatchPair> pairs;

  /// Indices into [pairs] giving the display order of the Arabic column.
  final List<int> shuffledAr;
}

/// Listen-and-repeat. Self-assessed: the app cannot measure pronunciation
/// offline, so this is never counted as accuracy.
class SpeakExercise extends Exercise {
  const SpeakExercise(
    super.id, {
    required super.promptAr,
    required super.expected,
    super.itemId,
    required this.ar,
  }) : super(type: 'speak', skill: 'speaking');

  final String ar;

  @override
  bool get isMeasured => false;
}

/// Stable 32-bit FNV-1a hash (String.hashCode is not guaranteed stable).
int stableHash(String s) {
  var h = 0x811c9dc5;
  for (final c in s.codeUnits) {
    h ^= c;
    h = (h * 0x01000193) & 0xffffffff;
  }
  return h;
}

/// Turns authored [ActivitySpec]s into concrete, deterministic exercises.
class ExerciseBuilder {
  ExerciseBuilder(this.pack);
  final ContentPack pack;

  List<LessonStep> buildLesson(Lesson lesson) {
    final pool = pack.itemsUpTo(lesson);
    return [
      for (final a in lesson.activities) _build(a, lesson.items, pool, ''),
    ];
  }

  LessonStep _build(
    ActivitySpec a,
    List<VocabItem> near,
    List<VocabItem> pool,
    String salt,
  ) {
    final rnd = Random(stableHash('${a.id}|$salt'));
    final d = a.data;
    final item = a.itemId == null ? null : pack.item(a.itemId!);
    String s(String k) => d[k] as String? ?? '';

    switch (a.type) {
      case 'teach':
        return TeachStep(a.id, item!);
      case 'note':
        return NoteStep(
          a.id,
          s('title_ar'),
          s('body_ar'),
          (d['examples'] as List? ?? const [])
              .map((e) => Example.fromJson((e as Map).cast<String, dynamic>()))
              .toList(),
        );
      case 'mcq_meaning':
        final opts = _options(item!, near, pool, rnd, (i) => i.ar);
        return ChoiceExercise(
          a.id,
          type: a.type,
          skill: 'vocabulary',
          promptAr: 'ما معنى هذه العبارة؟',
          expected: item.ar,
          itemId: item.id,
          stimulusEs: item.es,
          options: opts,
          correctIndex: opts.indexOf(item.ar),
          optionsAreSpanish: false,
        );
      case 'mcq_reverse':
        final opts = _options(item!, near, pool, rnd, (i) => i.es);
        return ChoiceExercise(
          a.id,
          type: a.type,
          skill: 'vocabulary',
          promptAr: 'كيف تقول بالإسبانية: «${item.ar}»؟',
          expected: item.es,
          itemId: item.id,
          options: opts,
          correctIndex: opts.indexOf(item.es),
          optionsAreSpanish: true,
        );
      case 'listen_choose':
        final opts = _options(item!, near, pool, rnd, (i) => i.ar);
        return ChoiceExercise(
          a.id,
          type: a.type,
          skill: 'listening',
          promptAr: 'استمع ثم اختر المعنى الصحيح',
          expected: item.ar,
          itemId: item.id,
          audioEs: item.es,
          options: opts,
          correctIndex: opts.indexOf(item.ar),
          optionsAreSpanish: false,
        );
      case 'listen_pick_es':
        final opts = _options(item!, near, pool, rnd, (i) => i.es);
        return ChoiceExercise(
          a.id,
          type: a.type,
          skill: 'listening',
          promptAr: 'استمع ثم اختر ما سمعته',
          expected: item.es,
          itemId: item.id,
          audioEs: item.es,
          options: opts,
          correctIndex: opts.indexOf(item.es),
          optionsAreSpanish: true,
        );
      case 'type_es':
        return TypeExercise(
          a.id,
          type: a.type,
          skill: 'writing',
          promptAr: 'اكتب بالإسبانية',
          expected: item!.es,
          itemId: item.id,
          stimulusAr: item.ar,
          accepted: item.acceptedAnswers,
        );
      case 'dictation':
        final es = item?.es ?? s('es');
        return TypeExercise(
          a.id,
          type: a.type,
          skill: 'listening',
          promptAr: 'استمع واكتب ما تسمعه',
          expected: es,
          itemId: item?.id,
          audioEs: es,
          accepted: [es, ...?item?.alt],
        );
      case 'speak':
        return SpeakExercise(
          a.id,
          promptAr: 'استمع ثم كرّر بصوت مسموع',
          expected: item?.es ?? s('es'),
          itemId: item?.id,
          ar: item?.ar ?? s('ar'),
        );
      case 'fill':
        final answer = s('answer');
        final full = s('es').replaceAll('___', answer);
        final options = (d['options'] as List? ?? const []).cast<String>();
        if (options.isNotEmpty) {
          final shuffled = [...options]..shuffle(rnd);
          return ChoiceExercise(
            a.id,
            type: a.type,
            skill: 'grammar',
            promptAr: 'اختر الكلمة المناسبة للفراغ\n«${s('ar')}»',
            expected: full,
            stimulusEs: s('es'),
            options: shuffled,
            correctIndex: shuffled.indexOf(answer),
            optionsAreSpanish: true,
            explainAr: s('explain_ar'),
          );
        }
        return TypeExercise(
          a.id,
          type: a.type,
          skill: 'writing',
          promptAr: 'أكمل الجملة',
          expected: full,
          stimulusAr: s('ar'),
          templateEs: s('es'),
          accepted: [answer, ...(d['alt'] as List? ?? const []).cast<String>()],
        );
      case 'order':
        final answer = tokenize(s('es'));
        final tokens = [
          ...answer,
          ...(d['distractors'] as List? ?? const []).cast<String>(),
        ]..shuffle(rnd);
        // Never present the bank already in the solved order.
        if (tokens.length > 1 && tokens.join(' ') == answer.join(' ')) {
          tokens.add(tokens.removeAt(0));
        }
        return OrderExercise(
          a.id,
          type: a.type,
          skill: 'writing',
          promptAr: 'رتّب الكلمات لتكوين الجملة',
          expected: s('es'),
          targetAr: s('ar'),
          tokens: tokens,
          answer: answer,
        );
      case 'match':
        final pairs = [
          for (final id in (d['items'] as List).cast<String>())
            MatchPair(id, pack.item(id)!.es, pack.item(id)!.ar),
        ];
        final order = List<int>.generate(pairs.length, (i) => i)..shuffle(rnd);
        return MatchExercise(
          a.id,
          type: a.type,
          skill: 'vocabulary',
          promptAr: 'صِل كل عبارة بمعناها',
          expected: pairs.map((p) => p.es).join(' | '),
          pairs: pairs,
          shuffledAr: order,
        );
      case 'choice':
        final choices = (d['choices'] as List).cast<String>();
        final correct = choices[d['answer'] as int];
        final shuffled = [...choices]..shuffle(rnd);
        return ChoiceExercise(
          a.id,
          type: a.type,
          skill: d['skill'] as String? ?? 'reading',
          promptAr: s('prompt_ar'),
          expected: correct,
          stimulusEs: d['stimulus_es'] as String?,
          audioEs: d['audio_es'] as String?,
          options: shuffled,
          correctIndex: shuffled.indexOf(correct),
          optionsAreSpanish: d['choices_es'] as bool? ?? true,
          explainAr: s('explain_ar'),
        );
      case 'respond':
        final accepted = (d['accepted'] as List).cast<String>();
        return TypeExercise(
          a.id,
          type: a.type,
          skill: 'writing',
          promptAr: 'موقف: اكتب ردّك بالإسبانية',
          expected: accepted.first,
          stimulusAr: s('prompt_ar'),
          audioEs: d['audio_es'] as String?,
          accepted: accepted,
        );
    }
    throw StateError('Unhandled activity type ${a.type}');
  }

  /// Correct option + up to 3 distinct distractors, shuffled.
  List<String> _options(
    VocabItem item,
    List<VocabItem> near,
    List<VocabItem> pool,
    Random rnd,
    String Function(VocabItem) text,
  ) {
    final correct = text(item);
    final seen = {correct};
    final distractors = <String>[];
    void take(List<VocabItem> from) {
      final shuffled = [...from]..shuffle(rnd);
      for (final c in shuffled) {
        if (distractors.length >= 3) return;
        if (c.id == item.id) continue;
        if (item.syn.isNotEmpty && c.syn == item.syn) continue;
        if (seen.add(text(c))) distractors.add(text(c));
      }
    }

    take(near);
    take(pool);
    return [correct, ...distractors]..shuffle(rnd);
  }

  /// Builds a practice run over already-learned [items].
  ///
  /// [mode]: `listening` | `writing` | `pronunciation` | `errors`.
  /// [salt] varies the shuffle between runs (pass the run start time).
  /// Comprehension questions for a dialogue, in authored order.
  ///
  /// The Spanish of the referenced turn is played as audio and is NOT shown,
  /// so the learner answers from what they hear. Options are shuffled
  /// deterministically per question.
  List<Exercise> buildDialogueQuestions(Dialogue d) {
    final out = <Exercise>[];
    for (final q in d.questions) {
      final rnd = Random(stableHash(q.id));
      final turn = q.turnId == null ? null : d.turn(q.turnId!);
      switch (q.type) {
        case 'choice':
          final correct = q.choices[q.answer];
          final options = [...q.choices]..shuffle(rnd);
          out.add(
            ChoiceExercise(
              q.id,
              type: 'dialogue_choice',
              skill: q.skill,
              promptAr: turn == null
                  ? q.promptAr
                  : '${q.promptAr}\n(استمع إلى الجملة)',
              expected: correct,
              audioEs: turn?.es,
              options: options,
              correctIndex: options.indexOf(correct),
              optionsAreSpanish: q.choicesEs,
              explainAr: q.explainAr,
            ),
          );
        case 'speaker':
          String label(DialogueSpeaker sp) => '${sp.name} — ${sp.roleAr}';
          final correct = label(d.speaker(turn!.speaker)!);
          final options = [for (final sp in d.speakers) label(sp)]
            ..shuffle(rnd);
          out.add(
            ChoiceExercise(
              q.id,
              type: 'dialogue_speaker',
              skill: q.skill,
              promptAr: 'استمع: مَن قال هذه الجملة في الحوار؟',
              expected: correct,
              audioEs: turn.es,
              options: options,
              correctIndex: options.indexOf(correct),
              optionsAreSpanish: false,
              explainAr: q.explainAr,
            ),
          );
        case 'dictation':
          out.add(
            TypeExercise(
              q.id,
              type: 'dictation',
              skill: q.skill,
              promptAr: 'استمع واكتب الجملة كما سمعتها',
              expected: turn!.es,
              audioEs: turn.es,
              accepted: [turn.es],
            ),
          );
      }
    }
    return out;
  }

  List<Exercise> buildPractice({
    required String mode,
    required List<VocabItem> items,
    required String salt,
    int limit = 10,
  }) {
    if (items.isEmpty) return const [];
    final pool = pack.allItems.toList();
    final rnd = Random(stableHash('$mode|$salt'));
    final picked = ([...items]..shuffle(rnd)).take(limit).toList();
    final out = <Exercise>[];
    for (var i = 0; i < picked.length; i++) {
      final item = picked[i];
      final type = switch (mode) {
        'listening' => i.isEven ? 'listen_choose' : 'dictation',
        'writing' => 'type_es',
        'pronunciation' => 'speak',
        _ => i.isEven ? 'type_es' : 'listen_pick_es',
      };
      final spec = ActivitySpec(
        id: 'practice:$mode:${item.id}:$type',
        type: type,
        data: {'type': type, 'item': item.id},
      );
      final lesson = pack.lesson(item.lessonId);
      out.add(_build(spec, lesson?.items ?? const [], pool, salt) as Exercise);
    }
    return out;
  }
}

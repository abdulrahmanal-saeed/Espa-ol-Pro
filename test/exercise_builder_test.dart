import 'package:espanol_pro/core/content/models.dart';
import 'package:espanol_pro/core/learning/answer_evaluator.dart';
import 'package:espanol_pro/core/learning/exercises.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support.dart';

void main() {
  late ContentPack pack;
  late ExerciseBuilder builder;
  setUpAll(() async {
    pack = await loadRealContent();
    builder = ExerciseBuilder(pack);
  });

  test('every shipped lesson builds into well-formed steps', () {
    for (final lesson in pack.orderedLessons) {
      final steps = builder.buildLesson(lesson);
      expect(steps.length, lesson.activities.length);
      for (final s in steps) {
        switch (s) {
          case ChoiceExercise e:
            expect(e.options.length, greaterThanOrEqualTo(2), reason: e.id);
            expect(e.options.toSet().length, e.options.length, reason: e.id);
            expect(e.correctIndex, inInclusiveRange(0, e.options.length - 1));
            expect(e.options[e.correctIndex], isNotEmpty);
          case TypeExercise e:
            expect(e.accepted, isNotEmpty, reason: e.id);
            // The canonical answer must grade as correct.
            expect(
              evaluateAnswer(e.accepted.first, e.accepted).isCorrect,
              isTrue,
            );
          case OrderExercise e:
            expect(e.check(e.answer), isTrue, reason: e.id);
            expect(
              e.tokens.join(' ') == e.answer.join(' '),
              isFalse,
              reason: '${e.id} is presented already solved',
            );
            for (final t in e.answer) {
              expect(e.tokens, contains(t));
            }
          case MatchExercise e:
            expect(e.shuffledAr.toSet().length, e.pairs.length);
          case SpeakExercise e:
            expect(e.isMeasured, isFalse);
          case TeachStep _:
          case NoteStep _:
            break;
        }
      }
    }
  });

  test('exercise generation is deterministic', () {
    final lesson = pack.orderedLessons[3];
    String sig(List<LessonStep> steps) => steps
        .whereType<ChoiceExercise>()
        .map((e) => '${e.options.join('|')}#${e.correctIndex}')
        .join('\n');
    expect(sig(builder.buildLesson(lesson)), sig(builder.buildLesson(lesson)));
  });

  test('near-synonyms are never offered as distractors for each other', () {
    for (final lesson in pack.orderedLessons) {
      for (final s in builder.buildLesson(lesson).whereType<ChoiceExercise>()) {
        final item = s.itemId == null ? null : pack.item(s.itemId!);
        if (item == null || item.syn.isEmpty) continue;
        final rivals = pack.allItems
            .where((i) => i.id != item.id && i.syn == item.syn)
            .expand((i) => [i.es, i.ar]);
        for (final r in rivals) {
          expect(s.options, isNot(contains(r)), reason: s.id);
        }
      }
    }
  });

  test('order exercise rejects wrong order and distractors', () {
    final ex = builder
        .buildLesson(pack.lesson('pa1_u3_l3')!)
        .whereType<OrderExercise>()
        .first;
    expect(ex.check(ex.answer.reversed.toList()), isFalse);
    expect(ex.check([...ex.answer, 'eres']), isFalse);
  });

  test('practice runs are built only from the given items', () {
    final items = pack.lesson('pa1_u2_l1')!.items;
    for (final mode in ['listening', 'writing', 'pronunciation', 'errors']) {
      final run = builder.buildPractice(mode: mode, items: items, salt: 'x');
      expect(run, isNotEmpty);
      expect(run.length, lessThanOrEqualTo(10));
      for (final ex in run) {
        expect(items.map((i) => i.id), contains(ex.itemId));
      }
    }
    expect(
      builder
          .buildPractice(mode: 'pronunciation', items: items, salt: 'x')
          .every((e) => !e.isMeasured),
      isTrue,
    );
    expect(
      builder.buildPractice(mode: 'writing', items: [], salt: 'x'),
      isEmpty,
    );
  });

  test('nouns taught with an article are accepted without it', () {
    final item = pack.item('el_trabajo')!;
    expect(item.acceptedAnswers, containsAll(['el trabajo', 'trabajo']));
    expect(pack.item('casa')!.acceptedAnswers, ['casa']);
  });

  test('stableHash is stable', () {
    expect(stableHash('hola'), stableHash('hola'));
    expect(stableHash('hola'), isNot(stableHash('holá')));
    expect(stableHash(''), 0x811c9dc5);
  });
}

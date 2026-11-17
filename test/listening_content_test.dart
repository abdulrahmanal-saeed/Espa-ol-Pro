import 'dart:convert';
import 'dart:io';

import 'package:espanol_pro/core/content/content_parser.dart';
import 'package:espanol_pro/core/content/content_validator.dart';
import 'package:espanol_pro/core/content/models.dart';
import 'package:espanol_pro/core/db/database.dart';
import 'package:espanol_pro/core/learning/exercises.dart';
import 'package:espanol_pro/features/listening/listening_progress.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support.dart';

/// Parses the real package, letting a test edit one dialogue file first.
Future<List<String>> issuesWith(
  void Function(List<Map<String, dynamic>> dialogues) edit, {
  String file = 'dialogues/pre_a1.json',
}) async {
  final pack = await parseContentPack((path) async {
    final text = await File('$contentDir/$path').readAsString();
    if (path != file) return text;
    final doc = jsonDecode(text) as Map<String, dynamic>;
    edit((doc['dialogues'] as List).cast<Map<String, dynamic>>());
    return jsonEncode(doc);
  });
  return ContentValidator().validate(pack).map((i) => '$i').toList();
}

void main() {
  late ContentPack pack;
  setUpAll(() async => pack = await loadRealContent());

  group('shipped dialogues', () {
    test('load, and every one passes validation', () {
      expect(pack.dialogues.length, greaterThanOrEqualTo(6));
      final issues = ContentValidator().validate(pack);
      expect(issues, isEmpty, reason: issues.join('\n'));
    });

    test('cover Pre-A1 and A1 and are reachable from real lessons', () {
      expect(pack.dialogues.map((d) => d.levelId).toSet(), {'pre_a1', 'a1'});
      for (final d in pack.dialogues) {
        for (final id in d.lessonIds) {
          expect(pack.lesson(id), isNotNull, reason: '${d.id} → $id');
        }
      }
    });

    test('only Spanish text can reach the voice', () {
      final arabic = RegExp(r'[؀-ۿ]');
      for (final d in pack.dialogues) {
        for (final t in d.turns) {
          expect(arabic.hasMatch(t.es), isFalse, reason: t.id);
        }
      }
    });
  });

  group('validator rejects broken dialogues', () {
    Future<void> rejects(
      void Function(Map<String, dynamic> d) edit,
      String message,
    ) async {
      final issues = await issuesWith((ds) => edit(ds.first));
      expect(issues.join('\n'), contains(message));
    }

    test(
      'unknown vocabulary item',
      () => rejects(
        (d) => (d['items'] as List).add('no_such_item'),
        'unknown item "no_such_item"',
      ),
    );

    test(
      'vocabulary not yet taught by its lessons',
      () => rejects(
        (d) => (d['items'] as List).add('gerente'), // taught in A1-U1
        'is not taught by its lessons or earlier',
      ),
    );

    test(
      'unknown lesson',
      () => rejects(
        (d) => (d['lessons'] as List).add('zz_lesson'),
        'unknown lesson "zz_lesson"',
      ),
    );

    test(
      'unit outside its level',
      () => rejects((d) => d['unit'] = 'a1_u1', 'is not in level'),
    );

    test(
      'turn by an unknown speaker',
      () => rejects(
        (d) => (d['turns'] as List).first['speaker'] = 'ghost',
        'unknown speaker "ghost"',
      ),
    );

    test(
      'Arabic inside Spanish text',
      () => rejects(
        (d) => (d['turns'] as List).first['es'] = 'Hola مرحباً',
        'es contains Arabic script',
      ),
    );

    test(
      'unbalanced Spanish question marks',
      () => rejects(
        (d) => (d['turns'] as List).first['es'] = 'Cómo estás?',
        'unbalanced ¿ ?',
      ),
    );

    test(
      'only one speaker',
      () => rejects((d) {
        for (final t in d['turns'] as List) {
          t['speaker'] = (d['speakers'] as List).first['id'];
        }
      }, 'needs at least two speakers who speak'),
    );

    test(
      'question pointing at a missing turn',
      () => rejects(
        (d) => (d['questions'] as List).first['turn'] = 'nope.t9',
        'unknown turn "nope.t9"',
      ),
    );

    test(
      'impossible answer index',
      () => rejects(
        (d) => (d['questions'] as List).first['answer'] = 7,
        'answer must be a valid index',
      ),
    );

    test(
      'duplicate choices',
      () => rejects(
        (d) => (d['questions'] as List).first['choices'] = ['a', 'a', 'b'],
        'choices must be distinct',
      ),
    );

    test(
      'dictation without a turn',
      () => rejects(
        (d) => (d['questions'] as List).add({'type': 'dictation'}),
        'dictation needs "turn"',
      ),
    );

    test(
      'unknown question type',
      () => rejects(
        (d) => (d['questions'] as List).add({'type': 'essay'}),
        'unknown question type "essay"',
      ),
    );

    test(
      'unknown grammar reference',
      () => rejects(
        (d) => (d['grammar'] as List).add('g_missing'),
        'unknown grammar reference "g_missing"',
      ),
    );

    test('duplicate dialogue id', () async {
      final issues = await issuesWith(
        (ds) => ds.add({...ds.first, 'turns': [], 'questions': []}),
      );
      expect(issues.join('\n'), contains('duplicate dialogue id'));
    });
  });

  group('comprehension questions', () {
    test('every shipped question builds into a gradable exercise', () {
      final builder = ExerciseBuilder(pack);
      for (final d in pack.dialogues) {
        final ex = builder.buildDialogueQuestions(d);
        expect(ex.length, d.questions.length);
        for (final e in ex) {
          switch (e) {
            case ChoiceExercise c:
              expect(c.correctIndex, inInclusiveRange(0, c.options.length - 1));
              expect(c.options.toSet().length, c.options.length);
              // Listening: the sentence is heard, never shown before answering.
              expect(c.stimulusEs, isNull, reason: e.id);
            case TypeExercise t:
              expect(t.audioEs, isNotNull);
              expect(t.accepted.single, t.audioEs);
            default:
              fail('unexpected ${e.runtimeType}');
          }
        }
      }
    });

    test('"who said it" offers the dialogue speakers', () {
      final d = pack.dialogue('dlg_a1_recepcion')!;
      final q = ExerciseBuilder(pack)
          .buildDialogueQuestions(d)
          .whereType<ChoiceExercise>()
          .firstWhere((e) => e.type == 'dialogue_speaker');
      expect(q.options.length, d.speakers.length);
      expect(q.options[q.correctIndex], startsWith('Recepcionista'));
    });

    test('question generation is deterministic', () {
      final d = pack.dialogues.first;
      String sig() =>
          ExerciseBuilder(pack)
              .buildDialogueQuestions(d)
              .whereType<ChoiceExercise>()
              .map((e) => e.options.join('|'))
              .join('\n');
      expect(sig(), sig());
    });
  });

  group('progress from attempts', () {
    ActivityAttempt a(
      String q,
      bool ok, {
      int at = 1,
      int attempt = 1,
      String context = 'listening',
      bool measured = true,
      int id = 0,
    }) => ActivityAttempt(
      id: id,
      activityId: q,
      skill: 'listening',
      exerciseType: 'dialogue_choice',
      context: context,
      isCorrect: ok,
      isMeasured: measured,
      attemptNumber: attempt,
      userAnswer: '',
      expected: '',
      createdAt: at,
    );

    test('counts the latest first attempt per question only', () {
      final d = pack.dialogue('dlg_pa1_saludo')!;
      final qs = d.questions.map((q) => q.id).toList();
      final p = DialogueProgress.of(d, [
        a(qs[0], false, at: 1),
        a(qs[0], true, at: 1, attempt: 2), // coached retry: ignored
        a(qs[0], true, at: 5), // a later run, right first time
        a(qs[1], true, at: 2),
        a(qs[2], true, at: 2, context: 'lesson'), // other context
        a(qs[3], true, at: 2, measured: false), // not measured
      ]);
      expect(p.total, qs.length);
      expect(p.answered, 2);
      expect(p.correct, 2);
      expect(p.completed, isFalse);
      expect(p.started, isTrue);
    });

    test('complete only when every question has a first attempt', () {
      final d = pack.dialogue('dlg_pa1_origen')!;
      final p = DialogueProgress.of(d, [
        for (final q in d.questions) a(q.id, q.id.endsWith('q1')),
      ]);
      expect(p.completed, isTrue);
      expect(p.correct, 1);
    });
  });
}

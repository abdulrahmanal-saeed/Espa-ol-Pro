import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:espanol_pro/core/assessment/assessment_engine.dart';
import 'package:espanol_pro/core/assessment/assessment_repository.dart';
import 'package:espanol_pro/core/content/content_parser.dart';
import 'package:espanol_pro/core/content/content_validator.dart';
import 'package:espanol_pro/core/content/models.dart';
import 'package:espanol_pro/core/db/database.dart';
import 'package:espanol_pro/core/learning/answer_evaluator.dart';
import 'package:espanol_pro/core/learning/difficulty.dart';
import 'package:espanol_pro/core/learning/exercises.dart';
import 'package:espanol_pro/core/learning/progress_repository.dart';
import 'package:espanol_pro/core/srs/review_repository.dart';
import 'package:espanol_pro/features/library/verbs_view.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;

import 'support.dart';
import 'widget_support.dart';

/// A2-U2 — the past (pretérito indefinido).
void main() {
  late ContentPack pack;
  setUpAll(() async {
    pack = await loadRealContent();
    await loadAppFonts();
    tzdata.initializeTimeZones();
  });

  Future<List<String>> verbIssuesWith(
    void Function(List<Map<String, dynamic>> verbs) edit,
  ) async {
    final broken = await parseContentPack((path) async {
      final text = await File('$contentDir/$path').readAsString();
      if (path != 'verbs.json') return text;
      final doc = jsonDecode(text) as Map<String, dynamic>;
      edit((doc['verbs'] as List).cast<Map<String, dynamic>>());
      return jsonEncode(doc);
    });
    return ContentValidator().validate(broken).map((i) => '$i').toList();
  }

  group('curriculum', () {
    test('five lessons, after A2-U1, each building on the previous one', () {
      final unit = pack.unit('a2_u2')!;
      expect(unit.lessons.map((l) => l.id), [
        'a2_u2_l1',
        'a2_u2_l2',
        'a2_u2_l3',
        'a2_u2_l4',
        'a2_u2_l5',
      ]);
      expect(unit.lessons.first.prerequisites, ['a2_u1_l5']);
      for (var i = 1; i < unit.lessons.length; i++) {
        expect(unit.lessons[i].prerequisites, [unit.lessons[i - 1].id]);
      }
      // A2-U2 directly follows A2-U1 among the available units.
      final a2 = pack.levels.firstWhere((l) => l.id == 'a2');
      expect(
        a2.units.where((u) => u.isAvailable).map((u) => u.id),
        containsAllInOrder(['a2_u1', 'a2_u2']),
      );
    });

    test('every lesson practises listening, typing, ordering, dictation, '
        'guided and free production, and has work items', () {
      for (final l in pack.unit('a2_u2')!.lessons) {
        final types = l.activities.map((a) => a.type).toSet();
        expect(
          types,
          containsAll([
            'listen_choose',
            'listen_pick_es',
            'type_es',
            'order',
            'dictation',
            'fill',
            'respond',
            'choice',
            'speak',
          ]),
          reason: l.id,
        );
        expect(l.items.length, inInclusiveRange(7, 10), reason: l.id);
        expect(l.items.where((i) => i.work), isNotEmpty, reason: l.id);
        expect(l.objectivesAr, isNotEmpty, reason: l.id);
        // Every fill exercise explains a wrong answer.
        for (final a in l.activities.where((a) => a.type == 'fill')) {
          expect(a.data['explain_ar'], isNotEmpty, reason: a.id);
        }
      }
    });

    test('the past is taught before it is assessed', () {
      final grammar = pack
          .unit('a2_u2')!
          .lessons
          .expand((l) => l.grammarIds)
          .toSet();
      expect(
        grammar,
        containsAll([
          'g_pret_ar',
          'g_pret_er_ir',
          'g_pret_spelling',
          'g_pret_irregular',
          'g_past_markers',
          'g_past_vs_present',
        ]),
      );
      // Irregular forms appear in lessons only from the lesson that teaches
      // them (lesson 4), and the checkpoint opens only after the unit.
      final l4 = pack.lesson('a2_u2_l4')!;
      expect(l4.grammarIds, contains('g_pret_irregular'));
      for (final id in ['fui', 'fue', 'hice', 'tuve']) {
        expect(pack.lesson('a2_u2_l4')!.items.any((i) => i.id == id), isTrue);
      }
    });

    test('lesson 38 opens only after the last A2-U1 lesson', () {
      final first = pack.lesson('a2_u2_l1')!;
      final before = <String, LessonProgressData>{};
      expect(
        ProgressRepository.isUnlocked(
          first,
          before,
          gates: LevelGates.from(pack, const []),
        ),
        isFalse,
      );
      final done = {
        for (final l in pack.orderedLessons.takeWhile((l) => l.id != first.id))
          l.id: LessonProgressData(
            lessonId: l.id,
            status: 'completed',
            bestScore: 1,
            lastScore: 1,
            completions: 1,
            startedAt: 0,
            contentVersion: pack.version,
          ),
      };
      expect(
        ProgressRepository.isUnlocked(
          first,
          done,
          gates: LevelGates.from(pack, const []),
        ),
        isTrue,
      );
      expect(
        ProgressRepository.nextLesson(
          pack,
          done,
          gates: LevelGates.from(pack, const []),
        )?.id,
        first.id,
      );
    });
  });

  group('verb reference: pretérito indefinido', () {
    test('regular past follows the rules, with yo spelling changes', () {
      expect(Verb.regularPreterite('hablar'), {
        'yo': 'hablé',
        'tu': 'hablaste',
        'el': 'habló',
        'nosotros': 'hablamos',
        'vosotros': 'hablasteis',
        'ellos': 'hablaron',
      });
      expect(Verb.regularPreterite('comer')!['el'], 'comió');
      expect(Verb.regularPreterite('salir')!['ellos'], 'salieron');
      expect(Verb.regularPreterite('llegar')!['yo'], 'llegué');
      expect(Verb.regularPreterite('llegar')!['el'], 'llegó');
      expect(Verb.regularPreterite('sacar')!['yo'], 'saqué');
      expect(Verb.regularPreterite('explicar')!['yo'], 'expliqué');
      expect(Verb.regularPreterite('empezar')!['yo'], 'empecé');
      expect(Verb.regularPreterite('empezar')!['tu'], 'empezaste');
      expect(Verb.regularPreterite('x'), isNull);
    });

    test(
      'every verb shows six past forms; regular ones are machine-checked',
      () {
        for (final v in pack.verbs) {
          expect(v.preterite.keys, Verb.persons, reason: v.id);
          if (v.preteriteRegular) {
            expect(
              v.preterite,
              Verb.regularPreterite(v.infinitive),
              reason: v.id,
            );
          }
        }
        final byId = {for (final v in pack.verbs) v.id: v};
        expect(byId['ir']!.preterite, byId['ser']!.preterite);
        expect(byId['ir']!.preterite['el'], 'fue');
        expect(byId['hacer']!.preterite['el'], 'hizo');
        expect(byId['tener']!.preterite['yo'], 'tuve');
        expect(byId['estar']!.preterite['ellos'], 'estuvieron');
        // Irregular in the present, regular in the past.
        expect(byId['volver']!.regular, isFalse);
        expect(byId['volver']!.preteriteRegular, isTrue);
        expect(byId['volver']!.preterite['yo'], 'volví');
        expect(byId['enviar']!.preterite['el'], 'envió');
      },
    );

    test('a verb without past forms still loads and validates (content '
        '< 1.6.0)', () async {
      final issues = await verbIssuesWith((verbs) {
        for (final v in verbs) {
          v.remove('preterite');
          v.remove('preterite_regular');
        }
      });
      // The verb file itself is valid without past forms.
      expect(
        issues.where((i) => i.contains('verb:')),
        isEmpty,
        reason: issues.join('\n'),
      );
      // Only the REVIEW-015 P3 rule notices: answers such as "terminó" are
      // no longer backed by a verb form in the reference.
      expect(
        issues.every((i) => i.contains('ends in a stressed é/ó')),
        isTrue,
        reason: issues.join('\n'),
      );
    });

    test(
      'the validator rejects wrong, missing and unknown past forms',
      () async {
        Map<String, dynamic> verb(List<Map<String, dynamic>> vs, String id) =>
            vs.firstWhere((v) => v['id'] == id);
        expect(
          await verbIssuesWith(
            (vs) => (verb(vs, 'hablar')['preterite'] as Map)['yo'] = 'hable',
          ),
          contains(contains('regular past form for "yo" should be "hablé"')),
        );
        expect(
          await verbIssuesWith(
            (vs) => (verb(vs, 'llegar')['preterite'] as Map)['yo'] = 'llegé',
          ),
          contains(contains('should be "llegué"')),
        );
        expect(
          await verbIssuesWith(
            (vs) => (verb(vs, 'hacer')['preterite'] as Map).remove('el'),
          ),
          contains(contains('missing past form for "el"')),
        );
        expect(
          await verbIssuesWith(
            (vs) => (verb(vs, 'ir')['preterite'] as Map)['usted'] = 'fue',
          ),
          contains(contains('unknown past person "usted"')),
        );
      },
    );

    testWidgets('the library shows the past table next to the present', (
      tester,
    ) async {
      final app = TestApp(pack);
      await app.pump(tester, location: '/library');
      await tester.tapSettled(find.text('الأفعال'));
      final tile = find.byKey(const ValueKey('verb-hacer'));
      await tester.scrollUntilVisible(
        tile,
        200,
        scrollable: find
            .descendant(
              of: find.byType(VerbsView),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.tapSettled(tile);
      expect(find.byKey(const ValueKey('verb-past-hacer')), findsOneWidget);
      expect(
        tester
            .widget<Text>(
              find.descendant(
                of: find.byKey(const ValueKey('verb-past-hacer-el')),
                matching: find.byType(Text),
              ),
            )
            .data,
        'hizo',
      );
      // Each past form can be heard.
      final row = find.ancestor(
        of: find.byKey(const ValueKey('verb-past-hacer-yo')),
        matching: find.byType(Row),
      );
      await tester.tapSettled(
        find.descendant(
          of: row.first,
          matching: find.byIcon(Icons.volume_up_rounded),
        ),
      );
      expect(app.speech.spoken, contains('hice'));
      await app.dispose(tester);
    });
  });

  group('answer evaluation of past forms', () {
    test('a missing final accent changes tense or person and is wrong', () {
      for (final (typed, expected) in [
        ('hablo', 'hablé'),
        ('hablo', 'habló'),
        ('trabaje', 'trabajé'),
        ('envio', 'envió'),
        ('llegue', 'llegué'),
        ('Ayer trabaje en casa', 'Ayer trabajé en casa.'),
      ]) {
        final r = evaluateAnswer(typed, [expected]);
        expect(r.isCorrect, isFalse, reason: '$typed → $expected');
        if (stripAccents(normalizeAnswer(typed)) ==
            stripAccents(normalizeAnswer(expected))) {
          expect(r.issue, AnswerIssue.accentMeaning, reason: typed);
          expect(r.explanationAr, contains('الزمن'), reason: typed);
        }
      }
    });

    test('the lenient rule for short words is unchanged', () {
      final r = evaluateAnswer('el cafe', ['el café']);
      expect(r.verdict, AnswerVerdict.correctMissingAccents);
      expect(r.issue, AnswerIssue.accents);
      // An accent on fue is a spelling slip, not another word.
      expect(
        evaluateAnswer('fué', ['fue']).verdict,
        AnswerVerdict.correctMissingAccents,
      );
    });

    test('the wrong person or tense of the right verb is diagnosed', () {
      final person = evaluateAnswer('Ayer hablaste con el cliente', [
        'Ayer hablé con el cliente.',
      ]);
      expect(person.isCorrect, isFalse);
      expect(person.issue, AnswerIssue.grammarForm);
      expect(person.expectedWord, 'hablé');
      final plural = evaluateAnswer('salieron', ['salí']);
      expect(plural.isCorrect, isFalse);
      expect(plural.issue, AnswerIssue.grammarForm);
    });

    test('no typed past form in A2-U2 accepts its unaccented twin', () {
      var checked = 0;
      for (final l in pack.unit('a2_u2')!.lessons) {
        for (final a in l.activities.where((a) => a.type == 'type_es')) {
          final item = l.items.firstWhere((i) => i.id == a.itemId);
          final last = item.es[item.es.length - 1];
          if (last != 'é' && last != 'ó') continue;
          checked++;
          final r = evaluateAnswer(stripAccents(item.es), item.acceptedAnswers);
          expect(r.isCorrect, isFalse, reason: item.es);
        }
      }
      expect(checked, greaterThanOrEqualTo(3));
    });
  });

  group('dialogues', () {
    test('three A2-U2 dialogues, unlocked inside the unit and understandable '
        'right after their lessons', () {
      final ds = pack.dialogues.where((d) => d.unitId == 'a2_u2').toList();
      expect(ds.map((d) => d.id), [
        'dlg_a2_finde',
        'dlg_a2_jornada',
        'dlg_a2_viaje',
      ]);
      final order = [for (final l in pack.orderedLessons) l.id];
      for (final d in ds) {
        expect(d.levelId, 'a2');
        expect(
          d.lessonIds.every((l) => pack.lesson(l)?.unitId == 'a2_u2'),
          isTrue,
        );
        final last = d.lessonIds
            .map(order.indexOf)
            .reduce((a, b) => a > b ? a : b);
        final exposure = LearnerExposure.from(pack, order.take(last + 1));
        final e = estimateDialogue(d, exposure);
        expect(
          e.band,
          isIn([DifficultyBand.veryEasy, DifficultyBand.appropriate]),
          reason: '${d.id}: ${e.reasonsAr}',
        );
        expect(d.questions.length, greaterThanOrEqualTo(5));
      }
    });
  });

  group('checkpoint chk_a2_u2', () {
    late Assessment chk;
    setUp(() => chk = pack.assessment('chk_a2_u2')!);

    test('covers three can-dos and five skills; grammar has feedback', () {
      expect(chk.unitId, 'a2_u2');
      expect(chk.questions.length, 12);
      expect(chk.canDos.length, 3);
      expect(chk.questions.map((q) => q.skill).toSet(), {
        'grammar',
        'listening',
        'reading',
        'writing',
        'vocabulary',
      });
      for (final q in chk.questions.where((q) => q.skill == 'grammar')) {
        expect(q.explainAr, isNotEmpty, reason: q.id);
      }
      expect(
        chk.questions.where((q) => q.dialogueTurnId != null).length,
        greaterThanOrEqualTo(3),
      );
    });

    test('grades correct, wrong-form and missing-accent answers', () {
      final all = gradeAssessment(chk, {
        for (final q in chk.questions) q.id: q.correctAnswer,
      });
      expect(all.every((g) => g.isCorrect), isTrue);
      final wrong = gradeAssessment(chk, {
        for (final q in chk.questions) q.id: q.correctAnswer,
        'chk_a2_u2.q5': 'envie', // envié without its accent
        'chk_a2_u2.q10': 'fue', // the wrong person
        'chk_a2_u2.q1': 'hablo',
      });
      expect(
        wrong.where((g) => !g.isCorrect).map((g) => g.question.id).toSet(),
        {'chk_a2_u2.q1', 'chk_a2_u2.q5', 'chk_a2_u2.q10'},
      );
    });

    test(
      'options are shuffled per attempt: the first one is not a shortcut',
      () {
        var firstRight = 0;
        var choices = 0;
        for (var s = 0; s < 10; s++) {
          for (final q in chk.questions.where((q) => q.type == 'choice')) {
            choices++;
            if (displayedChoices(q, 'attempt$s').first == q.correctAnswer) {
              firstRight++;
            }
          }
        }
        expect(firstRight / choices, lessThan(0.5));
      },
    );

    test('scores persist across a database reopen and a retry', () async {
      final tmp = Directory.systemTemp.createTempSync('espanol_pro_a2u2');
      addTearDown(() => tmp.deleteSync(recursive: true));
      final file = File('${tmp.path}/app.sqlite');
      final clock = FakeClock();
      var db = AppDatabase(NativeDatabase(file));
      final first = await AssessmentRepository(db, clock: clock.call).submit(
        assessment: chk,
        graded: gradeAssessment(chk, {
          for (final q in chk.questions) q.id: q.correctAnswer,
          'chk_a2_u2.q5': 'envie',
        }),
        startedAt: clock(),
        contentVersion: pack.version,
      );
      clock.advance(const Duration(days: 1));
      final retry = await AssessmentRepository(db, clock: clock.call).submit(
        assessment: chk,
        graded: gradeAssessment(chk, {
          for (final q in chk.questions) q.id: q.correctAnswer,
        }),
        startedAt: clock(),
        contentVersion: pack.version,
      );
      await db.close();
      db = AppDatabase(NativeDatabase(file));
      final repo = AssessmentRepository(db, clock: clock.call);
      expect((await repo.attempt(first))!.score, chk.questions.length - 1);
      expect((await repo.attempt(retry))!.score, chk.questions.length);
      final answers = await repo.answers(first);
      expect(answers.length, chk.questions.length);
      expect(
        answers.firstWhere((a) => a.questionId == 'chk_a2_u2.q5').isCorrect,
        isFalse,
      );
      await db.close();
    });
  });

  testWidgets('a completed A2-U2 lesson schedules FSRS cards for its items '
      'and leaves earlier progress untouched', (tester) async {
    final lesson = pack.lesson('a2_u2_l4')!;
    final app = TestApp(pack);
    final repo = ProgressRepository(
      app.db,
      ReviewRepository(app.db, clock: app.clock.call, enableFuzzing: false),
      clock: app.clock.call,
    );
    for (final l in pack.orderedLessons.takeWhile((l) => l.id != lesson.id)) {
      await repo.completeLesson(
        l,
        score: 1,
        seconds: 60,
        contentVersion: pack.version,
      );
    }
    final cardsBefore = await app.db.select(app.db.reviewCards).get();
    final progressBefore = await app.db.select(app.db.lessonProgress).get();

    final steps = ExerciseBuilder(pack).buildLesson(lesson);
    await app.pump(tester, location: '/lesson/${lesson.id}');
    await tester.tapKey('start-lesson');
    for (final step in steps) {
      await tester.answer(step);
    }
    await tester.tapKey('finish-lesson');

    final cards = await app.db.select(app.db.reviewCards).get();
    final newCards = cards.length - cardsBefore.length;
    expect(newCards, lesson.items.length * 2);
    for (final item in lesson.items) {
      expect(cards.where((c) => c.itemId == item.id).length, 2);
    }
    final progress = await app.db.select(app.db.lessonProgress).get();
    expect(progress.length, progressBefore.length + 1);
    for (final p in progressBefore) {
      expect(
        progress.firstWhere((x) => x.lessonId == p.lessonId).status,
        p.status,
      );
    }
    await app.dispose(tester);
  });
}

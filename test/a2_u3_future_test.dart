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
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;

import 'support.dart';
import 'widget_support.dart';

/// A2-U3 — plans and the future; and REVIEW-015 P3 (final-stress words).
void main() {
  late ContentPack pack;
  setUpAll(() async {
    pack = await loadRealContent();
    await loadAppFonts();
    tzdata.initializeTimeZones();
  });

  /// Validation issues after [edit] changes one content file.
  Future<List<String>> issuesWith(
    String file,
    void Function(Map<String, dynamic> doc) edit,
  ) async {
    final broken = await parseContentPack((path) async {
      final text = await File('$contentDir/$path').readAsString();
      if (path != file) return text;
      final doc = jsonDecode(text) as Map<String, dynamic>;
      edit(doc);
      return jsonEncode(doc);
    });
    return ContentValidator().validate(broken).map((i) => '$i').toList();
  }

  group('curriculum', () {
    test('five lessons after A2-U2, each building on the previous one', () {
      final unit = pack.unit('a2_u3')!;
      expect(unit.lessons.map((l) => l.id), [
        for (var i = 1; i <= 5; i++) 'a2_u3_l$i',
      ]);
      expect(unit.lessons.first.prerequisites, ['a2_u2_l5']);
      for (var i = 1; i < unit.lessons.length; i++) {
        expect(unit.lessons[i].prerequisites, [unit.lessons[i - 1].id]);
      }
      final a2 = pack.levels.firstWhere((l) => l.id == 'a2');
      expect(
        a2.units.where((u) => u.isAvailable).map((u) => u.id),
        containsAllInOrder(['a2_u1', 'a2_u2', 'a2_u3']),
      );
      for (final u in a2.units.where((u) => !u.isAvailable)) {
        expect(pack.unit(u.id)?.lessons ?? const [], isEmpty, reason: u.id);
      }
    });

    test('every lesson practises every skill and explains wrong answers', () {
      for (final l in pack.unit('a2_u3')!.lessons) {
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
            'match',
          ]),
          reason: l.id,
        );
        expect(l.items.length, inInclusiveRange(7, 10), reason: l.id);
        expect(l.items.where((i) => i.work), isNotEmpty, reason: l.id);
        for (final a in l.activities.where(
          (a) => a.type == 'fill' || a.data['skill'] == 'grammar',
        )) {
          expect(a.data['explain_ar'], isNotEmpty, reason: a.id);
        }
      }
    });

    test('each grammar point is taught in its lesson', () {
      final byLesson = {
        for (final l in pack.unit('a2_u3')!.lessons) l.id: l.grammarIds,
      };
      expect(byLesson['a2_u3_l1'], ['g_ir_a_full', 'g_future_markers']);
      expect(byLesson['a2_u3_l2'], ['g_pensar', 'g_invitations']);
      expect(byLesson['a2_u3_l3'], ['g_quedar']);
      expect(byLesson['a2_u3_l4'], ['g_present_schedule']);
      expect(byLesson['a2_u3_l5'], ['g_si_presente']);
    });

    test('lesson 43 opens only after the last A2-U2 lesson', () {
      final first = pack.lesson('a2_u3_l1')!;
      expect(ProgressRepository.isUnlocked(first, const {}), isFalse);
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
      expect(ProgressRepository.isUnlocked(first, done), isTrue);
      expect(ProgressRepository.nextLesson(pack, done)?.id, first.id);
    });
  });

  group('verbs', () {
    test('new verbs: stem changes by hand, regular ones machine-checked', () {
      final byId = {for (final v in pack.verbs) v.id: v};
      expect(byId['pensar']!.regular, isFalse);
      expect(byId['pensar']!.forms['yo'], 'pienso');
      expect(byId['pensar']!.forms['nosotros'], 'pensamos');
      expect(byId['pensar']!.preteriteRegular, isTrue);
      expect(byId['pensar']!.preterite['yo'], 'pensé');
      expect(byId['proponer']!.forms['yo'], 'propongo');
      expect(byId['proponer']!.preteriteRegular, isFalse);
      expect(byId['proponer']!.preterite['el'], 'propuso');
      for (final id in ['quedar', 'cambiar', 'confirmar', 'mandar', 'pasar']) {
        final v = byId[id]!;
        expect(v.regular, isTrue, reason: id);
        expect(v.forms, Verb.regularPresent(id), reason: id);
        expect(v.preterite, Verb.regularPreterite(id), reason: id);
      }
      expect(byId['ir']!.lessonIds, contains('a2_u3_l1'));
    });
  });

  group('REVIEW-015 P3: final-stress words that are not verbs', () {
    test('a non-verb keeps the meaning error but never mentions tense', () {
      final r = evaluateAnswer('el comite', ['el comité']);
      expect(r.isCorrect, isFalse);
      expect(r.issue, AnswerIssue.accentMeaning);
      expect(r.explanationAr, isNot(contains('الزمن')));
      // A verb form still gets the tense explanation.
      final v = evaluateAnswer('hablo', ['habló']);
      expect(v.explanationAr, contains('الزمن'));
    });

    test('the validator rejects an answer word ending in a stressed é/ó that '
        'is neither a verb form nor a listed non-verb', () async {
      void setFirstItem(Map<String, dynamic> doc, String es) {
        final lesson = (doc['lessons'] as List).first as Map;
        ((lesson['items'] as List).first as Map)['es'] = es;
      }

      final unknown = await issuesWith(
        'units/a2_u3.json',
        (d) => setFirstItem(d, 'el parqué'),
      );
      expect(unknown, contains(contains('"parqué" ends in a stressed é/ó')));

      final listed = await issuesWith(
        'units/a2_u3.json',
        (d) => setFirstItem(d, 'el comité'),
      );
      expect(listed.where((i) => i.contains('stressed é/ó')), isEmpty);

      // Respond answers and checkpoint answers are checked too.
      final respond = await issuesWith('units/a2_u3.json', (d) {
        final acts =
            ((d['lessons'] as List).first as Map)['activities'] as List;
        final r =
            acts.firstWhere((a) => (a as Map)['type'] == 'respond') as Map;
        (r['accepted'] as List).add('Voy al parqué');
      });
      expect(respond, contains(contains('"parqué"')));
      final question = await issuesWith('assessments/a2.json', (d) {
        final chk = (d['assessments'] as List).firstWhere(
          (a) => (a as Map)['id'] == 'chk_a2_u3',
        ) as Map;
        final q = (chk['questions'] as List).firstWhere(
          (q) => (q as Map)['type'] == 'type',
        ) as Map;
        (q['accepted'] as List).add('el plató');
      });
      expect(question, contains(contains('"plató"')));
    });

    test('every shipped final-stress answer word is a verb form', () {
      final issues = ContentValidator().validate(pack);
      expect(issues.where((i) => '$i'.contains('stressed é/ó')), isEmpty);
    });
  });

  group('answer evaluation of future forms', () {
    test('a missing "a" or a conjugated second verb is not accepted', () {
      for (final typed in [
        'Voy revisar el contrato',
        'Voy a reviso el contrato',
        'Va a revisar el contrato',
      ]) {
        expect(
          evaluateAnswer(typed, ['Voy a revisar el contrato']).isCorrect,
          isFalse,
          reason: typed,
        );
      }
      final person = evaluateAnswer('Mañana van a visitar al cliente', [
        'Mañana vamos a visitar al cliente.',
      ]);
      expect(person.isCorrect, isFalse);
      expect(person.bestMatch, 'Mañana vamos a visitar al cliente.');
    });
  });

  group('dialogues', () {
    test('three A2-U3 dialogues, understandable right after their lessons', () {
      final ds = pack.dialogues.where((d) => d.unitId == 'a2_u3').toList();
      expect(ds.map((d) => d.id), [
        'dlg_a2_invitacion',
        'dlg_a2_cita_cliente',
        'dlg_a2_proyecto',
      ]);
      final order = [for (final l in pack.orderedLessons) l.id];
      for (final d in ds) {
        expect(
          d.lessonIds.every((l) => pack.lesson(l)?.unitId == 'a2_u3'),
          isTrue,
        );
        final last = d.lessonIds
            .map(order.indexOf)
            .reduce((a, b) => a > b ? a : b);
        final e = estimateDialogue(
          d,
          LearnerExposure.from(pack, order.take(last + 1)),
        );
        expect(
          e.band,
          isIn([DifficultyBand.veryEasy, DifficultyBand.appropriate]),
          reason: '${d.id}: ${e.reasonsAr}',
        );
      }
    });
  });

  group('checkpoint chk_a2_u3', () {
    late Assessment chk;
    setUp(() => chk = pack.assessment('chk_a2_u3')!);

    test('12 questions, three can-dos, five skills, dialogue sentences', () {
      expect(chk.unitId, 'a2_u3');
      expect(chk.questions.length, 12);
      expect(chk.canDos.length, 3);
      expect(chk.questions.map((q) => q.skill).toSet(), {
        'grammar',
        'listening',
        'reading',
        'writing',
        'vocabulary',
      });
      expect(chk.questions.where((q) => q.dialogueTurnId != null).length, 3);
      for (final q in chk.questions.where((q) => q.skill == 'grammar')) {
        expect(q.explainAr, isNotEmpty, reason: q.id);
      }
    });

    test('grades right and wrong answers; options are shuffled', () {
      final all = gradeAssessment(chk, {
        for (final q in chk.questions) q.id: q.correctAnswer,
      });
      expect(all.every((g) => g.isCorrect), isTrue);
      final wrong = gradeAssessment(chk, {
        for (final q in chk.questions) q.id: q.correctAnswer,
        'chk_a2_u3.q1': 'van',
        'chk_a2_u3.q8': 'la llamada',
      });
      expect(
        wrong.where((g) => !g.isCorrect).map((g) => g.question.id).toSet(),
        {'chk_a2_u3.q1', 'chk_a2_u3.q8'},
      );
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
    });

    test('scores persist across a database reopen', () async {
      final tmp = Directory.systemTemp.createTempSync('espanol_pro_a2u3');
      addTearDown(() => tmp.deleteSync(recursive: true));
      final file = File('${tmp.path}/app.sqlite');
      final clock = FakeClock();
      var db = AppDatabase(NativeDatabase(file));
      final id = await AssessmentRepository(db, clock: clock.call).submit(
        assessment: chk,
        graded: gradeAssessment(chk, {
          for (final q in chk.questions) q.id: q.correctAnswer,
          'chk_a2_u3.q10': 'irá',
        }),
        startedAt: clock(),
        contentVersion: pack.version,
      );
      await db.close();
      db = AppDatabase(NativeDatabase(file));
      final repo = AssessmentRepository(db, clock: clock.call);
      expect((await repo.attempt(id))!.score, chk.questions.length - 1);
      expect((await repo.answers(id)).length, chk.questions.length);
      await db.close();
    });
  });

  testWidgets('a completed A2-U3 lesson schedules FSRS cards for its items', (
    tester,
  ) async {
    final lesson = pack.lesson('a2_u3_l3')!;
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
    final before = (await app.db.select(app.db.reviewCards).get()).length;
    final steps = ExerciseBuilder(pack).buildLesson(lesson);
    await app.pump(tester, location: '/lesson/${lesson.id}');
    await tester.tapKey('start-lesson');
    for (final step in steps) {
      await tester.answer(step);
    }
    await tester.tapKey('finish-lesson');
    final cards = await app.db.select(app.db.reviewCards).get();
    expect(cards.length - before, lesson.items.length * 2);
    await app.dispose(tester);
  });
}

// Renders real app screens to PNG for the review handoff.
//
//   flutter test test_screenshots --update-goldens
//
// Not part of the default `flutter test` run: pixel output differs slightly
// between machines, so these are evidence, not regression gates.
import 'package:espanol_pro/core/assessment/assessment_engine.dart';
import 'package:espanol_pro/core/assessment/assessment_repository.dart';
import 'package:espanol_pro/core/content/models.dart';
import 'package:espanol_pro/core/learning/exercises.dart';
import 'package:espanol_pro/core/learning/progress_repository.dart';
import 'package:espanol_pro/core/phrases/saved_phrases_repository.dart';
import 'package:espanol_pro/core/settings.dart';
import 'package:espanol_pro/core/srs/review_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fsrs/fsrs.dart' as fsrs;
import 'package:material_ui/material_ui.dart';

import '../test/support.dart';
import '../test/widget_support.dart';

void main() {
  late ContentPack pack;
  setUpAll(() async {
    pack = await loadRealContent();
    await loadAppFonts();
  });

  Future<void> shot(WidgetTester tester, String name) => expectLater(
    find.byType(MaterialApp),
    matchesGoldenFile('../docs/screenshots/$name.png'),
  );

  /// A learner three days in: 4 lessons done, some reviews, two mistakes.
  Future<TestApp> seeded() async {
    final app = TestApp(pack);
    final reviews = ReviewRepository(
      app.db,
      clock: app.clock.call,
      enableFuzzing: false,
    );
    final repo = ProgressRepository(app.db, reviews, clock: app.clock.call);
    final builder = ExerciseBuilder(pack);
    app.clock.now = DateTime.utc(2026, 3, 7, 9);
    for (var i = 0; i < 4; i++) {
      final lesson = pack.orderedLessons[i];
      final exercises = builder.buildLesson(lesson).whereType<Exercise>();
      var n = 0;
      for (final ex in exercises) {
        await repo.recordAttempt(
          ex,
          isCorrect: n++ % 6 != 5,
          userAnswer: n % 6 == 0 ? 'ola' : ex.expected,
          context: 'lesson',
          lessonId: lesson.id,
        );
      }
      await repo.completeLesson(
        lesson,
        score: 0.84 + i * 0.04,
        seconds: 600 + i * 90,
        contentVersion: pack.version,
      );
      for (final c in (await reviews.dueCards()).take(9)) {
        await reviews.rate(c.id, fsrs.Rating.good);
      }
      await repo.logStudy(kind: 'review', seconds: 240);
      if (i != 2) app.clock.advance(const Duration(days: 1));
    }
    final phrases = SavedPhrasesRepository(app.db, clock: app.clock.call);
    for (final (es, ar, kind, id, lesson) in [
      ('Mi casa es tu casa.', 'بيتي بيتك.', 'example', 'casa', 'pa1_u1_l1'),
      ('el trabajo', 'العمل', 'vocab', 'el_trabajo', 'pa1_u1_l2'),
      ('Pero / perro', 'لكن / كلب', 'grammar', 'g_letters', null),
    ]) {
      await phrases.save(
        PhraseDraft(
          es: es,
          ar: ar,
          source: PhraseSource(kind: kind, id: id, lessonId: lesson),
        ),
      );
    }
    final first = (await phrases.all()).firstWhere(
      (p) => p.es.startsWith('Mi'),
    );
    await phrases.updateNote(first.id, 'أقولها لضيف يزورني لأول مرة.');
    return app;
  }

  testWidgets('screens', (tester) async {
    var app = TestApp(pack);
    await app.pump(tester);
    await shot(tester, '01_home_new_learner');
    await app.dispose(tester);

    app = await seeded();
    await app.pump(tester);
    await shot(tester, '02_home_in_progress');
    await tester.tapSettled(find.text('المسار'));
    await shot(tester, '03_learning_path');
    await tester.tapSettled(find.text('التدريب'));
    await shot(tester, '04_practice_center');
    await tester.tapSettled(find.text('المكتبة'));
    await shot(tester, '05_library_dictionary');
    await tester.tapSettled(find.text('دفتر الأخطاء'));
    await shot(tester, '06_error_notebook');
    await tester.tapSettled(find.text('عباراتي'));
    await shot(tester, '18_saved_phrases');
    await tester.tapSettled(find.text('التقدّم'));
    await shot(tester, '07_progress');
    await app.dispose(tester);

    // Lesson: intro, teach card, exercises, feedback.
    app = await seeded();
    final lesson = pack.orderedLessons[4];
    final steps = ExerciseBuilder(pack).buildLesson(lesson);
    await app.pump(tester, location: '/lesson/${lesson.id}');
    await shot(tester, '08_lesson_intro');
    await tester.tapKey('start-lesson');
    await shot(tester, '09_lesson_teach_card');
    var i = 0;
    Future<void> advanceTo(bool Function(LessonStep) test) async {
      while (!test(steps[i])) {
        await tester.answer(steps[i++]);
      }
    }

    await advanceTo((s) => s is ChoiceExercise && s.audioEs == null);
    await shot(tester, '10_exercise_choice');
    final choice = steps[i] as ChoiceExercise;
    await tester.tapKey(
      'option-${(choice.correctIndex + 1) % choice.options.length}',
    );
    await tester.tapSettled(find.text('تحقّق'));
    await shot(tester, '11_feedback_incorrect');
    await tester.tapKey('continue-button');
    i++;
    await advanceTo((s) => s is NoteStep);
    await shot(tester, '12_grammar_note');
    await advanceTo((s) => s is MatchExercise);
    await shot(tester, '13_exercise_match');
    await advanceTo((s) => s is OrderExercise);
    await shot(tester, '14_exercise_order');
    await advanceTo((s) => s is TypeExercise);
    await tester.enterText(
      find.byKey(const ValueKey('answer-field')),
      (steps[i] as TypeExercise).accepted.first,
    );
    await tester.pumpAndSettle();
    await tester.tapSettled(find.text('تحقّق'));
    await shot(tester, '15_feedback_correct');
    await tester.tapKey('continue-button');
    i++;
    await app.dispose(tester);

    // Review card with FSRS intervals; dark theme.
    app = await seeded();
    await app.pump(
      tester,
      location: '/review',
      settings: const AppSettings(themeMode: 'dark'),
    );
    final reveal = find.byKey(const ValueKey('review-reveal'));
    if (reveal.evaluate().isNotEmpty) await tester.tapKey('review-reveal');
    await shot(tester, '16_review_dark');
    await app.dispose(tester);

    app = await seeded();
    await app.pump(tester, location: '/settings');
    await shot(tester, '17_settings');
    await app.dispose(tester);

    // Listening library and player, for a learner who finished Pre-A1 and
    // A1-U1 (so every shipped dialogue is open).
    app = await seeded();
    final repo = ProgressRepository(
      app.db,
      ReviewRepository(app.db, clock: app.clock.call, enableFuzzing: false),
      clock: app.clock.call,
    );
    for (final l in pack.orderedLessons) {
      await repo.completeLesson(
        l,
        score: 1,
        seconds: 60,
        contentVersion: pack.version,
      );
    }
    await app.pump(tester, location: '/listening');
    await shot(tester, '19_listening_library');
    await app.pump(tester, location: '/listening/dlg_a1_recepcion');
    await tester.tapKey('toggle-transcript');
    await tester.tapKey('toggle-translation');
    await shot(tester, '20_dialogue_player');

    // A unit checkpoint: one question, then a stored result with a missing
    // accent and one weak can-do.
    final chk = pack.assessment('chk_pa1_u1')!;
    await app.pump(tester, location: '/assessment/${chk.id}');
    await tester.tapKey('assessment-start');
    await tester.tapKey('assessment-play');
    await tester.tapOption(chk.questions.first.correctAnswer);
    await shot(tester, '21_checkpoint_question');
    final answers = {for (final q in chk.questions) q.id: q.correctAnswer}
      ..['chk_pa1_u1.q7'] = 'telefono'
      ..['chk_pa1_u1.q1'] = ''
      ..['chk_pa1_u1.q2'] = '';
    final id = await AssessmentRepository(app.db, clock: app.clock.call).submit(
      assessment: chk,
      graded: gradeAssessment(chk, answers),
      startedAt: app.clock(),
      contentVersion: pack.version,
    );
    await app.pump(tester, location: '/assessment/${chk.id}/result/$id');
    await shot(tester, '22_checkpoint_result');

    // Verb conjugation reference.
    await app.pump(tester, location: '/library');
    await tester.tapSettled(find.text('الأفعال'));
    await tester.tapKey('verb-tener');
    await shot(tester, '23_verb_reference');
    await app.dispose(tester);

    // The B1 gate: every A2 lesson done, lvl_a2 not passed yet.
    app = TestApp(pack);
    final gateRepo = ProgressRepository(
      app.db,
      ReviewRepository(app.db, clock: app.clock.call, enableFuzzing: false),
      clock: app.clock.call,
    );
    for (final l in pack.orderedLessons.takeWhile((l) => l.levelId != 'b1')) {
      await gateRepo.completeLesson(
        l,
        score: 1,
        seconds: 60,
        contentVersion: pack.version,
      );
    }
    await app.pump(tester, location: '/lesson/b1_u1_l1');
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('level-gate-b1')),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await shot(tester, '24_b1_locked_lesson');
    final lvl = pack.levelAssessmentFor('a2')!;
    final passed = await AssessmentRepository(app.db, clock: app.clock.call)
        .submit(
          assessment: lvl,
          graded: gradeAssessment(lvl, {
            for (final q in lvl.questions) q.id: q.correctAnswer,
          }),
          startedAt: app.clock(),
          contentVersion: pack.version,
        );
    await app.pump(tester, location: '/assessment/lvl_a2/result/$passed');
    await shot(tester, '25_b1_opened_result');

    // B1-U2 lesson 68: the long reading text with a Spanish-first prompt.
    for (final l in pack.orderedLessons.where((l) => l.levelId == 'b1')) {
      if (l.id == 'b1_u2_l6') break;
      await gateRepo.completeLesson(
        l,
        score: 1,
        seconds: 60,
        contentVersion: pack.version,
      );
    }
    final l6 = pack.lesson('b1_u2_l6')!;
    final l6Steps = ExerciseBuilder(pack).buildLesson(l6);
    await app.pump(tester, location: '/lesson/${l6.id}');
    await tester.tapKey('start-lesson');
    var k = 0;
    while (!(l6Steps[k] is ChoiceExercise &&
        (l6Steps[k] as ChoiceExercise).promptEs != null)) {
      await tester.answer(l6Steps[k++]);
    }
    await shot(tester, '26_b1_spanish_prompt_reading');
    await app.dispose(tester);
  });
}

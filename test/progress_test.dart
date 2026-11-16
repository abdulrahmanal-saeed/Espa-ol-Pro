import 'package:espanol_pro/core/content/models.dart';
import 'package:espanol_pro/core/db/database.dart';
import 'package:espanol_pro/core/learning/daily_planner.dart';
import 'package:espanol_pro/core/learning/exercises.dart';
import 'package:espanol_pro/core/learning/progress_repository.dart';
import 'package:espanol_pro/core/settings.dart';
import 'package:espanol_pro/core/srs/review_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support.dart';

void main() {
  late ContentPack pack;
  late AppDatabase db;
  late FakeClock clock;
  late ReviewRepository reviews;
  late ProgressRepository repo;

  setUpAll(() async => pack = await loadRealContent());
  setUp(() {
    db = memoryDb();
    clock = FakeClock();
    reviews = ReviewRepository(db, clock: clock.call, enableFuzzing: false);
    repo = ProgressRepository(db, reviews, clock: clock.call);
  });
  tearDown(() => db.close());

  Lesson l(int i) => pack.orderedLessons[i];
  Future<LessonOutcome> complete(Lesson lesson, {double score = 1}) =>
      repo.completeLesson(
        lesson,
        score: score,
        seconds: 300,
        contentVersion: pack.version,
      );

  group('lesson progress', () {
    test('only the first lesson is unlocked for a new learner', () async {
      final map = await repo.lessonProgressMap();
      expect(ProgressRepository.isUnlocked(l(0), map), isTrue);
      for (final lesson in pack.orderedLessons.skip(1)) {
        expect(ProgressRepository.isUnlocked(lesson, map), isFalse);
      }
      expect(ProgressRepository.nextLesson(pack, map)!.id, l(0).id);
    });

    test('starting a lesson does not unlock the next one', () async {
      await repo.markStarted(l(0).id);
      final map = await repo.lessonProgressMap();
      expect(map[l(0).id]!.status, 'started');
      expect(ProgressRepository.isUnlocked(l(1), map), isFalse);
    });

    test('completing a lesson unlocks exactly the next one', () async {
      final outcome = await complete(l(0), score: 0.8);
      expect(outcome.firstCompletion, isTrue);
      expect(outcome.newCards, l(0).items.length * 2);
      final map = await repo.lessonProgressMap();
      expect(ProgressRepository.isCompleted(map[l(0).id]), isTrue);
      expect(ProgressRepository.isUnlocked(l(1), map), isTrue);
      expect(ProgressRepository.isUnlocked(l(2), map), isFalse);
      expect(ProgressRepository.nextLesson(pack, map)!.id, l(1).id);
      expect(map[l(0).id]!.contentVersion, pack.version);
    });

    test('repeating keeps the best score and never duplicates cards', () async {
      await complete(l(0), score: 0.9);
      clock.advance(const Duration(hours: 2));
      final again = await complete(l(0), score: 0.6);
      expect(again.firstCompletion, isFalse);
      expect(again.newCards, 0);
      final row = (await repo.lessonProgressMap())[l(0).id]!;
      expect(row.bestScore, 0.9);
      expect(row.lastScore, 0.6);
      expect(row.completions, 2);
      expect(row.firstCompletedAt, lessThan(row.lastCompletedAt!));
      expect((await reviews.allCards()).length, l(0).items.length * 2);
    });

    test('nextLesson is null once every shipped lesson is done', () async {
      for (final lesson in pack.orderedLessons) {
        await complete(lesson);
      }
      expect(
        ProgressRepository.nextLesson(pack, await repo.lessonProgressMap()),
        isNull,
      );
      expect((await reviews.allCards()).length, pack.allItems.length * 2);
    });
  });

  group('attempts and error notebook', () {
    late List<Exercise> exercises;
    setUp(() {
      exercises = ExerciseBuilder(pack)
          .buildLesson(l(0))
          .whereType<Exercise>()
          .toList();
    });

    test('correct answers create no error record', () async {
      await repo.recordAttempt(
        exercises.first,
        isCorrect: true,
        userAnswer: 'x',
        context: 'lesson',
        lessonId: l(0).id,
      );
      expect(await db.select(db.errorRecords).get(), isEmpty);
      expect(
        (await db.select(db.activityAttempts).get()).single.isCorrect,
        isTrue,
      );
    });

    test(
      'repeated mistakes are counted on one record, then resolved',
      () async {
        final ex = exercises.whereType<TypeExercise>().firstWhere(
          (e) => e.type == 'type_es',
        );
        Future<void> answer(bool ok, String text) => repo.recordAttempt(
          ex,
          isCorrect: ok,
          userAnswer: text,
          context: 'lesson',
          lessonId: l(0).id,
        );

        await answer(false, 'caza');
        clock.advance(const Duration(minutes: 1));
        await answer(false, 'kasa');
        var e = (await db.select(db.errorRecords).get()).single;
        expect(e.count, 2);
        expect(e.incorrect, 'kasa');
        expect(e.correct, ex.expected);
        expect(e.category, 'spelling');
        expect(e.lastSeen, greaterThan(e.firstSeen));
        expect(ProgressRepository.isOpenError(e), isTrue);

        await answer(true, ex.expected);
        e = (await db.select(db.errorRecords).get()).single;
        expect(ProgressRepository.isOpenError(e), isTrue);
        await answer(true, ex.expected);
        e = (await db.select(db.errorRecords).get()).single;
        expect(ProgressRepository.isOpenError(e), isFalse);

        // A new mistake reopens it.
        await answer(false, 'cassa');
        e = (await db.select(db.errorRecords).get()).single;
        expect(e.count, 3);
        expect(ProgressRepository.isOpenError(e), isTrue);
        expect((await repo.openErrors()).length, 1);
      },
    );

    test(
      'self-assessed speaking is never counted as measured accuracy',
      () async {
        final speak = exercises.whereType<SpeakExercise>().first;
        await repo.recordAttempt(
          speak,
          isCorrect: true,
          userAnswer: 'self-practised',
          context: 'lesson',
        );
        final evidence = await repo.skillEvidence();
        expect(evidence.every((e) => e.attempts == 0), isTrue);
        expect(
          (await db.select(db.activityAttempts).get()).single.isMeasured,
          isFalse,
        );
      },
    );

    test('skill evidence aggregates measured attempts per skill', () async {
      final listening = exercises.firstWhere((e) => e.skill == 'listening');
      await repo.recordAttempt(
        listening,
        isCorrect: true,
        userAnswer: 'a',
        context: 'lesson',
      );
      await repo.recordAttempt(
        listening,
        isCorrect: false,
        userAnswer: 'b',
        context: 'lesson',
      );
      final ev = (await repo.skillEvidence()).firstWhere(
        (e) => e.skill == 'listening',
      );
      expect(ev.attempts, 2);
      expect(ev.accuracy, 0.5);
    });

    test('error categories follow what the exercise objectively tested', () {
      for (final ex in exercises.where((e) => e.isMeasured)) {
        expect(const {
          'vocabulary',
          'spelling',
          'word_order',
          'listening',
          'grammar',
          'meaning',
          'communication',
        }, contains(ProgressRepository.errorCategory(ex)));
      }
    });
  });

  group('study time', () {
    test('sessions are bucketed by local day and capped', () async {
      await repo.logStudy(kind: 'lesson', seconds: 600);
      await repo.logStudy(kind: 'review', seconds: 0);
      await repo.logStudy(kind: 'review', seconds: 99999);
      final sessions = await db.select(db.studySessions).get();
      expect(sessions.length, 2);
      expect(sessions.last.seconds, 5400);
      final today = dayKey(clock.now.toLocal());
      expect(ProgressRepository.secondsOn(sessions, today), 6000);
    });

    test(
      'streak counts consecutive days and survives a not-yet-studied today',
      () {
        StudySession s(String day) => StudySession(
          id: 0,
          day: day,
          kind: 'lesson',
          startedAt: 0,
          seconds: 60,
        );
        final now = DateTime(2026, 3, 10, 8);
        expect(ProgressRepository.streak([], now), 0);
        expect(ProgressRepository.streak([s('2026-03-10')], now), 1);
        expect(
          ProgressRepository.streak([
            s('2026-03-09'),
            s('2026-03-08'),
            s('2026-03-07'),
          ], now),
          3,
        );
        expect(
          ProgressRepository.streak([s('2026-03-10'), s('2026-03-08')], now),
          1,
        );
        expect(ProgressRepository.streak([s('2026-03-07')], now), 0);
        // Month boundary.
        expect(
          ProgressRepository.streak([
            s('2026-03-01'),
            s('2026-02-28'),
          ], DateTime(2026, 3, 1, 22)),
          2,
        );
      },
    );
  });

  group('daily planner', () {
    PlannerInput input({
      int minutes = 20,
      int due = 0,
      int reviewedToday = 0,
      bool hasNext = true,
      int lessonsToday = 0,
      int learned = 0,
      int errors = 0,
      Set<String> done = const {},
    }) => PlannerInput(
      dailyMinutes: minutes,
      dueCards: due,
      reviewedToday: reviewedToday,
      nextLesson: hasNext ? l(0) : null,
      lessonsCompletedToday: lessonsToday,
      learnedItems: learned,
      openErrors: errors,
      practiceKindsToday: done,
    );

    test('a brand-new learner just gets the first lesson', () {
      final plan = buildDailyPlan(input());
      expect(plan.map((p) => p.kind), ['lesson']);
      expect(plan.single.route, '/lesson/${l(0).id}');
      expect(plan.single.reasonAr, isNotEmpty);
    });

    test('due reviews always come before new learning', () {
      final plan = buildDailyPlan(input(due: 12, learned: 14));
      expect(plan.first.kind, 'review');
      expect(plan.first.route, '/review');
      expect(plan[1].kind, 'lesson');
    });

    test('session length changes the plan, never the curriculum order', () {
      final quick = buildDailyPlan(input(minutes: 20, due: 40, learned: 30));
      final std = buildDailyPlan(input(minutes: 45, due: 40, learned: 30));
      final intensive = buildDailyPlan(
        input(minutes: 60, due: 40, learned: 30),
      );
      expect(quick.map((p) => p.kind), isNot(contains('writing')));
      expect(std.map((p) => p.kind), contains('writing'));
      expect(intensive.map((p) => p.kind), contains('writing'));
      int review(List<PlanItem> p) => p.first.minutes;
      expect(review(quick), lessThan(review(std)));
      expect(review(std), lessThan(review(intensive)));
      for (final p in [quick, std, intensive]) {
        expect(
          p.firstWhere((i) => i.kind == 'lesson').route,
          '/lesson/${l(0).id}',
        );
      }
    });

    test('remediation appears only with evidence, and explains itself', () {
      expect(
        buildDailyPlan(input(learned: 10, errors: 2)).map((p) => p.kind),
        isNot(contains('errors')),
      );
      final plan = buildDailyPlan(input(learned: 10, errors: 5));
      final item = plan.firstWhere((p) => p.kind == 'errors');
      expect(item.reasonAr, contains('5'));
      expect(item.route, '/practice/errors');
    });

    test('completed blocks are marked done', () {
      final plan = buildDailyPlan(
        input(
          learned: 10,
          lessonsToday: 1,
          reviewedToday: 8,
          done: {'listening'},
        ),
      );
      expect(plan.firstWhere((p) => p.kind == 'review').done, isTrue);
      expect(plan.firstWhere((p) => p.kind == 'lesson').done, isTrue);
      expect(plan.firstWhere((p) => p.kind == 'listening').done, isTrue);
      expect(plan.firstWhere((p) => p.kind == 'pronunciation').done, isFalse);
    });

    test('intensive mode targets two lessons', () {
      final plan = buildDailyPlan(input(minutes: 60, lessonsToday: 1));
      expect(plan.firstWhere((p) => p.kind == 'lesson').done, isFalse);
    });

    test('is deterministic', () {
      String sig() =>
          buildDailyPlan(input(minutes: 45, due: 7, learned: 20, errors: 4))
              .map((p) => '${p.kind}:${p.minutes}:${p.done}')
              .join(',');
      expect(sig(), sig());
    });
  });

  group('settings', () {
    test('round-trip through the database', () async {
      final store = SettingsRepository(db);
      expect((await store.load()).dailyMinutes, 20);
      await store.save(
        const AppSettings(
          dailyMinutes: 60,
          themeMode: 'dark',
          accent: 'es-ES',
          desiredRetention: 0.85,
          showEnglish: true,
          autoPlayAudio: false,
          textScale: 1.2,
        ),
      );
      final s = await store.load();
      expect(s.dailyMinutes, 60);
      expect(s.themeMode, 'dark');
      expect(s.accent, 'es-ES');
      expect(s.desiredRetention, 0.85);
      expect(s.showEnglish, isTrue);
      expect(s.autoPlayAudio, isFalse);
      expect(s.textScale, 1.2);
    });

    test('corrupt values fall back to safe defaults', () {
      final s = AppSettings.fromMap({
        'dailyMinutes': '37',
        'themeMode': 'neon',
        'accent': 'fr-FR',
        'desiredRetention': '0.2',
        'textScale': 'huge',
        'speechRate': '9',
      });
      expect(s.dailyMinutes, 20);
      expect(s.themeMode, 'system');
      expect(s.accent, 'es-MX');
      expect(s.desiredRetention, 0.8);
      expect(s.textScale, 1.0);
      expect(s.speechRate, 0.7);
    });
  });
}

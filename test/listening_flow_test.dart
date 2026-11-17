import 'package:espanol_pro/core/content/models.dart';
import 'package:espanol_pro/core/learning/exercises.dart';
import 'package:espanol_pro/core/learning/progress_repository.dart';
import 'package:espanol_pro/core/srs/review_repository.dart';
import 'package:espanol_pro/core/widgets/common.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;

import 'support.dart';
import 'widget_support.dart';

void main() {
  late ContentPack pack;
  setUpAll(() async {
    pack = await loadRealContent();
    await loadAppFonts();
    tzdata.initializeTimeZones();
  });

  Future<void> complete(TestApp app, Iterable<String> lessonIds) async {
    final repo = ProgressRepository(
      app.db,
      ReviewRepository(app.db, clock: app.clock.call, enableFuzzing: false),
      clock: app.clock.call,
    );
    for (final id in lessonIds) {
      await repo.completeLesson(
        pack.lesson(id)!,
        score: 1,
        seconds: 60,
        contentVersion: pack.version,
      );
    }
  }

  /// Everything up to and including [lessonId], in curriculum order.
  Iterable<String> upTo(String lessonId) sync* {
    for (final l in pack.orderedLessons) {
      yield l.id;
      if (l.id == lessonId) return;
    }
  }

  testWidgets('a dialogue stays locked until its lessons are completed', (
    tester,
  ) async {
    final app = TestApp(pack);
    await app.pump(tester, location: '/listening');
    expect(find.text('مكتبة الاستماع'), findsOneWidget);
    await tester.tapKey('dialogue-dlg_pa1_saludo');
    // Locked: a snackbar names the missing lesson; no navigation.
    expect(find.textContaining('أكمل أولاً'), findsWidgets);
    expect(find.byKey(const ValueKey('play-all')), findsNothing);
    await app.dispose(tester);

    final app2 = TestApp(pack);
    await complete(app2, upTo('pa1_u2_l2'));
    await app2.pump(tester, location: '/listening');
    await tester.tapKey('dialogue-dlg_pa1_saludo');
    expect(find.byKey(const ValueKey('play-all')), findsOneWidget);
    await app2.dispose(tester);
  });

  testWidgets('play, transcript and translation toggles, sentence replay', (
    tester,
  ) async {
    final app = TestApp(pack);
    final d = pack.dialogue('dlg_pa1_saludo')!;
    await complete(app, upTo('pa1_u2_l2'));
    await app.pump(tester, location: '/listening/${d.id}');

    // Listen first: Spanish and Arabic hidden by default.
    expect(find.widgetWithText(EsText, d.turns.first.es), findsNothing);
    expect(find.text(d.turns.first.ar), findsNothing);

    await tester.tapKey('play-all');
    await tester.pumpAndSettle();
    expect(app.speech.spoken, [for (final t in d.turns) t.es]);
    expect(find.text('أعد الحوار'), findsOneWidget);

    await tester.tapKey('toggle-transcript');
    expect(find.widgetWithText(EsText, d.turns.first.es), findsOneWidget);
    expect(find.text(d.turns.first.ar), findsNothing);
    await tester.tapKey('toggle-translation');
    expect(find.text(d.turns.first.ar), findsOneWidget);

    app.speech.spoken.clear();
    await tester.tapKey('replay-2');
    expect(app.speech.spoken, [d.turns[2].es]);

    // Arabic is never sent to the Spanish voice.
    final arabic = RegExp(r'[؀-ۿ]');
    expect(app.speech.spoken.any(arabic.hasMatch), isFalse);
    await app.dispose(tester);
  });

  testWidgets('a dialogue sentence can be saved to «عباراتي»', (tester) async {
    final app = TestApp(pack);
    final d = pack.dialogue('dlg_pa1_saludo')!;
    await complete(app, upTo('pa1_u2_l2'));
    await app.pump(tester, location: '/listening/${d.id}');
    final turn = d.turns.first;
    await tester.tapKey(
      'save-phrase-${turn.es.toLowerCase().replaceAll(RegExp(r'[¿?¡!.,]'), ' ').replaceAll(RegExp(r'\s+'), ' ').trim()}',
    );
    final saved = (await app.db.select(app.db.savedPhrases).get()).single;
    expect(saved.es, turn.es);
    expect(saved.ar, turn.ar);
    expect(saved.sourceKind, 'dialogue');
    expect(saved.sourceId, turn.id);
    await app.dispose(tester);
  });

  testWidgets('without a Spanish voice: clear notice, transcript shown', (
    tester,
  ) async {
    final app = TestApp(pack, voice: false);
    final d = pack.dialogue('dlg_pa1_saludo')!;
    await complete(app, upTo('pa1_u2_l2'));
    await app.pump(tester, location: '/listening/${d.id}');
    await tester.tapKey('play-all');
    expect(
      find.byKey(const ValueKey('no-voice'), skipOffstage: false),
      findsOneWidget,
    );
    expect(find.widgetWithText(EsText, d.turns.first.es), findsOneWidget);
    expect(app.speech.spoken, isEmpty);
    await app.dispose(tester);
  });

  testWidgets(
    'comprehension questions are recorded and complete the dialogue',
    (tester) async {
      final app = TestApp(pack);
      final d = pack.dialogue('dlg_pa1_origen')!;
      await complete(app, upTo('pa1_u3_l3'));
      await app.pump(tester, location: '/listening/${d.id}');
      await tester.tapKey('start-quiz');

      final questions = ExerciseBuilder(pack).buildDialogueQuestions(d);
      // Answer the first one wrong (it comes back once), the rest right.
      for (var i = 0; i < questions.length; i++) {
        await tester.answer(questions[i], correct: i != 0);
      }
      await tester.answer(questions.first);
      expect(find.text('انتهت أسئلة الفهم'), findsOneWidget);
      expect(
        find.textContaining('${questions.length - 1} من ${questions.length}'),
        findsOneWidget,
      );
      expect(find.textContaining('ليس اختباراً لمستواك'), findsOneWidget);

      final attempts = (await app.db.select(app.db.activityAttempts).get())
          .where((a) => a.context == 'listening')
          .toList();
      expect(attempts.length, questions.length + 1);
      expect(attempts.where((a) => a.attemptNumber == 2).length, 1);
      final session = (await app.db.select(app.db.studySessions).get())
          .where((s) => s.kind == 'listening')
          .single;
      expect(session.refId, d.id);

      await tester.tapKey('questions-done');
      GoRouter.of(tester.element(find.byType(Scaffold).first)).go('/listening');
      await tester.pumpAndSettle();
      expect(
        find.textContaining(
          '${questions.length - 1} من ${questions.length} صحيحة',
        ),
        findsOneWidget,
      );
      await app.dispose(tester);
    },
  );

  testWidgets('the library is reachable from the practice centre', (
    tester,
  ) async {
    final app = TestApp(pack);
    await app.pump(tester, location: '/practice');
    await tester.tapKey('practice-listening-library');
    expect(find.text('مكتبة الاستماع'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('dialogue-dlg_a1_recepcion')),
      findsOneWidget,
    );
    await app.dispose(tester);
  });

  testWidgets('no Spanish voice: the text stays readable but comprehension '
      'questions are neither asked nor recorded', (tester) async {
    final app = TestApp(pack, voice: false);
    await complete(app, upTo('pa1_u2_l2'));
    await app.pump(tester, location: '/listening/dlg_pa1_saludo');
    // Known before anything is played; the Spanish text is shown.
    expect(
      find.widgetWithText(
        EsText,
        pack.dialogue('dlg_pa1_saludo')!.turns.first.es,
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('no-voice'), skipOffstage: false),
      findsOneWidget,
    );
    final start = tester.widget<FilledButton>(
      find.byKey(const ValueKey('start-quiz')),
    );
    expect(start.onPressed, isNull);

    // Even reached directly, the questions screen refuses.
    await app.pump(tester, location: '/listening/dlg_pa1_saludo/questions');
    expect(find.byKey(const ValueKey('questions-no-voice')), findsOneWidget);
    expect(
      (await app.db.select(app.db.activityAttempts).get()).where(
        (a) => a.context == 'listening',
      ),
      isEmpty,
    );
    await app.dispose(tester);
  });
}

import 'dart:async';

import 'package:espanol_pro/core/speech/speech_service.dart';
import 'package:espanol_pro/features/listening/dialogue_player.dart';
import 'package:flutter_test/flutter_test.dart';

/// A voice whose utterances finish only when the test says so.
class ControlledSpeech implements SpeechService {
  ControlledSpeech({this.available = true});
  bool available;
  final List<String> started = [];
  final List<double> rates = [];
  int stops = 0;
  Completer<void>? _current;

  /// Finishes the utterance currently being spoken.
  void finish() {
    final c = _current;
    _current = null;
    c?.complete();
  }

  @override
  Future<void> configure({
    required String accent,
    required double rate,
  }) async {}

  @override
  Future<bool> isAvailable() async => available;

  @override
  Future<void> speak(String spanish, {bool slow = false}) async {}

  @override
  Future<void> speakAndWait(String spanish, {double rateFactor = 1.0}) {
    started.add(spanish);
    rates.add(rateFactor);
    final c = Completer<void>();
    _current = c;
    return c.future;
  }

  @override
  Future<void> stop() async {
    stops++;
    // Like the device engine: a stopped utterance completes.
    finish();
  }
}

Future<void> settle() => Future<void>.delayed(Duration.zero);

void main() {
  const turns = ['Hola.', '¿Cómo estás?', 'Bien, gracias.'];
  late ControlledSpeech speech;
  late DialoguePlayer player;

  setUp(() {
    speech = ControlledSpeech();
    player = DialoguePlayer(speech, turns);
  });
  tearDown(() => player.dispose());

  test('play all speaks every turn in order, one at a time', () async {
    final done = player.playAll();
    await settle();
    expect(player.status, PlayerStatus.playing);
    expect(player.current, 0);
    expect(speech.started, ['Hola.']);

    speech.finish();
    await settle();
    expect(player.current, 1, reason: 'the next turn waits for the first');
    expect(speech.started, ['Hola.', '¿Cómo estás?']);

    speech.finish();
    await settle();
    speech.finish();
    await done;
    expect(speech.started, turns);
    expect(player.status, PlayerStatus.finished);
    expect(player.current, isNull);
  });

  test(
    'pause stops the voice and keeps the place; resume restarts that turn',
    () async {
      unawaited(player.playAll());
      await settle();
      speech.finish();
      await settle();
      expect(player.current, 1);

      await player.pause();
      expect(player.status, PlayerStatus.paused);
      expect(player.current, 1);
      expect(speech.stops, 1);
      await settle();
      expect(speech.started.length, 2, reason: 'the stale loop did not go on');

      unawaited(player.resume());
      await settle();
      expect(player.status, PlayerStatus.playing);
      expect(speech.started.last, '¿Cómo estás?', reason: 'turn restarts');
      speech.finish();
      await settle();
      expect(speech.started.last, 'Bien, gracias.');
    },
  );

  test('replaying one turn plays only that turn', () async {
    final done = player.playTurn(2);
    await settle();
    expect(player.current, 2);
    speech.finish();
    await done;
    expect(speech.started, ['Bien, gracias.']);
    expect(player.status, PlayerStatus.idle);
  });

  test('pressing a turn while the dialogue plays takes over cleanly', () async {
    unawaited(player.playAll());
    await settle();
    unawaited(player.playTurn(2));
    await settle();
    // The old loop's utterance was replaced; finishing must not resume it.
    speech.finish();
    await settle();
    await settle();
    expect(speech.started, ['Hola.', 'Bien, gracias.']);
    expect(player.status, PlayerStatus.idle);
  });

  test('stop resets the position', () async {
    unawaited(player.playAll());
    await settle();
    await player.stop();
    await settle();
    expect(player.status, PlayerStatus.idle);
    expect(player.current, isNull);
    expect(speech.started, ['Hola.']);
  });

  test('speed is passed to the voice as a rate factor', () async {
    player.setSpeed(0.6);
    unawaited(player.playTurn(0));
    await settle();
    expect(speech.rates, [0.6]);
  });

  test(
    'without a Spanish voice nothing is spoken and the state says so',
    () async {
      speech.available = false;
      await player.playAll();
      expect(player.status, PlayerStatus.unavailable);
      expect(speech.started, isEmpty);
    },
  );

  test('pause and resume do nothing in the wrong state', () async {
    await player.pause();
    await player.resume();
    expect(player.status, PlayerStatus.idle);
    expect(speech.started, isEmpty);
  });

  test('disposing stops the voice', () async {
    unawaited(player.playAll());
    await settle();
    final p = player;
    player = DialoguePlayer(speech, turns);
    p.dispose();
    expect(speech.stops, 1);
  });
}

import 'package:flutter/foundation.dart';

import '../../core/speech/speech_service.dart';

enum PlayerStatus {
  /// Nothing playing.
  idle,

  /// Speaking [DialoguePlayer.current].
  playing,

  /// Stopped mid-dialogue; [DialoguePlayer.resume] restarts the current turn.
  paused,

  /// The whole dialogue was played to the end.
  finished,

  /// No Spanish voice on the device. Transcript-based study still works.
  unavailable,
}

/// Plays a dialogue one turn at a time through the device voice.
///
/// What it can and cannot do, honestly:
/// - Each turn is spoken as a separate utterance and awaited, so [current]
///   is exactly the turn being spoken: highlighting is per turn, never per
///   word (there is no word-timing data).
/// - Android's speech engine cannot resume mid-sentence reliably, so
///   [pause] stops the current turn and [resume] starts that turn again.
///
/// Every action bumps a generation counter. A playback loop checks it after
/// each utterance, so a stale loop can never move the state after the
/// learner pressed something else.
class DialoguePlayer extends ChangeNotifier {
  DialoguePlayer(this.speech, this.turns);

  final SpeechService speech;

  /// Spanish text of each turn. The only text ever spoken.
  final List<String> turns;

  PlayerStatus status = PlayerStatus.idle;
  int? current;

  /// Multiplies the learner's configured speech rate.
  double speed = 1.0;
  static const speeds = [0.6, 0.8, 1.0];

  bool _single = false;
  int _generation = 0;
  bool _disposed = false;

  void _set(PlayerStatus s, int? i) {
    if (_disposed) return;
    status = s;
    current = i;
    notifyListeners();
  }

  Future<bool> _ready() async {
    if (await speech.isAvailable()) return true;
    _set(PlayerStatus.unavailable, null);
    return false;
  }

  /// Plays from [from] to the end.
  Future<void> playAll({int from = 0}) async {
    final g = ++_generation;
    _single = false;
    if (!await _ready() || g != _generation) return;
    for (var i = from; i < turns.length; i++) {
      _set(PlayerStatus.playing, i);
      await speech.speakAndWait(turns[i], rateFactor: speed);
      if (g != _generation) return;
    }
    _set(PlayerStatus.finished, null);
  }

  /// Plays a single turn (sentence replay).
  Future<void> playTurn(int index) async {
    if (index < 0 || index >= turns.length) return;
    final g = ++_generation;
    _single = true;
    if (!await _ready() || g != _generation) return;
    _set(PlayerStatus.playing, index);
    await speech.speakAndWait(turns[index], rateFactor: speed);
    if (g != _generation) return;
    _set(PlayerStatus.idle, null);
  }

  Future<void> pause() async {
    if (status != PlayerStatus.playing) return;
    ++_generation;
    _set(PlayerStatus.paused, current);
    await speech.stop();
  }

  /// Restarts the turn that was interrupted (see class comment).
  Future<void> resume() async {
    if (status != PlayerStatus.paused || current == null) return;
    final i = current!;
    if (_single) return playTurn(i);
    return playAll(from: i);
  }

  Future<void> stop() async {
    ++_generation;
    _set(PlayerStatus.idle, null);
    await speech.stop();
  }

  void setSpeed(double value) {
    speed = value;
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    ++_generation;
    _disposed = true;
    speech.stop();
    super.dispose();
  }
}

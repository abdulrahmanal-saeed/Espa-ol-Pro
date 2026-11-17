import 'package:flutter_tts/flutter_tts.dart';

/// Spanish audio output.
abstract class SpeechService {
  /// Whether a Spanish voice is usable on this device.
  Future<bool> isAvailable();
  Future<void> configure({required String accent, required double rate});
  Future<void> speak(String spanish, {bool slow = false});

  /// Speaks [spanish] and completes when the utterance has FINISHED (or was
  /// stopped). [rateFactor] scales the configured speech rate. Used to play
  /// dialogues one turn at a time.
  Future<void> speakAndWait(String spanish, {double rateFactor = 1.0});
  Future<void> stop();
}

/// Uses the device text-to-speech engine: works offline once a Spanish voice
/// is installed, costs nothing and sends no data anywhere.
class DeviceTtsSpeech implements SpeechService {
  final FlutterTts _tts = FlutterTts();
  String _accent = 'es-MX';
  double _rate = 0.45;
  bool? _available;
  bool _awaitConfigured = false;

  @override
  Future<void> configure({required String accent, required double rate}) async {
    _accent = accent;
    _rate = rate;
    _available = null;
  }

  @override
  Future<bool> isAvailable() async {
    if (_available != null) return _available!;
    try {
      var ok = await _tts.isLanguageAvailable(_accent) == true;
      if (!ok) {
        // Fall back to any Spanish voice rather than staying silent.
        for (final alt in const ['es-ES', 'es-MX', 'es-US', 'es']) {
          if (await _tts.isLanguageAvailable(alt) == true) {
            _accent = alt;
            ok = true;
            break;
          }
        }
      }
      if (ok) await _tts.setLanguage(_accent);
      _available = ok;
    } catch (_) {
      _available = false;
    }
    return _available!;
  }

  @override
  Future<void> speak(String spanish, {bool slow = false}) async {
    if (!await isAvailable()) return;
    try {
      await _tts.stop();
      await _tts.setSpeechRate(slow ? _rate * 0.6 : _rate);
      await _tts.speak(spanish);
    } catch (_) {
      _available = false;
    }
  }

  @override
  Future<void> speakAndWait(String spanish, {double rateFactor = 1.0}) async {
    if (!await isAvailable()) return;
    try {
      if (!_awaitConfigured) {
        // Makes `speak` complete when the utterance ends (or is stopped).
        await _tts.awaitSpeakCompletion(true);
        _awaitConfigured = true;
      }
      await _tts.stop();
      await _tts.setSpeechRate((_rate * rateFactor).clamp(0.1, 1.0));
      await _tts.speak(spanish);
    } catch (_) {
      _available = false;
    }
  }

  @override
  Future<void> stop() async {
    try {
      await _tts.stop();
    } catch (_) {}
  }
}

/// Test double / silent fallback that records what would have been spoken.
class SilentSpeech implements SpeechService {
  SilentSpeech({this.available = true});
  final bool available;
  final List<String> spoken = [];

  @override
  Future<void> configure({
    required String accent,
    required double rate,
  }) async {}

  @override
  Future<bool> isAvailable() async => available;

  @override
  Future<void> speak(String spanish, {bool slow = false}) async {
    spoken.add(spanish);
  }

  @override
  Future<void> speakAndWait(String spanish, {double rateFactor = 1.0}) async {
    spoken.add(spanish);
  }

  @override
  Future<void> stop() async {}
}

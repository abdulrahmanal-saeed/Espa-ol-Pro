/// Which Spanish sentences were actually spoken, in order.
///
/// Every successful playback through [SpeakButton.play] is recorded. A
/// screen takes a [mark] when it starts and later asks whether a sentence
/// was delivered after that mark. This is what lets listening evidence
/// depend on audio that was really heard, not on a voice that was available
/// when the screen opened.
class SpeechDeliveryLog {
  int _seq = 0;
  final Map<String, int> _last = {};

  /// The current position; deliveries after it count as "since".
  int mark() => _seq;

  void record(String spanish) => _last[spanish] = ++_seq;

  bool deliveredSince(String spanish, int mark) =>
      (_last[spanish] ?? -1) > mark;
}

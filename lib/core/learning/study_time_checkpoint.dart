/// Serialises every write of review study time for one review session.
///
/// Two kinds of write record study time: a rating (which stores the time
/// together with the FSRS update, in one transaction) and a flush (time spent
/// on a card the learner left without rating). Both run strictly one after
/// another through [_tail], and each computes its seconds from [acknowledged]
/// *inside* its turn, so a flush started while a rating is being written can
/// never count the same seconds again.
///
/// [acknowledged] advances only after a write SUCCEEDS. A failed write keeps
/// its seconds pending, and the next flush or rating includes them (retry).
class StudyTimeCheckpoint {
  StudyTimeCheckpoint({required this.writeTime});

  /// Persists [seconds] of study time on their own (no rating).
  final Future<void> Function(int seconds) writeTime;

  /// Seconds of the session already stored in the database.
  int get acknowledged => _acknowledged;
  int _acknowledged = 0;

  Future<void> _tail = Future<void>.value();

  Future<T> _serial<T>(Future<T> Function() op) {
    final result = _tail.then((_) => op());
    // Keep the chain alive after a failure; the caller still sees the error.
    _tail = result.then<void>((_) {}, onError: (Object _) {});
    return result;
  }

  /// Stores time not yet stored, up to [elapsed] seconds of the session.
  /// Throws if the write fails; the seconds then stay pending.
  Future<void> flush(int Function() elapsed) => _serial(() async {
    final upTo = elapsed();
    final pending = upTo - _acknowledged;
    if (pending <= 0) return;
    await writeTime(pending);
    _acknowledged = upTo;
  });

  /// Runs [rate], which must store `activeSeconds` in the same transaction as
  /// the rating. On failure nothing is acknowledged, so no time is lost.
  Future<R> commitWithRating<R>(
    int Function() elapsed,
    Future<R> Function(int activeSeconds) rate,
  ) => _serial(() async {
    final upTo = elapsed();
    final pending = upTo > _acknowledged ? upTo - _acknowledged : 0;
    final result = await rate(pending);
    if (upTo > _acknowledged) _acknowledged = upTo;
    return result;
  });

  /// Completes when every write queued so far has finished.
  Future<void> get idle => _tail;
}

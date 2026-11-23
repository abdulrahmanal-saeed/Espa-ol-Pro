/// Level gates: a level whose content declares `requires_pass` stays locked
/// until the learner has passed that level assessment once.
///
/// Owner decision (PHASE4-001): B1 requires passing `lvl_a2`; A1 → A2 does
/// not require passing `lvl_a1`. The rule lives in `curriculum.json`, so a
/// future level can opt in without code changes.
///
/// No new learner state is stored. The gate is derived from the assessment
/// attempts and answers already kept in SQLite (and already in backups), so
/// restoring a backup restores the gate with it.
library;

import '../assessment/assessment_engine.dart';
import '../content/models.dart';

/// Ids of the assessments with at least one passing attempt
/// (see [CanDoEvidence.passed]). A later failed retry never removes an id.
Set<String> passedAssessmentIds(Iterable<AttemptRecord> attempts) => {
  for (final a in attempts)
    if (CanDoEvidence.passed(a)) a.assessmentId,
};

class LevelGates {
  const LevelGates._(this._required);

  /// Locked level id → the assessment that opens it.
  final Map<String, String> _required;

  /// The gates for [pack] given every stored attempt.
  ///
  /// While attempts are still loading, pass an empty list: gated levels then
  /// read as locked, which is the safe side.
  factory LevelGates.from(ContentPack pack, Iterable<AttemptRecord> attempts) {
    final passed = passedAssessmentIds(attempts);
    return LevelGates._({
      for (final level in pack.levels)
        if (level.requiresPass != null && !passed.contains(level.requiresPass))
          level.id: level.requiresPass!,
    });
  }

  /// Whether lessons of [levelId] may be opened (prerequisites aside).
  bool isOpen(String levelId) => !_required.containsKey(levelId);

  /// The assessment that must be passed to open [levelId], or null when the
  /// level is open.
  String? requiredAssessment(String levelId) => _required[levelId];

  /// Locked level ids, in no particular order.
  Iterable<String> get lockedLevels => _required.keys;
}

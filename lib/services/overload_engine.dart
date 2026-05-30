import '../core/constants/game_balance.dart';
import '../models/exercise_entry.dart';

/// Progressive-overload math: given a successfully cleared exercise, compute the
/// next session's target. Weighted lifts add load; bodyweight movements add reps
/// (rolling reps into an extra set once they pass the threshold).
abstract final class OverloadEngine {
  OverloadEngine._();

  /// Returns a NEW [ExerciseEntry] with progressed targets (input untouched).
  static ExerciseEntry progress(ExerciseEntry entry) {
    final isWeighted = entry.targetWeight != null;

    if (isWeighted) {
      final step =
          entry.overloadStep > 0 ? entry.overloadStep : GameBalance.defaultWeightStep;
      return entry.copyWith(
        targetWeight: (entry.targetWeight ?? 0) + step,
        completed: false,
      );
    }

    // Bodyweight: bump reps, rolling into an extra set past the threshold.
    final nextReps = entry.targetReps + GameBalance.defaultRepStep;
    if (nextReps > GameBalance.repRolloverThreshold) {
      return entry.copyWith(
        targetSets: entry.targetSets + 1,
        targetReps: 8, // reset to a fresh working-rep range
        completed: false,
      );
    }
    return entry.copyWith(targetReps: nextReps, completed: false);
  }

  /// Progress every exercise in a list (used when a whole node is cleared).
  static List<ExerciseEntry> progressAll(List<ExerciseEntry> entries) =>
      entries.map(progress).toList();

  /// Estimated next-session volume for an entry — drives "projected gains" UI.
  static double projectedVolume(ExerciseEntry entry) =>
      progress(entry).volume;
}

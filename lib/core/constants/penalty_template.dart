import '../../models/exercise_entry.dart';
import '../../models/penalty_quest.dart';

/// Generates the System's penalty quests. The checklist intentionally scales
/// with how many mandatory days were missed — skipping more days hurts more.
abstract final class PenaltyTemplate {
  PenaltyTemplate._();

  /// EXP docked per missed mandatory day (negative).
  static const double penaltyPerMissedDay = -50;

  /// Build a single penalty quest covering [missedDays] missed mandatory days,
  /// stamped to [issuedDayKey].
  static PenaltyQuest build({
    required String id,
    required String issuedDayKey,
    required int missedDays,
  }) {
    final factor = missedDays.clamp(1, 5);
    return PenaltyQuest(
      id: id,
      issuedDayKey: issuedDayKey,
      reason: missedDays > 1
          ? 'Missed $missedDays mandatory days'
          : 'Missed a mandatory day',
      penaltyApplied: penaltyPerMissedDay * missedDays,
      exercises: [
        ExerciseEntry(name: 'Burpees', targetSets: 3, targetReps: 10 * factor),
        ExerciseEntry(name: 'Push-ups', targetSets: 3, targetReps: 15 * factor),
        ExerciseEntry(name: 'Squats', targetSets: 3, targetReps: 20 * factor),
        ExerciseEntry(name: 'Plank (sec)', targetSets: 3, targetReps: 30 * factor),
      ],
    );
  }
}

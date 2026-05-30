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
    // Keep penalties humane: fixed, modest rep targets with only a gentle set
    // bump for repeated misses (2 sets for one miss, capped at 4 sets). The EXP
    // dock is likewise capped so a long absence can't nuke a hunter.
    final sets = (1 + missedDays).clamp(2, 4);
    final exp = (penaltyPerMissedDay * missedDays).clamp(-150.0, 0.0);

    return PenaltyQuest(
      id: id,
      issuedDayKey: issuedDayKey,
      reason: missedDays > 1
          ? 'Missed $missedDays mandatory days'
          : 'Missed a mandatory day',
      penaltyApplied: exp,
      exercises: [
        ExerciseEntry(name: 'Burpees', targetSets: sets, targetReps: 8),
        ExerciseEntry(name: 'Push-ups', targetSets: sets, targetReps: 12),
        ExerciseEntry(name: 'Squats', targetSets: sets, targetReps: 15),
        ExerciseEntry(name: 'Plank (sec)', targetSets: sets, targetReps: 30),
      ],
    );
  }
}

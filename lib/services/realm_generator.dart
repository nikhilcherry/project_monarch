import '../core/constants/game_balance.dart';
import '../models/enums.dart';
import '../models/exercise_entry.dart';

/// Builds the workout + rewards for a single level of a Shop Realm gauntlet.
/// Levels scale with both the realm's unlock tier and the level index.
abstract final class RealmGenerator {
  RealmGenerator._();

  static const Map<MuscleGroup, List<String>> _movements = {
    MuscleGroup.chest: ['Push-ups', 'Incline Push-ups', 'Diamond Push-ups'],
    MuscleGroup.back: ['Inverted Rows', 'Supermans', 'Reverse Snow Angels'],
    MuscleGroup.legs: ['Bodyweight Squats', 'Forward Lunges', 'Jump Squats'],
    MuscleGroup.shoulders: ['Pike Push-ups', 'Arm Circles', 'Wall Holds'],
    MuscleGroup.arms: ['Chair Dips', 'Plank Taps', 'Push-up Holds'],
    MuscleGroup.core: ['Plank (sec)', 'Leg Raises', 'Bicycle Crunches'],
    MuscleGroup.cardio: ['High Knees', 'Mountain Climbers', 'Jumping Jacks'],
    MuscleGroup.fullBody: ['Burpees', 'Bear Crawls', 'Push-ups'],
    MuscleGroup.mobility: ['Deep Squat Hold', 'Cat-Cow', 'World\'s Greatest Stretch'],
  };

  static List<ExerciseEntry> exercises(MuscleGroup muscle, int level, int tier) {
    final pool = _movements[muscle] ?? _movements[MuscleGroup.fullBody]!;
    final reps = 8 + (level - 1) + 2 * tier;
    return [
      for (final name in pool)
        ExerciseEntry(name: name, targetSets: 3, targetReps: reps),
    ];
  }

  /// EXP for clearing [level] (1-based) of a realm unlocked at [tier].
  static double levelExp(int tier, int level) =>
      30 * (tier + 1) * (1 + 0.08 * (level - 1));

  static int levelCoins(int tier) => 6 * (tier + 1);

  static Map<StatType, int> levelStats(MuscleGroup muscle) =>
      {GameBalance.primaryStatFor(muscle): 1};
}

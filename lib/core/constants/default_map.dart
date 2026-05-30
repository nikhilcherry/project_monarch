import '../../models/enums.dart';
import '../../models/exercise_entry.dart';
import '../../models/workout_node.dart';

/// The seed campaign map — a branching graph of starter dungeons.
///
/// Coordinates are normalized [0,1]: x spreads the two branches left/right, y
/// climbs from the bottom (start) toward the top (boss). Prerequisites form the
/// edges the map painter draws. Loaded once on first run by the repository.
abstract final class DefaultMap {
  DefaultMap._();

  static List<WorkoutNode> build() => [
        // -- Origin -----------------------------------------------------------
        WorkoutNode(
          id: 'awakening',
          title: 'The Awakening',
          description: 'Your first gate. Prove you belong in the System.',
          difficulty: Rank.e,
          muscleGroup: MuscleGroup.fullBody,
          status: NodeStatus.unlocked, // always open — the entry point
          unlockCost: 0,
          baseExpReward: 60,
          coinReward: 20,
          statRewards: const {StatType.end: 1, StatType.str: 1},
          x: 0.5,
          y: 0.92,
          exercises: [
            ExerciseEntry(name: 'Push-ups', targetSets: 3, targetReps: 10),
            ExerciseEntry(name: 'Bodyweight Squats', targetSets: 3, targetReps: 12),
            ExerciseEntry(name: 'Plank', targetSets: 3, targetReps: 30),
          ],
        ),

        // -- Left branch: Strength -------------------------------------------
        WorkoutNode(
          id: 'iron_path',
          title: 'Iron Path',
          description: 'The road of raw power. STR-focused.',
          difficulty: Rank.e,
          muscleGroup: MuscleGroup.chest,
          unlockCost: 30,
          baseExpReward: 90,
          coinReward: 25,
          statRewards: const {StatType.str: 2},
          prerequisiteIds: const ['awakening'],
          x: 0.28,
          y: 0.70,
          exercises: [
            ExerciseEntry(name: 'Incline Push-ups', targetSets: 4, targetReps: 12),
            ExerciseEntry(name: 'Pike Push-ups', targetSets: 3, targetReps: 8),
          ],
        ),
        WorkoutNode(
          id: 'titans_grip',
          title: "Titan's Grip",
          description: 'Heavy compound work. Forge an unbreakable frame.',
          difficulty: Rank.d,
          muscleGroup: MuscleGroup.back,
          unlockCost: 60,
          baseExpReward: 140,
          coinReward: 35,
          statRewards: const {StatType.str: 3, StatType.end: 1},
          prerequisiteIds: const ['iron_path'],
          x: 0.20,
          y: 0.46,
          exercises: [
            ExerciseEntry(name: 'Pull-ups', targetSets: 4, targetReps: 6),
            ExerciseEntry(name: 'Dips', targetSets: 4, targetReps: 8),
          ],
        ),

        // -- Right branch: Agility / Endurance -------------------------------
        WorkoutNode(
          id: 'swift_wind',
          title: 'Swift Wind',
          description: 'Footwork and speed. AGI-focused.',
          difficulty: Rank.e,
          muscleGroup: MuscleGroup.cardio,
          unlockCost: 30,
          baseExpReward: 90,
          coinReward: 25,
          statRewards: const {StatType.agi: 2},
          prerequisiteIds: const ['awakening'],
          x: 0.72,
          y: 0.70,
          exercises: [
            ExerciseEntry(name: 'High Knees', targetSets: 4, targetReps: 30),
            ExerciseEntry(name: 'Burpees', targetSets: 3, targetReps: 10),
          ],
        ),
        WorkoutNode(
          id: 'endless_road',
          title: 'Endless Road',
          description: 'Stamina trial. Outlast the System.',
          difficulty: Rank.d,
          muscleGroup: MuscleGroup.legs,
          unlockCost: 60,
          baseExpReward: 140,
          coinReward: 35,
          statRewards: const {StatType.end: 3, StatType.agi: 1},
          prerequisiteIds: const ['swift_wind'],
          x: 0.80,
          y: 0.46,
          exercises: [
            ExerciseEntry(name: 'Lunges', targetSets: 4, targetReps: 16),
            ExerciseEntry(name: 'Jump Squats', targetSets: 4, targetReps: 12),
          ],
        ),

        // -- Convergence: Mobility -------------------------------------------
        WorkoutNode(
          id: 'serpents_coil',
          title: "Serpent's Coil",
          description: 'Mobility and flexibility crucible.',
          difficulty: Rank.c,
          muscleGroup: MuscleGroup.mobility,
          unlockCost: 100,
          baseExpReward: 200,
          coinReward: 50,
          statRewards: const {StatType.flex: 4},
          prerequisiteIds: const ['titans_grip', 'endless_road'],
          x: 0.5,
          y: 0.26,
          exercises: [
            ExerciseEntry(name: 'Deep Squat Hold', targetSets: 3, targetReps: 45),
            ExerciseEntry(name: 'Jefferson Curl', targetSets: 3, targetReps: 8),
          ],
        ),

        // -- Boss ------------------------------------------------------------
        WorkoutNode(
          id: 'monarch_gate',
          title: 'Monarch Gate',
          description: 'The first true boss. All paths converge here.',
          difficulty: Rank.b,
          muscleGroup: MuscleGroup.fullBody,
          unlockCost: 200,
          baseExpReward: 400,
          coinReward: 120,
          statRewards: const {
            StatType.str: 2,
            StatType.agi: 2,
            StatType.vit: 2,
            StatType.end: 2,
            StatType.flex: 2,
          },
          prerequisiteIds: const ['serpents_coil'],
          x: 0.5,
          y: 0.07,
          exercises: [
            ExerciseEntry(name: 'Muscle-ups', targetSets: 3, targetReps: 4),
            ExerciseEntry(name: 'Pistol Squats', targetSets: 3, targetReps: 6),
            ExerciseEntry(name: 'Handstand Hold', targetSets: 3, targetReps: 20),
          ],
        ),
      ];
}

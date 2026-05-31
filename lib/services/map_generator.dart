import '../models/enums.dart';
import '../models/exercise_entry.dart';
import '../models/workout_node.dart';

/// Procedurally builds a rank's World Map region: 4 branching paths, each
/// `depth = 5 + 2·tier` nodes deep, converging on a capstone Rank Gate.
/// See docs/GAME_DESIGN_V2.md §1–2. Names are always written in full.
abstract final class MapGenerator {
  MapGenerator._();

  static const List<String> pathNames = [
    'Trail of the Steadfast', // Path I  — endurance
    'Road of the Tempest', // Path II — agility
    'Climb of the Titan', // Path III — strength
    'Ascent of the Monarch', // Path IV — elite / mixed
  ];

  static const List<double> _pathMult = [1.0, 1.5, 2.0, 3.0];
  static const List<MuscleGroup> _pathMuscle = [
    MuscleGroup.cardio,
    MuscleGroup.legs,
    MuscleGroup.back,
    MuscleGroup.fullBody,
  ];

  /// Map depth for a rank tier (E=0 → 5, D=1 → 7, … +2 per rank).
  static int depthForTier(int tier) => 5 + 2 * tier;

  /// Build the full set of nodes for [rank]'s region.
  static List<WorkoutNode> generateRegion(Rank rank) {
    final t = rank.tier;
    final r = t + 1; // rank factor R
    final depth = depthForTier(t);
    final nodes = <WorkoutNode>[];
    final deepestIds = <String>[];

    for (var p = 0; p < 4; p++) {
      final mult = _pathMult[p];
      final muscle = _pathMuscle[p];
      final x = 0.18 + p * 0.21; // 4 columns across the canvas
      String? prevId;

      for (var d = 1; d <= depth; d++) {
        final id = 'r${t}_p${p}_d$d';
        final y = depth == 1
            ? 0.5
            : 0.90 - (d - 1) * ((0.90 - 0.20) / (depth - 1));

        nodes.add(
          WorkoutNode(
            id: id,
            title: '${pathNames[p]} — Stage $d',
            description: '${rank.label} · ${pathNames[p]}.',
            difficulty: rank,
            muscleGroup: muscle,
            status: d == 1 ? NodeStatus.unlockable : NodeStatus.locked,
            unlockCost: (10 * r * mult).round(),
            baseExpReward: 40 * r * (1 + 0.12 * (d - 1)) * mult,
            coinReward: (8 * r * mult).round(),
            statRewards: _statRewardsFor(p),
            exercises: _exercisesFor(muscle, d, t, gate: false),
            prerequisiteIds: prevId == null ? const [] : [prevId],
            x: x,
            y: y,
            pathIndex: p,
            depth: d,
          ),
        );
        prevId = id;
      }
      deepestIds.add('r${t}_p${p}_d$depth');
    }

    // Capstone Rank Gate — unlocks when ANY one path's deepest node is cleared.
    nodes.add(
      WorkoutNode(
        id: 'r${t}_gate',
        title: '${rank.label} Gate',
        description:
            'The capstone of this region. Clear any path to challenge it.',
        difficulty: rank,
        muscleGroup: MuscleGroup.fullBody,
        status: NodeStatus.locked,
        unlockCost: (10 * r * 3.0).round(),
        baseExpReward: 200.0 * r,
        coinReward: 40 * r,
        statRewards: const {
          StatType.str: 2,
          StatType.agi: 2,
          StatType.vit: 2,
          StatType.end: 2,
          StatType.flex: 2,
        },
        exercises: _exercisesFor(MuscleGroup.fullBody, depth, t, gate: true),
        prerequisiteIds: deepestIds,
        x: 0.5,
        y: 0.06,
        pathIndex: -1,
        depth: depth + 1,
        isGate: true,
      ),
    );

    return nodes;
  }

  static Map<StatType, int> _statRewardsFor(int pathIndex) => switch (pathIndex) {
        0 => const {StatType.end: 1},
        1 => const {StatType.agi: 1},
        2 => const {StatType.str: 1},
        _ => const {StatType.str: 1, StatType.end: 1},
      };

  static const Map<MuscleGroup, List<String>> _movements = {
    MuscleGroup.cardio: ['High Knees', 'Mountain Climbers', 'Jumping Jacks'],
    MuscleGroup.legs: ['Bodyweight Squats', 'Forward Lunges', 'Jump Squats'],
    MuscleGroup.back: ['Inverted Rows', 'Supermans', 'Reverse Snow Angels'],
    MuscleGroup.fullBody: ['Burpees', 'Bear Crawls', 'Push-ups'],
  };

  static List<ExerciseEntry> _exercisesFor(
    MuscleGroup muscle,
    int depth,
    int tier, {
    required bool gate,
  }) {
    final pool = _movements[muscle] ?? _movements[MuscleGroup.fullBody]!;
    final sets = gate ? 4 : 3;
    final baseReps = (gate ? 10 : 8) + (depth - 1) + 2 * tier;
    return [
      for (final name in pool)
        ExerciseEntry(name: name, targetSets: sets, targetReps: baseReps),
    ];
  }
}

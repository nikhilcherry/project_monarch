import 'package:hive/hive.dart';

import 'enums.dart';
import 'exercise_entry.dart';

part 'workout_node.g.dart';

/// A node on the branching world map — a single "dungeon" / workout the hunter
/// can unlock with coins and clear for EXP, stat points and coin rewards.
///
/// The map is a directed graph: [prerequisiteIds] define edges, and
/// [x]/[y] are normalized [0,1] coordinates for laying the node out on the
/// campaign canvas (Phase 5).
@HiveType(typeId: 3)
class WorkoutNode extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  String description;

  /// Difficulty tier — gates which rank can reasonably attempt it.
  @HiveField(3)
  Rank difficulty;

  @HiveField(4)
  MuscleGroup muscleGroup;

  @HiveField(5)
  NodeStatus status;

  /// Coin price to unlock this node.
  @HiveField(6)
  int unlockCost;

  /// Base EXP granted on clear (scaled by the math engine).
  @HiveField(7)
  double baseExpReward;

  /// Coins granted on clear.
  @HiveField(8)
  int coinReward;

  /// Stat points awarded on clear, keyed by [StatType].
  @HiveField(9)
  Map<StatType, int> statRewards;

  /// The exercise checklist for this node.
  @HiveField(10)
  List<ExerciseEntry> exercises;

  /// IDs of nodes that must be completed before this unlocks.
  @HiveField(11)
  List<String> prerequisiteIds;

  /// Normalized map coordinates [0,1].
  @HiveField(12)
  double x;

  @HiveField(13)
  double y;

  /// Times this node has been cleared (for progressive overload scaling).
  @HiveField(14)
  int clearCount;

  /// Which branch (Path) this node belongs to: 0=I, 1=II, 2=III, 3=IV.
  /// -1 for the Rank Gate (it belongs to no single path).
  @HiveField(15)
  int pathIndex;

  /// 1-based depth of this node along its path (1 = hub-adjacent entry).
  @HiveField(16)
  int depth;

  /// True for the region's capstone Rank Gate. Gates unlock when ANY one of
  /// their [prerequisiteIds] is cleared (OR), unlike normal nodes (AND).
  @HiveField(17)
  bool isGate;

  /// Fog of War: whether this node has been revealed. Only depth-1 entries are
  /// revealed at region start; clearing a node reveals its direct successors.
  @HiveField(18)
  bool revealed;

  WorkoutNode({
    required this.id,
    required this.title,
    this.description = '',
    this.difficulty = Rank.e,
    this.muscleGroup = MuscleGroup.fullBody,
    this.status = NodeStatus.locked,
    this.unlockCost = 0,
    this.baseExpReward = 50,
    this.coinReward = 10,
    Map<StatType, int>? statRewards,
    List<ExerciseEntry>? exercises,
    List<String>? prerequisiteIds,
    this.x = 0.5,
    this.y = 0.5,
    this.clearCount = 0,
    this.pathIndex = 0,
    this.depth = 1,
    this.isGate = false,
    this.revealed = false,
  })  : statRewards = statRewards ?? const {},
        exercises = exercises ?? [],
        prerequisiteIds = prerequisiteIds ?? const [];

  bool get isCompleted => status == NodeStatus.completed;

  /// True once every exercise in the checklist is ticked.
  bool get allExercisesDone =>
      exercises.isNotEmpty && exercises.every((e) => e.completed);

  /// Reset all exercise checkmarks (e.g. when starting a fresh attempt).
  void resetChecklist() {
    for (final e in exercises) {
      e.completed = false;
    }
  }

  WorkoutNode copyWith({
    String? id,
    String? title,
    String? description,
    Rank? difficulty,
    MuscleGroup? muscleGroup,
    NodeStatus? status,
    int? unlockCost,
    double? baseExpReward,
    int? coinReward,
    Map<StatType, int>? statRewards,
    List<ExerciseEntry>? exercises,
    List<String>? prerequisiteIds,
    double? x,
    double? y,
    int? clearCount,
    int? pathIndex,
    int? depth,
    bool? isGate,
    bool? revealed,
  }) =>
      WorkoutNode(
        id: id ?? this.id,
        title: title ?? this.title,
        description: description ?? this.description,
        difficulty: difficulty ?? this.difficulty,
        muscleGroup: muscleGroup ?? this.muscleGroup,
        status: status ?? this.status,
        unlockCost: unlockCost ?? this.unlockCost,
        baseExpReward: baseExpReward ?? this.baseExpReward,
        coinReward: coinReward ?? this.coinReward,
        statRewards: statRewards ?? this.statRewards,
        exercises: exercises ?? this.exercises,
        prerequisiteIds: prerequisiteIds ?? this.prerequisiteIds,
        x: x ?? this.x,
        y: y ?? this.y,
        clearCount: clearCount ?? this.clearCount,
        pathIndex: pathIndex ?? this.pathIndex,
        depth: depth ?? this.depth,
        isGate: isGate ?? this.isGate,
        revealed: revealed ?? this.revealed,
      );

  @override
  String toString() =>
      'WorkoutNode($id "$title" ${difficulty.label} ${status.name})';
}

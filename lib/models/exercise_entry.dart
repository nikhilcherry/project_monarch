import 'package:hive/hive.dart';

part 'exercise_entry.g.dart';

/// A single exercise inside a workout node's checklist.
///
/// Stores the progressive-overload target (sets × reps, optional weight). The
/// math engine reads `targetSets/targetReps` to compute volume and award EXP;
/// `completed` is toggled from the Active Workout checklist UI (Phase 5).
@HiveType(typeId: 4)
class ExerciseEntry extends HiveObject {
  @HiveField(0)
  String name;

  @HiveField(1)
  int targetSets;

  @HiveField(2)
  int targetReps;

  /// Optional load in kg; `null` for bodyweight movements.
  @HiveField(3)
  double? targetWeight;

  /// Rest between sets, seconds (UI timer hint).
  @HiveField(4)
  int restSeconds;

  @HiveField(5)
  bool completed;

  /// Progressive-overload step applied per clear (kg or reps depending on type).
  @HiveField(6)
  double overloadStep;

  ExerciseEntry({
    required this.name,
    this.targetSets = 3,
    this.targetReps = 10,
    this.targetWeight,
    this.restSeconds = 60,
    this.completed = false,
    this.overloadStep = 2.5,
  });

  /// Total prescribed reps (sets × reps) — base unit for volume/EXP math.
  int get totalReps => targetSets * targetReps;

  /// Volume = total reps × load (bodyweight treated as 1 for relative volume).
  double get volume => totalReps * (targetWeight ?? 1);

  ExerciseEntry copyWith({
    String? name,
    int? targetSets,
    int? targetReps,
    double? targetWeight,
    int? restSeconds,
    bool? completed,
    double? overloadStep,
  }) =>
      ExerciseEntry(
        name: name ?? this.name,
        targetSets: targetSets ?? this.targetSets,
        targetReps: targetReps ?? this.targetReps,
        targetWeight: targetWeight ?? this.targetWeight,
        restSeconds: restSeconds ?? this.restSeconds,
        completed: completed ?? this.completed,
        overloadStep: overloadStep ?? this.overloadStep,
      );

  @override
  String toString() => 'ExerciseEntry($name ${targetSets}x$targetReps'
      '${targetWeight != null ? ' @${targetWeight}kg' : ''})';
}

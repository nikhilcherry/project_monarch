import 'package:hive/hive.dart';

import 'exercise_entry.dart';

part 'penalty_quest.g.dart';

/// A punishing quest the System issues when a mandatory training day is missed.
///
/// Until it's resolved (cleared), it nags from the dashboard. Clearing it is the
/// path to redemption; the EXP penalty for the missed day is applied once at
/// issue time (see the daily controller), so this is the "work it off" task.
@HiveType(typeId: 8)
class PenaltyQuest extends HiveObject {
  @HiveField(0)
  String id;

  /// The day-key (yyyy-MM-dd) that triggered this penalty.
  @HiveField(1)
  String issuedDayKey;

  /// Human-readable reason, e.g. "Missed mandatory day".
  @HiveField(2)
  String reason;

  /// The redemption checklist.
  @HiveField(3)
  List<ExerciseEntry> exercises;

  /// EXP penalty that was applied when this quest was issued (negative).
  @HiveField(4)
  double penaltyApplied;

  @HiveField(5)
  bool resolved;

  PenaltyQuest({
    required this.id,
    required this.issuedDayKey,
    this.reason = 'Missed mandatory day',
    List<ExerciseEntry>? exercises,
    this.penaltyApplied = 0,
    this.resolved = false,
  }) : exercises = exercises ?? [];

  PenaltyQuest copyWith({
    String? id,
    String? issuedDayKey,
    String? reason,
    List<ExerciseEntry>? exercises,
    double? penaltyApplied,
    bool? resolved,
  }) =>
      PenaltyQuest(
        id: id ?? this.id,
        issuedDayKey: issuedDayKey ?? this.issuedDayKey,
        reason: reason ?? this.reason,
        exercises: exercises ?? this.exercises,
        penaltyApplied: penaltyApplied ?? this.penaltyApplied,
        resolved: resolved ?? this.resolved,
      );

  @override
  String toString() =>
      'PenaltyQuest($id $issuedDayKey resolved:$resolved)';
}

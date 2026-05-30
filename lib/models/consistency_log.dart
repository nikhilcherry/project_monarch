import 'package:hive/hive.dart';

import 'enums.dart';

part 'consistency_log.g.dart';

/// One day's entry in the 365-day consistency heatmap.
///
/// Keyed in its box by [dayKey] (yyyy-MM-dd). [intensity] (0–4) maps directly to
/// heatmap glow levels; [outcome] carries the semantic meaning (rest vs penalty
/// vs complete) so the dashboard can color/annotate cells precisely.
@HiveType(typeId: 6)
class ConsistencyLog extends HiveObject {
  /// yyyy-MM-dd — also this entry's key in the Hive box.
  @HiveField(0)
  String dayKey;

  @HiveField(1)
  DayOutcome outcome;

  /// Heatmap glow level 0–4 (0 = empty, 4 = fully cleared day).
  @HiveField(2)
  int intensity;

  /// Total EXP earned that day (for stats/tooltips).
  @HiveField(3)
  double expEarned;

  /// Number of quests/nodes cleared that day.
  @HiveField(4)
  int questsCleared;

  /// Whether a penalty quest was issued for missing a mandatory day.
  @HiveField(5)
  bool penaltyIssued;

  ConsistencyLog({
    required this.dayKey,
    this.outcome = DayOutcome.none,
    this.intensity = 0,
    this.expEarned = 0,
    this.questsCleared = 0,
    this.penaltyIssued = false,
  });

  ConsistencyLog copyWith({
    String? dayKey,
    DayOutcome? outcome,
    int? intensity,
    double? expEarned,
    int? questsCleared,
    bool? penaltyIssued,
  }) =>
      ConsistencyLog(
        dayKey: dayKey ?? this.dayKey,
        outcome: outcome ?? this.outcome,
        intensity: intensity ?? this.intensity,
        expEarned: expEarned ?? this.expEarned,
        questsCleared: questsCleared ?? this.questsCleared,
        penaltyIssued: penaltyIssued ?? this.penaltyIssued,
      );

  @override
  String toString() =>
      'ConsistencyLog($dayKey ${outcome.name} lvl:$intensity)';
}

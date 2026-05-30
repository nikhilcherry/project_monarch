import 'package:hive/hive.dart';

part 'enums.g.dart';

/// Hunter rank tiers, ascending. Drives the exponential EXP curve
/// (see Phase 4 math engine) and gates world-map difficulty.
@HiveType(typeId: 20)
enum Rank {
  @HiveField(0)
  e,
  @HiveField(1)
  d,
  @HiveField(2)
  c,
  @HiveField(3)
  b,
  @HiveField(4)
  a,
  @HiveField(5)
  s,
  @HiveField(6)
  ss,
  @HiveField(7)
  sss,
  @HiveField(8)
  national; // The apex — "National Level Hunter".

  /// Display label, e.g. "E-Rank", "SSS-Rank", "NATIONAL".
  String get label => switch (this) {
        Rank.national => 'NATIONAL',
        _ => '${name.toUpperCase()}-Rank',
      };

  /// Zero-based ladder index, used by the EXP scaling formula.
  int get tier => index;

  /// Next rank up, or `null` if already at the apex.
  Rank? get next =>
      index < Rank.values.length - 1 ? Rank.values[index + 1] : null;
}

/// The five tracked attributes shown on the pentagon radar chart.
@HiveType(typeId: 21)
enum StatType {
  @HiveField(0)
  str, // Strength
  @HiveField(1)
  agi, // Agility
  @HiveField(2)
  vit, // Vitality
  @HiveField(3)
  end, // Endurance
  @HiveField(4)
  flex; // Flexibility

  String get short => name.toUpperCase();

  String get label => switch (this) {
        StatType.str => 'Strength',
        StatType.agi => 'Agility',
        StatType.vit => 'Vitality',
        StatType.end => 'Endurance',
        StatType.flex => 'Flexibility',
      };
}

/// Lifecycle of a node on the branching world map.
@HiveType(typeId: 22)
enum NodeStatus {
  /// Hidden/greyed — prerequisites unmet.
  @HiveField(0)
  locked,

  /// Prerequisites met, purchasable with coins.
  @HiveField(1)
  unlockable,

  /// Bought and currently selectable as today's quest.
  @HiveField(2)
  unlocked,

  /// Cleared at least once.
  @HiveField(3)
  completed;

  bool get isPlayable => this == NodeStatus.unlocked || this == NodeStatus.completed;
}

/// Primary muscle group a node/exercise targets — informs which stat it feeds.
@HiveType(typeId: 23)
enum MuscleGroup {
  @HiveField(0)
  chest,
  @HiveField(1)
  back,
  @HiveField(2)
  legs,
  @HiveField(3)
  shoulders,
  @HiveField(4)
  arms,
  @HiveField(5)
  core,
  @HiveField(6)
  fullBody,
  @HiveField(7)
  mobility,
  @HiveField(8)
  cardio;

  String get label => switch (this) {
        MuscleGroup.fullBody => 'Full Body',
        _ => name[0].toUpperCase() + name.substring(1),
      };
}

/// Categories for manual VIT wellness habits.
@HiveType(typeId: 24)
enum HabitCategory {
  @HiveField(0)
  recovery, // sleep, stretching
  @HiveField(1)
  mindfulness, // meditation, digital detox
  @HiveField(2)
  hydration,
  @HiveField(3)
  nutrition,
  @HiveField(4)
  discipline; // wake time, cold shower

  String get label => name[0].toUpperCase() + name.substring(1);
}

/// How a day scored on the consistency heatmap.
@HiveType(typeId: 25)
enum DayOutcome {
  @HiveField(0)
  none, // nothing logged
  @HiveField(1)
  rest, // configured rest day (neutral)
  @HiveField(2)
  partial, // some quests done
  @HiveField(3)
  complete, // all mandatory quests cleared
  @HiveField(4)
  penalty; // failed mandatory day → penalty quest issued
}

import 'package:hive/hive.dart';

import 'enums.dart';

part 'user_stats.g.dart';

/// The hunter's five core attributes (the radar chart values).
///
/// Stats are stored as raw points; the radar chart normalizes them for display.
/// Mutation always goes through the math engine (Phase 4) → repository so the
/// values stay the single offline source of truth.
@HiveType(typeId: 1)
class UserStats extends HiveObject {
  @HiveField(0)
  int str;

  @HiveField(1)
  int agi;

  @HiveField(2)
  int vit;

  @HiveField(3)
  int end;

  @HiveField(4)
  int flex;

  UserStats({
    this.str = 0,
    this.agi = 0,
    this.vit = 0,
    this.end = 0,
    this.flex = 0,
  });

  /// A fresh hunter starts every attribute at the floor value.
  factory UserStats.initial({int floor = 10}) => UserStats(
        str: floor,
        agi: floor,
        vit: floor,
        end: floor,
        flex: floor,
      );

  /// Read a single attribute by its [StatType].
  int valueOf(StatType type) => switch (type) {
        StatType.str => str,
        StatType.agi => agi,
        StatType.vit => vit,
        StatType.end => end,
        StatType.flex => flex,
      };

  /// Add [amount] to the attribute identified by [type].
  void add(StatType type, int amount) {
    switch (type) {
      case StatType.str:
        str += amount;
      case StatType.agi:
        agi += amount;
      case StatType.vit:
        vit += amount;
      case StatType.end:
        end += amount;
      case StatType.flex:
        flex += amount;
    }
  }

  /// Apply a batch of stat rewards (e.g. on quest completion).
  void applyRewards(Map<StatType, int> rewards) {
    rewards.forEach(add);
  }

  /// Sum of all attributes — a quick "power level" proxy.
  int get total => str + agi + vit + end + flex;

  /// Immutable snapshot as a map, handy for the radar chart + serialization.
  Map<StatType, int> toMap() => {
        StatType.str: str,
        StatType.agi: agi,
        StatType.vit: vit,
        StatType.end: end,
        StatType.flex: flex,
      };

  UserStats copyWith({
    int? str,
    int? agi,
    int? vit,
    int? end,
    int? flex,
  }) =>
      UserStats(
        str: str ?? this.str,
        agi: agi ?? this.agi,
        vit: vit ?? this.vit,
        end: end ?? this.end,
        flex: flex ?? this.flex,
      );

  @override
  String toString() =>
      'UserStats(STR:$str AGI:$agi VIT:$vit END:$end FLEX:$flex)';
}

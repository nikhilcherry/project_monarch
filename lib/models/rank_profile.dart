import 'package:hive/hive.dart';

import 'enums.dart';

part 'rank_profile.g.dart';

/// The hunter's progression wallet: current rank, EXP within the rank, lifetime
/// EXP, level, and the in-game coin balance used for world-map progression.
///
/// All EXP math (threshold for next rank, overflow handling, level-ups) lives in
/// the Phase 4 math engine; this model only *holds* state and exposes cheap,
/// derived getters. The engine writes back through the repository.
@HiveType(typeId: 2)
class RankProfile extends HiveObject {
  @HiveField(0)
  Rank rank;

  /// EXP accumulated toward the next rank threshold.
  @HiveField(1)
  double currentExp;

  /// Lifetime EXP earned — never decreases.
  @HiveField(2)
  double lifetimeExp;

  /// Numeric level within/across ranks (cosmetic + scaling input).
  @HiveField(3)
  int level;

  /// Spendable in-game currency for unlocking map nodes & cosmetics.
  @HiveField(4)
  int coins;

  /// Cached threshold to reach the next rank, computed by the math engine and
  /// stored so the UI can render the progress bar without recomputing.
  @HiveField(5)
  double expToNextRank;

  RankProfile({
    this.rank = Rank.e,
    this.currentExp = 0,
    this.lifetimeExp = 0,
    this.level = 1,
    this.coins = 0,
    this.expToNextRank = 100,
  });

  factory RankProfile.initial() => RankProfile();

  /// Fraction [0,1] of the current rank completed — drives the EXP bar.
  double get rankProgress {
    if (expToNextRank <= 0) return 1;
    return (currentExp / expToNextRank).clamp(0.0, 1.0);
  }

  bool get isMaxRank => rank.next == null;

  RankProfile copyWith({
    Rank? rank,
    double? currentExp,
    double? lifetimeExp,
    int? level,
    int? coins,
    double? expToNextRank,
  }) =>
      RankProfile(
        rank: rank ?? this.rank,
        currentExp: currentExp ?? this.currentExp,
        lifetimeExp: lifetimeExp ?? this.lifetimeExp,
        level: level ?? this.level,
        coins: coins ?? this.coins,
        expToNextRank: expToNextRank ?? this.expToNextRank,
      );

  @override
  String toString() =>
      'RankProfile(${rank.label} Lv$level | EXP ${currentExp.toStringAsFixed(0)}/'
      '${expToNextRank.toStringAsFixed(0)} | coins:$coins)';
}

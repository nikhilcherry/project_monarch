import '../../models/enums.dart';

/// Single source of truth for all gameplay tuning numbers.
///
/// Keeping every magic constant here (instead of scattered in engines) means
/// balancing the whole game is a one-file edit, and the Python reference script
/// (`scripts/math_engine.py`) mirrors these exact values for offline tuning.
abstract final class GameBalance {
  GameBalance._();

  // ---------------------------------------------------------------------------
  // EXP / Rank curve  —  threshold(rank) = baseExp * (tier+1)^rankExponent
  // ---------------------------------------------------------------------------

  /// EXP required to clear the very first rank band.
  static const double baseExp = 100;

  /// Exponent driving exponential rank scaling. >1 makes each rank notably
  /// harder than the last (the "punishing" curve).
  static const double rankExponent = 1.8;

  /// Per-level multiplier applied on top of the rank threshold. Each level
  /// within a rank costs a little more than the previous one.
  static const double levelGrowth = 1.12;

  /// How many levels make up a single rank band before rank-up is allowed.
  static const int levelsPerRank = 10;

  // ---------------------------------------------------------------------------
  // Stat distribution
  // ---------------------------------------------------------------------------

  /// Stat points granted per unit of "relative volume" (sets×reps×load proxy).
  static const double statPerVolume = 0.02;

  /// Minimum stat points a cleared node grants to its primary attribute.
  static const int minPrimaryStatGain = 1;

  /// Fraction of primary-stat gain that bleeds into secondary attributes.
  static const double secondaryStatRatio = 0.4;

  // ---------------------------------------------------------------------------
  // Progressive overload
  // ---------------------------------------------------------------------------

  /// Default load increment (kg) added per successful clear for weighted lifts.
  static const double defaultWeightStep = 2.5;

  /// Rep increment added per clear for bodyweight movements.
  static const int defaultRepStep = 1;

  /// Cap reps before the engine rolls reps back and bumps a set instead.
  static const int repRolloverThreshold = 15;

  // ---------------------------------------------------------------------------
  // Economy
  // ---------------------------------------------------------------------------

  /// Coins awarded per 100 EXP earned, on top of explicit node coin rewards.
  static const double coinsPerHundredExp = 5;

  // ---------------------------------------------------------------------------
  // Penalties
  // ---------------------------------------------------------------------------

  /// EXP penalty applied for failing a mandatory day (negative).
  static const double penaltyExp = -50;

  /// Maps a muscle group to the primary attribute it develops.
  static StatType primaryStatFor(MuscleGroup group) => switch (group) {
        MuscleGroup.chest => StatType.str,
        MuscleGroup.back => StatType.str,
        MuscleGroup.legs => StatType.str,
        MuscleGroup.arms => StatType.str,
        MuscleGroup.shoulders => StatType.str,
        MuscleGroup.core => StatType.vit,
        MuscleGroup.fullBody => StatType.end,
        MuscleGroup.mobility => StatType.flex,
        MuscleGroup.cardio => StatType.end,
      };

  /// Maps a muscle group to a secondary attribute that gets partial gains.
  static StatType secondaryStatFor(MuscleGroup group) => switch (group) {
        MuscleGroup.chest => StatType.end,
        MuscleGroup.back => StatType.end,
        MuscleGroup.legs => StatType.agi,
        MuscleGroup.arms => StatType.vit,
        MuscleGroup.shoulders => StatType.flex,
        MuscleGroup.core => StatType.str,
        MuscleGroup.fullBody => StatType.str,
        MuscleGroup.mobility => StatType.agi,
        MuscleGroup.cardio => StatType.agi,
      };
}

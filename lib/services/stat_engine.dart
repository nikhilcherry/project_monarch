import 'dart:math' as math;

import '../core/constants/game_balance.dart';
import '../models/enums.dart';
import '../models/workout_node.dart';

/// Computes how clearing a workout node distributes points across the five
/// attributes. Pure math — returns a {StatType: points} map the caller merges
/// into [UserStats] via `applyRewards`.
abstract final class StatEngine {
  StatEngine._();

  /// Distribute stat gains for clearing [node].
  ///
  /// Strategy:
  ///   1. Start from any explicit `node.statRewards` (designer-authored).
  ///   2. Add volume-derived gains: primary attribute (by muscle group) scales
  ///      with total relative volume; a fraction bleeds to a secondary attribute.
  ///
  /// This means heavier/larger sessions yield more, while still honoring
  /// hand-tuned rewards on signature nodes.
  static Map<StatType, int> distribute(WorkoutNode node) {
    final result = <StatType, int>{...node.statRewards};

    final totalVolume =
        node.exercises.fold<double>(0, (sum, e) => sum + e.volume);

    final primaryGain = math.max(
      GameBalance.minPrimaryStatGain,
      (totalVolume * GameBalance.statPerVolume).round(),
    );
    final secondaryGain =
        (primaryGain * GameBalance.secondaryStatRatio).round();

    final primary = GameBalance.primaryStatFor(node.muscleGroup);
    final secondary = GameBalance.secondaryStatFor(node.muscleGroup);

    result.update(primary, (v) => v + primaryGain, ifAbsent: () => primaryGain);
    if (secondaryGain > 0) {
      result.update(secondary, (v) => v + secondaryGain,
          ifAbsent: () => secondaryGain);
    }

    return result;
  }

  /// Total points a distribution adds — for "+N STAT" summary toasts.
  static int totalPoints(Map<StatType, int> dist) =>
      dist.values.fold(0, (a, b) => a + b);
}

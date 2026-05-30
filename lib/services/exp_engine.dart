import 'dart:math' as math;

import '../core/constants/game_balance.dart';
import '../models/enums.dart';
import '../models/rank_profile.dart';

/// Immutable result of awarding EXP — the new profile plus what changed, so the
/// UI can fire the right "LEVEL UP" / "RANK UP" System animations.
class ExpAwardResult {
  final RankProfile profile;
  final double expGained;
  final int levelsGained;
  final int ranksGained;
  final int coinsGained;

  const ExpAwardResult({
    required this.profile,
    required this.expGained,
    required this.levelsGained,
    required this.ranksGained,
    required this.coinsGained,
  });

  bool get leveledUp => levelsGained > 0;
  bool get rankedUp => ranksGained > 0;
}

/// Pure, offline EXP & rank math. No I/O — callers pass in a [RankProfile] and
/// get a new one back, then persist it via the repository. This purity makes the
/// curve trivially unit-testable and keeps it identical to the Python reference.
abstract final class ExpEngine {
  ExpEngine._();

  /// EXP needed to advance ONE level while at [rank] and [level].
  ///
  ///   threshold = baseExp · (rankTier+1)^rankExponent · levelGrowth^(level-1)
  static double expForLevel(Rank rank, int level) {
    final rankFactor = math.pow(rank.tier + 1, GameBalance.rankExponent);
    final levelFactor =
        math.pow(GameBalance.levelGrowth, math.max(0, level - 1));
    return GameBalance.baseExp * rankFactor * levelFactor;
  }

  /// Total EXP to clear an entire rank band (sum across its levels) — handy for
  /// progress summaries and the tuning table.
  static double expForRankBand(Rank rank) {
    var total = 0.0;
    for (var lvl = 1; lvl <= GameBalance.levelsPerRank; lvl++) {
      total += expForLevel(rank, lvl);
    }
    return total;
  }

  /// Award [amount] EXP, cascading through level-ups (and rank-ups when a rank
  /// band's level cap is reached). Handles arbitrary overflow in one call.
  ///
  /// [amount] may be negative (penalty); EXP/level never drop below the floor of
  /// the current rank band (we don't de-rank — failure stings but isn't ruinous).
  static ExpAwardResult award(RankProfile profile, double amount) {
    var rank = profile.rank;
    var level = profile.level;
    var currentExp = profile.currentExp + amount;
    var lifetime = profile.lifetimeExp + math.max(0, amount);

    var levelsGained = 0;
    var ranksGained = 0;

    // Handle penalties: clamp at zero, no de-level.
    if (currentExp < 0) currentExp = 0;

    // Cascade level-ups.
    var threshold = expForLevel(rank, level);
    while (currentExp >= threshold) {
      currentExp -= threshold;
      level++;
      levelsGained++;

      // Rank-up when we exceed this rank band's level cap.
      if (level > GameBalance.levelsPerRank) {
        final next = rank.next;
        if (next == null) {
          // Max rank: park at the cap and stop draining EXP.
          level = GameBalance.levelsPerRank;
          currentExp = math.min(currentExp, threshold);
          break;
        }
        rank = next;
        level = 1;
        ranksGained++;
      }

      threshold = expForLevel(rank, level);
    }

    final coinsGained = _coinsFor(math.max(0, amount));

    final updated = profile.copyWith(
      rank: rank,
      level: level,
      currentExp: currentExp,
      lifetimeExp: lifetime,
      coins: profile.coins + coinsGained,
      expToNextRank: threshold,
    );

    return ExpAwardResult(
      profile: updated,
      expGained: amount,
      levelsGained: levelsGained,
      ranksGained: ranksGained,
      coinsGained: coinsGained,
    );
  }

  /// Recompute and stamp the cached [RankProfile.expToNextRank] — useful after
  /// loading a legacy profile or changing balance constants.
  static RankProfile refreshThreshold(RankProfile profile) =>
      profile.copyWith(expToNextRank: expForLevel(profile.rank, profile.level));

  static int _coinsFor(double exp) =>
      (exp / 100 * GameBalance.coinsPerHundredExp).floor();
}

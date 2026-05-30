import 'package:flutter_test/flutter_test.dart';
import 'package:project_monarch/core/constants/game_balance.dart';
import 'package:project_monarch/models/enums.dart';
import 'package:project_monarch/models/rank_profile.dart';
import 'package:project_monarch/services/exp_engine.dart';

void main() {
  group('ExpEngine.expForLevel', () {
    test('first level of E-rank equals baseExp', () {
      expect(ExpEngine.expForLevel(Rank.e, 1),
          closeTo(GameBalance.baseExp, 0.001));
    });

    test('grows with level within a rank', () {
      final l1 = ExpEngine.expForLevel(Rank.e, 1);
      final l2 = ExpEngine.expForLevel(Rank.e, 2);
      final l3 = ExpEngine.expForLevel(Rank.e, 3);
      expect(l2, greaterThan(l1));
      expect(l3, greaterThan(l2));
    });

    test('grows exponentially with rank', () {
      final e = ExpEngine.expForLevel(Rank.e, 1);
      final d = ExpEngine.expForLevel(Rank.d, 1);
      final c = ExpEngine.expForLevel(Rank.c, 1);
      // D should be 2^1.8 times E.
      expect(d / e, closeTo(3.482, 0.01));
      expect(c, greaterThan(d));
    });
  });

  group('ExpEngine.award', () {
    test('single level up consumes exactly one threshold', () {
      final profile = ExpEngine.refreshThreshold(RankProfile.initial());
      final result = ExpEngine.award(profile, GameBalance.baseExp);

      expect(result.levelsGained, 1);
      expect(result.ranksGained, 0);
      expect(result.profile.level, 2);
      expect(result.profile.currentExp, closeTo(0, 0.001));
      expect(result.profile.lifetimeExp, closeTo(GameBalance.baseExp, 0.001));
    });

    test('awards coins proportional to EXP', () {
      final profile = ExpEngine.refreshThreshold(RankProfile.initial());
      final result = ExpEngine.award(profile, 200);
      // 200 EXP -> 2 * coinsPerHundredExp coins.
      expect(result.coinsGained, (2 * GameBalance.coinsPerHundredExp).floor());
    });

    test('cascades through multiple level-ups in one award', () {
      final profile = ExpEngine.refreshThreshold(RankProfile.initial());
      // Enough to clear several E-rank levels at once.
      final result = ExpEngine.award(profile, 1000);
      expect(result.levelsGained, greaterThan(1));
    });

    test('ranks up when the level cap is exceeded', () {
      var profile = RankProfile(
        rank: Rank.e,
        level: GameBalance.levelsPerRank,
        currentExp: 0,
      );
      profile = ExpEngine.refreshThreshold(profile);
      final threshold = ExpEngine.expForLevel(Rank.e, GameBalance.levelsPerRank);

      final result = ExpEngine.award(profile, threshold);

      expect(result.ranksGained, 1);
      expect(result.profile.rank, Rank.d);
      expect(result.profile.level, 1);
    });

    test('penalty clamps EXP at zero and never de-levels', () {
      final profile = RankProfile(
        rank: Rank.c,
        level: 3,
        currentExp: 20,
        expToNextRank: ExpEngine.expForLevel(Rank.c, 3),
      );
      final result = ExpEngine.award(profile, GameBalance.penaltyExp);

      expect(result.profile.currentExp, 0);
      expect(result.profile.level, 3);
      expect(result.profile.rank, Rank.c);
      expect(result.levelsGained, 0);
      expect(result.coinsGained, 0); // no coins for penalties
    });

    test('parks at the cap at max rank without losing data', () {
      var profile = RankProfile(
        rank: Rank.national,
        level: GameBalance.levelsPerRank,
      );
      profile = ExpEngine.refreshThreshold(profile);
      final result = ExpEngine.award(profile, 999999);

      expect(result.profile.rank, Rank.national);
      expect(result.profile.level, GameBalance.levelsPerRank);
      expect(result.ranksGained, 0);
    });

    test('lifetime EXP accumulates and ignores penalties', () {
      var profile = ExpEngine.refreshThreshold(RankProfile.initial());
      profile = ExpEngine.award(profile, 50).profile;
      profile = ExpEngine.award(profile, -30).profile; // penalty
      profile = ExpEngine.award(profile, 50).profile;
      expect(profile.lifetimeExp, closeTo(100, 0.001));
    });
  });

  group('RankProfile derived getters', () {
    test('rankProgress is the clamped currentExp/threshold fraction', () {
      final profile = RankProfile(currentExp: 50, expToNextRank: 100);
      expect(profile.rankProgress, closeTo(0.5, 0.001));
    });

    test('rankProgress clamps to 1', () {
      final profile = RankProfile(currentExp: 200, expToNextRank: 100);
      expect(profile.rankProgress, 1.0);
    });

    test('isMaxRank only at national', () {
      expect(RankProfile(rank: Rank.s).isMaxRank, false);
      expect(RankProfile(rank: Rank.national).isMaxRank, true);
    });
  });
}

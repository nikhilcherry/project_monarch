import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/database/database_service.dart';
import '../models/enums.dart';
import '../models/rank_profile.dart';
import '../models/user_stats.dart';
import '../repositories/consistency_repository.dart';
import '../repositories/profile_repository.dart';
import '../repositories/stats_repository.dart';
import '../services/exp_engine.dart';

// ---------------------------------------------------------------------------
// Repository providers — thin wrappers over the already-open Hive boxes.
// ---------------------------------------------------------------------------

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(DatabaseService.rankProfileBox);
});

final statsRepositoryProvider = Provider<StatsRepository>((ref) {
  return StatsRepository(DatabaseService.userStatsBox);
});

final consistencyRepositoryProvider = Provider<ConsistencyRepository>((ref) {
  return ConsistencyRepository(DatabaseService.consistencyBox);
});

// ---------------------------------------------------------------------------
// Rank / EXP profile controller.
// ---------------------------------------------------------------------------

final rankProfileProvider =
    NotifierProvider<RankProfileNotifier, RankProfile>(RankProfileNotifier.new);

class RankProfileNotifier extends Notifier<RankProfile> {
  ProfileRepository get _repo => ref.read(profileRepositoryProvider);

  @override
  RankProfile build() {
    final profile = _repo.getOrCreate();
    // Interim daily Crystal grant (the guaranteed "System Check-In" from the v2
    // design). Phase 2 will replace this with the full Daily Quest system; for
    // now it keeps the map playable and honors the soft-lock guarantee:
    // grant 10·R crystals once per calendar day on app open.
    _grantDailyCrystalsIfDue();
    return profile;
  }

  Future<void> _grantDailyCrystalsIfDue() async {
    final box = DatabaseService.settingsBox;
    const key = 'last_crystal_grant_day';
    final today = _todayKey();
    if (box.get(key) == today) return; // already granted today

    final profile = _repo.getOrCreate();
    final grant = 10 * profile.rankFactor; // 10·R
    await _repo.addCrystals(grant);
    await box.put(key, today);
    state = _repo.getOrCreate();
  }

  static String _todayKey() {
    final now = DateTime.now();
    return '${now.year.toString().padLeft(4, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
  }

  /// Award EXP and surface the result (for LEVEL/RANK UP animations).
  Future<ExpAwardResult> awardExp(double amount) async {
    final result = await _repo.awardExp(amount);
    state = result.profile;
    return result;
  }

  Future<bool> spendCoins(int cost) async {
    final ok = await _repo.spendCoins(cost);
    if (ok) state = _repo.getOrCreate();
    return ok;
  }

  Future<void> addCoins(int amount) async {
    await _repo.addCoins(amount);
    state = _repo.getOrCreate();
  }

  /// Spend crystals (World Map). Returns false if the hunter can't afford it.
  Future<bool> spendCrystals(int cost) async {
    final ok = await _repo.spendCrystals(cost);
    if (ok) state = _repo.getOrCreate();
    return ok;
  }
}

// ---------------------------------------------------------------------------
// User stats controller (radar chart).
// ---------------------------------------------------------------------------

final userStatsProvider =
    NotifierProvider<UserStatsNotifier, UserStats>(UserStatsNotifier.new);

class UserStatsNotifier extends Notifier<UserStats> {
  StatsRepository get _repo => ref.read(statsRepositoryProvider);

  @override
  UserStats build() => _repo.getOrCreate();

  Future<void> applyRewards(Map<StatType, int> rewards) async {
    state = await _repo.applyRewards(rewards);
  }
}

// ---------------------------------------------------------------------------
// Consistency heatmap — derived providers.
// ---------------------------------------------------------------------------

/// {DateTime: intensity(0–4)} for the last year.
final heatmapDataProvider = Provider<Map<DateTime, int>>((ref) {
  return ref.watch(consistencyRepositoryProvider).heatmapData();
});

/// Current consecutive-day streak.
final streakProvider = Provider<int>((ref) {
  return ref.watch(consistencyRepositoryProvider).currentStreak();
});

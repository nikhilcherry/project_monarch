import 'package:hive/hive.dart';

import '../core/database/hive_boxes.dart';
import '../models/rank_profile.dart';
import '../services/exp_engine.dart';

/// Persistence for the singleton [RankProfile]. Wraps the Hive box so the rest
/// of the app never touches storage directly and the profile stays the single
/// offline source of truth.
class ProfileRepository {
  ProfileRepository(this._box);

  final Box<RankProfile> _box;

  /// Load the profile, seeding a fresh one (with a correct EXP threshold) the
  /// first time the app runs.
  RankProfile getOrCreate() {
    final existing = _box.get(HiveBoxes.primaryKey);
    if (existing != null) return existing;

    final fresh = ExpEngine.refreshThreshold(RankProfile.initial());
    _box.put(HiveBoxes.primaryKey, fresh);
    return fresh;
  }

  Future<void> save(RankProfile profile) =>
      _box.put(HiveBoxes.primaryKey, profile);

  /// Award EXP through the engine and persist the result in one step.
  Future<ExpAwardResult> awardExp(double amount) async {
    final result = ExpEngine.award(getOrCreate(), amount);
    await save(result.profile);
    return result;
  }

  /// Spend coins if affordable. Returns false (and changes nothing) if broke.
  Future<bool> spendCoins(int cost) async {
    final profile = getOrCreate();
    if (profile.coins < cost) return false;
    await save(profile.copyWith(coins: profile.coins - cost));
    return true;
  }

  Future<void> addCoins(int amount) async {
    final profile = getOrCreate();
    await save(profile.copyWith(coins: profile.coins + amount));
  }

  // --- Crystals (World Map currency) ---------------------------------------

  /// Spend crystals if affordable. Returns false (and changes nothing) if short.
  Future<bool> spendCrystals(int cost) async {
    final profile = getOrCreate();
    if (profile.crystals < cost) return false;
    await save(profile.copyWith(crystals: profile.crystals - cost));
    return true;
  }

  Future<void> addCrystals(int amount) async {
    final profile = getOrCreate();
    await save(profile.copyWith(crystals: profile.crystals + amount));
  }
}

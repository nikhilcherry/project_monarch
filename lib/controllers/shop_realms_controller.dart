import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/database/database_service.dart';
import '../models/shop_realm.dart';
import '../repositories/shop_realm_repository.dart';
import '../services/realm_generator.dart';
import 'providers.dart';

final shopRealmRepositoryProvider = Provider<ShopRealmRepository>((ref) {
  return ShopRealmRepository(DatabaseService.realmsBox);
});

/// Outcome of trying to buy a realm.
enum RealmPurchase { success, alreadyOwned, locked, insufficientCoins }

final shopRealmsProvider =
    NotifierProvider<ShopRealmsNotifier, List<ShopRealm>>(
        ShopRealmsNotifier.new);

class ShopRealmsNotifier extends Notifier<List<ShopRealm>> {
  ShopRealmRepository get _repo => ref.read(shopRealmRepositoryProvider);

  @override
  List<ShopRealm> build() {
    _repo.seedIfEmpty();
    return _repo.getAll();
  }

  /// The highest rank tier the player has reached (gates realm availability).
  int get currentTier => ref.read(rankProfileProvider).rank.tier;

  bool isAvailable(ShopRealm realm) => realm.unlockTier <= currentTier;

  /// Buy a realm with Coins (never Crystals).
  Future<RealmPurchase> buy(String id) async {
    final realm = _repo.byId(id);
    if (realm == null) return RealmPurchase.locked;
    if (realm.owned) return RealmPurchase.alreadyOwned;
    if (!isAvailable(realm)) return RealmPurchase.locked;

    final paid =
        await ref.read(rankProfileProvider.notifier).spendCoins(realm.coinCost);
    if (!paid) return RealmPurchase.insufficientCoins;

    await _repo.markOwned(id);
    state = _repo.getAll();
    return RealmPurchase.success;
  }

  /// Clear the realm's current level: award EXP/coins/stats (one-time) and
  /// advance progress.
  Future<void> clearCurrentLevel(String id) async {
    final realm = _repo.byId(id);
    if (realm == null || !realm.owned || realm.isComplete) return;

    final level = realm.currentLevel;
    final tier = realm.unlockTier;

    await ref
        .read(rankProfileProvider.notifier)
        .awardExp(RealmGenerator.levelExp(tier, level));
    await ref
        .read(rankProfileProvider.notifier)
        .addCoins(RealmGenerator.levelCoins(tier));
    await ref
        .read(userStatsProvider.notifier)
        .applyRewards(RealmGenerator.levelStats(realm.muscleGroup));

    await _repo.clearLevel(id);
    state = _repo.getAll();
  }
}

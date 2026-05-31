import 'package:hive/hive.dart';

import '../core/constants/realm_catalog.dart';
import '../models/shop_realm.dart';

/// Persistence for Shop Realms (coin-bought linear gauntlets).
class ShopRealmRepository {
  ShopRealmRepository(this._box);

  final Box<ShopRealm> _box;

  Future<void> seedIfEmpty() async {
    if (_box.isEmpty) {
      for (final realm in RealmCatalog.build()) {
        await _box.put(realm.id, realm);
      }
    }
  }

  List<ShopRealm> getAll() => _box.values.toList()
    ..sort((a, b) => a.unlockTier != b.unlockTier
        ? a.unlockTier - b.unlockTier
        : a.coinCost - b.coinCost);

  ShopRealm? byId(String id) => _box.get(id);

  Future<void> markOwned(String id) async {
    final r = _box.get(id);
    if (r == null) return;
    await _box.put(id, r.copyWith(owned: true));
  }

  /// Advance a realm by one cleared level (capped at its length).
  Future<void> clearLevel(String id) async {
    final r = _box.get(id);
    if (r == null || r.isComplete) return;
    await _box.put(id, r.copyWith(clearedLevels: r.clearedLevels + 1));
  }
}

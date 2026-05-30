import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/shop_catalog.dart';
import '../core/database/database_service.dart';
import '../models/shop_item.dart';
import '../repositories/shop_repository.dart';
import 'providers.dart';

final shopRepositoryProvider = Provider<ShopRepository>((ref) {
  return ShopRepository(DatabaseService.settingsBox);
});

/// Immutable snapshot of shop state for the UI.
class ShopState {
  final Set<String> owned;
  final String equippedTitleId;
  final String? equippedBadgeId;

  const ShopState({
    required this.owned,
    required this.equippedTitleId,
    required this.equippedBadgeId,
  });
}

/// Result of a purchase attempt.
enum PurchaseOutcome { success, alreadyOwned, insufficientCoins }

final shopProvider =
    NotifierProvider<ShopNotifier, ShopState>(ShopNotifier.new);

class ShopNotifier extends Notifier<ShopState> {
  ShopRepository get _repo => ref.read(shopRepositoryProvider);

  @override
  ShopState build() => _read();

  ShopState _read() => ShopState(
        owned: _repo.owned(),
        equippedTitleId: _repo.equippedTitleId(),
        equippedBadgeId: _repo.equippedBadgeId(),
      );

  /// Buy [item] with coins. Free items are simply granted.
  Future<PurchaseOutcome> purchase(ShopItem item) async {
    if (_repo.isOwned(item.id)) return PurchaseOutcome.alreadyOwned;

    if (item.cost > 0) {
      final paid =
          await ref.read(rankProfileProvider.notifier).spendCoins(item.cost);
      if (!paid) return PurchaseOutcome.insufficientCoins;
    }

    await _repo.addOwned(item.id);
    state = _read();
    return PurchaseOutcome.success;
  }

  /// Equip an owned cosmetic (no-op if not owned).
  Future<void> equip(ShopItem item) async {
    if (!_repo.isOwned(item.id)) return;
    switch (item.category) {
      case ShopCategory.title:
        await _repo.equipTitle(item.id);
      case ShopCategory.badge:
        // Toggle badge off if re-equipping the same one.
        final current = _repo.equippedBadgeId();
        await _repo.equipBadge(current == item.id ? null : item.id);
    }
    state = _read();
  }
}

/// Convenience provider: the currently equipped title's display name.
final equippedTitleNameProvider = Provider<String>((ref) {
  final state = ref.watch(shopProvider);
  return ShopCatalog.byId(state.equippedTitleId).name;
});

/// The currently equipped badge item, or null if none.
final equippedBadgeProvider = Provider<ShopItem?>((ref) {
  final id = ref.watch(shopProvider).equippedBadgeId;
  return id == null ? null : ShopCatalog.byId(id);
});

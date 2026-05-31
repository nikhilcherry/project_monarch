import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../controllers/providers.dart';
import '../../controllers/shop_controller.dart';
import '../../controllers/shop_realms_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/shop_catalog.dart';
import '../../models/enums.dart';
import '../../models/shop_item.dart';
import '../../models/shop_realm.dart';
import '../../widgets/glow_panel.dart';
import 'realm_view.dart';

/// The cosmetic shop — spend dungeon coins on Hunter titles and badges.
class ShopView extends ConsumerWidget {
  const ShopView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shop = ref.watch(shopProvider);
    final coins = ref.watch(rankProfileProvider).coins;

    final titles = ShopCatalog.items
        .where((i) => i.category == ShopCategory.title)
        .toList();
    final badges = ShopCatalog.items
        .where((i) => i.category == ShopCategory.badge)
        .toList();
    final realms = ref.watch(shopRealmsProvider);
    final rankTier = ref.watch(rankProfileProvider).rank.tier;

    return Scaffold(
      appBar: AppBar(
        title: const Text('SHOP'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Row(
              children: [
                const Icon(Icons.monetization_on,
                    color: AppColors.coin, size: 18),
                const SizedBox(width: 4),
                Text('$coins',
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(color: AppColors.coin)),
              ],
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const _SectionHeader('Hunter Titles'),
            ...titles.map((item) => _ShopTile(
                  item: item,
                  owned: shop.owned.contains(item.id),
                  equipped: shop.equippedTitleId == item.id,
                  onBuy: () => _buy(context, ref, item),
                  onEquip: () =>
                      ref.read(shopProvider.notifier).equip(item),
                )),
            const SizedBox(height: 8),
            const _SectionHeader('Badges'),
            ...badges.map((item) => _ShopTile(
                  item: item,
                  owned: shop.owned.contains(item.id),
                  equipped: shop.equippedBadgeId == item.id,
                  onBuy: () => _buy(context, ref, item),
                  onEquip: () =>
                      ref.read(shopProvider.notifier).equip(item),
                )),
            const SizedBox(height: 8),
            const _SectionHeader('Alternate Realms'),
            ...realms.map((r) => _RealmTile(
                  realm: r,
                  available: r.unlockTier <= rankTier,
                  onBuy: () => _buyRealm(context, ref, r),
                  onEnter: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => RealmView(realmId: r.id),
                    ),
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Future<void> _buyRealm(
      BuildContext context, WidgetRef ref, ShopRealm realm) async {
    final outcome = await ref.read(shopRealmsProvider.notifier).buy(realm.id);
    if (!context.mounted) return;
    final message = switch (outcome) {
      RealmPurchase.success => 'Unlocked "${realm.name}".',
      RealmPurchase.alreadyOwned => 'Already unlocked.',
      RealmPurchase.locked =>
        'Locked — reach ${Rank.values[realm.unlockTier].label} to unlock.',
      RealmPurchase.insufficientCoins =>
        'System Warning: insufficient Coins.',
    };
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _buy(
      BuildContext context, WidgetRef ref, ShopItem item) async {
    final outcome = await ref.read(shopProvider.notifier).purchase(item);
    if (!context.mounted) return;
    final message = switch (outcome) {
      PurchaseOutcome.success => 'Acquired "${item.name}".',
      PurchaseOutcome.alreadyOwned => 'Already owned.',
      PurchaseOutcome.insufficientCoins =>
        'System Warning: insufficient coins.',
    };
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: PanelLabel(text),
    );
  }
}

class _ShopTile extends StatelessWidget {
  const _ShopTile({
    required this.item,
    required this.owned,
    required this.equipped,
    required this.onBuy,
    required this.onEquip,
  });

  final ShopItem item;
  final bool owned;
  final bool equipped;
  final VoidCallback onBuy;
  final VoidCallback onEquip;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlowPanel(
        glow: equipped,
        borderColor: equipped ? AppColors.success : AppColors.accent,
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.surfaceElevated,
                border: Border.all(color: AppColors.accent.withOpacity(0.5)),
              ),
              child: Icon(
                item.category == ShopCategory.title
                    ? Icons.military_tech
                    : item.icon,
                color: AppColors.accent,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.name, style: textTheme.titleMedium),
                  const SizedBox(height: 2),
                  Text(item.description,
                      style: textTheme.bodySmall
                          ?.copyWith(color: AppColors.textSecondary)),
                ],
              ),
            ),
            const SizedBox(width: 12),
            _ActionButton(
              item: item,
              owned: owned,
              equipped: equipped,
              onBuy: onBuy,
              onEquip: onEquip,
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.item,
    required this.owned,
    required this.equipped,
    required this.onBuy,
    required this.onEquip,
  });

  final ShopItem item;
  final bool owned;
  final bool equipped;
  final VoidCallback onBuy;
  final VoidCallback onEquip;

  @override
  Widget build(BuildContext context) {
    if (equipped) {
      return const _Tag(text: 'EQUIPPED', color: AppColors.success);
    }
    if (owned) {
      return OutlinedButton(onPressed: onEquip, child: const Text('EQUIP'));
    }
    return ElevatedButton.icon(
      onPressed: onBuy,
      icon: const Icon(Icons.monetization_on, size: 16),
      label: Text('${item.cost}'),
    );
  }
}

class _RealmTile extends StatelessWidget {
  const _RealmTile({
    required this.realm,
    required this.available,
    required this.onBuy,
    required this.onEnter,
  });

  final ShopRealm realm;
  final bool available;
  final VoidCallback onBuy;
  final VoidCallback onEnter;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final locked = !available && !realm.owned;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlowPanel(
        borderColor: realm.owned ? AppColors.accent : AppColors.textDisabled,
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.surfaceElevated,
                border: Border.all(
                  color: locked ? AppColors.textDisabled : AppColors.accent,
                ),
              ),
              child: Icon(locked ? Icons.lock : Icons.castle,
                  color: locked ? AppColors.textDisabled : AppColors.accent,
                  size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(realm.name, softWrap: true, style: textTheme.titleMedium),
                  const SizedBox(height: 2),
                  Text(
                    realm.owned
                        ? '${realm.clearedLevels}/${realm.length} levels cleared'
                        : '${realm.length} levels',
                    style: textTheme.bodySmall
                        ?.copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            _RealmAction(
              realm: realm,
              available: available,
              onBuy: onBuy,
              onEnter: onEnter,
            ),
          ],
        ),
      ),
    );
  }
}

class _RealmAction extends StatelessWidget {
  const _RealmAction({
    required this.realm,
    required this.available,
    required this.onBuy,
    required this.onEnter,
  });

  final ShopRealm realm;
  final bool available;
  final VoidCallback onBuy;
  final VoidCallback onEnter;

  @override
  Widget build(BuildContext context) {
    if (realm.owned) {
      return OutlinedButton(onPressed: onEnter, child: const Text('ENTER'));
    }
    if (!available) {
      return Text('${Rank.values[realm.unlockTier].label}',
          style: Theme.of(context)
              .textTheme
              .labelMedium
              ?.copyWith(color: AppColors.textDisabled, letterSpacing: 1));
    }
    return ElevatedButton.icon(
      onPressed: onBuy,
      icon: const Icon(Icons.monetization_on, size: 16),
      label: Text('${realm.coinCost}'),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.text, required this.color});
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color),
      ),
      child: Text(text,
          style: Theme.of(context)
              .textTheme
              .labelMedium
              ?.copyWith(color: color, letterSpacing: 1)),
    );
  }
}

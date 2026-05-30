import 'package:flutter/material.dart';

/// What kind of cosmetic a shop item is. Kept cosmetic-only so the economy never
/// becomes pay-to-win — coins buy identity (and map unlocks elsewhere), not raw
/// power.
enum ShopCategory {
  /// A Hunter title shown on the dashboard rank header.
  title,

  /// A badge/sigil icon displayed alongside the rank.
  badge,
}

/// An immutable catalog entry. Ownership/equip state lives in the repository,
/// not on the item, so the catalog itself stays `const`.
@immutable
class ShopItem {
  final String id;
  final String name;
  final String description;
  final int cost;
  final ShopCategory category;

  /// Icon used for badge items (ignored for titles).
  final IconData icon;

  const ShopItem({
    required this.id,
    required this.name,
    required this.description,
    required this.cost,
    required this.category,
    this.icon = Icons.shield,
  });
}

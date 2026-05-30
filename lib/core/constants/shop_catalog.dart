import 'package:flutter/material.dart';

import '../../models/shop_item.dart';

/// The cosmetic shop catalog. Coins (earned from dungeons) are spent here on
/// Hunter titles and badges — pure identity, no stat advantage.
abstract final class ShopCatalog {
  ShopCatalog._();

  /// The free default title every hunter starts with.
  static const String defaultTitleId = 'title_novice';

  static const List<ShopItem> items = [
    // --- Titles ---------------------------------------------------------------
    ShopItem(
      id: defaultTitleId,
      name: 'Novice Hunter',
      description: 'Where every legend begins.',
      cost: 0,
      category: ShopCategory.title,
    ),
    ShopItem(
      id: 'title_awakened',
      name: 'The Awakened',
      description: 'You have opened your eyes to the System.',
      cost: 150,
      category: ShopCategory.title,
    ),
    ShopItem(
      id: 'title_ironwill',
      name: 'Iron-Willed',
      description: 'Discipline forged in repetition.',
      cost: 400,
      category: ShopCategory.title,
    ),
    ShopItem(
      id: 'title_shadow_monarch',
      name: 'Shadow Monarch',
      description: 'Arise. The apex title.',
      cost: 1500,
      category: ShopCategory.title,
    ),

    // --- Badges ---------------------------------------------------------------
    ShopItem(
      id: 'badge_bolt',
      name: 'Surge Sigil',
      description: 'A crackling mark of speed.',
      cost: 200,
      category: ShopCategory.badge,
      icon: Icons.bolt,
    ),
    ShopItem(
      id: 'badge_flame',
      name: 'Ember Crest',
      description: 'For those who never cool down.',
      cost: 300,
      category: ShopCategory.badge,
      icon: Icons.local_fire_department,
    ),
    ShopItem(
      id: 'badge_diamond',
      name: 'Diamond Core',
      description: 'Unbreakable. Brilliant.',
      cost: 800,
      category: ShopCategory.badge,
      icon: Icons.diamond,
    ),
  ];

  static ShopItem byId(String id) =>
      items.firstWhere((i) => i.id == id, orElse: () => items.first);
}

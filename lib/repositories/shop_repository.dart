import 'package:hive/hive.dart';

import '../core/constants/shop_catalog.dart';

/// Persists shop ownership + equip state in the dynamic settings box. Cosmetics
/// don't warrant their own typed box/model, so we store light scalars/lists.
class ShopRepository {
  ShopRepository(this._settings);

  final Box<dynamic> _settings;

  static const _kOwned = 'shop_owned';
  static const _kEquippedTitle = 'shop_equipped_title';
  static const _kEquippedBadge = 'shop_equipped_badge';

  /// Owned item ids — the free default title is always owned.
  Set<String> owned() {
    final raw = _settings.get(_kOwned, defaultValue: const <String>[]);
    final set = {...(raw as List).cast<String>(), ShopCatalog.defaultTitleId};
    return set;
  }

  bool isOwned(String id) => owned().contains(id);

  Future<void> addOwned(String id) async {
    final next = owned()..add(id);
    await _settings.put(_kOwned, next.toList());
  }

  /// Equipped title id (defaults to the novice title).
  String equippedTitleId() =>
      _settings.get(_kEquippedTitle, defaultValue: ShopCatalog.defaultTitleId)
          as String;

  /// Equipped badge id, or null if none equipped.
  String? equippedBadgeId() =>
      _settings.get(_kEquippedBadge, defaultValue: null) as String?;

  Future<void> equipTitle(String id) =>
      _settings.put(_kEquippedTitle, id);

  Future<void> equipBadge(String? id) =>
      _settings.put(_kEquippedBadge, id);
}

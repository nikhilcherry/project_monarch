import 'package:hive/hive.dart';

import 'enums.dart';

part 'shop_realm.g.dart';

/// A Shop-bought Alternate Realm — an isolated, strictly linear gauntlet of
/// `length` progressively harder levels, reachable only from the Shop UI
/// (independent of the World Map). Bought once with Coins; levels are cleared
/// one at a time and never replayed. See docs/GAME_DESIGN_V2.md §3.
@HiveType(typeId: 10)
class ShopRealm extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String description;

  /// Rank tier at which this realm becomes buyable (0 = E … 8 = National).
  @HiveField(3)
  int unlockTier;

  /// Number of linear levels in the gauntlet.
  @HiveField(4)
  int length;

  /// One-time Coin price to unlock the realm.
  @HiveField(5)
  int coinCost;

  @HiveField(6)
  bool owned;

  /// How many levels have been cleared (0…length). The next playable level is
  /// `clearedLevels + 1` (1-based).
  @HiveField(7)
  int clearedLevels;

  @HiveField(8)
  MuscleGroup muscleGroup;

  ShopRealm({
    required this.id,
    required this.name,
    this.description = '',
    this.unlockTier = 0,
    this.length = 20,
    this.coinCost = 200,
    this.owned = false,
    this.clearedLevels = 0,
    this.muscleGroup = MuscleGroup.fullBody,
  });

  bool get isComplete => clearedLevels >= length;

  /// Next level to play (1-based), or `length` once complete.
  int get currentLevel => isComplete ? length : clearedLevels + 1;

  ShopRealm copyWith({
    bool? owned,
    int? clearedLevels,
  }) =>
      ShopRealm(
        id: id,
        name: name,
        description: description,
        unlockTier: unlockTier,
        length: length,
        coinCost: coinCost,
        owned: owned ?? this.owned,
        clearedLevels: clearedLevels ?? this.clearedLevels,
        muscleGroup: muscleGroup,
      );
}

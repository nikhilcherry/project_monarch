import '../../models/enums.dart';
import '../../models/shop_realm.dart';

/// One catalog definition. Length and cost are derived from the unlock tier and
/// the realm's index within that tier (see GAME_DESIGN_V2 §3):
///   length    = 20 + 2·tier
///   coinCost  = round(200·(tier+1)·(1 + 0.25·index))
class _RealmDef {
  final String id;
  final String name;
  final String description;
  final int tier;
  final int index;
  final MuscleGroup muscle;
  const _RealmDef(
      this.id, this.name, this.description, this.tier, this.index, this.muscle);
}

/// The fixed Shop Realm catalog. Availability is cumulative: 4 realms at E,
/// then +2 each rank, reaching 20 at National. All names are written in full.
abstract final class RealmCatalog {
  RealmCatalog._();

  static const List<_RealmDef> _defs = [
    // E-Rank (tier 0) — 4 realms
    _RealmDef('realm_sunken_coliseum', 'The Sunken Coliseum',
        'A flooded arena of the forgotten.', 0, 0, MuscleGroup.fullBody),
    _RealmDef('realm_frostbound_halls', 'Halls of the Frostbound',
        'Endless corridors of unyielding ice.', 0, 1, MuscleGroup.legs),
    _RealmDef('realm_emberforge_spire', 'The Emberforge Spire',
        'A tower wreathed in living flame.', 0, 2, MuscleGroup.chest),
    _RealmDef('realm_verdant_labyrinth', 'Verdant Labyrinth',
        'A maze that grows as you climb.', 0, 3, MuscleGroup.cardio),
    // D-Rank (tier 1)
    _RealmDef('realm_cathedral_echoes', 'Cathedral of Echoes',
        'Where every footstep answers back.', 1, 0, MuscleGroup.core),
    _RealmDef('realm_obsidian_gauntlet', 'The Obsidian Gauntlet',
        'A black-glass trial of will.', 1, 1, MuscleGroup.arms),
    // C-Rank (tier 2)
    _RealmDef('realm_skybound_sanctum', 'Skybound Sanctum',
        'A temple adrift above the clouds.', 2, 0, MuscleGroup.shoulders),
    _RealmDef('realm_molten_causeway', 'The Molten Causeway',
        'A bridge across a sea of fire.', 2, 1, MuscleGroup.legs),
    // B-Rank (tier 3)
    _RealmDef('realm_drowned_cathedral', 'Drowned Cathedral of Tides',
        'Sunken halls ruled by the deep.', 3, 0, MuscleGroup.back),
    _RealmDef('realm_shattered_ascent', 'The Shattered Ascent',
        'A climb up a broken world.', 3, 1, MuscleGroup.fullBody),
    // A-Rank (tier 4)
    _RealmDef('realm_hollow_king', 'Citadel of the Hollow King',
        'The seat of an empty crown.', 4, 0, MuscleGroup.chest),
    _RealmDef('realm_tempest_crucible', 'The Tempest Crucible',
        'A storm given shape and malice.', 4, 1, MuscleGroup.cardio),
    // S-Rank (tier 5)
    _RealmDef('realm_abyssal_procession', 'Abyssal Procession',
        'A march into the lightless deep.', 5, 0, MuscleGroup.core),
    _RealmDef('realm_gilded_inferno', 'The Gilded Inferno',
        'Splendor and ruin in equal measure.', 5, 1, MuscleGroup.arms),
    // SS-Rank (tier 6)
    _RealmDef('realm_thousand_trials', 'Throne of a Thousand Trials',
        'Each step a test, each test a throne.', 6, 0, MuscleGroup.legs),
    _RealmDef('realm_riftborne_expanse', 'The Riftborne Expanse',
        'A wound in the world, ever widening.', 6, 1, MuscleGroup.fullBody),
    // SSS-Rank (tier 7)
    _RealmDef('realm_eternal_dawn', 'Sanctum of the Eternal Dawn',
        'Where the sun never finishes rising.', 7, 0, MuscleGroup.shoulders),
    _RealmDef('realm_voidforged_bastion', 'The Voidforged Bastion',
        'A fortress hammered from nothing.', 7, 1, MuscleGroup.back),
    // National (tier 8)
    _RealmDef('realm_final_dominion', "Monarch's Final Dominion",
        'The last domain a hunter will ever face.', 8, 0, MuscleGroup.fullBody),
    _RealmDef('realm_apex_beyond', 'The Apex Beyond Worlds',
        'Past the edge of everything known.', 8, 1, MuscleGroup.fullBody),
  ];

  static int lengthForTier(int tier) => 20 + 2 * tier;

  static int costFor(int tier, int index) =>
      (200 * (tier + 1) * (1 + 0.25 * index)).round();

  /// Fresh, unowned realms for a new game.
  static List<ShopRealm> build() => [
        for (final d in _defs)
          ShopRealm(
            id: d.id,
            name: d.name,
            description: d.description,
            unlockTier: d.tier,
            length: lengthForTier(d.tier),
            coinCost: costFor(d.tier, d.index),
            muscleGroup: d.muscle,
          ),
      ];
}

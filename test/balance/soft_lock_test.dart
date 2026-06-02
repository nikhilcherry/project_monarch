import 'package:flutter_test/flutter_test.dart';
import 'package:project_monarch/models/enums.dart';
import 'package:project_monarch/services/map_generator.dart';

/// Locks the v2 soft-lock invariant against the real map generator: at every
/// rank, the guaranteed daily Crystal income (10·R from the System Check-In)
/// must be >= the cheapest unlockable map node, so progress can never stall.
void main() {
  int guaranteedDaily(int tier) => 10 * (tier + 1);

  group('Soft-lock invariant', () {
    for (final rank in Rank.values) {
      test('${rank.label}: daily income covers the cheapest node', () {
        final region = MapGenerator.generateRegion(rank);
        final cheapest = region
            .where((n) => !n.isGate)
            .map((n) => n.unlockCost)
            .reduce((a, b) => a < b ? a : b);
        expect(
          guaranteedDaily(rank.tier),
          greaterThanOrEqualTo(cheapest),
          reason: 'A zero-savings hunter must afford a node each day.',
        );
      });
    }

    test('map depth scales 5 + 2*tier', () {
      expect(MapGenerator.depthForTier(0), 5);
      expect(MapGenerator.depthForTier(8), 21);
    });

    test('each region has 4 paths × depth nodes plus one gate', () {
      for (final rank in Rank.values) {
        final region = MapGenerator.generateRegion(rank);
        final depth = MapGenerator.depthForTier(rank.tier);
        expect(region.where((n) => n.isGate).length, 1);
        expect(region.where((n) => !n.isGate).length, 4 * depth);
      }
    });
  });
}

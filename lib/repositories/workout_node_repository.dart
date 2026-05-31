import 'package:hive/hive.dart';

import '../models/enums.dart';
import '../models/workout_node.dart';
import '../services/map_generator.dart';

/// Persistence + graph logic for the world-map nodes.
///
/// The map is regenerated per rank: each rank loads its own region (4 paths ×
/// rank-scaled depth + a Gate). Completed dungeons are terminal — there is no
/// replay (anti-grind), and moving to a new rank regenerates a fresh region.
class WorkoutNodeRepository {
  WorkoutNodeRepository(this._box, this._settings);

  final Box<WorkoutNode> _box;
  final Box<dynamic> _settings;

  static const _kRegionTier = 'map_region_tier';

  /// Ensure the loaded region matches [rank]. Regenerates (wiping the previous
  /// region) when the rank's tier changes or the box is empty.
  Future<void> ensureRegion(Rank rank) async {
    final tier = rank.tier;
    final loaded = _settings.get(_kRegionTier);
    if (loaded == tier && _box.isNotEmpty) {
      await recomputeStatuses();
      return;
    }
    await _box.clear();
    for (final node in MapGenerator.generateRegion(rank)) {
      await _box.put(node.id, node);
    }
    await _settings.put(_kRegionTier, tier);
    await recomputeStatuses();
  }

  List<WorkoutNode> getAll() => _box.values.toList();

  WorkoutNode? getById(String id) => _box.get(id);

  Future<void> save(WorkoutNode node) => _box.put(node.id, node);

  /// Promote `locked` nodes to `unlockable` once prerequisites are met. Normal
  /// nodes need ALL prerequisites cleared; the Gate needs ANY ONE (so clearing
  /// a single full path opens it).
  Future<void> recomputeStatuses() async {
    final all = {for (final n in _box.values) n.id: n};
    for (final node in all.values) {
      if (node.status == NodeStatus.unlocked ||
          node.status == NodeStatus.completed) {
        continue;
      }
      bool cleared(String id) => all[id]?.status == NodeStatus.completed;
      final prereqsMet = node.prerequisiteIds.isEmpty
          ? true
          : (node.isGate
              ? node.prerequisiteIds.any(cleared)
              : node.prerequisiteIds.every(cleared));
      final next = prereqsMet ? NodeStatus.unlockable : NodeStatus.locked;
      if (next != node.status) {
        await _box.put(node.id, node.copyWith(status: next));
      }
    }
  }

  /// Mark a node unlocked (after Crystals are spent by the controller).
  Future<void> markUnlocked(String id) async {
    final node = _box.get(id);
    if (node == null) return;
    await _box.put(id, node.copyWith(status: NodeStatus.unlocked));
  }

  /// Mark a node completed, lift the fog on its successors, and cascade
  /// unlocks. Completion is terminal — the UI never offers a replay, so this
  /// can't be used to farm currency.
  Future<void> markCompleted(String id) async {
    final node = _box.get(id);
    if (node == null) return;
    await _box.put(
      id,
      node.copyWith(
        status: NodeStatus.completed,
        clearCount: node.clearCount + 1,
      ),
    );
    await _revealSuccessors(id);
    await recomputeStatuses();
  }

  /// Reveal every node that lists [id] as a prerequisite (Fog of War lift).
  Future<void> _revealSuccessors(String id) async {
    for (final n in _box.values.toList()) {
      if (!n.revealed && n.prerequisiteIds.contains(id)) {
        await _box.put(n.id, n.copyWith(revealed: true));
      }
    }
  }

  /// Force a full regeneration of the current region on next [ensureRegion].
  Future<void> resetRegion() async {
    await _box.clear();
    await _settings.delete(_kRegionTier);
  }
}

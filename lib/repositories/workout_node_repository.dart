import 'package:hive/hive.dart';

import '../core/constants/default_map.dart';
import '../models/enums.dart';
import '../models/workout_node.dart';

/// Persistence + graph logic for the world-map nodes.
class WorkoutNodeRepository {
  WorkoutNodeRepository(this._box);

  final Box<WorkoutNode> _box;

  /// Seed the default campaign on first run, then normalize statuses.
  Future<void> seedIfEmpty() async {
    if (_box.isEmpty) {
      for (final node in DefaultMap.build()) {
        await _box.put(node.id, node);
      }
    }
    await recomputeStatuses();
  }

  List<WorkoutNode> getAll() => _box.values.toList();

  WorkoutNode? getById(String id) => _box.get(id);

  Future<void> save(WorkoutNode node) => _box.put(node.id, node);

  /// Promote `locked` nodes to `unlockable` once every prerequisite is cleared.
  /// Leaves already-unlocked/completed nodes untouched.
  Future<void> recomputeStatuses() async {
    final all = {for (final n in _box.values) n.id: n};
    for (final node in all.values) {
      if (node.status == NodeStatus.unlocked ||
          node.status == NodeStatus.completed) {
        continue;
      }
      final prereqsMet = node.prerequisiteIds.every(
        (id) => all[id]?.status == NodeStatus.completed,
      );
      final next =
          prereqsMet ? NodeStatus.unlockable : NodeStatus.locked;
      if (next != node.status) {
        await _box.put(node.id, node.copyWith(status: next));
      }
    }
  }

  /// Mark a node unlocked (after coins are spent by the controller).
  Future<void> markUnlocked(String id) async {
    final node = _box.get(id);
    if (node == null) return;
    await _box.put(id, node.copyWith(status: NodeStatus.unlocked));
  }

  /// Mark a node completed, bump its clear count, and cascade unlocks.
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
    await recomputeStatuses();
  }

  /// Reset the entire map back to the seed (for a "new game" action).
  Future<void> resetToDefault() async {
    await _box.clear();
    await seedIfEmpty();
  }
}

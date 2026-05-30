import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/database/database_service.dart';
import '../models/enums.dart';
import '../models/workout_node.dart';
import '../repositories/workout_node_repository.dart';
import 'providers.dart';

final workoutNodeRepositoryProvider =
    Provider<WorkoutNodeRepository>((ref) {
  return WorkoutNodeRepository(DatabaseService.workoutNodesBox);
});

/// Outcome of attempting to unlock a node — lets the UI show the right message.
enum UnlockOutcome { success, notUnlockable, insufficientCoins }

/// Holds the live list of map nodes and owns unlock/complete actions.
final worldMapProvider =
    NotifierProvider<WorldMapNotifier, List<WorkoutNode>>(
        WorldMapNotifier.new);

class WorldMapNotifier extends Notifier<List<WorkoutNode>> {
  WorkoutNodeRepository get _repo => ref.read(workoutNodeRepositoryProvider);

  @override
  List<WorkoutNode> build() {
    // Seed lazily; the box is already open at this point.
    final repo = _repo;
    // Fire-and-forget seed, then read current snapshot.
    repo.seedIfEmpty();
    return repo.getAll();
  }

  void _refresh() => state = _repo.getAll();

  WorkoutNode? byId(String id) =>
      state.where((n) => n.id == id).cast<WorkoutNode?>().firstOrNull;

  /// Spend coins to unlock an `unlockable` node.
  Future<UnlockOutcome> unlock(String id) async {
    final node = byId(id);
    if (node == null || node.status != NodeStatus.unlockable) {
      return UnlockOutcome.notUnlockable;
    }

    final paid =
        await ref.read(rankProfileProvider.notifier).spendCoins(node.unlockCost);
    if (!paid) return UnlockOutcome.insufficientCoins;

    await _repo.markUnlocked(id);
    _refresh();
    return UnlockOutcome.success;
  }

  /// Mark a node cleared (called by the Active Workout flow in the next phase).
  Future<void> markCompleted(String id) async {
    await _repo.markCompleted(id);
    _refresh();
  }
}

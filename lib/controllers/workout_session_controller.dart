import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/enums.dart';
import '../models/exercise_entry.dart';
import '../models/workout_node.dart';
import '../services/exp_engine.dart';
import '../services/overload_engine.dart';
import '../services/stat_engine.dart';
import 'map_controller.dart';
import 'providers.dart';

/// Live state of an in-progress dungeon run: working copies of the node's
/// exercises (so toggling checkmarks never mutates the saved node until the run
/// is committed) plus derived progress.
class WorkoutSession {
  final WorkoutNode node;
  final List<ExerciseEntry> exercises;

  const WorkoutSession({required this.node, required this.exercises});

  int get doneCount => exercises.where((e) => e.completed).length;
  int get total => exercises.length;

  double get progress => total == 0 ? 0 : doneCount / total;
  bool get allDone => total > 0 && doneCount == total;
}

/// Summary returned after committing a run — drives the reward dialog/animations.
class WorkoutReward {
  final ExpAwardResult expResult;
  final Map<StatType, int> statGains;
  final int coinsFromNode;

  const WorkoutReward({
    required this.expResult,
    required this.statGains,
    required this.coinsFromNode,
  });

  int get totalStatPoints => statGains.values.fold(0, (a, b) => a + b);
}

/// Per-node session controller. Use `.call(nodeId)` to obtain the family member.
final workoutSessionProvider = NotifierProvider.family<WorkoutSessionNotifier,
    WorkoutSession, String>(WorkoutSessionNotifier.new);

class WorkoutSessionNotifier
    extends FamilyNotifier<WorkoutSession, String> {
  @override
  WorkoutSession build(String nodeId) {
    final node = ref.read(worldMapProvider.notifier).byId(nodeId);
    if (node == null) {
      // Defensive: empty session if the node vanished.
      return WorkoutSession(
        node: WorkoutNode(id: nodeId, title: 'Unknown'),
        exercises: const [],
      );
    }
    // Fresh, uncompleted working copies.
    return WorkoutSession(
      node: node,
      exercises: node.exercises.map((e) => e.copyWith(completed: false)).toList(),
    );
  }

  /// Toggle a single exercise's checkmark.
  void toggle(int index) {
    final updated = [
      for (var i = 0; i < state.exercises.length; i++)
        if (i == index)
          state.exercises[i].copyWith(completed: !state.exercises[i].completed)
        else
          state.exercises[i],
    ];
    state = WorkoutSession(node: state.node, exercises: updated);
  }

  /// Commit a cleared dungeon: award EXP, distribute stats, pay coins, mark the
  /// node completed, apply progressive overload for next time, and log the day.
  ///
  /// This is the heart of the gameplay loop — all offline, all local.
  Future<WorkoutReward> complete() async {
    final node = state.node;

    // 1. Stat distribution (volume + designer rewards).
    final statGains = StatEngine.distribute(node);
    await ref.read(userStatsProvider.notifier).applyRewards(statGains);

    // 2. EXP (scaled lightly by clear count so replays still pay, but less).
    final expAmount = node.baseExpReward * _replayFactor(node.clearCount);
    final expResult =
        await ref.read(rankProfileProvider.notifier).awardExp(expAmount);

    // 3. Explicit node coin reward (EXP-based coins handled inside awardExp).
    await ref.read(rankProfileProvider.notifier).addCoins(node.coinReward);

    // 4. Progressive overload — persist tougher targets onto the node.
    final progressed = OverloadEngine.progressAll(node.exercises);
    final repo = ref.read(workoutNodeRepositoryProvider);
    await repo.save(node.copyWith(exercises: progressed));

    // 5. Mark completed (cascades unlocks) via the map controller.
    await ref.read(worldMapProvider.notifier).markCompleted(node.id);

    // 6. Log today's consistency for the heatmap.
    await ref.read(consistencyRepositoryProvider).logToday(
          outcome: DayOutcome.complete,
          intensity: 4,
          expEarned: expAmount,
          questsCleared: 1,
        );
    // Invalidate derived heatmap/streak so the dashboard refreshes.
    ref.invalidate(heatmapDataProvider);
    ref.invalidate(streakProvider);

    return WorkoutReward(
      expResult: expResult,
      statGains: statGains,
      coinsFromNode: node.coinReward,
    );
  }

  /// Replays pay diminishing EXP (floor 40%) to discourage farming one node.
  double _replayFactor(int clearCount) =>
      clearCount <= 0 ? 1.0 : (1.0 - clearCount * 0.15).clamp(0.4, 1.0);
}

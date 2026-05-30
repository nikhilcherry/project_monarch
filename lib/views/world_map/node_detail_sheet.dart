import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../models/enums.dart';
import '../../models/workout_node.dart';
import '../../widgets/glow_panel.dart';

/// Bottom sheet shown when a node is tapped: title, difficulty, rewards, the
/// exercise preview, and a context-aware primary action (unlock / start / locked).
class NodeDetailSheet extends StatelessWidget {
  const NodeDetailSheet({
    super.key,
    required this.node,
    required this.onUnlock,
    required this.onStart,
  });

  final WorkoutNode node;
  final VoidCallback onUnlock;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: Text(node.title, style: textTheme.titleLarge),
              ),
              _DifficultyTag(rank: node.difficulty),
            ],
          ),
          const SizedBox(height: 8),
          Text(node.description,
              style: textTheme.bodyMedium
                  ?.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 16),

          // Rewards
          GlowPanel(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _Reward(
                    icon: Icons.bolt,
                    color: AppColors.accent,
                    label: '${node.baseExpReward.toStringAsFixed(0)} EXP'),
                _Reward(
                    icon: Icons.monetization_on,
                    color: AppColors.coin,
                    label: '+${node.coinReward}'),
                _Reward(
                    icon: Icons.show_chart,
                    color: AppColors.success,
                    label: '+${_statTotal()} STAT'),
              ],
            ),
          ),
          const SizedBox(height: 16),

          Text('EXERCISES',
              style: textTheme.labelMedium
                  ?.copyWith(color: AppColors.textSecondary, letterSpacing: 2)),
          const SizedBox(height: 8),
          ...node.exercises.map(
            (e) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  const Icon(Icons.fitness_center,
                      size: 16, color: AppColors.accent),
                  const SizedBox(width: 8),
                  Expanded(child: Text(e.name, style: textTheme.bodyMedium)),
                  Text(
                    '${e.targetSets}×${e.targetReps}'
                    '${e.targetWeight != null ? ' @${e.targetWeight}kg' : ''}',
                    style: textTheme.bodySmall
                        ?.copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          _PrimaryAction(node: node, onUnlock: onUnlock, onStart: onStart),
        ],
      ),
    );
  }

  int _statTotal() =>
      node.statRewards.values.fold(0, (a, b) => a + b);
}

class _PrimaryAction extends StatelessWidget {
  const _PrimaryAction({
    required this.node,
    required this.onUnlock,
    required this.onStart,
  });

  final WorkoutNode node;
  final VoidCallback onUnlock;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return switch (node.status) {
      NodeStatus.locked => SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: null,
            icon: const Icon(Icons.lock),
            label: const Text('LOCKED — CLEAR PREREQUISITES'),
          ),
        ),
      NodeStatus.unlockable => SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: onUnlock,
            icon: const Icon(Icons.diamond, size: 18),
            label: Text('UNLOCK — ${node.unlockCost} CRYSTALS'),
          ),
        ),
      NodeStatus.unlocked || NodeStatus.completed => SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: onStart,
            icon: const Icon(Icons.play_arrow),
            label: Text(node.isCompleted ? 'REPLAY DUNGEON' : 'ENTER DUNGEON'),
          ),
        ),
    };
  }
}

class _DifficultyTag extends StatelessWidget {
  const _DifficultyTag({required this.rank});
  final Rank rank;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.accent.withOpacity(0.5)),
      ),
      child: Text(rank.label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: AppColors.accent,
                letterSpacing: 1,
              )),
    );
  }
}

class _Reward extends StatelessWidget {
  const _Reward(
      {required this.icon, required this.color, required this.label});
  final IconData icon;
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 4),
        Text(label,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: AppColors.textPrimary)),
      ],
    );
  }
}

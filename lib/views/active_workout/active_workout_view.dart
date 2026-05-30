import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../controllers/workout_session_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../models/exercise_entry.dart';
import '../../widgets/glow_panel.dart';
import '../../widgets/reward_dialog.dart';

/// The fast, clean active-workout checklist. Tick each exercise; once all are
/// done the "CLEAR DUNGEON" action commits rewards and pops back to the map.
class ActiveWorkoutView extends ConsumerWidget {
  const ActiveWorkoutView({super.key, required this.nodeId});

  final String nodeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(workoutSessionProvider(nodeId));
    final notifier = ref.read(workoutSessionProvider(nodeId).notifier);

    return Scaffold(
      appBar: AppBar(
        title: Text(session.node.title.toUpperCase()),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _ProgressBar(progress: session.progress),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: session.exercises.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, i) => _ExerciseTile(
                  entry: session.exercises[i],
                  onToggle: () => notifier.toggle(i),
                ),
              ),
            ),
            _CompleteBar(
              enabled: session.allDone,
              doneCount: session.doneCount,
              total: session.total,
              onComplete: () => _complete(context, ref),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _complete(BuildContext context, WidgetRef ref) async {
    final reward =
        await ref.read(workoutSessionProvider(nodeId).notifier).complete();
    if (!context.mounted) return;
    await RewardDialog.show(context, reward);
    if (context.mounted) Navigator.of(context).pop();
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.progress});
  final double progress;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(height: 4, color: AppColors.surfaceElevated),
        LayoutBuilder(
          builder: (context, c) => Container(
            height: 4,
            width: c.maxWidth * progress,
            decoration: BoxDecoration(
              gradient: AppColors.accentGradient,
              boxShadow: [
                BoxShadow(
                  color: AppColors.accent.withValues(alpha: 0.7),
                  blurRadius: 8,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ExerciseTile extends StatelessWidget {
  const _ExerciseTile({required this.entry, required this.onToggle});
  final ExerciseEntry entry;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final done = entry.completed;

    return GestureDetector(
      onTap: onToggle,
      child: GlowPanel(
        glow: done,
        borderColor: done ? AppColors.success : AppColors.accent,
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            // Custom check indicator.
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: done ? AppColors.success : Colors.transparent,
                border: Border.all(
                  color: done ? AppColors.success : AppColors.textSecondary,
                  width: 2,
                ),
              ),
              child: done
                  ? const Icon(Icons.check,
                      size: 18, color: AppColors.background)
                  : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.name,
                    style: textTheme.titleMedium?.copyWith(
                      color: done
                          ? AppColors.textSecondary
                          : AppColors.textPrimary,
                      decoration:
                          done ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${entry.targetSets} sets × ${entry.targetReps} reps'
                    '${entry.targetWeight != null ? ' @ ${entry.targetWeight}kg' : ''}'
                    ' · ${entry.restSeconds}s rest',
                    style: textTheme.bodySmall
                        ?.copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CompleteBar extends StatelessWidget {
  const _CompleteBar({
    required this.enabled,
    required this.doneCount,
    required this.total,
    required this.onComplete,
  });

  final bool enabled;
  final int doneCount;
  final int total;
  final VoidCallback onComplete;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton.icon(
          onPressed: enabled ? onComplete : null,
          icon: const Icon(Icons.verified),
          label: Text(
            enabled
                ? 'CLEAR DUNGEON'
                : 'COMPLETE ALL ($doneCount/$total)',
          ),
        ),
      ),
    );
  }
}

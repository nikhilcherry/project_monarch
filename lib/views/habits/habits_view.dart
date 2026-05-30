import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../controllers/habits_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../models/enums.dart';
import '../../models/habit.dart';
import '../../widgets/glow_panel.dart';
import '../../widgets/system_warning_dialog.dart';

/// Manual VIT wellness habits. Each check-off passes through a "System Warning"
/// honesty gate before awarding its stat and extending the streak.
class HabitsView extends ConsumerWidget {
  const HabitsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final habits = ref.watch(habitsProvider);
    final notifier = ref.read(habitsProvider.notifier);
    final doneToday = notifier.doneTodayCount;

    return Scaffold(
      appBar: AppBar(title: const Text('VITALITY')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            GlowPanel(
              glow: true,
              child: Row(
                children: [
                  const Icon(Icons.favorite,
                      color: AppColors.vit, size: 28),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('DAILY WELLNESS',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(letterSpacing: 1.5)),
                        Text('$doneToday / ${habits.length} completed today',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            ...habits.map((h) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _HabitTile(
                    habit: h,
                    done: notifier.isDoneToday(h),
                    onTap: () => _attemptComplete(context, ref, h),
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Future<void> _attemptComplete(
      BuildContext context, WidgetRef ref, Habit habit) async {
    final notifier = ref.read(habitsProvider.notifier);
    if (notifier.isDoneToday(habit)) return;

    final confirmed = await SystemWarningDialog.show(context, habit.title);
    if (!confirmed) return;

    await notifier.confirmComplete(habit);
  }
}

class _HabitTile extends StatelessWidget {
  const _HabitTile({
    required this.habit,
    required this.done,
    required this.onTap,
  });

  final Habit habit;
  final bool done;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return GestureDetector(
      onTap: done ? null : onTap,
      child: GlowPanel(
        glow: done,
        borderColor: done ? AppColors.success : AppColors.accent,
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 30,
              height: 30,
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
                  Text(habit.title,
                      style: textTheme.titleMedium?.copyWith(
                        color: done
                            ? AppColors.textSecondary
                            : AppColors.textPrimary,
                      )),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(habit.category.label,
                          style: textTheme.bodySmall
                              ?.copyWith(color: AppColors.textSecondary)),
                      const SizedBox(width: 8),
                      _StatChip(stat: habit.feedsStat, amount: habit.statReward),
                    ],
                  ),
                ],
              ),
            ),
            if (habit.streak > 0) _StreakBadge(streak: habit.streak),
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.stat, required this.amount});
  final StatType stat;
  final int amount;

  @override
  Widget build(BuildContext context) {
    return Text('+$amount ${stat.short}',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.accent,
              fontWeight: FontWeight.w700,
            ));
  }
}

class _StreakBadge extends StatelessWidget {
  const _StreakBadge({required this.streak});
  final int streak;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.local_fire_department,
            color: AppColors.warning, size: 16),
        const SizedBox(width: 2),
        Text('$streak',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppColors.warning,
                )),
      ],
    );
  }
}

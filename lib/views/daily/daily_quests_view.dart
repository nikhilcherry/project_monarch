import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../controllers/daily_quests_controller.dart';
import '../../controllers/providers.dart';
import '../../core/constants/app_colors.dart';
import '../../widgets/glow_panel.dart';

/// The Daily Quests screen — the renewable Crystal tap. Claim the three quests
/// for Crystals (World Map currency) + Coins, and keep a daily streak going for
/// a weekly bonus.
class DailyQuestsView extends ConsumerWidget {
  const DailyQuestsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final daily = ref.watch(dailyQuestsProvider);
    final crystals = ref.watch(rankProfileProvider).crystals;

    return Scaffold(
      appBar: AppBar(
        title: const Text('DAILY QUESTS'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Row(
              children: [
                const Icon(Icons.diamond, color: AppColors.crystal, size: 18),
                const SizedBox(width: 4),
                Text('$crystals',
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(color: AppColors.crystal)),
              ],
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _StreakPanel(
              streak: daily.streak,
              target: daily.streakTarget,
              reward: daily.streakCrystalReward,
            ),
            const SizedBox(height: 16),
            const PanelLabel('Today\'s Quests'),
            const SizedBox(height: 12),
            ...daily.quests.map(
              (q) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _QuestCard(
                  vm: q,
                  onClaim: () => _claim(context, ref, q),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _claim(
      BuildContext context, WidgetRef ref, DailyQuestVm q) async {
    final granted = await ref.read(dailyQuestsProvider.notifier).claim(q.kind);
    if (!context.mounted || granted <= 0) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Claimed +$granted Crystals.')),
    );
  }
}

class _StreakPanel extends StatelessWidget {
  const _StreakPanel({
    required this.streak,
    required this.target,
    required this.reward,
  });

  final int streak;
  final int target;
  final int reward;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final intoCycle = target == 0 ? 0 : streak % target;
    final progress = target == 0 ? 0.0 : intoCycle / target;

    return GlowPanel(
      glow: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.local_fire_department,
                  color: AppColors.warning, size: 26),
              const SizedBox(width: 10),
              Text('$streak DAY STREAK',
                  style: textTheme.titleMedium
                      ?.copyWith(color: AppColors.warning, letterSpacing: 1.5)),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Stack(
              children: [
                Container(height: 8, color: AppColors.surfaceElevated),
                LayoutBuilder(
                  builder: (context, c) => Container(
                    height: 8,
                    width: c.maxWidth * progress,
                    decoration: const BoxDecoration(
                      gradient: AppColors.accentGradient,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${target - intoCycle} day(s) to the +$reward Crystal weekly bonus',
            style: textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _QuestCard extends StatelessWidget {
  const _QuestCard({required this.vm, required this.onClaim});

  final DailyQuestVm vm;
  final VoidCallback onClaim;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final borderColor = vm.claimed
        ? AppColors.success
        : (vm.available ? AppColors.crystal : AppColors.textDisabled);

    return GlowPanel(
      glow: vm.claimable,
      borderColor: borderColor,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(vm.title,
                    softWrap: true,
                    maxLines: 2,
                    style: textTheme.titleMedium),
                const SizedBox(height: 2),
                Text(vm.description,
                    softWrap: true,
                    style: textTheme.bodySmall
                        ?.copyWith(color: AppColors.textSecondary)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.diamond,
                        color: AppColors.crystal, size: 14),
                    const SizedBox(width: 4),
                    Text('+${vm.crystals}',
                        style: textTheme.labelMedium
                            ?.copyWith(color: AppColors.crystal)),
                    const SizedBox(width: 12),
                    const Icon(Icons.monetization_on,
                        color: AppColors.coin, size: 14),
                    const SizedBox(width: 4),
                    Text('+${vm.coins}',
                        style: textTheme.labelMedium
                            ?.copyWith(color: AppColors.coin)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _ClaimButton(vm: vm, onClaim: onClaim),
        ],
      ),
    );
  }
}

class _ClaimButton extends StatelessWidget {
  const _ClaimButton({required this.vm, required this.onClaim});

  final DailyQuestVm vm;
  final VoidCallback onClaim;

  @override
  Widget build(BuildContext context) {
    if (vm.claimed) {
      return const Icon(Icons.check_circle, color: AppColors.success, size: 28);
    }
    if (!vm.available) {
      return Text('LOCKED',
          style: Theme.of(context)
              .textTheme
              .labelMedium
              ?.copyWith(color: AppColors.textDisabled, letterSpacing: 1));
    }
    return ElevatedButton(onPressed: onClaim, child: const Text('CLAIM'));
  }
}

import 'package:flutter/material.dart';

import '../controllers/workout_session_controller.dart';
import '../core/constants/app_colors.dart';
import '../models/enums.dart';

/// The "System" victory panel shown after clearing a dungeon: EXP gained, any
/// LEVEL/RANK UP banner, stat gains, and coins.
class RewardDialog extends StatelessWidget {
  const RewardDialog({super.key, required this.reward});

  final WorkoutReward reward;

  static Future<void> show(BuildContext context, WorkoutReward reward) {
    return showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.85),
      builder: (_) => RewardDialog(reward: reward),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final exp = reward.expResult;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.accent, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: AppColors.accent.withValues(alpha: 0.4),
              blurRadius: 40,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('DUNGEON CLEARED',
                style: textTheme.titleLarge?.copyWith(
                  color: AppColors.accent,
                  letterSpacing: 3,
                )),
            const SizedBox(height: 4),
            Container(width: 60, height: 2, color: AppColors.accent),
            const SizedBox(height: 20),

            // Rank / Level up banners.
            if (exp.rankedUp)
              _Banner(
                text: 'RANK UP → ${exp.profile.rank.label}',
                color: AppColors.warning,
              ),
            if (exp.leveledUp && !exp.rankedUp)
              _Banner(
                text: 'LEVEL UP → Lv${exp.profile.level}',
                color: AppColors.success,
              ),
            if (exp.leveledUp || exp.rankedUp) const SizedBox(height: 16),

            _RewardRow(
              icon: Icons.bolt,
              color: AppColors.accent,
              label: 'EXP',
              value: '+${exp.expGained.toStringAsFixed(0)}',
            ),
            _RewardRow(
              icon: Icons.monetization_on,
              color: AppColors.coin,
              label: 'Coins',
              value: '+${reward.coinsFromNode + exp.coinsGained}',
            ),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 12),

            // Stat gains grid.
            Wrap(
              spacing: 16,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: reward.statGains.entries
                  .where((e) => e.value > 0)
                  .map((e) => _StatGain(type: e.key, amount: e.value))
                  .toList(),
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('CONTINUE'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({required this.text, required this.color});
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color),
      ),
      alignment: Alignment.center,
      child: Text(text,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: color,
                letterSpacing: 2,
                fontWeight: FontWeight.w700,
              )),
    );
  }
}

class _RewardRow extends StatelessWidget {
  const _RewardRow({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final Color color;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Text(label, style: textTheme.bodyLarge),
          const Spacer(),
          Text(value,
              style: textTheme.titleMedium
                  ?.copyWith(color: color, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _StatGain extends StatelessWidget {
  const _StatGain({required this.type, required this.amount});
  final StatType type;
  final int amount;

  static const Map<StatType, Color> _colors = {
    StatType.str: AppColors.str,
    StatType.agi: AppColors.agi,
    StatType.vit: AppColors.vit,
    StatType.end: AppColors.end,
    StatType.flex: AppColors.flex,
  };

  @override
  Widget build(BuildContext context) {
    final color = _colors[type]!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.6)),
      ),
      child: Text('${type.short} +$amount',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              )),
    );
  }
}

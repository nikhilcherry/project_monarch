import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../models/penalty_quest.dart';

/// A pulsing red alert shown on the dashboard when penalty quests are active.
class PenaltyBanner extends StatelessWidget {
  const PenaltyBanner({super.key, required this.quest, required this.onTap});

  final PenaltyQuest quest;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.danger.withOpacity(0.10),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.danger, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: AppColors.danger.withOpacity(0.3),
              blurRadius: 24,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.warning_amber_rounded,
                color: AppColors.danger, size: 28),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('PENALTY QUEST ACTIVE',
                      style: textTheme.titleSmall?.copyWith(
                        color: AppColors.danger,
                        letterSpacing: 1.5,
                      )),
                  const SizedBox(height: 2),
                  Text(quest.reason,
                      style: textTheme.bodySmall
                          ?.copyWith(color: AppColors.textSecondary)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.danger),
          ],
        ),
      ),
    );
  }
}

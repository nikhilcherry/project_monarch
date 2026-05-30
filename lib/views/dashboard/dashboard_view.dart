import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../controllers/providers.dart';
import '../../core/constants/app_colors.dart';
import '../../widgets/consistency_heatmap.dart';
import '../../widgets/glow_panel.dart';
import '../../widgets/rank_header.dart';
import '../../widgets/stat_radar_chart.dart';

/// The hunter's status screen: rank/EXP hero, the pentagon stat radar, and the
/// 365-day consistency heatmap. Everything reads from local Hive via Riverpod.
class DashboardView extends ConsumerWidget {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(rankProfileProvider);
    final stats = ref.watch(userStatsProvider);
    final heatmap = ref.watch(heatmapDataProvider);
    final streak = ref.watch(streakProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('STATUS'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: _StreakChip(days: streak),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            RankHeader(profile: profile),
            const SizedBox(height: 20),

            // --- Attribute radar ------------------------------------------
            GlowPanel(
              child: Column(
                children: [
                  const PanelLabel('Attributes'),
                  const SizedBox(height: 8),
                  StatRadarChart(stats: stats),
                  const SizedBox(height: 12),
                  StatLegend(stats: stats),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // --- Consistency heatmap --------------------------------------
            GlowPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  PanelLabel(
                    'Consistency',
                    trailing: Text(
                      '$streak DAY STREAK',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: AppColors.accent,
                            letterSpacing: 1.2,
                          ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ConsistencyHeatmap(data: heatmap),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StreakChip extends StatelessWidget {
  const _StreakChip({required this.days});
  final int days;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.local_fire_department,
          size: 18,
          color: days > 0 ? AppColors.warning : AppColors.textDisabled,
        ),
        const SizedBox(width: 4),
        Text('$days',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: days > 0 ? AppColors.warning : AppColors.textDisabled,
                )),
      ],
    );
  }
}

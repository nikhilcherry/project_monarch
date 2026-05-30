import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../models/enums.dart';
import '../models/user_stats.dart';

/// The pentagon radar chart of the five attributes (STR/AGI/VIT/END/FLEX),
/// rendered in the signature neon-on-black style.
class StatRadarChart extends StatelessWidget {
  const StatRadarChart({super.key, required this.stats});

  final UserStats stats;

  // Stable axis order around the pentagon.
  static const List<StatType> _order = [
    StatType.str,
    StatType.agi,
    StatType.vit,
    StatType.end,
    StatType.flex,
  ];

  @override
  Widget build(BuildContext context) {
    final values = _order.map((t) => stats.valueOf(t).toDouble()).toList();
    final maxValue = (values.reduce((a, b) => a > b ? a : b)).clamp(10, 9999);
    // Round the tick ceiling up so the web has breathing room.
    final ceiling = (maxValue * 1.25);

    return AspectRatio(
      aspectRatio: 1,
      child: RadarChart(
        RadarChartData(
          radarShape: RadarShape.polygon,
          tickCount: 4,
          ticksTextStyle: const TextStyle(color: Colors.transparent, fontSize: 0),
          radarBorderData:
              const BorderSide(color: AppColors.border, width: 1),
          gridBorderData:
              BorderSide(color: AppColors.accent.withValues(alpha: 0.15), width: 1),
          tickBorderData:
              BorderSide(color: AppColors.accent.withValues(alpha: 0.10), width: 1),
          radarBackgroundColor: Colors.transparent,
          borderData: FlBorderData(show: false),
          titlePositionPercentageOffset: 0.15,
          getTitle: (index, angle) => RadarChartTitle(
            text: _order[index].short,
            angle: 0,
          ),
          titleTextStyle: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: AppColors.textPrimary,
                letterSpacing: 1.5,
                fontWeight: FontWeight.w700,
              ),
          dataSets: [
            RadarDataSet(
              dataEntries:
                  values.map((v) => RadarEntry(value: v)).toList(),
              fillColor: AppColors.accent.withValues(alpha: 0.22),
              borderColor: AppColors.accent,
              borderWidth: 2,
              entryRadius: 3,
            ),
            // Invisible anchor entry to fix the chart's scale ceiling.
            RadarDataSet(
              dataEntries: List.generate(
                  _order.length, (_) => RadarEntry(value: ceiling.toDouble())),
              fillColor: Colors.transparent,
              borderColor: Colors.transparent,
              entryRadius: 0,
            ),
          ],
        ),
      ),
    );
  }
}

/// Compact legend pairing each stat with its current value + accent color.
class StatLegend extends StatelessWidget {
  const StatLegend({super.key, required this.stats});
  final UserStats stats;

  static const Map<StatType, Color> _colors = {
    StatType.str: AppColors.str,
    StatType.agi: AppColors.agi,
    StatType.vit: AppColors.vit,
    StatType.end: AppColors.end,
    StatType.flex: AppColors.flex,
  };

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 14,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: StatType.values.map((t) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 8, height: 8, color: _colors[t]),
            const SizedBox(width: 6),
            Text('${t.short} ${stats.valueOf(t)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textPrimary,
                    )),
          ],
        );
      }).toList(),
    );
  }
}

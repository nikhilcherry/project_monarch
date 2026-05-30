import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';

/// The 365-day glowing consistency grid, hand-painted with core Flutter only
/// (no third-party heatmap dependency). Columns are weeks (oldest → newest),
/// rows are weekdays (Mon → Sun). Intensity 0–4 maps to a deepening neon ramp.
class ConsistencyHeatmap extends StatelessWidget {
  const ConsistencyHeatmap({super.key, required this.data});

  /// {DateTime(date-only): intensity 0–4}.
  final Map<DateTime, int> data;

  static const double _cell = 12;
  static const double _gap = 3;

  Color _colorFor(int intensity) => switch (intensity) {
        >= 4 => AppColors.accent,
        3 => AppColors.accent.withOpacity(0.70),
        2 => AppColors.accent.withOpacity(0.40),
        1 => AppColors.accent.withOpacity(0.20),
        _ => AppColors.surfaceElevated,
      };

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // ~52 weeks back, aligned so each column starts on a Monday.
    final roughStart = today.subtract(const Duration(days: 363));
    final start =
        roughStart.subtract(Duration(days: roughStart.weekday - 1));
    final totalDays = today.difference(start).inDays + 1;
    final weeks = (totalDays / 7).ceil();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      reverse: true, // newest weeks visible first
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(weeks, (w) {
          return Padding(
            padding: const EdgeInsets.only(right: _gap),
            child: Column(
              children: List.generate(7, (d) {
                final date = start.add(Duration(days: w * 7 + d));
                final isFuture = date.isAfter(today);
                final intensity = data[DateTime(date.year, date.month, date.day)] ?? 0;
                return Padding(
                  padding: const EdgeInsets.only(bottom: _gap),
                  child: Container(
                    width: _cell,
                    height: _cell,
                    decoration: BoxDecoration(
                      color: isFuture
                          ? Colors.transparent
                          : _colorFor(intensity),
                      borderRadius: BorderRadius.circular(2),
                      boxShadow: intensity >= 4
                          ? [
                              BoxShadow(
                                color: AppColors.accent.withOpacity(0.6),
                                blurRadius: 6,
                              ),
                            ]
                          : null,
                    ),
                  ),
                );
              }),
            ),
          );
        }),
      ),
    );
  }
}

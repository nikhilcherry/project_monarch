import 'package:flutter/material.dart';
import 'package:flutter_heatmap_calendar/flutter_heatmap_calendar.dart';

import '../core/constants/app_colors.dart';

/// The 365-day glowing consistency grid. Intensity 0–4 maps to deepening neon.
class ConsistencyHeatmap extends StatelessWidget {
  const ConsistencyHeatmap({super.key, required this.data});

  /// {DateTime(date-only): intensity 0–4}.
  final Map<DateTime, int> data;

  // Intensity → glow color ramp (true black base → full neon).
  static final Map<int, Color> _colorsets = {
    1: AppColors.accent.withOpacity(0.20),
    2: AppColors.accent.withOpacity(0.40),
    3: AppColors.accent.withOpacity(0.70),
    4: AppColors.accent,
  };

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return HeatMap(
      startDate: now.subtract(const Duration(days: 364)),
      endDate: now,
      datasets: data,
      colorMode: ColorMode.color,
      defaultColor: AppColors.surfaceElevated,
      textColor: AppColors.textSecondary,
      showColorTip: false,
      showText: false,
      scrollable: true,
      size: 14,
      margin: const EdgeInsets.all(2),
      borderRadius: 3,
      colorsets: _colorsets,
    );
  }
}

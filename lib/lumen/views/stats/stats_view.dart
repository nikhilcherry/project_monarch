import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../controllers/prefs_controller.dart';
import '../../controllers/providers.dart';
import '../../core/theme/lumen_palette.dart';
import '../../core/theme/lumen_typography.dart';
import '../../models/reading_session.dart';

class StatsView extends ConsumerWidget {
  const StatsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(prefsControllerProvider);
    final palette = settings.palette;
    final sessions = ref.watch(sessionRepositoryProvider).all();
    final currentWpm = sessions.isNotEmpty ? sessions.last.wpm : settings.defaultWpm;

    return Scaffold(
      appBar: AppBar(title: Text('Statistics', style: LumenType.titleSerif(palette.heading))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
        children: [
          Row(
            children: [
              Expanded(child: _StatCard(palette: palette, label: 'WORDS\nREAD', value: _words(settings.totalWordsRead))),
              const SizedBox(width: 16),
              Expanded(child: _StatCard(palette: palette, label: 'TIME\nFOCUSED', value: _time(settings.totalReadMs))),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _StatCard(palette: palette, label: 'CURRENT\nWPM', value: '$currentWpm')),
              const SizedBox(width: 16),
              Expanded(child: _StatCard(palette: palette, label: 'STREAK', value: '${settings.streakDays}d')),
            ],
          ),
          const SizedBox(height: 36),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('READING VELOCITY', style: LumenType.overline(palette.caption)),
              Text('Recent sessions',
                  style: LumenType.caption(palette.caption).copyWith(fontStyle: FontStyle.italic)),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            height: 200,
            padding: const EdgeInsets.fromLTRB(8, 20, 16, 8),
            decoration: BoxDecoration(
              color: palette.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: palette.border),
            ),
            child: _VelocityChart(palette: palette, sessions: sessions),
          ),
        ],
      ),
    );
  }

  static String _words(int n) {
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(n >= 10000 ? 0 : 1)}k';
    return '$n';
  }

  static String _time(int ms) {
    final mins = ms ~/ 60000;
    if (mins >= 60) return '${mins ~/ 60}h';
    return '${mins}m';
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.palette, required this.label, required this.value});
  final LumenPalette palette;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 150,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: LumenType.overline(palette.caption)),
          Text(value, style: LumenType.headlineLg(palette.accent).copyWith(fontSize: 40)),
        ],
      ),
    );
  }
}

class _VelocityChart extends StatelessWidget {
  const _VelocityChart({required this.palette, required this.sessions});
  final LumenPalette palette;
  final List<ReadingSession> sessions;

  @override
  Widget build(BuildContext context) {
    final wpms = sessions.map((s) => s.wpm.toDouble()).toList();
    // Need at least two points to draw a line; pad with a sensible baseline.
    final series = switch (wpms.length) {
      0 => <double>[280, 300],
      1 => [wpms.first, wpms.first],
      _ => wpms.length > 16 ? wpms.sublist(wpms.length - 16) : wpms,
    };
    final spots = [
      for (var i = 0; i < series.length; i++) FlSpot(i.toDouble(), series[i]),
    ];
    final minY = (series.reduce((a, b) => a < b ? a : b) - 40).clamp(0, 2000).toDouble();
    final maxY = series.reduce((a, b) => a > b ? a : b) + 40;

    return LineChart(
      LineChartData(
        minY: minY,
        maxY: maxY,
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: const FlTitlesData(show: false),
        lineTouchData: const LineTouchData(enabled: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.3,
            color: palette.accent,
            barWidth: 3,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  palette.accent.withValues(alpha: 0.30),
                  palette.accent.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

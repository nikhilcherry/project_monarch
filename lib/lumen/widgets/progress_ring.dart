import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/theme/lumen_typography.dart';

/// A thin circular progress ring — the recurring Lumen progress motif
/// (Continue-reading card, chapter rows, the Boost screen).
class ProgressRing extends StatelessWidget {
  const ProgressRing({
    super.key,
    required this.progress,
    required this.accent,
    required this.track,
    this.size = 44,
    this.stroke = 2.5,
    this.label,
    this.labelColor,
  });

  final double progress; // 0..1
  final Color accent;
  final Color track;
  final double size;
  final double stroke;
  final String? label;
  final Color? labelColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _RingPainter(
          progress: progress.clamp(0.0, 1.0),
          accent: accent,
          track: track,
          stroke: stroke,
        ),
        child: label == null
            ? null
            : Center(
                child: Text(
                  label!,
                  style: LumenType.caption(labelColor ?? accent)
                      .copyWith(fontWeight: FontWeight.w600, fontSize: size * 0.24),
                ),
              ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.progress,
    required this.accent,
    required this.track,
    required this.stroke,
  });

  final double progress;
  final Color accent;
  final Color track;
  final double stroke;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = (size.shortestSide - stroke) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = track;
    canvas.drawCircle(center, radius, trackPaint);

    if (progress > 0) {
      final arcPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..color = accent;
      canvas.drawArc(rect, -math.pi / 2, 2 * math.pi * progress, false, arcPaint);
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress ||
      old.accent != accent ||
      old.track != track ||
      old.stroke != stroke;
}

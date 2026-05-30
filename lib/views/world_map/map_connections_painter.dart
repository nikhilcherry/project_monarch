import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../models/enums.dart';
import '../../models/workout_node.dart';

/// Paints the glowing edges of the branching map. An edge lights up neon once
/// its source node is completed (a cleared path); otherwise it reads as a faint
/// dormant line.
class MapConnectionsPainter extends CustomPainter {
  MapConnectionsPainter(this.nodes);

  final List<WorkoutNode> nodes;

  @override
  void paint(Canvas canvas, Size size) {
    final byId = {for (final n in nodes) n.id: n};

    for (final node in nodes) {
      for (final prereqId in node.prerequisiteIds) {
        final from = byId[prereqId];
        if (from == null) continue;

        final p1 = Offset(from.x * size.width, from.y * size.height);
        final p2 = Offset(node.x * size.width, node.y * size.height);

        // A path is "active" when the prerequisite is cleared.
        final active = from.status == NodeStatus.completed;

        final paint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = active ? 3 : 2
          ..strokeCap = StrokeCap.round
          ..color = active
              ? AppColors.accent.withValues(alpha: 0.9)
              : AppColors.border;

        if (active) {
          paint.maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
        }

        // Gentle vertical S-curve between nodes for an organic "circuit" look.
        final path = Path()
          ..moveTo(p1.dx, p1.dy)
          ..cubicTo(
            p1.dx,
            (p1.dy + p2.dy) / 2,
            p2.dx,
            (p1.dy + p2.dy) / 2,
            p2.dx,
            p2.dy,
          );
        canvas.drawPath(path, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant MapConnectionsPainter oldDelegate) =>
      oldDelegate.nodes != nodes;
}

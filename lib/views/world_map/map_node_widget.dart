import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../models/enums.dart';
import '../../models/workout_node.dart';

/// A single tappable node on the world map. Styling encodes status at a glance:
/// locked (dim), unlockable (pulsing coin price), unlocked (solid neon),
/// completed (filled check + steady glow).
class MapNodeWidget extends StatelessWidget {
  const MapNodeWidget({
    super.key,
    required this.node,
    required this.onTap,
    this.diameter = 64,
  });

  final WorkoutNode node;
  final VoidCallback onTap;
  final double diameter;

  @override
  Widget build(BuildContext context) {
    if (!node.revealed) return _FoggedNode(diameter: diameter);

    final style = _styleFor(node.status);

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: diameter,
        height: diameter + 42, // room for a two-line (untruncated) title below
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: diameter,
              height: diameter,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: style.fill,
                border: Border.all(color: style.border, width: 2),
                boxShadow: style.glow
                    ? [
                        BoxShadow(
                          color: style.border.withOpacity(0.6),
                          blurRadius: 20,
                          spreadRadius: 1,
                        ),
                      ]
                    : null,
              ),
              child: Icon(style.icon, color: style.iconColor, size: 26),
            ),
            const SizedBox(height: 4),
            Flexible(
              child: Text(
                node.title,
                maxLines: 2,
                softWrap: true,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: style.glow
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                      letterSpacing: 0.5,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  _NodeStyle _styleFor(NodeStatus status) => switch (status) {
        NodeStatus.locked => const _NodeStyle(
            fill: AppColors.surface,
            border: AppColors.textDisabled,
            icon: Icons.lock,
            iconColor: AppColors.textDisabled,
            glow: false,
          ),
        NodeStatus.unlockable => const _NodeStyle(
            fill: AppColors.surfaceElevated,
            border: AppColors.crystal,
            icon: Icons.diamond,
            iconColor: AppColors.crystal,
            glow: true,
          ),
        NodeStatus.unlocked => const _NodeStyle(
            fill: AppColors.surfaceElevated,
            border: AppColors.accent,
            icon: Icons.play_arrow,
            iconColor: AppColors.accent,
            glow: true,
          ),
        NodeStatus.completed => const _NodeStyle(
            fill: AppColors.accent,
            border: AppColors.accent,
            icon: Icons.check,
            iconColor: AppColors.background,
            glow: true,
          ),
      };
}

class _NodeStyle {
  const _NodeStyle({
    required this.fill,
    required this.border,
    required this.icon,
    required this.iconColor,
    required this.glow,
  });

  final Color fill;
  final Color border;
  final IconData icon;
  final Color iconColor;
  final bool glow;
}

/// An undiscovered node under the Fog of War — a dim, blurred dot with no label
/// and no interaction. It hints that the region continues without revealing it.
class _FoggedNode extends StatelessWidget {
  const _FoggedNode({required this.diameter});

  final double diameter;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: SizedBox(
        width: diameter,
        height: diameter + 42,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
              child: Container(
                width: diameter * 0.7,
                height: diameter * 0.7,
                margin: EdgeInsets.all(diameter * 0.15),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.surfaceElevated.withOpacity(0.6),
                  border: Border.all(
                    color: AppColors.textDisabled.withOpacity(0.4),
                  ),
                ),
                child: const Icon(Icons.question_mark,
                    color: AppColors.textDisabled, size: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

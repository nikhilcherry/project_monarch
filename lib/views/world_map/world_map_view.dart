import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../controllers/map_controller.dart';
import '../../controllers/providers.dart';
import '../../core/constants/app_colors.dart';
import '../../models/workout_node.dart';
import 'map_connections_painter.dart';
import 'map_node_widget.dart';
import 'node_detail_sheet.dart';

/// The branching campaign map. A pan/zoomable canvas: glowing edges painted
/// behind status-styled nodes positioned by their normalized coordinates.
class WorldMapView extends ConsumerWidget {
  const WorldMapView({super.key});

  // Logical canvas size — larger than the viewport so the map feels expansive
  // and is explorable via InteractiveViewer.
  static const double _canvasWidth = 900;
  static const double _canvasHeight = 1400;
  static const double _nodeDiameter = 64;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nodes = ref.watch(worldMapProvider);
    final coins = ref.watch(rankProfileProvider).coins;

    return Scaffold(
      appBar: AppBar(
        title: const Text('WORLD MAP'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Row(
              children: [
                const Icon(Icons.monetization_on,
                    color: AppColors.coin, size: 18),
                const SizedBox(width: 4),
                Text('$coins',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: AppColors.coin,
                        )),
              ],
            ),
          ),
        ],
      ),
      body: InteractiveViewer(
        constrained: false,
        minScale: 0.5,
        maxScale: 2.5,
        boundaryMargin: const EdgeInsets.all(80),
        child: SizedBox(
          width: _canvasWidth,
          height: _canvasHeight,
          child: Stack(
            children: [
              // Edges behind everything.
              Positioned.fill(
                child: CustomPaint(
                  painter: MapConnectionsPainter(nodes),
                ),
              ),
              // Nodes positioned by normalized coords.
              for (final node in nodes)
                Positioned(
                  left: node.x * _canvasWidth - _nodeDiameter / 2,
                  top: node.y * _canvasHeight - _nodeDiameter / 2,
                  child: MapNodeWidget(
                    node: node,
                    diameter: _nodeDiameter,
                    onTap: () => _openNode(context, ref, node),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _openNode(BuildContext context, WidgetRef ref, WorkoutNode node) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (sheetContext) => NodeDetailSheet(
        node: node,
        onUnlock: () async {
          final outcome =
              await ref.read(worldMapProvider.notifier).unlock(node.id);
          if (sheetContext.mounted) Navigator.of(sheetContext).pop();
          if (context.mounted) _showUnlockResult(context, outcome);
        },
        onStart: () {
          Navigator.of(sheetContext).pop();
          // Active Workout flow lands in the next phase (5c). For now, surface
          // intent so the navigation contract is clear.
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Entering ${node.title}… (workout in 5c)')),
          );
        },
      ),
    );
  }

  void _showUnlockResult(BuildContext context, UnlockOutcome outcome) {
    final message = switch (outcome) {
      UnlockOutcome.success => 'Gate unlocked. The path opens.',
      UnlockOutcome.insufficientCoins =>
        'System Warning: insufficient coins.',
      UnlockOutcome.notUnlockable => 'This gate cannot be opened yet.',
    };
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}

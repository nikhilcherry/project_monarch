import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../controllers/boards_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../widgets/board_tile.dart';
import '../../widgets/empty_state.dart';
import '../threads/threads_screen.dart';

class BoardsScreen extends ConsumerWidget {
  const BoardsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final boards = ref.watch(boardsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Text('Veil'),
            SizedBox(width: 8),
            Text(
              'anonymous boards',
              style: TextStyle(
                color: AppColors.textFaint,
                fontSize: 13,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
      body: boards.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => EmptyState(
          icon: Icons.cloud_off,
          title: "Couldn't load boards",
          subtitle: '$e',
        ),
        data: (list) {
          if (list.isEmpty) {
            return const EmptyState(
              icon: Icons.dashboard_outlined,
              title: 'No boards yet',
              subtitle: 'Seeding defaults…',
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            itemCount: list.length,
            itemBuilder: (context, i) {
              final board = list[i];
              return BoardTile(
                board: board,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => ThreadsScreen(board: board),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

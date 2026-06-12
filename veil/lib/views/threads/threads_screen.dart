import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../controllers/threads_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../models/board.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/thread_tile.dart';
import '../thread/thread_screen.dart';
import 'create_thread_sheet.dart';

class ThreadsScreen extends ConsumerWidget {
  const ThreadsScreen({super.key, required this.board});

  final Board board;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final threads = ref.watch(threadsProvider(board.id));
    final accent = Color(board.accentColor);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Text('/${board.id}/'),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                board.title,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textFaint,
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: accent,
        onPressed: () => CreateThreadSheet.show(context, board),
        icon: const Icon(Icons.add),
        label: const Text('New thread'),
      ),
      body: threads.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => EmptyState(
          icon: Icons.cloud_off,
          title: "Couldn't load threads",
          subtitle: '$e',
        ),
        data: (list) {
          if (list.isEmpty) {
            return const EmptyState(
              icon: Icons.forum_outlined,
              title: 'No threads yet',
              subtitle: 'Be the first — tap “New thread”.',
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            itemCount: list.length,
            itemBuilder: (context, i) {
              final thread = list[i];
              return ThreadTile(
                thread: thread,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => ThreadScreen(
                      boardId: board.id,
                      threadId: thread.id,
                    ),
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

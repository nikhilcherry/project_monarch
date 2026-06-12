import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../controllers/posts_controller.dart';
import '../../controllers/threads_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/relative_time.dart';
import '../../models/thread.dart';
import '../../widgets/anon_tag.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/post_card.dart';
import 'reply_composer.dart';

class ThreadScreen extends ConsumerWidget {
  const ThreadScreen({
    super.key,
    required this.boardId,
    required this.threadId,
  });

  final String boardId;
  final String threadId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final args = (boardId: boardId, threadId: threadId);
    final thread = ref.watch(threadProvider(args));
    final posts = ref.watch(postsProvider(args));

    return Scaffold(
      appBar: AppBar(
        title: Text(thread.valueOrNull?.title ?? 'Thread',
            overflow: TextOverflow.ellipsis),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              children: [
                thread.when(
                  loading: () => const SizedBox(
                    height: 120,
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (e, _) => EmptyState(
                    icon: Icons.cloud_off,
                    title: "Couldn't load thread",
                    subtitle: '$e',
                  ),
                  data: (t) => t == null
                      ? const EmptyState(
                          icon: Icons.help_outline,
                          title: 'Thread not found',
                        )
                      : _OpCard(thread: t),
                ),
                const SizedBox(height: 8),
                posts.when(
                  loading: () => const SizedBox.shrink(),
                  error: (e, _) => Text('$e',
                      style: const TextStyle(color: AppColors.danger)),
                  data: (list) {
                    if (list.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Text(
                          'No replies yet — start the conversation.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.textFaint),
                        ),
                      );
                    }
                    return Column(
                      children: [
                        for (var i = 0; i < list.length; i++)
                          PostCard(post: list[i], index: i + 1),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
          ReplyComposer(boardId: boardId, threadId: threadId),
        ],
      ),
    );
  }
}

class _OpCard extends StatelessWidget {
  const _OpCard({required this.thread});

  final Thread thread;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.accentDim.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AnonTag(hash: thread.authorHash, isOp: true),
              const Spacer(),
              Text(
                relativeTime(thread.createdAt),
                style: const TextStyle(
                    color: AppColors.textFaint, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            thread.title,
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 10),
          SelectableText(
            thread.body,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 15,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

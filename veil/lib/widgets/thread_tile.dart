import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../core/utils/relative_time.dart';
import '../models/thread.dart';
import 'anon_tag.dart';

class ThreadTile extends StatelessWidget {
  const ThreadTile({super.key, required this.thread, required this.onTap});

  final Thread thread;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(16),
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
                      color: AppColors.textFaint,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                thread.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  height: 1.25,
                ),
              ),
              if (thread.body.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  thread.body,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                    height: 1.35,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.forum_outlined,
                      size: 15, color: AppColors.textFaint),
                  const SizedBox(width: 5),
                  Text(
                    '${thread.replyCount} ${thread.replyCount == 1 ? "reply" : "replies"}',
                    style: const TextStyle(
                      color: AppColors.textFaint,
                      fontSize: 12,
                    ),
                  ),
                  if (thread.lastReplyAt != null) ...[
                    const SizedBox(width: 12),
                    const Icon(Icons.bolt,
                        size: 15, color: AppColors.textFaint),
                    const SizedBox(width: 4),
                    Text(
                      'active ${relativeTime(thread.bumpedAt)}',
                      style: const TextStyle(
                        color: AppColors.textFaint,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/utils/anon_identity.dart';
import '../models/post.dart';
import 'providers.dart';

/// Live replies in a thread (oldest first).
final postsProvider =
    StreamProvider.family<List<Post>, ({String boardId, String threadId})>(
        (ref, args) {
  return ref
      .watch(postRepositoryProvider)
      .watchPosts(args.boardId, args.threadId);
});

/// Orchestrates posting a reply with the author's per-thread anonymous tag.
final replyComposerProvider =
    Provider<ReplyComposer>((ref) => ReplyComposer(ref));

class ReplyComposer {
  ReplyComposer(this._ref);
  final Ref _ref;

  Future<void> send({
    required String boardId,
    required String threadId,
    required String body,
    String? replyTo,
  }) async {
    final uid = _ref.read(currentUidProvider);
    if (uid == null) {
      throw StateError('Not signed in yet — anonymous auth still resolving.');
    }
    final hash = AnonId.forThread(uid, threadId).code;
    await _ref.read(postRepositoryProvider).addReply(
          boardId: boardId,
          threadId: threadId,
          body: body.trim(),
          authorHash: hash,
          replyTo: replyTo,
        );
  }
}

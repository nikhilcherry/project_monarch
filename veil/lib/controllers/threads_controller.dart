import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/utils/anon_identity.dart';
import '../models/thread.dart';
import 'providers.dart';

/// Live threads for a board (bump-ordered).
final threadsProvider =
    StreamProvider.family<List<Thread>, String>((ref, boardId) {
  return ref.watch(threadRepositoryProvider).watchThreads(boardId);
});

/// A single thread document (for the header in the thread view).
final threadProvider =
    StreamProvider.family<Thread?, ({String boardId, String threadId})>(
        (ref, args) {
  return ref
      .watch(threadRepositoryProvider)
      .watchThread(args.boardId, args.threadId);
});

/// Orchestrates thread creation: ensures the anonymous uid exists, computes the
/// OP's per-thread tag, and persists via the repository.
final threadComposerProvider =
    Provider<ThreadComposer>((ref) => ThreadComposer(ref));

class ThreadComposer {
  ThreadComposer(this._ref);
  final Ref _ref;

  Future<String> create({
    required String boardId,
    required String title,
    required String body,
  }) async {
    final uid = _ref.read(currentUidProvider);
    if (uid == null) {
      throw StateError('Not signed in yet — anonymous auth still resolving.');
    }
    return _ref.read(threadRepositoryProvider).createThread(
          boardId: boardId,
          title: title.trim(),
          body: body.trim(),
          authorHashFor: (threadId) =>
              AnonId.forThread(uid, threadId, isOp: true).code,
        );
  }
}

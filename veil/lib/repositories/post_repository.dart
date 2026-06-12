import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/post.dart';

/// Persistence for posts (replies) within a thread.
class PostRepository {
  PostRepository(this._db);

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> _posts(
    String boardId,
    String threadId,
  ) =>
      _db
          .collection('boards')
          .doc(boardId)
          .collection('threads')
          .doc(threadId)
          .collection('posts');

  Stream<List<Post>> watchPosts(String boardId, String threadId) {
    return _posts(boardId, threadId)
        .orderBy('createdAt')
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => Post.fromMap(d.id, d.data()))
            .toList(growable: false));
  }

  /// Adds a reply and bumps the thread (and board counters) atomically.
  Future<void> addReply({
    required String boardId,
    required String threadId,
    required String body,
    required String authorHash,
    String? imageUrl,
    String? replyTo,
  }) async {
    final postRef = _posts(boardId, threadId).doc();
    final now = FieldValue.serverTimestamp();
    final batch = _db.batch();

    batch.set(postRef, <String, dynamic>{
      'body': body,
      'authorHash': authorHash,
      if (imageUrl != null) 'imageUrl': imageUrl,
      if (replyTo != null) 'replyTo': replyTo,
      'createdAt': now,
    });

    final threadRef = _db
        .collection('boards')
        .doc(boardId)
        .collection('threads')
        .doc(threadId);
    batch.update(threadRef, <String, dynamic>{
      'replyCount': FieldValue.increment(1),
      'bumpedAt': now,
      'lastReplyAt': now,
    });

    batch.update(_db.collection('boards').doc(boardId), <String, dynamic>{
      'postCount': FieldValue.increment(1),
      'bumpedAt': now,
    });

    await batch.commit();
  }
}

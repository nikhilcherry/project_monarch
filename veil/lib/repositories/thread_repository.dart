import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/thread.dart';

/// Persistence for threads under a board.
class ThreadRepository {
  ThreadRepository(this._db);

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> _threads(String boardId) =>
      _db.collection('boards').doc(boardId).collection('threads');

  /// Active threads bubble to the top via `bumpedAt`.
  Stream<List<Thread>> watchThreads(String boardId, {int limit = 50}) {
    return _threads(boardId)
        .orderBy('bumpedAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => Thread.fromMap(d.id, boardId, d.data()))
            .toList(growable: false));
  }

  Stream<Thread?> watchThread(String boardId, String threadId) {
    return _threads(boardId).doc(threadId).snapshots().map(
          (d) => d.exists ? Thread.fromMap(d.id, boardId, d.data()!) : null,
        );
  }

  /// Creates a thread and bumps the board's denormalized counters atomically.
  /// The OP's anonymous tag is computed by the caller from the new id.
  Future<String> createThread({
    required String boardId,
    required String title,
    required String body,
    required String Function(String threadId) authorHashFor,
    String? imageUrl,
  }) async {
    final docRef = _threads(boardId).doc();
    final now = FieldValue.serverTimestamp();
    final batch = _db.batch();

    batch.set(docRef, <String, dynamic>{
      'title': title,
      'body': body,
      'authorHash': authorHashFor(docRef.id),
      if (imageUrl != null) 'imageUrl': imageUrl,
      'createdAt': now,
      'bumpedAt': now,
      'replyCount': 0,
    });

    final boardRef = _db.collection('boards').doc(boardId);
    batch.update(boardRef, <String, dynamic>{
      'threadCount': FieldValue.increment(1),
      'postCount': FieldValue.increment(1),
      'bumpedAt': now,
    });

    await batch.commit();
    return docRef.id;
  }
}

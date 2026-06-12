import 'package:cloud_firestore/cloud_firestore.dart';

/// A thread (the original post + its metadata). Lives at
/// `boards/{boardId}/threads/{threadId}`.
class Thread {
  const Thread({
    required this.id,
    required this.boardId,
    required this.title,
    required this.body,
    required this.authorHash,
    required this.createdAt,
    required this.bumpedAt,
    this.imageUrl,
    this.replyCount = 0,
    this.lastReplyAt,
  });

  final String id;
  final String boardId;
  final String title;
  final String body;

  /// Per-thread anonymous author tag of the OP (hex from AnonId).
  final String authorHash;
  final String? imageUrl;
  final DateTime createdAt;

  /// Sort key — threads float up when replied to.
  final DateTime bumpedAt;
  final int replyCount;
  final DateTime? lastReplyAt;

  factory Thread.fromMap(String id, String boardId, Map<String, dynamic> map) {
    DateTime ts(dynamic v) =>
        (v as Timestamp?)?.toDate() ?? DateTime.fromMillisecondsSinceEpoch(0);
    return Thread(
      id: id,
      boardId: boardId,
      title: map['title'] as String? ?? '',
      body: map['body'] as String? ?? '',
      authorHash: map['authorHash'] as String? ?? '',
      imageUrl: map['imageUrl'] as String?,
      createdAt: ts(map['createdAt']),
      bumpedAt: ts(map['bumpedAt'] ?? map['createdAt']),
      replyCount: (map['replyCount'] as num?)?.toInt() ?? 0,
      lastReplyAt: (map['lastReplyAt'] as Timestamp?)?.toDate(),
    );
  }
}

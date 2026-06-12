import 'package:cloud_firestore/cloud_firestore.dart';

/// A reply within a thread. Lives at
/// `boards/{boardId}/threads/{threadId}/posts/{postId}`.
class Post {
  const Post({
    required this.id,
    required this.body,
    required this.authorHash,
    required this.createdAt,
    this.imageUrl,
    this.replyTo,
  });

  final String id;
  final String body;

  /// Per-thread anonymous author tag (hex from AnonId).
  final String authorHash;
  final String? imageUrl;

  /// Id of the post this one replies to (for `>>` style threading), if any.
  final String? replyTo;
  final DateTime createdAt;

  factory Post.fromMap(String id, Map<String, dynamic> map) {
    return Post(
      id: id,
      body: map['body'] as String? ?? '',
      authorHash: map['authorHash'] as String? ?? '',
      imageUrl: map['imageUrl'] as String?,
      replyTo: map['replyTo'] as String?,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

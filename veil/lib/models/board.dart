/// A topic board, e.g. `/tech/`. The document id is its slug.
class Board {
  const Board({
    required this.id,
    required this.title,
    required this.description,
    required this.accentColor,
    required this.order,
    this.threadCount = 0,
    this.postCount = 0,
  });

  final String id;
  final String title;
  final String description;

  /// ARGB int so it survives Firestore without a Color adapter.
  final int accentColor;
  final int order;
  final int threadCount;
  final int postCount;

  factory Board.fromMap(String id, Map<String, dynamic> map) {
    return Board(
      id: id,
      title: map['title'] as String? ?? id,
      description: map['description'] as String? ?? '',
      accentColor: (map['accentColor'] as num?)?.toInt() ?? 0xFF8B7CFF,
      order: (map['order'] as num?)?.toInt() ?? 0,
      threadCount: (map['threadCount'] as num?)?.toInt() ?? 0,
      postCount: (map['postCount'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
        'title': title,
        'description': description,
        'accentColor': accentColor,
        'order': order,
        'threadCount': threadCount,
        'postCount': postCount,
      };
}

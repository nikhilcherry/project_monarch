import 'package:flutter_test/flutter_test.dart';
import 'package:veil/core/utils/anon_identity.dart';

void main() {
  group('AnonId.forThread', () {
    test('is stable for the same (uid, thread)', () {
      final a = AnonId.forThread('uid-123', 'thread-abc');
      final b = AnonId.forThread('uid-123', 'thread-abc');
      expect(a.code, b.code);
      expect(a.color, b.color);
    });

    test('differs for the same user across different threads (no cross-link)',
        () {
      final inThread1 = AnonId.forThread('uid-123', 'thread-1');
      final inThread2 = AnonId.forThread('uid-123', 'thread-2');
      expect(inThread1.code, isNot(inThread2.code));
    });

    test('differs for different users in the same thread', () {
      final user1 = AnonId.forThread('uid-1', 'thread-x');
      final user2 = AnonId.forThread('uid-2', 'thread-x');
      expect(user1.code, isNot(user2.code));
    });

    test('produces a 6-char hex code', () {
      final id = AnonId.forThread('uid-123', 'thread-abc');
      expect(id.code.length, 6);
      expect(RegExp(r'^[0-9a-f]{6}$').hasMatch(id.code), isTrue);
    });

    test('fromCode re-derives a consistent color', () {
      final original = AnonId.forThread('uid-123', 'thread-abc');
      final rebuilt = AnonId.fromCode(original.code);
      expect(rebuilt.color, isNotNull);
      // Same code in → same color out, every time.
      expect(AnonId.fromCode(original.code).color, rebuilt.color);
    });
  });
}

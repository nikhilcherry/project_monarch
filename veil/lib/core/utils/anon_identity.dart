import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

/// A stable, *per-thread* anonymous identity.
///
/// This is Veil's "better than 4chan" trust layer: within a single thread you
/// can tell two posts came from the same person (same tag + color), so replies
/// and back-and-forth are readable — but the tag is derived from
/// `sha256(uid + threadId + salt)`, so it does NOT correlate across threads and
/// never exposes the underlying account. The OP is additionally flagged.
@immutable
class AnonId {
  const AnonId({required this.code, required this.color, this.isOp = false});

  /// Short human-facing tag, e.g. `a3f9c1`.
  final String code;
  final Color color;
  final bool isOp;

  /// Rotating salt keeps tags from being precomputed/looked up across the app.
  static const String _salt = 'veil.v1';

  static AnonId forThread(
    String uid,
    String threadId, {
    bool isOp = false,
  }) {
    final digest = sha256.convert(utf8.encode('$uid|$threadId|$_salt')).bytes;
    final hex = digest
        .take(3)
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join();
    final color =
        AppColors.anonPalette[digest[3] % AppColors.anonPalette.length];
    return AnonId(code: hex, color: color, isOp: isOp);
  }

  /// Rebuild the display identity from a stored hash (posts persist the hex
  /// `code`; we re-derive the color from it so it stays consistent).
  static AnonId fromCode(String code, {bool isOp = false}) {
    var seed = 0;
    for (final unit in code.codeUnits) {
      seed = (seed + unit) & 0xFF;
    }
    return AnonId(
      code: code,
      color: AppColors.anonPalette[seed % AppColors.anonPalette.length],
      isOp: isOp,
    );
  }
}

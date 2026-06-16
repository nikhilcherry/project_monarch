import 'package:hive_flutter/hive_flutter.dart';

import '../../models/book.dart';
import '../../models/chapter.dart';
import '../../models/reading_session.dart';
import '../../models/user_prefs.dart';
import '../constants/lumen_seed.dart';
import 'lumen_boxes.dart';

/// Owns Lumen's Hive adapter registration, box lifecycle, and first-run seed.
///
/// Adapter registration is guarded by typeId so this can safely coexist with
/// Project Monarch's `DatabaseService` if both ever boot in the same process.
abstract final class LumenDatabase {
  LumenDatabase._();

  static late Box<Book> books;
  static late Box<UserPrefs> prefs;
  static late Box<ReadingSession> sessions;

  /// Call after `Hive.initFlutter()`. Registers adapters, opens boxes, seeds.
  static Future<void> init() async {
    _registerAdapters();
    books = await Hive.openBox<Book>(LumenBoxes.books);
    prefs = await Hive.openBox<UserPrefs>(LumenBoxes.prefs);
    sessions = await Hive.openBox<ReadingSession>(LumenBoxes.sessions);
    await _seedIfEmpty();
  }

  static void _registerAdapters() {
    if (!Hive.isAdapterRegistered(40)) Hive.registerAdapter(BookAdapter());
    if (!Hive.isAdapterRegistered(41)) Hive.registerAdapter(ChapterAdapter());
    if (!Hive.isAdapterRegistered(43)) {
      Hive.registerAdapter(ReadingSessionAdapter());
    }
    if (!Hive.isAdapterRegistered(44)) Hive.registerAdapter(UserPrefsAdapter());
  }

  static Future<void> _seedIfEmpty() async {
    if (!prefs.containsKey(LumenBoxes.prefsKey)) {
      await prefs.put(LumenBoxes.prefsKey, UserPrefs());
    }
    if (books.isEmpty) {
      for (final book in LumenSeed.library()) {
        await books.put(book.id, book);
      }
    }
  }

  static UserPrefs get currentPrefs =>
      prefs.get(LumenBoxes.prefsKey) ?? UserPrefs();
}

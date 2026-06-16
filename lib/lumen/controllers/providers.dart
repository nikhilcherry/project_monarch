import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/database/lumen_database.dart';
import '../repositories/book_repository.dart';
import '../repositories/prefs_repository.dart';
import '../repositories/session_repository.dart';

/// Repository providers — the seam between controllers and Hive storage.
final bookRepositoryProvider =
    Provider<BookRepository>((ref) => BookRepository(LumenDatabase.books));

final prefsRepositoryProvider =
    Provider<PrefsRepository>((ref) => PrefsRepository(LumenDatabase.prefs));

final sessionRepositoryProvider = Provider<SessionRepository>(
    (ref) => SessionRepository(LumenDatabase.sessions));

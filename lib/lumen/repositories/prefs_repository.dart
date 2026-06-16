import 'package:hive/hive.dart';

import '../core/database/lumen_boxes.dart';
import '../models/user_prefs.dart';

/// Persistence for the single [UserPrefs] record.
class PrefsRepository {
  PrefsRepository(this._box);

  final Box<UserPrefs> _box;

  UserPrefs load() {
    final existing = _box.get(LumenBoxes.prefsKey);
    if (existing != null) return existing;
    final fresh = UserPrefs();
    _box.put(LumenBoxes.prefsKey, fresh);
    return fresh;
  }

  Future<void> save(UserPrefs prefs) => _box.put(LumenBoxes.prefsKey, prefs);
}

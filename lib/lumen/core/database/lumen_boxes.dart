/// Hive box names for Lumen. Namespaced (`lumen_`) so they never collide with
/// Project Monarch's boxes in the same Hive directory.
abstract final class LumenBoxes {
  LumenBoxes._();

  static const String books = 'lumen_books';
  static const String prefs = 'lumen_prefs';
  static const String sessions = 'lumen_sessions';

  /// Fixed key for the single [UserPrefs] record in the prefs box.
  static const String prefsKey = 'prefs';
}

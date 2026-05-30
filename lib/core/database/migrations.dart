import 'database_service.dart';

/// One-shot schema migrations, run once at boot after [DatabaseService.init].
///
/// The currency/map model changed enough between v1 and v2 (Coins→Crystals on
/// the map, no-replay, regenerated layout) that the cleanest, safest upgrade is
/// a wipe-and-regenerate: clear all gameplay boxes so seeds/providers rebuild
/// fresh against the v2 rules. A brand-new install also lands here harmlessly
/// (boxes are already empty).
abstract final class AppMigrations {
  AppMigrations._();

  /// Current on-disk schema version. Bump when a future change needs a wipe or
  /// a real data transform.
  static const int currentSchema = 2;

  static const String _schemaKey = 'schema_version';

  static Future<void> run() async {
    final box = DatabaseService.settingsBox;
    final onDisk = box.get(_schemaKey, defaultValue: 1) as int;
    if (onDisk >= currentSchema) return;

    // v1 -> v2: wipe & regenerate. clearAll() also empties the settings box, so
    // the schema marker is written afterwards.
    await DatabaseService.clearAll();
    await DatabaseService.settingsBox.put(_schemaKey, currentSchema);
  }
}

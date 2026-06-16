import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/lumen_palette.dart';
import '../models/user_prefs.dart';
import 'providers.dart';

/// Immutable snapshot of app settings the UI watches. Backed by the Hive
/// [UserPrefs] record, but exposed as a value type so Riverpod rebuilds cleanly.
@immutable
class LumenSettings {
  const LumenSettings({
    required this.palette,
    required this.defaultWpm,
    required this.smartPauses,
    required this.fontScale,
    required this.onboardingDone,
    required this.streakDays,
    required this.totalWordsRead,
    required this.totalReadMs,
  });

  final LumenPalette palette;
  final int defaultWpm;
  final bool smartPauses;
  final double fontScale;
  final bool onboardingDone;
  final int streakDays;
  final int totalWordsRead;
  final int totalReadMs;

  factory LumenSettings.fromPrefs(UserPrefs p) => LumenSettings(
        palette: p.paletteMap.isEmpty
            ? LumenPalette.midnight
            : LumenPalette.fromMap(p.paletteMap),
        defaultWpm: p.defaultWpm,
        smartPauses: p.smartPauses,
        fontScale: p.fontScale,
        onboardingDone: p.onboardingDone,
        streakDays: p.streakDays,
        totalWordsRead: p.totalWordsRead,
        totalReadMs: p.totalReadMs,
      );
}

class PrefsController extends Notifier<LumenSettings> {
  @override
  LumenSettings build() =>
      LumenSettings.fromPrefs(ref.read(prefsRepositoryProvider).load());

  UserPrefs get _record => ref.read(prefsRepositoryProvider).load();

  Future<void> _commit(UserPrefs record) async {
    await ref.read(prefsRepositoryProvider).save(record);
    state = LumenSettings.fromPrefs(record);
  }

  Future<void> setPalette(LumenPalette palette) async {
    final r = _record..paletteMap = palette.toMap();
    await _commit(r);
  }

  Future<void> setPreset(LumenPreset preset) =>
      setPalette(LumenPalette.forPreset(preset));

  Future<void> setToken(LumenToken token, Color color) async {
    final updated = state.palette.withToken(token, color);
    await setPalette(updated);
  }

  Future<void> resetPaletteToPreset() async {
    final base = state.palette.preset == LumenPreset.custom
        ? LumenPreset.midnight
        : state.palette.preset;
    await setPreset(base);
  }

  Future<void> setDefaultWpm(int wpm) async {
    final r = _record..defaultWpm = wpm;
    await _commit(r);
  }

  Future<void> setSmartPauses(bool on) async {
    final r = _record..smartPauses = on;
    await _commit(r);
  }

  Future<void> setFontScale(double scale) async {
    final r = _record..fontScale = scale;
    await _commit(r);
  }

  Future<void> completeOnboarding() async {
    final r = _record..onboardingDone = true;
    await _commit(r);
  }

  /// Fold a finished stint into the aggregate stats + streak.
  Future<void> recordSession({
    required int wordsRead,
    required int durationMs,
  }) async {
    final r = _record;
    r.totalWordsRead += wordsRead;
    r.totalReadMs += durationMs;
    const msPerDay = 86400000;
    final today = DateTime.now().millisecondsSinceEpoch ~/ msPerDay;
    if (r.lastReadDayEpoch != today) {
      r.streakDays = (r.lastReadDayEpoch == today - 1) ? r.streakDays + 1 : 1;
      r.lastReadDayEpoch = today;
    }
    await _commit(r);
  }
}

final prefsControllerProvider =
    NotifierProvider<PrefsController, LumenSettings>(PrefsController.new);

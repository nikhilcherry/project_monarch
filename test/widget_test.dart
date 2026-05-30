import 'package:flutter_test/flutter_test.dart';
import 'package:project_monarch/models/rank_profile.dart';
import 'package:project_monarch/services/exp_engine.dart';

// Minimal smoke test. Kept dependency-free (no Hive/ProviderScope) so it runs
// anywhere, and its presence stops `flutter create` from generating the default
// template test that references a non-existent `MyApp`.
void main() {
  test('smoke: EXP engine awards EXP and levels up from the floor', () {
    final result = ExpEngine.award(RankProfile.initial(), 100);
    expect(result.expGained, 100);
    expect(result.profile.lifetimeExp, 100);
  });
}

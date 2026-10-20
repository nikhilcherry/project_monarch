# Project Monarch

**A gamified, offline-first fitness tracker modelled on the "System" from Solo Leveling.**

Log workouts, nutrition and habits, and the app turns them into stats, EXP and rank. Everything runs on-device: the progression maths, the stat distribution and the world map work with no network.

## How it plays

- **Five stats** (STR, AGI, VIT, END, FLEX) shown on a pentagon radar chart, fed by what you actually log.
- **Nine ranks**, from E up to National. Every table in the game scales off the rank.
- **World map**: a hub with four branching paths, fogged until you reach it. Depth grows with rank (`5 + 2t`), and each region ends in a rank-gate boss.
- **Two separate currencies.** Crystals move you along the map and come only from time-gated Daily Quests. Coins buy cosmetics and shop realms and never touch the map.
- **No grinding.** Dungeons and shop levels are one-time, so there is no infinite-resource loop.
- **Never soft-locked.** A tested invariant guarantees you can always advance one node a day with zero savings.
- Fast text-checklist workouts with penalty quests, a target-based macro tracker, VIT habit check-offs and a 365-day consistency heatmap.

The look is true black (`#000000`) with neon-blue (`#00E5FF`) glow and Orbitron/Rajdhani HUD type.

## Architecture

Strict layers, UI never holds game maths:

```
lib/
  core/          theme, constants, router, utils
  models/        Hive models: UserStats, ExpProfile, WorkoutNode, Habit
  repositories/  persistence over Hive boxes
  services/      EXP scaling, stat distribution, economy
  controllers/   Riverpod notifiers
  views/         dashboard, world_map, active_workout, nutrition, habits, shop
  widgets/       glow buttons, panels, hand-painted heatmap
scripts/         Python reference math engine + balance tests
```

Flutter · Riverpod (manual notifiers, no codegen) · Hive · fl_chart.

Longer reading: [`ARCHITECTURE.md`](ARCHITECTURE.md), [`docs/GAME_DESIGN_V2.md`](docs/GAME_DESIGN_V2.md) (economy and progression), [`docs/BUILD_RETROSPECTIVE.md`](docs/BUILD_RETROSPECTIVE.md).

## Run it

```bash
flutter pub get
flutter run                 # Android, or any Flutter device
flutter test                # service, economy-balance and widget tests
python3 scripts/test_balance.py   # the reference maths, in Python
```

Releases are cut automatically on every push by `.github/workflows/auto-version.yml` (current version in `pubspec.yaml`).

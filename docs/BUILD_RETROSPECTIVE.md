# Project Monarch — Build Retrospective & Problems Log

A candid, honest record of everything that went wrong (and how it was fixed)
while building Project Monarch from an empty repo to a published, installable
APK with an automated release pipeline — written from the perspective of an AI
agent working in a constrained cloud sandbox.

---

## 0. TL;DR of the hard parts

1. **No Flutter SDK in the sandbox** → code was written "blind" and never
   compiled until CI ran it. The first real compile happened *in GitHub Actions*.
2. **No access to CI logs** from the agent's tools → failures were invisible
   until a self-built feedback loop (post the error to a GitHub Issue) was added.
3. **Version-sensitive Flutter APIs** → several APIs differ between Flutter
   versions; guessing the wrong one = a build failure with no local signal.
4. **Codegen is gitignored** → the app literally cannot compile until
   `build_runner` runs, which only happened in CI.
5. **The auto-release bot fought my pushes** → every successful build pushed a
   `chore(release)` commit, causing non-fast-forward rejections on the next push.

The app shipped anyway (v0.2.0), but it took several red CI runs to get the
first green one because the normal "just run it locally" feedback loop didn't
exist.

---

## 1. Environment & tooling constraints

### 1.1 No local Dart/Flutter toolchain
`which dart flutter` → not found. The sandbox is for editing + git + Python, not
Flutter builds. Consequences:
- Could not run `flutter analyze`, `flutter test`, `dart run build_runner`, or
  `flutter build` locally.
- Every Dart correctness decision was effectively a **prediction**, validated
  only later by CI.
- The **Python reference engine** (`scripts/math_engine.py`) became the only
  thing I could actually execute and verify in-sandbox — which is exactly why
  the math was mirrored 1:1 in Python and tested there (16/16 passing locally).

**Lesson:** when you can't run the target language, isolate the *logic* into
something you *can* run. The Python mirror caught zero Dart syntax errors but
gave real confidence in the EXP/overload/stat math.

### 1.2 No visibility into GitHub Actions runs
The available GitHub tools could list commits, releases, tags, issues — but
**not** workflow-run logs or job step output. So when a build failed, the agent
knew *that* it failed (no release/tag appeared) but not *why*.

**The fix that unblocked everything:** add a CI step that, `if: failure()`,
writes the tail of `build.log` / `analyze.log` / `codegen.log` into a **GitHub
Issue**. Issues *are* readable via the available tools. That converted an opaque
red X into the exact compiler error — turning a guessing game into a normal
debug loop.

### 1.3 WebFetch caching & private-render limits
- The GitHub Actions web UI is JS-rendered; `WebFetch` (markdown conversion)
  couldn't reliably read run conclusions or release assets.
- `WebFetch` caches per-URL for ~15 min, which briefly showed a *stale* run list
  and made it look like a new push hadn't triggered a build.

**Lesson:** trust the API/MCP tools (releases, tags, issues) as the source of
truth, not a scraped web page.

---

## 2. CI/CD pipeline problems

### 2.1 The repo had no `android/` folder
The project was built as pure `lib/` (no `flutter create` scaffold). `flutter
build apk` needs a platform project. Fix: a CI step runs
`flutter create --platforms=android .` to generate the scaffold on the fly
(kept out of git via `.gitignore`).

### 2.2 Build before tag, always
Early versions risked tagging/releasing even when the build failed. Re-ordered
the workflow so the **APK build runs before** the commit/tag/release steps — a
failed build cuts no release and leaves no half-published version. Also learned
a GitHub Actions subtlety: a step with an `if:` expression still implicitly
ANDs `success()` unless you use `failure()`/`always()`, so downstream steps
correctly skip after a failed build.

### 2.3 The auto-release bot vs. my pushes (non-fast-forward hell)
Every green build pushed a `chore(release): vX.Y.Z [skip ci]` commit that bumped
`pubspec.yaml`. The next agent push was then rejected:
`! [rejected] ... (non-fast-forward)`. This happened on basically every
follow-up commit. Routine fix each time:
```
git fetch origin <branch>
git rebase origin/<branch>   # picks up the bot's version bump
git push
```
**Lesson:** an auto-committing CI bot turns the working branch into a moving
target; rebase-before-push must be the default.

### 2.4 Docs/no-op commits triggering full APK builds
A docs-only commit would still trigger the workflow and cut a pointless release.
Fix: put `[skip ci]` in the commit subject for documentation-only changes; the
workflow's `if:` guard skips those.

---

## 3. Flutter / Dart specific gotchas

These are the ones that actually broke the build (each cost a CI round-trip):

### 3.1 Codegen is gitignored → app can't compile until CI runs build_runner
`*.g.dart` (Hive `TypeAdapter`s) are generated, not committed. So the repo on
its own does **not** compile. `build_runner` *gates the whole build*, and it
only ran in CI. Any `@HiveType` mistake surfaces there.

### 3.2 Version-sensitive theme classes: `CardTheme` vs `CardThemeData`
Newer Flutter expects `cardTheme: CardThemeData(...)` / `dialogTheme:
DialogThemeData(...)`; the pinned 3.24.5 toolchain expects the **non-`Data`**
`CardTheme` / `DialogTheme`. Picked the wrong pair first. Fixed by aligning the
code to the *pinned* SDK version rather than "latest".

### 3.3 `Color.withValues(alpha:)` vs `withOpacity()`
`withValues` is a newer-SDK API (and `withOpacity` is deprecated on newer SDKs).
On the pinned 3.24.5, `withValues` doesn't exist. Swapped all 14 usages to
`withOpacity` (compiles on the pinned SDK; only a deprecation warning on newer —
never a build error).

### 3.4 `fl_chart` `RadarChartTitle(angle:)` doesn't exist in 0.68
The radar chart's `getTitle` callback receives an `angle`, but the
`RadarChartTitle` constructor in fl_chart 0.68 has no `angle` parameter. Removed
it. Classic "the callback gives you X but the constructor won't take X" trap.

### 3.5 `flutter_heatmap_calendar` API uncertainty → replaced entirely
The heatmap package's widget parameters were version-uncertain and a likely
compile failure. Rather than keep guessing a third-party API I couldn't test, I
**deleted the dependency** and hand-painted the 365-day grid with core Flutter
(`Container` cells in week-columns). Removing an unverifiable dependency was more
reliable than guessing its surface.

### 3.6 Missing imports the analyzer caught but I didn't
The build that finally produced log output revealed two plain mistakes:
- `nutrition_view.dart` used `MacroTargets` without importing `nutrition_day.dart`.
- `habits_controller.dart` used `DayOutcome` (in `enums.dart`) but only imported
  `consistency_log.dart`.
These compiled fine in my head but not in `dartc`. **`build_runner` succeeded**
on this commit (it only fully analyzes generator inputs), so the errors only
appeared at `flutter build` (full kernel compile) — a reminder that green
codegen ≠ a compiling app.

### 3.7 `firstOrNull` is not in dart:core
`Iterable.firstOrNull` comes from `package:collection`, not the SDK. An early
`byId` used it without the import; rewritten as a plain loop to avoid the
dependency. (A linter pass had already flagged/fixed it before CI, but it's a
common trap.)

### 3.8 `flutter create` regenerates a broken default test
The scaffold step generates a template `test/widget_test.dart` that references a
non-existent `MyApp`, which `flutter analyze` flags. It doesn't break
`flutter build apk` (tests aren't compiled for the APK), but to keep analyze
clean a minimal dependency-free `widget_test.dart` is committed so the template
one is never generated.

---

## 4. Gameplay / logic bugs (found by actually using the app)

### 4.1 First-run penalty avalanche
On a brand-new install, the daily-check logic scanned the **week before
install** and counted every mandatory day as "missed" → an instant, stacked
penalty quest with inhumane reps (3×100 squats, etc.) the moment the user opened
the app for the first time. Two fixes:
- First launch records *today* as the baseline and issues **no** retroactive
  penalties.
- A one-time migration clears penalties already wrongly issued, so existing
  installs self-heal without wiping data.

### 4.2 Inhumane penalty scaling
The penalty workout scaled reps linearly up to 5× (hence 50 burpees / 100
squats). Capped to a humane fixed set (8/12/15 reps, 30s plank) with only a
gentle 2→4 set bump and a capped EXP dock.

**Lesson:** "works as coded" ≠ "feels right". These bugs were only obvious once
the app was actually opened on a device — something the agent could never do
directly.

---

## 5. Process lessons (what I'd do from the start next time)

1. **Build a CI feedback channel first.** The single biggest accelerator was the
   `if: failure()` → open-an-Issue step. Without log access, that *was* my
   compiler output. Do it before the first real build, not after three red runs.
2. **Pin the toolchain, then write to it.** Don't write to "latest Flutter" when
   you can't run it; pick a specific SDK version and match every API + package
   to that exact epoch (theme classes, color APIs, codegen tool versions).
3. **Prefer core-framework widgets over unverifiable packages** when you can't
   compile. Hand-painting the heatmap removed an entire class of risk.
4. **Mirror untestable logic into something runnable.** The Python engine paid
   for itself.
5. **Rebase before every push** when an auto-release bot shares the branch.
6. **Green codegen is not a compiling app.** `build_runner` only analyzes what
   it generates; the full `flutter build` is the real gate.
7. **Ship small, test on-device, iterate.** The penalty bugs prove that no
   amount of static reasoning replaces opening the actual app.

---

## 6. Timeline of CI runs (how many tries it really took)

| Build | Result | Cause |
|-------|--------|-------|
| #1 (`ca07b9a`) | ❌ | wrong/initial CI setup (latest Flutter, no pin) |
| #2 (`749cbc3`) | ❌ | compile failure at APK build, no log captured yet |
| #3 (`3b73603`) | ❌ | failure-report Issue revealed exact errors (missing imports) |
| #4 (`1339957`) | ✅ | imports fixed → **v0.1.1**, first APK in Releases |
| later | ✅ | v0.1.2 (penalty fixes), v0.2.0 (currency split) |

Four builds to first green — almost entirely because the first three were
debugging *blind*. Once real errors were visible, fixes were one commit each.

---

*Honesty note:* none of the Dart in this project was compiler-verified inside
the development sandbox. Confidence came from (a) the executable Python mirror,
(b) the CI build itself, and (c) the failure-report feedback loop. The app is
real and installable, but the path there was "write, push, read the CI error,
fix, repeat" rather than a local edit-compile-run cycle.

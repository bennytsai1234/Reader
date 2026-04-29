# AGENTS.md

This file gives coding agents a compact orientation for working in this repository.

## Project

墨頁 Inkpage is a Flutter novel reader package named `inkpage_reader`.

Current project facts:

- App: Flutter / Dart
- State management: `provider` / `ChangeNotifier`
- DI: `get_it`
- Database: Drift / SQLite, schema version `1`
- Routing: `Navigator` + `MaterialPageRoute`
- JS engine: `flutter_js`
- Release version source: tag `vX.Y.Z`; release workflow rewrites `pubspec.yaml` to `X.Y.Z+<github.run_number>`

Development database policy:

- Treat the current latest `reader` app as a new-app development baseline.
- This project is still in active development. The maintainer commonly deletes the installed app and starts with a fresh local database between updates.
- Do not treat migration from older development schemas as a reader recovery blocker unless the user explicitly asks for upgrade compatibility.
- Keep the current Drift schema, generated code, DAOs, and model fields internally consistent for fresh installs.
- For reader work, prioritize runtime correctness, progress flush, restore semantics, viewport behavior, content loading, and layout mapping over backward-compatible DB migration work.

## Architecture

```text
lib/
  main.dart
  app_providers.dart
  core/
    database/        Drift tables, DAOs, AppDatabase
    di/              get_it registration
    engine/          book source rules, JS bridge, WebBook parsers
    local_book/      TXT / EPUB / UMD parsers
    models/          domain models
    network/         Dio API and interceptors
    services/        book source, backup, restore, TTS, download services
    storage/         app-owned filesystem paths
    utils/           pure utilities
    widgets/         domain-aware shared widgets
  features/
    bookshelf/
    book_detail/
    explore/
    reader/
    search/
    settings/
    source_manager/
    ...
  shared/
    theme/
    widgets/
docs/
test/
release-notes/
```

## Main Runtime Paths

App startup:

```text
main.dart
  -> configureDependencies()
  -> MultiProvider(AppProviders.providers)
  -> LegadoReaderApp
  -> SplashPage
  -> MainPage
```

Reader mainline:

```text
ReaderPage
  -> ReaderDependencies
  -> ChapterRepository
  -> ReaderRuntime
  -> PageResolver / LayoutEngine
  -> EngineReaderScreen
  -> SlideReaderViewport / ScrollReaderViewport
```

Durable reader progress is:

```text
ReaderLocation(chapterIndex, charOffset, visualOffsetPx)
```

Reader invariants:

1. `ReaderRuntime` is the active reader state owner.
2. DB progress stores only `chapterIndex`, `charOffset`, and `visualOffsetPx`.
3. `chapter display text` is the source of truth for `charOffset`, including title text.
4. `ChapterLayout`, `TextLine`, `LineLayout`, and `PageCache` are the shared layout truth for scroll and slide.
5. Restore consumes DB progress and does not write DB.
6. `saveProgress()` captures the current visible anchor before persisting.
7. Loading, error, and placeholder pages must not publish durable reading positions.
8. Scroll uses a fixed canvas window with signed `virtualScrollY`; `virtualScrollY` is runtime-only.

## Common Commands

Dependencies:

```bash
flutter pub get
```

Code generation:

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

Analyze:

```bash
flutter analyze
```

Tests:

```bash
flutter test
flutter test test/features/reader
tool/flutter_test_with_quickjs.sh
```

Run:

```bash
flutter run
```

Build:

```bash
flutter build apk --split-per-abi --release
flutter build ios --release --no-codesign
```

## Release Commands

Create release notes:

```bash
mkdir -p release-notes
$EDITOR release-notes/vX.Y.Z.md
```

Create and push a tag:

```bash
git tag vX.Y.Z
git push origin main
git push origin vX.Y.Z
```

After the release workflow rewrites `pubspec.yaml`, sync local `main`:

```bash
git pull --ff-only origin main
```

## Docs

Useful references:

- `README.md`
- `docs/README.md`
- `docs/reader_current_state.md`
- `docs/reader_mobile_test_plan.md`
- `CONTRIBUTING.md`
- `CHANGELOG.md`
- `release-notes/`

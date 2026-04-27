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
ReaderLocation(chapterIndex, charOffset)
```

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
- `docs/architecture.md`
- `docs/app_flow_architecture.md`
- `docs/DATABASE.md`
- `docs/reader_runtime.md`
- `docs/reader_spec.md`
- `docs/release.md`

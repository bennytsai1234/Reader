# CLAUDE.md

This file gives coding agents current guidance for this repository.

## Project

墨頁 Inkpage is a Flutter novel reader package named `inkpage_reader`.

Current project facts:

- Release version is derived from tag `vX.Y.Z`; the workflow rewrites `pubspec.yaml` to `X.Y.Z+<github.run_number>`
- Dart SDK: `^3.7.0`
- State management: `provider` / `ChangeNotifier`
- DI: `get_it`
- Database: Drift / SQLite, schema version `1`
- Routing: `Navigator` + `MaterialPageRoute`
- JS engine: `flutter_js`

This repo is not using Riverpod or GoRouter.

## Common Commands

```bash
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
flutter analyze
flutter test
flutter test test/features/reader
tool/flutter_test_with_quickjs.sh
flutter run
flutter build apk --split-per-abi --release
flutter build ios --release --no-codesign
```

Run build runner after changing Drift tables, DAO declarations, or `AppDatabase`.

## Architecture

```text
lib/
  main.dart
  app_providers.dart
  core/
    database/
    di/
    engine/
    local_book/
    models/
    network/
    services/
    storage/
    utils/
    widgets/
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
```

`main.dart` is the app composition root. It initializes Flutter, error handling, DI, `Workmanager`, global navigator/scaffold messenger keys, `MultiProvider`, and `MaterialApp`.

`app_providers.dart` registers global UI state: source manager, search, bookshelf, explore, settings, fonts, cover changing, dictionary, and global `TTSService`.

## Data Layer

- Entry: `lib/core/database/app_database.dart`
- Tables: `lib/core/database/tables/app_tables.dart`
- DAOs: `lib/core/database/dao/`
- Schema version: `1`
- DB path: `<ApplicationSupportDirectory>/databases/inkpage_reader.db`
- Migration strategy: clean `onCreate(createAll)` only

Database access should go through DAOs. UI code should not manually query SQLite or depend on Drift generated tables directly.

## Reader Mainline

The current reader mainline is:

```text
ReaderPage
  -> ReaderDependencies
  -> ChapterRepository
  -> ReaderRuntime
  -> PageResolver / LayoutEngine
  -> EngineReaderScreen
  -> SlideReaderViewport / ScrollReaderViewport
```

Key files:

- `lib/features/reader/reader_page.dart`
- `lib/features/reader/runtime/reader_runtime.dart`
- `lib/features/reader/controllers/reader_dependencies.dart`
- `lib/features/reader/engine/chapter_repository.dart`
- `lib/features/reader/engine/page_resolver.dart`
- `lib/features/reader/viewport/reader_screen.dart`

Durable reader progress is `ReaderLocation(chapterIndex, charOffset, visualOffsetPx)`. Page index, page placement, scroll offset, and `virtualScrollY` are runtime projections only.

Do not describe old `ReadBookController` / mixin runtime docs as current behavior. The active reader path is `ReaderPage -> ReaderRuntime -> EngineReaderScreen -> SlideReaderViewport / ScrollReaderViewport`.

## Book Source Engine

`core/engine` is the book-source execution subsystem:

- `analyze_url.dart`: URL rules, headers, charset detection, WebView, request construction
- `analyze_rule/`: rule execution core
- `parsers/`: CSS, XPath, JSONPath, regex
- `js/`: `flutter_js`, JS extensions, async JS rewriter, Promise bridge
- `web_book/`: search, book info, chapter list, content fetching
- `reader/`: content processing and Chinese conversion

`WebBook` does not use isolates for rule parsing because JS runtime / FFI objects cannot be moved across isolates safely.

## Development Rules

- Keep Provider / ChangeNotifier as the app state system.
- Use constructor injection for testable classes when practical; production can still resolve DAOs from `getIt`.
- Keep feature UI orchestration in `features/`, cross-feature business flows in `core/services`, and parsing rules in `core/engine`.
- Keep reader progress semantics as `chapterIndex + charOffset + visualOffsetPx`.
- Update docs when changing module boundaries, reader runtime contracts, release flow, or database schema.

## Documentation

Start with:

- `README.md`
- `docs/README.md`
- `docs/reader_current_state.md`
- `docs/reader_mobile_test_plan.md`
- `CONTRIBUTING.md`
- `CHANGELOG.md`

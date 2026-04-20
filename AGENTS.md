# AGENTS.md

This file provides guidance to coding agents working in this repository.

## Scope

These rules are specific to `reader`. Follow them before running Dart or Flutter commands.

## Why These Rules Exist

This repository has a non-trivial Flutter test suite plus Drift code generation. Running multiple heavy Dart/Flutter commands at the same time can exhaust WSL memory and kill the editor or remote session.

`.vscode/settings.json` only limits editor-side indexing. It does **not** make CLI commands safe to run in parallel.

## Heavy Commands

Treat all of the commands below as **mutually exclusive**:

- `flutter test ...`
- `dart test ...`
- `flutter analyze ...`
- `dart analyze ...`
- `flutter pub run build_runner build ...`
- `dart run build_runner build ...`
- any `build_runner watch`
- any `flutter test --watch` / `dart test --watch`
- `flutter run ...`
- `flutter build ...`
- `dart run ...` commands that traverse large parts of the repo

If a command will compile, analyze, generate code, watch files, or run the full test graph, assume it is heavy.

## Hard Rules

1. Never run more than one heavy Dart/Flutter command at a time.
2. Never run `flutter test` and `dart test` together.
3. Never run `analyze` together with any test command.
4. Never run `build_runner` together with `test`, `analyze`, `run`, or `build`.
5. Do not use any `--watch` mode unless the user explicitly asks for it.
6. If VS Code is already open on this repo, prefer not to run extra `dart analyze` unless it is required for the task.
7. After an interrupted heavy command, do not start another one until the previous process has fully exited.
8. If the task does not require a full-repo check, prefer targeted commands.
9. Never create or publish a release without first running `flutter analyze` on the current worktree.
10. If any code changed after the last `flutter analyze`, run `flutter analyze` again before tagging, pushing a release commit, or creating a GitHub release.

## Default Execution Strategy

Use this order when verification is needed:

1. `flutter pub get` only if dependencies changed.
2. `build_runner build --delete-conflicting-outputs` only if Drift schema or generator inputs changed.
3. `flutter analyze` once.
4. `flutter test` once, or a targeted test file if full-suite coverage is unnecessary.

Run these steps sequentially, never in parallel.

## Release Gate

If the task includes any release action such as:

- bumping the app version
- creating a release commit
- creating or pushing a tag
- creating a GitHub release
- building a release artifact for distribution

then the minimum verification flow is:

1. `flutter pub get` only if dependencies changed.
2. `build_runner build --delete-conflicting-outputs` only if Drift schema or generator inputs changed.
3. `flutter analyze` once on the current worktree.
4. Run targeted tests for the changed areas, or `flutter test` if the release scope is broad.
5. Only after steps 1-4 pass, proceed with commit/tag/push/release actions.

Do not skip step 3 for release work, even if targeted tests already passed.

## Preferred Commands

- Prefer `flutter test test/path/to/file_test.dart` over full `flutter test` when a targeted test is enough.
- Prefer one-time `build_runner build` over any watch mode.
- Prefer one analyzer invocation, not both `flutter analyze` and `dart analyze`.

## Drift-Specific Rule

If a change touches `lib/core/database/tables/`, `lib/core/database/app_database.dart`, or any Drift DAO definition:

1. Run `build_runner build --delete-conflicting-outputs`.
2. Wait for it to finish.
3. Run `flutter analyze`.
4. Run targeted tests unless the change clearly requires the full suite.

Do not overlap any of these steps.

## Agent Behavior

When working in this repo, agents should default to the safest path:

- Do not launch multiple verification commands in parallel.
- Do not start a background watcher.
- Do not "speed up" work by running test, analyze, and codegen together.
- If the user asks for broad verification, do it sequentially and say so.
- If WSL appears unstable or memory usage spikes, stop spawning new heavy commands and report what was running.

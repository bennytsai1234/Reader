# AGENTS.md

This file provides guidance to coding agents working in this repository.

## Scope

These rules are specific to `reader`. Follow them before running Dart or Flutter commands.

## Why These Notes Exist

This repository has a non-trivial Flutter test suite plus Drift code generation. On some WSL setups, running several expensive Dart/Flutter commands at once can spike memory usage or destabilize the editor session.

`.vscode/settings.json` only limits editor-side indexing. It does **not** control CLI workload. Use judgment based on the current machine state.

## Resource-Intensive Commands

The commands below are typically expensive and may compile, analyze, generate code, watch files, or traverse large parts of the repo:

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

If a command will compile, analyze, generate code, watch files, or run the full test graph, treat it as resource-intensive.

## Execution Guidance

1. Resource-intensive Dart/Flutter commands may be run in parallel when it materially helps and the environment can support it.
2. If the task does not require a full-repo check, prefer targeted commands.
3. Do not use any `--watch` mode unless the user explicitly asks for it.
4. If VS Code is already open on this repo, avoid redundant analyzer runs unless they are required for the task.
5. After an interrupted command, make sure the previous process has actually exited before reusing the same outputs, ports, or locks.
6. Never create or publish a release without first running `flutter analyze` on the current worktree.
7. If any code changed after the last `flutter analyze`, run `flutter analyze` again before tagging, pushing a release commit, or creating a GitHub release.
8. If WSL appears unstable or memory usage spikes, reduce concurrency and report what was running.

## Default Execution Strategy

Use this order when a broad verification pass is needed:

1. `flutter pub get` only if dependencies changed.
2. `build_runner build --delete-conflicting-outputs` only if Drift schema or generator inputs changed.
3. `flutter analyze` once.
4. `flutter test` once, or a targeted test file if full-suite coverage is unnecessary.

These steps are a recommended baseline, not a mandatory serialization rule. Parallelize when appropriate, but account for command dependencies.

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
2. Run `flutter analyze` against the resulting generated code.
3. Run targeted tests unless the change clearly requires the full suite.

If downstream commands depend on generated outputs, ensure `build_runner` has completed before relying on those outputs.

## Agent Behavior

When working in this repo, agents should use judgment:

- Parallelize verification when it saves time and the commands do not block on each other.
- Do not start a background watcher unless the user asked for it.
- If the user asks for broad verification, explain the command set you intend to run.
- If WSL appears unstable or memory usage spikes, stop increasing concurrency and report what was running.

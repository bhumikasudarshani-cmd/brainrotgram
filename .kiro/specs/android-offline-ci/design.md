# Design: Android offline CI

## Workflow

One file, `.github/workflows/flutter-ci.yml`, with one job on `ubuntu-latest`.

| Concern | Choice | Requirement |
| --- | --- | --- |
| Triggers | `push` to `main`, `pull_request` | R1 |
| Permissions | top-level `permissions: contents: read` | R4 |
| Concurrency | group `flutter-ci-${{ github.ref }}`, `cancel-in-progress: true` | R4 |
| Timeout | `timeout-minutes: 20` | R4 |
| Checkout | `actions/checkout` v7.0.1, pinned SHA, `persist-credentials: false` | R5 |
| Flutter | `subosito/flutter-action` v2.23.0, pinned SHA, `channel: stable`, `flutter-version: 3.47.8`, SDK and pub cache on | R3, R5 |
| Checks | `flutter pub get`, `flutter analyze`, `flutter test` as separate steps | R2 |

## Version choice

The local toolchain is Flutter 3.47.8 stable (Dart 3.13.7). `pubspec.lock`
requires Flutter >=3.47.0 and Dart >=3.13.0, and the Linux release manifest
lists 3.47.8 stable with Dart 3.13.7. Pinning the same version CI and local
use keeps analyzer and test results comparable. Bumping it is a one-line edit.

## Exclusions

No `secrets.*`, no `flutter build apk`, no signing, no upload or release
steps, no deployment. Pub package downloads are the only network access.
Tests already use synthetic data, so no test changes are needed.

## README

Short sections: what the app is, requirements, setup, checks (same commands
as CI), links to backend and releases, release pointer to `RELEASING.md`, and
"Built with Kiro" scoped to this CI task.

# Tasks: Android offline CI

- [x] 1. Inspect constraints and toolchain (R3)
  - `pubspec.yaml` sdk `^3.6.0`; `pubspec.lock` dart `>=3.13.0`, flutter `>=3.47.0`.
  - Local `flutter --version`: 3.47.8 stable, Dart 3.13.7.
  - Linux release manifest lists 3.47.8 stable with Dart 3.13.7.
- [x] 2. Add `.github/workflows/flutter-ci.yml` (R1, R2, R3, R4, R5)
- [x] 3. Add `README.md` (R6)
- [x] 4. Validate locally (R2, R7)
- [ ] 5. Push to `main` and record the GitHub Actions result (R1, R7)

## Verification record

Run locally on macOS, 2026-11-04, Flutter 3.47.8:

- `flutter pub get`: dependencies resolved.
- `flutter analyze`: no issues found.
- `flutter test`: 56 tests passed.
- `actionlint` 1.7.12 (Docker image `rhysd/actionlint`): 0 errors.

Not verified locally:

- Execution on a GitHub-hosted `ubuntu-latest` runner, including the
  `subosito/flutter-action` install and caching.
- The `pull_request` trigger and concurrency cancellation (no PR was opened).

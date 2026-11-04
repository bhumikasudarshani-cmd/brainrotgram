# Requirements: Android offline CI

## Context

BrainRotGram is a Flutter Android app owned by a teammate. It has no CI. The
existing test suite (56 tests on 2026-11-04) uses synthetic fixtures
(`test/fixtures/api-contract.json`, `test/support/fake_player.dart`) and
`example.invalid` / `example.com` URLs. This spec covers only adding offline CI
and a README. It changes no app code.

## Requirements

**R1. Triggers.** CI runs on every push to `main` and on every pull request.

**R2. Offline checks.** CI runs `flutter pub get`, `flutter analyze` and
`flutter test`, and fails if any of them fails.

**R3. Pinned compatible toolchain.** CI uses a pinned stable Flutter version
that satisfies `pubspec.yaml` (`sdk: ^3.6.0`) and `pubspec.lock`
(`dart >=3.13.0`, `flutter >=3.47.0`).

**R4. Least privilege and bounded runs.** The workflow token has only
`contents: read`. The job has a timeout. A newer run for the same ref cancels
a superseded one.

**R5. No secrets or side effects.** CI uses no secrets, release signing,
paid or live API calls, third-party media, APK release or deployment.
Third-party actions are pinned to commit SHAs.

**R6. README.** A concise `README.md` gives setup and check commands, links to
the backend (https://github.com/sea-deep/brainrotten) and the signed GitHub
releases, and has a "Built with Kiro" section that describes only this CI
task and links these spec files.

**R7. Verification record.** `tasks.md` records which checks actually ran
and which remain unverified.

# BrainRotGram

BrainRotGram is the Android app for [Brainrotten](https://github.com/sea-deep/brainrotten):
short learning videos generated from your own coding sessions.

Signed APKs are published in this repository's
[GitHub releases](https://github.com/bhumikasudarshani-cmd/brainrotgram/releases).
Release steps are in [RELEASING.md](RELEASING.md).

## Setup

Requires Flutter 3.47 stable or later (Dart 3.13+) and the Android SDK.

```sh
flutter pub get
flutter run
```

## Checks

These are the same offline checks CI runs. Tests use synthetic fixtures and
make no network calls.

```sh
flutter pub get
flutter analyze
flutter test
```

## Built with Kiro

The Android app is the teammate's work. Kiro added only the offline CI
workflow ([`.github/workflows/flutter-ci.yml`](.github/workflows/flutter-ci.yml))
and this README, using Kiro's spec workflow:
[requirements](.kiro/specs/android-offline-ci/requirements.md),
[design](.kiro/specs/android-offline-ci/design.md),
[tasks](.kiro/specs/android-offline-ci/tasks.md).

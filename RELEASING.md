# Android releases

The public APK is published in this repository's GitHub releases. Version 1.1.0 (build 2) supports Android 7 and later. Sign in with the same Google account used for Brainrotten and its agent connection.

Before publishing, run `flutter analyze`, `flutter test`, and `flutter build apk --release`. Verify the APK with the Android SDK's `apksigner verify --verbose --print-certs`, then upload the release APK as `brainrotgram.apk` alongside `SHA256SUMS`. Tag the verified main commit matching the built source. Website download links use the versioned GitHub asset URL.

Release signing uses the existing Gradle configuration and an ignored `android/key.properties` file. Keep the private keystore outside the repository and back it up, together with its passwords, in secure storage. Future updates must use this same key. Never commit a keystore, passwords or `key.properties`.

The first public release certificate SHA-256 is `703670df2f5b9a53d53e8e1214e7b1418f48efa0a435ab2dbe55c110c744f744`.

A debug install uses a different signing certificate. Install debug updates with `adb install -r` to preserve local test state. Do not uninstall a tester's debug copy just to install a release: switching signing certificates requires a fresh install and separate sign-in.

Offline checks cover synthetic API responses and player behavior. Google sign-in and real signed-media playback require a manual device check; an APK signature check does not establish either.

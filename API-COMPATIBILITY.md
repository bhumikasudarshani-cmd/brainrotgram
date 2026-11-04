# Backend compatibility checks

The account-owned `/library` list includes videos generated from Android, Studio and MCP. Library rows include `review` and a poster, but no playable video URL; the player fetches `/videos/{jobId}` for a fresh signed URL when needed.

API video lengths can be fractional and exceed the requested target (for example, `215.6` seconds). Progress can also be fractional. Review `answers` contain graded objects with a `choice`, `correct`, `attempts` and `answeredAt`; the mobile model restores each selected choice from those objects.

Errors use `code`, `message`, `retryable` and `requestId`. API Gateway may instead return only `message` for a 401. Studio preserves the request ID for support, handles non-JSON upstream errors, and stops polling `needs_review` jobs without offering another generation request. Failed playback refreshes its signed URL once automatically, then shows an error; refreshing after the widget closes creates no new player.

Run the offline checks:

```sh
flutter analyze
flutter test
flutter build apk --debug
```

`test/fixtures/api-contract.json` is synthetic, generated through the canonical Zod schemas in the Brainrotten backend repository. It contains no real accounts, media URLs or credentials. With both repositories side by side, refresh it after an intentional backend contract change:

```sh
cd ../brainrot-ide
pnpm build
node scripts/app-contract-fixtures.mjs
pnpm app:sync --no-pull
```

Review changed fixtures and mobile parsers together. `app:sync` checks fixtures, live API/auth configuration, analysis and tests; it never generates a video. It refuses to pull over local changes or a feature branch. `--skip-flutter` runs only the API/auth checks.

For a test deployment, set the API URL at build time:

```sh
flutter run --dart-define=API_BASE_URL=https://your-test-api.example/api/v1
```

This changes the API endpoint only. A separate Cognito environment also requires matching client/issuer settings. Real Google sign-in on a phone or emulator remains a manual smoke check; offline tests do not exercise the Google UI or real signed-media playback.

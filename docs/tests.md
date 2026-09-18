# Tests and quality

## Test layers

| Layer | Coverage |
|---|---|
| Unit/ViewModel | Sorting, nullable fields, selection, editing, policy and feature access |
| SQLite FFI | Persistence, schema upgrades, disposable legacy cleanup, transactions |
| Archive/import/export | Plain/encrypted round trips, lock handling, collisions, paths, CRC and expansion limits |
| Widgets | Screens, locks, search scope, layout and navigation with fake repositories |
| Goldens | 20 local card comparisons; excluded from CI due to host font rasterization |
| Integration | Device-only folders, locking and transfer scenarios under integration_test |

FFI uses ordinary SQLite, not proof of SQLCipher encryption. `flutter_test_config.dart`
provides mock secure storage for tests; production never falls back to a public key.

```sh
flutter analyze
flutter test
flutter test --exclude-tags golden
flutter test integration_test
```

Only run device integration with an explicitly selected/authorized device. Do not
regenerate goldens to hide regressions. If an intended visual change needs new
references, generate and inspect PNGs before accepting them.

Initial 18 September consolidation: 316 passing tests including 20 goldens. Follow-up on 19 September: **320 tests pass**, including 20 goldens,
with clean static analysis. The command output is the source of truth for counts. Native builds, SQLCipher/backup verification and captured
Sentry envelopes are separate checks, not implied by Dart test success.

## Step 2 validation

333 tests pass, including 20 unchanged goldens. Static analysis is clean.
Debug Android and unsigned debug iOS builds succeed. New scenarios cover lifecycle
privacy, protected drafts/system Back, OS credential return, startup retries and
partial initialization, unreadable preferences, save failure/retry, and orphan
collection with shared/trash/corrupt references. See [step 2](consolidation-step-2.md).
These builds do not replace real-device security checks.

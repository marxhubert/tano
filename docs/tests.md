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

## Current validation

On `refactor/consolidation`: 469 tests pass, including 32 unchanged goldens.
Static analysis is clean. Scenarios cover lifecycle privacy, protected
drafts/system Back, OS credential return, startup retries and partial
initialization, unreadable preferences, save failure/retry, orphan collection
with shared/trash/corrupt references, cleartext-export refusal, locked trash
deletion, the shared sort/filter controllers, the atomic move/delete batches,
the manifest-v3 folder round-trip, the FTS5 search index (prefix match, reindex
on update, deleted notes excluded, LIKE fallback helper), and a deterministic
import fuzz smoke test plus a 300-note import/search. See [history](history.md) for
the earlier validation records. These builds do not replace real-device security
checks.

## Developer fixtures

In a debug build, open Settings > Reset data > Developer reset and confirm.
This replaces all notes, folders, attachments and preferences with synthetic
fixtures: five folders (one empty), 33 unfiled notes and 15–27 notes in each
populated folder, with long text, important marks, themes, note links and checklists.
Locked fixtures are enabled only when the device has a system credential.
The button is hidden and the operation rejected in profile/release builds.
Normal reset and first launch keep an empty database. Fixtures cover notes, folders
and task checklists: every task is a list of short rows (5 to 15, some 26 to 40, one
task in three described) and no row passes 250 characters; four hand-written lists
add the mixed, completed and locked shapes.

Run `flutter test test/developer_reset_test.dart` to check replacement,
repeatability, reference integrity and both device-lock capability states.

Release exclusion check: `flutter build apk --release --target-platform
android-arm64 --analyze-size` was verified locally. The AOT size report excludes
`notes_fixtures.dart`, `buildFixtures`, `TanoFixtures` and `developerReset`;
the APK contains no fixture assets or developer-reset labels. Fixture insertion
and localized developer-reset strings also use compile-time `kDebugMode` guards.

Task-list behavior and focused tests: [Task lists](tasks.md).

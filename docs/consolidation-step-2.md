# Consolidation step 2

Branch: `audit/consolidation-security`. Scope: background locking, storage recovery
and safe orphan attachment collection. No billing/network features are introduced.

## Background privacy and reauthentication

`PrivacyGuard` sits above navigation. Every inactive frame hides content; real
background transitions invalidate access while a protected editor/folder is mounted.
`ProtectedContent` registers the scope for its lifetime, including routes covered
by another route. The guard keeps draft widgets mounted but offstage, removing paint,
hit testing and semantics. Returning to a protected session requires a new OS
credential; cancellation/failure keeps it covered. System Back cannot dismiss the
protected route while covered. Inactive alone does not invalidate a session, because
native biometric prompts also produce that transition.

A successful credential result is accepted only in the resumed app. Android's
system credential activity can pause/resume the app, so that transition must not
reject a fresh successful result. `local_auth` does not persist authentication
across external background interruptions. Real-device lifecycle testing remains
required, particularly passcode fallback and interruption during the prompt.

Native snapshot defenses complement Dart rendering:

- iOS uses a FlutterSceneDelegate subclass. UIKit adds a solid cover synchronously
  on scene inactivity/backgrounding. It remains until Flutter signals that the
  resumed privacy frame has been painted, avoiding exposure of an old content frame.
- Android 13+ disables Recents screenshots. Older Android uses FLAG_SECURE, which
  also prevents ordinary screenshots/screen recording on those OS versions.

These measures do not encrypt in-memory drafts or control copies already handed
to external viewers. No physical device or simulator was launched for this work.

## Storage failures

`StartupGate` blocks application routes until startup succeeds. Failure shows a
generic retry screen, with no raw SQL, filenames, keys or exception values. Retrying
is idempotent even after partial service registration; no reset or key replacement
is offered. A lost key or corrupted storage may require separate recovery work:
retry is for transient failures, not a claim to repair arbitrary corruption.

Unreadable encrypted preferences now fail closed instead of silently reverting to
defaults. Stored values are preserved. Preference caches update only after successful
writes/removals. The existing splash load error also omits raw exception text.

Editor saves persist before leaving the route. Failed writes keep the draft open,
show a generic error and allow another save. In-place saves, save-before-leaving,
link navigation, moves and attachment reference removal use the same error path.
Attachment/membership changes count as dirty. Lock autosave failure restores the
previous lock flag. Folder editor deletion results are no longer accidentally upserted.

## Orphan attachment collection

Collection runs once during bootstrap, before editors/imports can create new files
or references. SQLite supplies a transactionally consistent snapshot from all notes
and folders, including trash, covers and shared attachment names. Malformed references
or a failed snapshot abort before any deletion. Stored filenames are validated;
directory enumeration does not follow links or recursively delete unexpected folders.

Files absent from the complete reference set are deleted, together with their
materialized cache copy. Collection is repeatable after interruption. Deleting a
reference in the editor no longer eagerly deletes a file that another note/cover
might use. Files newly orphaned during a running session are reclaimed at the next
startup, not by a racing background collector. Unpersisted draft attachments after
process death have no durable owner and can be collected.

This is not a filesystem/SQLite distributed transaction and does not make an entire
hard reset atomic. External-viewer cache expiry during a running session and shared
command services for all remaining mutations are separate follow-up work.

## Validation

Final validation: **333 tests pass**, including 20 unchanged goldens; static analysis
and `git diff --check` are clean. Android debug APK and unsigned iOS debug builds
both succeeded. No device or simulator was launched. Existing plugin migration
warnings (Swift Package Manager / Kotlin Gradle) remain non-blocking.

Automated tests cover draft retention, refusal/retry, inactive-only transitions,
background results, system Back, credential-activity return, startup retry, partial
service registration, corrupted preferences, write failure/retry, shared files,
trash references and corrupt reference snapshots. Existing goldens are retained.
Debug iOS (unsigned) and Android builds compile the native integrations. Real-device
snapshot inspection, credential/key-loss/backup scenarios and final Sentry envelopes
remain the next validation phase.

References: [Flutter scene lifecycle](https://docs.flutter.dev/release/breaking-changes/uiscenedelegate),
[Android activity snapshot control](https://developer.android.com/reference/android/app/Activity#setRecentsScreenshotEnabled(boolean)).

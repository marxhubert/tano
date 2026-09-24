# Consolidation roadmap

Updated for the `refactor/consolidation` branch. The app has never shipped; old
test data is disposable.

## Consolidation and security cycle (current branch)

- One wording source for group counts and selection sentences (`document_filter.dart`).
- One `FabRouteCollapse` mixin for Home and Folder instead of two copies.
- One `SortPreferencesController` and one `DocumentFilterController` owned by
  Home, Folder and Settings, and one `FabLayoutMetrics` for the FAB location
  and geometry.
- `EntitySliver` requires a `ContentEntity` and keys every card by id; one
  attachment glyph across cards, the editor and the FAB menu.
- One `NoteCards` widget for the note grid and list, and one `buildNoteCard`
  shared by Home and Folder.
- One `cardTextColor` for the card ink, used by the card and the trash overlay.
- The editor's two save paths merged into `_save({required bool popAfter})`;
  the FAB's never-wired `onColorLens`, `onMore` and `onLinkSelected` removed.
- The FAB link/move menus sort with the shared `EntitySorting`; the trash counts
  with `groupCountLabel`; `collectSelectedNotes` and `emptyStateSliver` own the
  selection accounting and the empty screen.
- `focusSearchField` / `leaveSearchMode`, `openNoteEditor` and
  `requestLockChange` are the single implementations of the search timing, the
  editor's authentication prologue and the lock decision.
- `deleteSelectionTitle`, `announceMove` and `announceDeletion` own the delete
  dialog title and the move/delete feedback; the folder page now taps the same
  haptic as Home after a delete.
- `runStorageOperation` is the one recoverable-write wrapper: the editor, Home
  and a folder report a failed write with the same message and reload instead of
  leaving optimistic state behind. Multi-note moves and deletes go through the
  `AtomicNotesWriter` capability, so the SQLite store applies each batch in one
  transaction while test doubles keep a plain loop.
- Removed dead code: three unreferenced strings, the legacy JSON note codec, an
  unused radius, the unreachable no-selection delete branch and the FAB's
  never-wired callbacks.
- Removed the repository-level `toggleLock`, which no caller used and which
  bypassed the editor's authentication and feedback flow.
- Folder search records its query in the shared history, like Home.
- App Store links from the update lookup are only followed when Apple + HTTPS.
- A cleartext export is refused while the selection contains a locked note.
- Destroying locked trash content, or emptying the trash with locked items in it,
  requires the device credential.
- A generated installation key is read back from secure storage; an unpersisted
  key fails loudly instead of silently changing on the next launch.
- Materialized attachment plaintext expires after ten minutes and is swept on
  return from the system viewer.
- A configured database passphrase provider that returns null fails closed
  instead of opening SQLCipher in the clear.

## Optional future consolidation

These are architectural refactors, not known defects: the shared logic they
would absorb already lives in one place behind the helpers above.

- A search-mode *controller* that owns the active flag and query, rather than
  each page holding them and calling the shared helpers.
- A common `EntityBrowser` scaffold and a shared move command path, replacing
  the remaining Home/Folder page boilerplate.

## Completed in the previous consolidation

- Archive bounds/path validation, import collision handling and SQLite batch rollback.
- Search/navigation/export parent-folder access policy and explicit lock rules.
- Removal of fixed fallback keys; single-flight key/database initialization.
- Plaintext temporary-cache cleanup and memory-only cover decoding.
- Removal of legacy plaintext data recovery and known test backups.
- Common entity/sorting/category/copy semantics.
- Consent-gated diagnostic allowlist, including coarse device/OS/locale-region data.
- Premium policy foundation for projects, sharing and collaboration; no billing yet.
- English documentation and filenames, updated current/future distinction.
- Lifecycle privacy guard and native snapshot covers; draft-preserving reauthentication.
- Non-destructive startup retry and editor write-failure recovery.
- Startup orphan collection using complete references, including trash and covers.

## Before first public release

1. Validate native encryption, backup/restore, key loss, app-switcher protection and
   authentication-session invalidation.
2. Extend transaction-aware recovery to remaining commands and validate exhaustive reset.
3. Inspect Sentry envelopes, queues and service-side non-retention settings before
   configuring a production DSN.
4. Establish a non-destructive migration policy for all data created after release.
5. Test native builds, distribution signing and store declarations.

## Domain and backup work

Task lists now share note editing and storage; see [task lists](tasks.md).
Manifest v3 carries notes, tasks, their attachments and folders; project data and
cross-note relations are still out. Extract the remaining transaction-aware commands,
measure large-data search and move expensive work off the UI. Project persistence
remains separate future work.

## Premium and collaboration

Choose billing later and implement verified entitlements/restoration. Follow
[collaboration](collaboration.md) for peer authentication, remote transport, permissions,
replication and conflict testing. No central content storage. Premium is independent
from a collaborator's permission to a shared resource.

Use `develop` for integration and PRs into protected `master` for release promotion.

Earlier audits and the step 2 journal: [history](history.md).

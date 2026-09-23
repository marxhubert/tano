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

## Remaining consolidation

- One search-mode controller shared by Home and Folder (selection/search coupling).
- Shared delete/undo/move command paths, and a common `EntityBrowser` scaffold.

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
Manifest v2 preserves task types. A future format must carry folders and relations.
Extract transaction-aware commands, measure large-data search/pagination and move
expensive work off the UI. Project persistence remains separate future work.

## Premium and collaboration

Choose billing later and implement verified entitlements/restoration. Follow
[collaboration](collaboration.md) for peer authentication, remote transport, permissions,
replication and conflict testing. No central content storage. Premium is independent
from a collaborator's permission to a shared resource.

Use `develop` for integration and PRs into protected `master` for release promotion.

Earlier audits and the step 2 journal: [history](history.md).

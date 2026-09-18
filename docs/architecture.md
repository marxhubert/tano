# Architecture

Updated 19 September 2026. [Product rules](product-rules.md) define intended behavior.

## Current implementation

Flutter code is divided into `core` (models, repositories, services), `features`
(screens and presentation logic), and `shared` (configuration and UI). GetIt assembles
services. Notes and folders use `SQLiteNotesRepository`, schema 7, with SQLCipher
in production. FFI tests use ordinary SQLite and do not prove native encryption.

Attachments are encrypted separately. Covers are decoded in memory; external
viewers require a temporary plaintext file. Sensitive preferences are encrypted.
Installation keys use OS secure storage with single-flight initialization. A keystore
failure never permits a fixed fallback key.

`ContentEntity` defines shared read-only properties for Note, Folder, Task and
Project. `EntityKind`, generic sorting, category normalization and nullable copy
semantics belong to the domain. Task and Project remain models without persistence
or a production Kanban. The common contract does not merge distinct business schemas.

`NoteAccessPolicy` centralizes note visibility. Folder-authenticated access does not
grant blanket permission for arbitrary linked notes. Future remote authorization
must live at command/protocol boundaries, not only in widgets.

Import validates a bounded v1 archive before writing files. It resolves attachment
name collisions and inserts notes in one SQLite transaction. Imported notes have no
folder because v1 does not carry folder metadata. Existing IDs, including trash,
are skipped. Filesystem and SQLite writes are not one atomic transaction: a crash
can leave encrypted orphans for a future collector.

## Development data

No shipped data exists. Known legacy JSON/backup files are deleted, and a plaintext
SQLite database is discarded when opening with a production password. The current
schema still has upgrade support for development versions; no plaintext migration
or permanent plaintext backup is maintained. Before public release, establish a
versioned, tested migration and recovery policy for all future schema changes.

## Next consolidation

Extract repeated commands (metadata, move, trash, restore, lock), enforce
permissions and invariants, persist atomically, then notify UI. Handle failures
without leaving optimistic state inconsistent. Add orphan collection and lifecycle
lock invalidation. Persist tasks/projects before adding their screens.

[PremiumAccess](premium.md) defines feature boundaries; no store adapter exists.
[Collaboration](collaboration.md) is a design target. No signaling, CRDT or replication
journal is implemented; `updatedAt` is not a distributed revision protocol.

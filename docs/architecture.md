# Architecture

Updated 19 September 2026. [Product rules](product-rules.md) define intended behavior.

## Current implementation

Flutter code is divided into `core` (models, repositories, services), `features`
(screens and presentation logic), and `shared` (configuration and UI). GetIt assembles
services. Notes and folders use `SQLiteNotesRepository`, schema 9, with SQLCipher
in production. FFI tests use ordinary SQLite and do not prove native encryption.

Attachments are encrypted separately. Covers are decoded in memory; external
viewers require a temporary plaintext file. Sensitive preferences are encrypted.
Installation keys use OS secure storage with single-flight initialization. A keystore
failure never permits a fixed fallback key.

`ContentEntity` defines shared read-only properties for Note, Folder, Task and
Project. `EntityKind`, generic sorting, category normalization and nullable copy
semantics belong to the domain. Task is now a checklist document using the shared
note lifecycle, distinguished by a persisted kind. Project remains a prototype.
See [task lists](tasks.md) for editing and storage details.

`NoteAccessPolicy` centralizes note visibility. Folder-authenticated access does not
grant blanket permission for arbitrary linked notes. Future remote authorization
must live at command/protocol boundaries, not only in widgets.

Import validates a bounded v1/v2 manifest archive before writing files. It resolves attachment
name collisions and inserts notes in one SQLite transaction. Imported notes have no
folder because neither manifest carries folder metadata. Existing IDs, including trash,
are skipped. Filesystem and SQLite writes are not one atomic transaction: a crash
can leave encrypted orphans, collected at the next startup before editing begins.

## Development data

No shipped data exists. Known legacy JSON/backup files are deleted, and a plaintext
SQLite database is discarded when opening with a production password. The current
schema still has upgrade support for development versions; no plaintext migration
or permanent plaintext backup is maintained. Before public release, establish a
versioned, tested migration and recovery policy for all future schema changes.

## Next consolidation

Extract repeated commands (metadata, move, trash, restore, lock), enforce
permissions and invariants, persist atomically, then notify UI. Handle failures
without leaving optimistic state inconsistent. Startup orphan collection, recovery UI and lifecycle locking are implemented;
validate their native behavior before release. Project persistence remains future work.

[PremiumAccess](premium.md) defines feature boundaries; no store adapter exists.
[Collaboration](collaboration.md) is a design target. No signaling, CRDT or replication
journal is implemented; `updatedAt` is not a distributed revision protocol.

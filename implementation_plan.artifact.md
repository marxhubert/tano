# Phase 1 Implementation Plan: Infrastructure Migration (SQLite)

This phase focuses on upgrading the core infrastructure of TanoNote to support future features and ensure long-term stability using a relational database.

## Goals
- Migrate from simple JSON file storage to a structured database (**SQLite**). [DONE]
- Implement a Service Locator (**GetIt**) for cleaner dependency management. [DONE]
- Improve error handling for data persistence. [IN PROGRESS]

## User Review Required

> [!IMPORTANT]
> This change modifies the internal data storage format. A migration path from the old JSON file to the new SQLite database will be implemented to ensure users don't lose their existing notes.

## Proposed Changes

### 1. Dependencies & Configuration [DONE]
Add the necessary packages for SQLite and dependency injection.

#### [MODIFY] [pubspec.yaml](file:///Users/marx/Devhub/tano/pubspec.yaml)
- Add `sqflite`, `path`, `get_it`.

### 2. Service Locator Setup [DONE]
Centralize dependency management.

#### [NEW] [service_locator.dart](file:///Users/marx/Devhub/tano/lib/shared/config/service_locator.dart)
- Initialize `GetIt`.
- Register the `NotesRepository` (switching to the SQLite implementation).

### 3. Database Persistence [DONE]
Implement the new SQLite-based repository.

#### [NEW] [sqlite_notes_repository.dart](file:///Users/marx/Devhub/tano/lib/core/repositories/sqlite_notes_repository.dart)
- Implement `NotesRepository` interface using `sqflite`.
- Define the `notes` table schema.
- Handle data migration from the old `local_persistence.json` file on first run.

### 4. Application Lifecycle [DONE]
Wiring everything together in `main.dart`.

#### [MODIFY] [main.dart](file:///Users/marx/Devhub/tano/lib/main.dart)
- Initialize the Service Locator before `runApp`.
- Ensure Flutter bindings are initialized for SQLite.
- Cleaned up manual injection in `Home`, `EditNote`, and `SplashScreen`.

## Verification Plan

### Automated Tests
- [x] Run `flutter test` to ensure business logic remains intact.
- [ ] Add specific unit tests for `SQLiteNotesRepository` (needs mock sqflite).
- [x] Fix legacy tests broken by model renaming.

### Manual Verification
- [ ] Launch the app and verify that demo notes are still seeded.
- [ ] Create, edit, and delete notes to ensure database operations work as expected.
- [ ] Verify that theme and favorite toggles are correctly persisted.
- [ ] **Test the migration logic** by ensuring notes from an old JSON file are imported into SQLite.

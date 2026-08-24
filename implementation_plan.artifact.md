# Phase 2 Implementation Plan: Model Extension (Trash, Pinning, Locking)

This phase focuses on extending the `Note` model and the SQLite database to support new organizational and security features.

## Goals
- Add `isDeleted`, `isPinned`, and `isLocked` fields to the `Note` model.
- Update the SQLite database schema to store these new fields.
- Implement "Soft Delete" logic (moving to trash).
- Implement Pinning and Locking business logic in the repository.

## User Review Required

> [!IMPORTANT]
> The database schema will be updated. SQLite migration from version 1 to 2 will be handled automatically without data loss.

## Proposed Changes

### 1. Model Upgrade
Add the new functional fields to the `Note` class.

#### [MODIFY] [note.dart](file:///Users/marx/Devhub/tano/lib/core/models/note.dart)
- Add `isDeleted` (bool), `isPinned` (bool), `isLocked` (bool).
- Update `fromJson` and `toJson` to handle these fields (stored as INTEGER 0/1 in SQLite).
- Update `copyWith`.

### 2. Database Schema Migration
Update the SQLite repository to handle the new columns.

#### [MODIFY] [sqlite_notes_repository.dart](file:///Users/marx/Devhub/tano/lib/core/repositories/sqlite_notes_repository.dart)
- Increment database version to `2`.
- Add `onUpgrade` logic to `openDatabase` to add the new columns (`isDeleted`, `isPinned`, `isLocked`) to existing installations.
- Update the `onCreate` schema.

### 3. Repository Logic Extension
Add methods to handle the new states.

#### [MODIFY] [notes_repository.dart](file:///Users/marx/Devhub/tano/lib/core/repositories/notes_repository.dart)
- Add `Future<void> trashNote(String id)` (soft delete).
- Add `Future<void> restoreNote(String id)`.
- Add `Future<void> togglePin(String id)`.
- Add `Future<void> toggleLock(String id, String? password)`.

### 4. View Model Integration
Prepare the ViewModels to use these new properties.

#### [MODIFY] [home_view_model.dart](file:///Users/marx/Devhub/tano/lib/features/notes/home_view_model.dart)
- Filter out notes where `isDeleted == true` from the main list.
- Implement sorting that puts `isPinned` notes at the top.

## Verification Plan

### Automated Tests
- Run `flutter test` to ensure existing features still work.
- Add unit tests for database schema migration (v1 to v2).
- Add unit tests for soft delete and pinning logic.

### Manual Verification
- Verify that "Deleted" notes no longer appear in the main list.
- Verify that pinned notes stay at the top of the grid/list.
- Verify that toggling favorite/pin/lock state is persisted after app restart.

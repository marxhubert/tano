# Phase 4 Implementation Plan: CRUD Optimization & Performance

This phase focuses on transitioning from a "full-save" approach to a fine-grained CRUD (Create, Read, Update, Delete) model. This will significantly improve performance and data integrity by only modifying specific rows in the SQLite database.

## Goals
- Transition the `NotesRepository` from `saveNotes(List<Note>)` to individual entity management.
- Implement efficient `upsertNote` (Insert or Update) logic.
- Optimize the `HomeViewModel` and `EditNoteViewModel` to perform targeted updates.
- Improve search performance by moving from in-memory filtering to SQL-based queries.

## Proposed Changes

### 1. Repository Interface Refactor
Update the interface to reflect modern data access patterns.

#### [MODIFY] [notes_repository.dart](file:///Users/marx/Devhub/tano/lib/core/repositories/notes_repository.dart)
- [DELETE] `Future<void> saveNotes(List<Note> notes)`.
- [NEW] `Future<void> upsertNote(Note note)`.
- [NEW] `Future<List<Note>> searchNotes(String query)`.

### 2. SQLite Implementation Optimization
Leverage SQL capabilities for targeted operations.

#### [MODIFY] [sqlite_notes_repository.dart](file:///Users/marx/Devhub/tano/lib/core/repositories/sqlite_notes_repository.dart)
- Implement `upsertNote` using `ConflictAlgorithm.replace`.
- Implement `searchNotes` using a `WHERE title LIKE ? OR content LIKE ?` SQL query.

### 3. ViewModel Logic Update
Switch from entire list persistence to single note persistence.

#### [MODIFY] [edit_note_view_model.dart](file:///Users/marx/Devhub/tano/lib/features/editor/edit_note_view_model.dart)
- Use `repository.upsertNote(note)` instead of loading and saving the whole list.

#### [MODIFY] [home_view_model.dart](file:///Users/marx/Devhub/tano/lib/features/notes/home_view_model.dart)
- Update `applyNoteAction` to use individual CRUD methods.
- (Optimization) Update `setSearchQuery` to trigger a repository-side search if needed.

### 4. Tests Adjustment
Ensure test mocks match the new interface.

#### [MODIFY] All `_InMemoryNotesRepository` in test files.
- Replace `saveNotes` implementation with `upsertNote`.

## Verification Plan

### Automated Tests
- Run `flutter test` to ensure that targeted updates correctly reflect in the final state.
- Verify that search results from SQL match the previous in-memory filtering logic.

### Manual Verification
- Verify that editing a note saves it correctly without affecting other notes.
- Test the search bar with various keywords to ensure reactivity and accuracy.
- Check that "Restore" and "Trash" actions still work perfectly.

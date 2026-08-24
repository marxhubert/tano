# Phase 3 Implementation Plan: Trash & Pinning Features

This phase focuses on exposing the infrastructure built in Phase 2 to the user, specifically the Recycle Bin and Note Pinning functionalities.

## Goals
- Implement visual indicators and controls for **Note Pinning**. [DONE]
- Create a dedicated **Recycle Bin** page for managing soft-deleted notes. [DONE]
- Allow **Restoring** or **Permanently Deleting** notes from the trash. [DONE]
- Integrate these features into the existing UI (Edit page, Settings, Home). [DONE]

## Proposed Changes

### 1. Note Pinning (Visibility & Controls) [DONE]
📍 *Make pinned notes stay at the top and clearly visible.*

#### [MODIFY] [note_card.dart](file:///Users/marx/Devhub/tano/lib/shared/widgets/note_card.dart)
- Display a small pin icon if `note.isPinned` is true.

#### [MODIFY] [app_fab.dart](file:///Users/marx/Devhub/tano/lib/shared/widgets/app_fab.dart)
- Wire up the `onPinSelected` callback in the "More" menu.
- Display `push_pin` (filled) when pinned, `push_pin_outlined` otherwise.

#### [MODIFY] [edit_note_page.dart](file:///Users/marx/Devhub/tano/lib/features/editor/edit_note_page.dart)
- Implement `onPinSelected` logic to toggle pin status via `EditNoteViewModel`.

### 2. Recycle Bin (Management) [DONE]
🗑️ *A safe place for deleted notes.*

#### [NEW] [trash_page.dart](file:///Users/marx/Devhub/tano/lib/features/trash/trash_page.dart)
- Displays only notes where `isDeleted == true`.
- Provides "Restore" and "Delete Forever" actions on each note.
- "Empty Trash" action in the AppBar.

#### [NEW] [trash_view_model.dart](file:///Users/marx/Devhub/tano/lib/features/trash/trash_view_model.dart)
- Handle loading deleted notes and the restore/purge logic.

#### [MODIFY] [settings_page.dart](file:///Users/marx/Devhub/tano/lib/features/settings/settings_page.dart)
- Link the "Recycle bin" option to the new `TrashPage`.

#### [MODIFY] [notes_repository.dart](file:///Users/marx/Devhub/tano/lib/core/repositories/notes_repository.dart)
- Added `deleteNotePermanently`.

#### [MODIFY] [sqlite_notes_repository.dart](file:///Users/marx/Devhub/tano/lib/core/repositories/sqlite_notes_repository.dart)
- Implemented `deleteNotePermanently`.

## Verification Plan

### Automated Tests
- [x] Run `flutter test` (All 45 tests passing).
- [x] Updated in-memory test repositories to support the new interface.

### Manual Verification
- **Pinning**: Verify pinned notes stay at the top.
- **Trash Flow**: Verify deleting from home, seeing in trash, and restoring/purging.

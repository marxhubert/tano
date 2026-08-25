# Feature Plan: Link a Note

This feature allows users to insert clickable links to other notes within the editor.

## Goals
- Allow users to select a note from a list within the FAB.
- Insert a styled link (icon + title, bold, underlined, colored) at the cursor position.
- Make the link clickable to navigate to the referenced note.

## Proposed Changes

### 1. FAB (Note Selection Menu)
#### [MODIFY] [app_fab.dart](file:///Users/marx/Devhub/tano/lib/shared/widgets/app_fab.dart)
- Add a new menu state `FabVerticalMenu.link`.
- Implement `_buildLinkMenu(context)` to list all notes.
- Ensure the menu has a max height of 1/3 of the screen and is scrollable.
- Add a "Back" button at the top left of this menu to return to the "Add" menu.
- Each item will display the `sticky_note_2` icon and the note title.

### 2. Editor Logic (Rich Text & Linking)
#### [NEW] `lib/shared/widgets/link_text_controller.dart`
- Create a custom `TextEditingController` that detects a specific pattern (e.g., `[[noteId:title]]`).
- Render this pattern using a `TextSpan` with:
    - The `sticky_note_2` icon.
    - The title in bold, underlined, and colored.

#### [MODIFY] [edit_note_page.dart](file:///Users/marx/Devhub/tano/lib/features/editor/edit_note_page.dart)
- Replace the standard `TextEditingController` with the new `LinkTextEditingController`.
- Implement tap detection on the link spans to navigate to the target note.
- Implement the `onLinkSelected` callback to insert the link placeholder at the current cursor position.

### 3. Repository
#### [MODIFY] [notes_repository.dart](file:///Users/marx/Devhub/tano/lib/core/repositories/notes_repository.dart)
- Ensure we can fetch notes efficiently for the selection list.

### 4. Localization
#### [MODIFY] [l10n.dart](file:///Users/marx/Devhub/tano/lib/shared/config/l10n.dart)
- Add translations for "Back" if not already present.

## Verification Plan
- **Selection**: Open the "Plus" menu, click "Link a note", and verify the list of notes appears with a back button.
- **Insertion**: Select a note and verify that a styled link is inserted at the cursor position.
- **Navigation**: Tap the inserted link and verify it opens the correct note.
- **Persistence**: Save the note, reopen it, and verify the link is still there and functional.

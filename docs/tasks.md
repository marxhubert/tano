# Task lists

Task is a free checklist document with a title, metadata and checkable rows.
It follows the same local lifecycle as a note.

## Editing

The third Home FAB action (`format_list_bulleted_add`) creates a task list.
Folders also offer task creation in their add menu. Both routes open the shared
editor, with its title, app bar, undo/redo and save. The Task add menu contains image,
link a note and description. Linked notes are inserted at the current cursor in
the description or task row and retain the normal authentication policy when opened. The tools menu labels search as
"Find in tasks". New rows and FAB layout changes recenter the active caret in the
space above the FAB and keyboard, within the document scroll bounds. Current find
results are centered in that space in both Note and Task editors.

A new list focuses an empty row beside a checkbox. Enter splits a row; multiline
paste creates multiple rows. Rows can be removed individually. Active rows can be reordered using the drag
handle before their checkbox. Add and Enter reuse an existing empty draft instead
of accumulating blank rows. Completed rows
appear below a divider and a collapsible, primary-colored heading with an animated
chevron. The section disappears when no completed row remains. Unchecking
returns the row to its original relative position among active rows. A list with
all rows completed can still add new active rows. The metadata shows the bookmark indicator on the right and the lock before the
date, separated by a divider. It counts all nonblank
rows, completed or not; the empty drafting row is not counted or persisted.

Home, folder and trash cards show checkbox previews with active rows first, and
count items rather than blocks.
Locked cards continue to hide content. Task lists have no Premium gate.

## Shared implementation

The existing `Note` class is the shared document representation, now discriminated
by `kind: note | task`; `Task` constructs a checklist document. The repository API
keeps its existing names for compatibility. Schema 9 adds the discriminator to the
shared encrypted document table. Older rows default to `note`. Copying, editing,
moving, restoring and importing preserve the discriminator.

A separate description field appears after the cover and before the checklist. It
is limited to 500 characters in the editor, including link markup. It is included
in save, undo/redo, global search and import/export, but never counts as a checklist
item. Note and Task covers are cropped to 160 logical pixels high, like folder
covers. Inline note links display only their label in the editor text font. FAB menus
keep the keyboard open and scroll within the remaining viewport.

Checklist rows use the existing `- [ ] text` / `- [x] text` representation. There is
no stored presentation separator. `TaskContent` parses and normalizes rows;
`TaskListEditor` projects them into active/completed sections and synchronizes with
the shared document controller. This keeps save, undo/redo, links and find on the
same content, without a second persistence pipeline.

Locking, folder access, search scopes, attachment encryption/cleanup, privacy
shielding, deletion, reset and write-failure recovery use the existing note paths.
These rules apply equally to task documents. A note checklist stays a note;
there is no implicit conversion.

## Transfer and development data

Archives containing tasks use manifest version 2 so older applications reject
rather than silently reinterpret them as notes. Note-only exports remain manifest
version 1. Both are supported on import; the encrypted envelope remains version 1.
Folders are still not carried in either manifest, so imports clear folder membership.

Developer reset adds synthetic task lists with mixed, completed and locked rows.
They follow the same debug-only exclusion and device-credential checks as other
fixtures. No automatic first-launch seeding is enabled.

## Verification

- `task_list_editor_test.dart`: caret, row creation, completion sections and restores.
- `task_persistence_test.dart`: empty validity, normalization, type preservation,
  SQLite persistence, lock policy, trash/restore and export/import.
- `home_refresh_after_edit_test.dart`: Home FAB creation, counts, undo/redo,
  save, watermark and reopening.

Native keyboard, text composition and accessibility behavior still require real
Android/iOS device validation. Widget tests do not replace that validation.

The previous Task baseline passed 338 tests including existing goldens. Follow-up
tests cover reordering, empty draft reuse, collapsing, description undo/persistence
and authentication when opening linked notes.
The editor was also rendered and visually inspected at 390×844 logical pixels.
No simulator or physical device was launched for this implementation.

Refinement tests also cover inline link insertion in task rows and descriptions,
the description length limit, and centering with a simulated keyboard: expanded
FAB, add menu, new empty row with collapsed FAB, and find-result navigation.
Folder regressions include descriptions in folder-scoped search.

## Document filters

Home and folders offer every document, the notes and the tasks through one
segmented control: each segment keeps its label and its own count, and the active
one is filled with the accent. Counts reflect visible
documents. Changing filters clears selection, and Select all respects the active
filter. Folder flags appear beside the title; its document filter sits below the
cover when present. Task cards count links in both description and checklist,
align checkboxes with the title, and hide the checklist when a cover is present.

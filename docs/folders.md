# Folders

## Implemented model

A `Folder` groups notes through nullable `Note.folderId`. Null means unfiled.
There are no nested folders. Common fields include stable ID, name, timestamps,
important, color category, lock and trash state. Rich content, attachments,
checklists and note links belong to notes, not folders.

Home shows folders first, then unfiled notes. Each group uses common sorting;
favourites sort first in their group. Default folder names use the lowest available
`Folder N`. Grid and list use the shared entity cards. A folder name allows up to
three lines in grid and two in list. Metadata is omitted when empty.

Selection can delete folders and notes. Moving is limited to notes; a selection
containing a folder disables Move. The FAB destination menu excludes the current
folder. Move preserves the note's own lock flag and updates its timestamp.

## Opening and search

A locked folder requires the OS credential. Once inside, objects do not request
it again for that folder session. A locked note moved outside remains locked.
Folder search and selection operate only on that folder's objects. Locked objects
never appear in search; unlocked children can be searched inside an already-open
locked folder. Home search includes eligible notes inside unlocked folders.
Folders themselves are not currently full-text search results.

The folder screen reuses card layouts and sorting, with its name as the title,
important, rename, lock and deletion actions. Without a device credential, Lock is
disabled and the folder keeps the only remaining corner watermark; it no longer
has a cover.

## Deletion

Trashing a folder keeps its notes linked, so restoration brings the folder back
intact. They are excluded from global results while the parent is deleted.
Permanent folder deletion removes its notes and folder record in one transaction.
Encrypted orphan attachments are collected at startup against the complete
reference set. Confirmation indicates
the affected contents. Nested folders and remote synchronization are not implemented.

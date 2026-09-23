# Components and contracts

Use shared components and [design tokens](design-system.md). Code is the source for
current values; historical mockups do not override tested behavior.

## Page and navigation

`PageScaffold` provides scrolling, page/header layout and actions. Back navigation is
present outside Home. App bars allow at most three actions; Cancel is the text-action
exception. Hide the theme toggle when editing actions occupy those slots. Titles
collapse with scrolling and handle long content without overflow. All routes share
the ruled hero paper; category colors tint cards only. `SectionTitleLine` and `MetadataLine` own header
text and metadata rather than duplicating ad-hoc Rows. When a title is reduced to the
app bar its flags read bookmark + title + lock (`headerMetadataLeading` /
`headerMetadataTrailing`); the body title line keeps its own right-hand metadata.

## FAB

The unified `AppFab` has circular, extended and vertical-menu forms. Secondary
menus provide note links and folder destinations. Search, selection, find-in-note,
editor and folder modes reuse the same component. Selection offers move/delete/
select-all/select-none; Move is disabled if a folder is selected. The current folder
is not a move target. Lock is disabled without device authentication capability.
Menu states and transitions should remain consistent across screens.

See **[fab.md](fab.md)** for the full description: every form, the geometry, the
state machine, the motion tokens, the integration and the rules a change must keep.

## Cards

`EntityCard` renders Note, Folder, Task and Project presentations through a shared
shell and type-specific content. Types belong to the domain (`EntityKind`). Task persistence is implemented; Project cards remain presentation previews.

Cards use paper surfaces, radius 8, warm 1px borders and a subtle shadow.
List heights are compact 100 and normal 112, adjusted for text scaling. Grid covers occupy the
upper half; list covers occupy the left third. Shared markers represent selection,
bookmark and lock. Pinning was removed; bookmarks sort first.

Locked cards share a restricted template and inset dotted contour. Grid titles allow
three lines, list titles two. Insets and inner radii follow the outer-radius-minus-
inset rule; refer to the widget constants for geometry. Avoid content previews that
leak locked data. Image errors use a neutral placeholder.

## Covers and settings

`ManageableCover` gives the editor's note/task cover its affordances: long press
exposes remove with confirmation. The cover keeps its own aspect ratio; a phone in
portrait lets it bleed to both screen edges, while every other window insets it with
the content and rounds its corners. It keeps the shared top/bottom rules and, in the
editor, no light-theme dim. Covers decode in memory, not plaintext cache files.

Settings groups have a title, option rows and footer (up to three lines).
Premium opens an information page while billing is pending, not a fake purchase flow.

## Feedback and accessibility

Major decisions use platform-adaptive dialogs. Minor confirmations use Android
snackbars or an iOS top toast, typically two seconds. Undo retains its own timing.
Use Material Symbols, consistent tap targets and meaningful labels. Test dark/light,
small screens, large text and native back behavior; goldens alone are insufficient.

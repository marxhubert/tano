# The floating action button — `AppFab`

The FAB is the app's one command button. It is not a `FloatingActionButton`: it is
a stateful shell that **morphs** between every form the app needs, so the
button keeps its identity — and its state — while the page it belongs to changes
mode. This document describes what it looks like in each form, the numbers behind
its geometry, its state machine, and the rules any change must respect.

## Where it lives

| File | Holds |
|---|---|
| `lib/shared/widgets/fab/app_fab.dart` | the public widget, rendering and surface painters |
| `lib/shared/widgets/fab/fab_state.dart` | synchronous presentation state and allowed transitions |
| `lib/shared/widgets/fab/fab_geometry.dart` | pure sizing, safe-area budget and mirrored offsets |
| `lib/shared/widgets/fab/fab_lifecycle.dart` | lifecycle reconciliation, cancellable data reads and layout notifications |
| `lib/shared/widgets/fab/fab_measurement.dart` | size observation of the visible layout |
| `lib/shared/widgets/fab/fab_bars.dart` | the horizontal bars (home, editor, selection, search, find) |
| `lib/shared/widgets/fab/fab_items.dart` | the pieces they share: one bar action, one menu row, the sub-menu shell, the active-zone painter |
| `lib/shared/widgets/fab/fab_menus.dart` | the active menu and its loading/retry presentation |

Bars, items, menus, lifecycle and measurement remain `part`s of the widget library.
Presentation state and geometry are independently testable modules. The public
callback API remains compatible with the pages. See
[history](history.md) for the instability findings and scope.

## The forms

### 1. The rest: a circle

64 × 64, radius 55, holding one glyph:

- **Home**: `Symbols.add_2` — the "+" that expands the bar.
- **Editor and folder**: `Symbols.more_horiz` — the "…" that expands the bar.
  On a folder it is the *resting* form when the list can scroll
  (`collapsedByDefault`), so the page opens calm and the button is opened on
  demand.

The rest is the anchor of everything else: the FAB never leaves it, it only grows
from it.

### 2. The extended bar

A row of icon-only actions, each in its own equal zone, growing out of the circle:

| Mode | Rest | Extended, left to right |
|---|---|---|
| Home | `add_2` | `create_new_folder` · `add_notes` · `format_list_bulleted_add` · reduce chevron |
| Editor / folder | `more_horiz` | `add_circle` · `palette` · `build_circle` · reduce chevron |

The reduce chevron is `arrow_forward_ios`, or `arrow_back_ios` when the FAB sits
on the left. With `onLeft` the whole row is reordered so that chevron leads: the
bar grows **away** from the edge it is anchored to, and the fold-back always sits
next to the button's origin.

### 3. The vertical menus

Opening an action that has sub-choices grows the FAB **upwards**: the bar stays at
its place and a panel unfurls above it, filled with the menu's own teal. The bar
action that opened it gets an *active zone* — the same teal, with concave fillets
spilling into the panel — so the two read as one piece.

| Menu | Opened from | Holds |
|---|---|---|
| `add` | `add_circle` / a new note | image, checklist, link, attachment (note, task or folder variants) |
| `color` | `palette` | the 10 pastel couplets (20 swatches), five per row |
| `more` | `build_circle` | important, find, move, lock, delete (note) · important, edit, lock, delete (folder) |
| `link` | "link" inside `add` | every other note, sortable |
| `move` | "move" inside `more`, or the selection bar | "Home" plus every other folder, sortable |

`link` and `move` are second-degree: they take over the panel with a header that
carries a back arrow (back to `add`, or to whatever opened the move) and the two
sort switches.

### 4. The mode bars

Three modes replace the bar with a dedicated one, with no circle at all:

- **Search** (`isSearchMode`): a magnifier, a text field, and a clear button once
  something is typed.
- **Find in note** (`isFindMode`): the counter (`3/12`, two lines past 99),
  previous/next, and close.
- **Selection** (`isSelectionMode`): select-all, select-none, move, delete.
  Move is refused as soon as a folder is part of the selection; delete is refused
  when nothing is selected.

## The state machine

`FabPresentation` owns the effective mode, explicit expansion choice, active
menu and Move's return destination. The adapter resolves mode priority once:
Find → Selection → Search → Folder → Editor → Home. Rendering only reads state;
`didChangeDependencies`, `didUpdateWidget` and user actions reconcile changes.

- Home defaults to a circle. Editor/folder defaults to expanded while the keyboard
  is closed, unless `collapsedByDefault` or a new editor requests a circle.
- Search, Find and Selection use dedicated bars.
- Explicit expand/collapse survives keyboard metrics, rotation and unrelated
  rebuilds. The keyboard only changes the automatic default before a user choice.
- Renaming a folder closes its menu and forces the circle.
- Changing effective mode or document context closes the previous menu. Selection
  permits only Move, and revoking `canMove` closes that panel.
- Opening a menu changes presentation **synchronously**. Repository reads populate
  it afterwards; they never open, close or replace a panel.
- Closing, collapsing, changing context or choosing another panel invalidates the
  outstanding request generation. Late completions are ignored. Errors offer Retry
  in list submenus; duplicate requests while loading are ignored.

`closeVerticalMenu()` retains the explicit expanded bar; `collapse()` closes the
menu and folds the bar. Returning from a submenu restores its parent explicitly.

## The geometry

### Width

The expanded bar's width never depends on the window's *long* side. It starts from
a **content width**:

```dart
raw = compactChrome(size)          // landscape, or any tablet
    ? size.shortestSide            // the width it has in portrait
    : size.width - sideSafeInset * 2;
contentWidth = min(raw, appContentMaxWidth);   // 1080
```

- resting (circle): **64**
- expanded, nothing open: `contentWidth - 48` — 24 to the anchor, 24 to the far
  side
- expanded with a menu open or the keyboard up: `contentWidth - 24` — the extra
  width is given back to the far side, because the panel needs it

Because the compact width is the *shortest side*, rotating a device moves the FAB
without resizing it — the bar is the same shape as before the rotation.

### Height

```dart
barHeight = 64                       // 48 for search/find while the keyboard is open
currentHeight = barHeight + verticalMenuHeight;
```

Only the **active, visible** menu is laid out, at its target width and within
`FabGeometry.maxMenuHeight`. A render-size observer reports changes after layout;
there are no hidden copies, fallback height guesses or build-time state mutations.
The measured size becomes the animated shell's target height. Measurement uses
the available viewport, never the shell's currently animated height, avoiding a
feedback loop. It follows width, locale, text scale and asynchronous content.

The available height is the distance between the actual painted bottom of the FAB
and the safe app-bar bottom, minus the bar itself. Bottom safe area and keyboard
are combined with `max`, not added together. A zero-height menu remains valid.

Long menus scroll inside that budget. Link/Move headers remain outside their body
scroll view when space permits; in a very short viewport the header scrolls with
the body so items remain reachable. A persistent scroll controller avoids losing
the current position during keyboard resizing. Menu identity is keyed by menu
kind, not by the changing keyboard height.

### Corner radius

| State | Radius |
|---|---|
| Resting | 55 — a circle |
| Menu open, compact window | 24 on all four corners |
| Menu open, portrait phone | 24 top, 55 bottom — the original tab |
| Extended bar, no menu | 55 |

### Position

The FAB does not use `FloatingActionButtonLocation`'s defaults; it uses
`FlushFabLocation` (in `page_layout.dart`):

- **compact window** (a landscape phone, or a tablet in either orientation): the
  FAB is anchored to the edge of the content column, **12** from it on a phone and
  **24** on a tablet, for both the horizontal and the bottom edge;
- **portrait phone**: the FAB hugs the centred column's right edge, 24 short of
  it;

and with `onLeft` everything mirrors to the left edge.

**The FAB never moves to open.** It extends and opens its menus from the point it
rests at. The one exception, kept for the portrait phone it was designed for, is a
12 px nudge (`tx`) and 8/12 px drop (`ty`) that grow the bar towards the edge —
both are zero in a compact window.

```dart
double tx = 0, ty = 0;
if (!compact) {
  if ((isExpanded || isMenuOpen) && (isMenuOpen || !isKeyboardClosed)) {
    tx = onLeft ? -12 : 12;
  }
  if (isMenuOpen) ty = 8; else if (!isKeyboardClosed) ty = 12;
}
```

The transform is `null` while both are zero: passing a fresh identity `Matrix4`
every build made the implicit animation interpolate for nothing.

## The surface

The FAB wears the site's primary button (the `.btn` tokens in `site/site.css`),
drawn translucent so the page shows through:

- fill: the theme's primary at **86 %** opacity (`_fabMenuSurface`);
- a **10 px** `BackdropFilter` blur behind it — the "masthead" effect;
- a 1 px border mixed 22 % towards black, and an inset white highlight painted
  above the fill and below the border (`_PrimaryButtonEdge`, its offset path
  reproducing CSS `inset 0 1px 0`);
- a warm black shadow (`0, 10`, blur 18, spread −14);
- icons and labels in `onPrimary`.

An active menu zone paints **the same 86 % teal overlay** as the panel
(`_fabActiveSurface` = `_fabMenuSurface`): the shape alone marks the active
action. Both overlays composite over the translucent shell, so their effective
opacity is higher than 86 %. The submenu header adds no extra colour layer; its
separate body viewport prevents rows showing through the header while scrolling.

## The motion

| What | Duration | Curve |
|---|---|---|
| The `AnimatedContainer` (size, radius, nudge) | 250 ms | easeInOut |
| The content swap (fade + 0.75 → 1 scale) | 250 ms | easeOutCubic / easeInCubic |
| The bar content opacity | 150 ms | — |
| The hover lift | 160 ms | ease |

Non-text bar content is swapped by an `AnimatedSwitcher` keyed on effective mode: the
outgoing set zooms out while the incoming zooms in — the box itself does not move.
Search/Find fields switch directly: keeping an outgoing editable field alive would
attach the same controller and focus node twice during rapid mode changes.
During the growth, the content only fades in once `expansionProgress > 0.8`, so
labels never appear squeezed; while a menu is open the bar content stays visible.

The outer shell animates size and shape; the panel content is laid out at its
natural bounded size from the first frame (`OverflowBox`), and the growing container clips it. That is
why a menu never wraps or squashes on the way up.

## The horizontal bar

`_buildHorizontalBar(width, children)` splits the bar into **N equal, gapless,
full-height zones** (`Expanded` per child, no spacing, padding or margin), so
the tap targets meet edge to edge. With `onLeft` the list is rotated by one: the
last child (the reduce chevron) moves to the head in Home/Editor/Folder. Selection
keeps its action order: Delete must not be mistaken for a reduce chevron.

One action (`_EditorAction`) is: an `IconButton` with no padding and a shrink-wrapped
tap target, a tooltip and an accessibility label (the label doubles as the
Semantics), and an optional colour. A refused action keeps its place — the row
never reshuffles — but wears the neutral foreground at 35 % and ignores taps.
Disabled **delete** borrows that neutral grey too: red at 35 % would lose contrast
against the teal.

## The vertical menus

The panel is a container filled with the menu surface, with its content anchored
at the bottom and clipped by the growing FAB. Each row (`_VerticalMenuItem`) is
an `InkWell` with an icon, a label and a 12 px vertical padding; a disabled row
keeps its seat at 38 % opacity.

- **colour** — the 10 pastel couplets of `TanoPastels` (20 swatches), five per
  row. The couplet is two
  colours split diagonally (the row rotated 45°); the selected one gets a soft halo
  36 % larger and an amber check on a white disc.
- **add** — image · checklist · link · description · attachment, minus the ones
  the mode forbids (a task has no checklist, a folder has no checklist either).
- **more** — important · find · move · lock · delete. `important` is a fill axis
  (0 outlined, 1 filled) in amber; delete is painted in the destructive red.
- **link** and **move** — the sub-menu shell: a header (back arrow, title, sort
  criteria, sort direction) over a scrollable list. Link lists the notes (title
  first, two lines max), move lists "Home" then the folders.

Data is read lazily when opening Add/Link or More/Move, with current document,
task-kind and folder exclusions applied. Folder editing does not need those reads;
**folder selection does**, because selected notes can move to other folders.
Loading and error states are explicit. The repository remains the source of data;
menu eligibility does not replace authorization in page/view-model operations.

## Reporting back

A render observer reports actual size changes; lifecycle changes also notify when
metrics or the chosen side change. Notifications are coalesced after the frame,
with another notification at animation completion. `build` schedules no work.
The editor debounces caret centring until layout settles, bounds follow-up attempts
and cancels the current centring request on a manual scroll. A new edit, search
result or layout change can start a new request.

## The public surface

The `AppFab` constructor takes the mode flags (`isSearchMode`,
`isSelectionMode`, `isFindMode`, `isEditorMode`, `isFolderMode`,
`collapsedByDefault`, `isTitleEditing`, `onLeft`), the capability flags
(`canMove`, `canLock`, `canDelete`), the data it needs (`currentCategory`,
`currentNoteId`, `currentFolderId`, `isImportant`, `isLocked`, `isTaskMode`,
`isAddMode`, the find counters) and one callback per action. Navigation and writes
belong to the page. The lifecycle adapter reads notes/folders through the
registered repository for picker content.

Imperatively, the pages hold a `GlobalKey<AppFabState>` and call:

- `collapse()` — back to the circle, menu closed. Home and the folder do it from
  `didPushNext`, so the button is already folded after a normal route visit. The
  delayed fold is cancelled on an early return or disposal;
- `closeVerticalMenu()` — drops the panel only, used before a navigation.

The key is stable across rebuilds, which is also what keeps the FAB's own state
(the open menu, the manual expansion) alive while the page rebuilds around it.

## Integration

`PageScaffold` passes the widget straight to `Scaffold.floatingActionButton`,
with `FlushFabLocation(onLeft: …)` as the location. Three pages mount it:

| Page | Flags |
|---|---|
| `home_page` | home mode, plus search and selection |
| `folder_page` | `isEditorMode`, `isFolderMode`, `collapsedByDefault`, plus search and selection |
| `edit_note_page` | editor mode, plus find and selection |

Both the FAB and the cards join the same `TapRegion` group (`fabTapGroup`), and so
does the theme toggle: tapping any of them keeps the menu open, tapping anywhere
else closes the panel **and** folds the FAB back. `TextFieldTapRegion` also groups
FAB actions with editable fields so mouse clicks preserve the insertion caret.

## Rules any change must keep

1. **The FAB does not move.** Extending it, or opening a menu, must not shift the
   circle; only its far edge grows, towards the middle. The portrait nudge is the
   grandfathered exception.
2. **The location must compare equal.** `FlushFabLocation` defines `==` and
   `hashCode` on `onLeft`. Without that, the pages' freshly-built location looked
   like a new one on every rebuild and the `Scaffold` replayed its move animation
   — which scales the FAB — so the button blinked on every tap.
3. **Rest with a `null` transform.** A new identity matrix each build keeps the
   implicit animation running for nothing.
4. **One side everywhere.** The FAB's side is a global setting
   (`FabSideController`): a page must read it, never keep its own copy, or the
   button ends up on two different sides.
5. **Measure the active menu, then grow.** Keep measurement independent of the
   animated height and bounded by the keyboard/app-bar budget. Never build hidden
   copies or mutate presentation state during rendering.
6. **A refused action keeps its seat.** Disabling greys a row or a zone out; it
   does not remove it, so the row never reshuffles under the finger.
7. **The circle is 64 and the corner is 55.** Anything else breaks the morph.

## Tests

| File | What it pins |
|---|---|
| `test/fab_state_test.dart` | expansion defaults, explicit intent, allowed modes and capability revocation |
| `test/fab_geometry_test.dart` | pure sizing, keyboard budget, mirrored offsets and narrow windows |
| `test/fab_stability_test.dart` | request races, failures/retry, mode changes, short landscape menus, scroll/focus retention and real painted anchors |
| `test/fab_menu_test.dart` | the menu rules: a button that would open an empty list is refused, and opens as soon as the list has something; a note is never offered the folder it already sits in |
| `test/folder_home_test.dart` | the FAB inside a page: it folds while another route covers the page; quick returns cancel delayed folding |
| `test/home_refresh_after_edit_test.dart` | the same, from the Home side |
| `test/view_layout_sync_test.dart` | the shared settings — the FAB's side is one global choice — and the view-switch fan-out |
| `test/golden/site_design_golden_test.dart` | the box: fill, radius, shadow, edge highlight, in both themes |
| `test/golden/responsive_golden_test.dart` | the geometry across phone, tablet and wide windows |

FAB geometry is asserted in `fab_geometry_test.dart` and through painted bounds in
`fab_stability_test.dart`. Card column tests remain separate. Golden tests guard
appearance, but automated tests do not replace checking keyboard transitions,
rotation and blur on a physical device.

# Project review and FAB consolidation — September 2026

Baseline: `6641380` on `feature/site-inspired-design`. This review compares current
source and tests with the documentation; historical feature descriptions are not
implementation contracts. No new feature, dependency or storage migration is part
of this consolidation.

## Current application

| Area | Current implementation and constraints |
|---|---|
| Data/domain | Models, services and repositories live in `core`; SQLCipher schema 9 stores Note and Task through the shared document model. Task has structured checklist content and a separate description. |
| Features | Home, Folder and Editor use shared cards, filtering, selection, lock and persistence paths. Projects remain a prototype; sharing/collaboration and billing are not operational features. |
| State | GetIt services and ChangeNotifier view models; secure preferences control presentation. Global view-layout and FAB-side controllers were recently introduced. |
| Design | Common paper surface, bundled serif fonts, teal FAB, persistent segmented document filters, compact landscape/tablet chrome and a centred content column. Folders are square and retain their watermark; document cards no longer have the earlier watermarks. |
| Responsive layouts | Current grid columns: phone portrait 2, phone landscape 4, tablet portrait 4, tablet landscape 5, wide 5. List: 1/2/3/4/5. Folders: 3/5/5/7/7. `compactChrome` includes tablets; `condensedHeader` is landscape-only. |
| Privacy | Authentication and access policy remain in operations, including linked documents. Cached menu rows are not authorization. PrivacyGuard keeps drafts mounted while hidden; UI restructuring must preserve these identities. |
| Transfer/maintenance | Import/export, attachment validation, trash, reset and developer fixtures have existing dedicated services/tests. This work does not change their formats or rules. |

## Why the FAB was unstable

| Finding | Consolidation |
|---|---|
| `build` changed expansion/menu state after computing local flags | `FabPresentation` handles transitions before rendering; one effective mode resolves conflicting page flags. |
| Repository completion decided whether a menu opened | Open synchronously, then read data; generation invalidation prevents stale completion after close, mode/context changes or another choice. |
| No explicit failed-load state | Loading and retry states, guarded duplicate reads, no uncaught picker-load exception. |
| Every rebuild constructed five offstage menus and copies of their lists | Measure only the active visible menu at its target width and bounded natural height. |
| Menu measurement became stale with rotation, text scale or content changes | A render observer follows actual layout; pure geometry budgets space independently of the animated height. |
| A fixed submenu header could consume the entire landscape keyboard viewport | Scroll the whole submenu in very short viewports; retain the body controller during metric changes. |
| Keyboard edges reset explicit user intent | Preserve explicit expansion/menu state; only the untouched automatic default follows the keyboard. |
| Search/Find transitions could leave duplicate or squeezed editable bars | Text-entry modes switch directly; other bars keep their icon animation. |
| Left mode used a rightward portrait nudge; editor ignored global side | Mirror the nudge and subscribe the editor to the same setting as Home/Folder. |
| Delayed route collapse could fire after returning and reopening | Cancellable timers plus route/generation checks. |
| Completed or interrupted caret animation recursively scheduled another | Bounded retries and cancellation on manual scrolling, with fresh edits allowed to re-centre. |
| Mouse interaction could unfocus the insertion field | FAB actions participate in `TextFieldTapRegion`; tests preserve focus and selection through insertion. |

The renderer retains the circle/pill radii, teal surface, active zones, icons,
menus, callbacks and established compact anchors. Submenu headers no longer add a
third translucent colour layer. Full behaviour and file boundaries are documented
in [fab.md](fab.md).

## Remaining work outside this consolidation

- Bring `ViewLayoutController` into a consistent startup/reset lifecycle. Its
  current load path silently updates listeners and concurrent persistence can
  conflict with a new user choice. The analogous FAB-side lifecycle is addressed
  here because it directly affects this component.
- Align product documentation: README still advertises swipe deletion and the old
  release badge; historical task notes refer to folder covers and Task watermarks.
  Decide which historical notes to archive instead of treating them as requirements.
- Decide whether tablet portrait should also use the condensed page header. Current
  code and some design wording differ; this is a product decision, not a FAB state
  bug.
- Continue the existing Project/Premium/collaboration roadmap separately. There is
  no new networking, central user-data storage or billing implementation here.
- Validate physical-device keyboard animation, rotation, text scaling and blur
  performance in both themes. Widget tests cannot establish platform rendering
  performance or native keyboard behaviour.

## Validation scope

Regression tests cover presentation rules, allowed modes, geometry, request races,
failed reads/retry, rapid mode changes, small landscape menus, retained scrolling,
mouse focus/caret, shared side, quick route returns and interrupted centring.
Existing Home/Folder/Editor and visual tests remain part of the full-suite check.
This is a source and regression review focused on the current architecture and FAB;
it is not a new penetration test or proof that every platform/device is validated.

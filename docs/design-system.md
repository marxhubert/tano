# Design system

The reference is the static [site](../site/index.html), audited in
[Site design audit](site-design-audit.md). The implementation sources are
`theme.dart`, `paper_surface.dart`, `card_typography.dart` and `entity_layout.dart`.

## Paper and ink

| Role | Light | Dark |
|---|---|---|
| Paper | #F2EBDC | #18140E |
| Secondary paper | #EAE0CB | #1F1A12 |
| Neutral card | #FFFDF6 | #221C14 |
| Ink | #241F18 | #EFE4D0 |
| Muted ink | #6F6553 | #B1A288 |
| Border | #D9CBB0 | #3A3122 |
| Ruled line | #E6DAC2 | #2B2417 |
| Accent | #0F766E | #5CC9BD |
| Amber | #B06A0C | #DFA14A |

`PaperSurface` paints the hero's horizontal ruling (34 logical pixels, scaled with
text size) and subtle deterministic grain. It is a decorative, noninteractive,
separate repaint boundary. All routes use this same background, including folders,
settings and editors. Editor paper adds a fine notebook margin. Category colors
only tint cards; category identifiers and stored data are unchanged. Native splash
backgrounds use the same paper colors.

The FAB keeps the site's primary `.btn` treatment, shared by “Read the
documentation” and “Repository”: accent fill, on-accent text and icons, fully
rounded resting/extended forms with the original menu corners, a 1px border mixing
78% accent with 22% black in sRGB, a 1px white highlight inside the top edge and
the compact black shadow. The fill is drawn at **86% over a 10px backdrop blur**,
so the page shows through the way it does behind the site's masthead, while the
content stays on-accent. Modes, icons and focus behavior are unchanged. Flutter
and browser rasterization can differ despite these shared source values.

FAB modes, icons, menu layout and focus behavior stay unchanged. Pointer hover
uses the site's 160ms ease, a 1px lift and 105% brightness. Action states,
search fields and menu text must remain legible on their actual backgrounds.
Menus remain bounded by the available space above the keyboard.

## Typography and cards

Noto Serif 2.015 is bundled under SIL OFL 1.1 (see `assets/fonts/README.md`). The
Flutter alias `TanoSerif` is used for page titles, Note prose and card titles. This
is a portable equivalent to the site's platform serif stack, not its exact font.
Task rows, controls and small metadata use the system sans serif. No runtime font
requests or external assets are needed.

Page titles 28, section titles 26, document filter 22, body 17, labels 15, metadata 12.
Cards use their own compact scale: title 14, body 12, date/count 10. Small card
metadata uses shared muted ink with tested contrast across all category surfaces.

Cards have 8px corners, a 1px warm border and a discreet shadow. Document covers,
locked templates and selection affordances stay intact. A folder has no cover any
more, its tile is a perfect square, and it keeps the only remaining corner
watermark. List
heights are 100/112px as appropriate, and grow with accessibility text sizing.
Task covers hide their checklist previews. Grid covers occupy the upper half;
list covers occupy the left third. Settings cards use the same paper surface and
fine border. Material Symbols identities and existing navigation are unchanged.

## Document filters

Home and a folder share one control: a segmented button reading **All (30) ·
23 Notes · 7 Tasks**. Every choice keeps its label and its own count — `All (n)`
for the whole list, `n Note` or `n Task` for one kind, singular for zero and one —
so the title line carries no separate counter; only a selection still needs a
sentence there. The number and its parentheses print light, so the word stays the
label. The selected segment takes
the accent fill with on-accent content, and the filter is remembered under the
`documentFilter` preference. The control scopes the document list only: folders are
structure, not documents, and the search scope and selection rules are unchanged.

## Responsive layout

Counts follow logical viewport dimensions, including split-screen resizing. A
shortest side of 600px identifies a tablet window; a width of 1440px takes precedence
as the large layout.

| Viewport | Grid columns | List columns |
|---|---:|---:|
| Phone portrait |2|1|
| Phone landscape |4|2|
| Tablet portrait |3|2|
| Tablet landscape |5|4|
| Width 1440px or more |5|5|

The folder group ignores that list/grid choice and stays a grid, on its own denser
scale: 3 columns on a phone portrait, 5 once the window is landscape or a tablet,
and 7 on a tablet held landscape and above. It is the same `EntitySliver` with an
overridden count.

Both modes share `EntitySliver`. List rows preserve card widths in an incomplete
last row. Swipe gestures perform no actions; selection and action menus remain
the way to move, delete and undo. Existing sort, folder/search scope and lock rules
are preserved.

Every route keeps one centred content column of `appContentMaxWidth` (1080), like
the site's wrap, and the FAB follows its right edge rather than the window's,
staying inside the safe area. The FAB's right edge stops 24 short of the column
while the cards stop 12 short, so the *visible* gap is 12; on a landscape phone
the bottom edge gets that same 12. An expanded bar keeps that right edge and grows
leftwards only, stopping 12 from the cards on that side too: the two gaps stay
symmetric. Grid
cards keep an almost square ratio (0.9) — a folder tile is a perfect square — so
they follow their width in every column count.

A **folder** on a landscape phone is too short for the big title line: it drops it
and the app bar carries the name from the first frame, centred while it fits and
left-aligned once it is too long, with the flags in front of it. Only the filter
control (or a rename field) stays above the list; Home keeps its own title line.
The document grid fits four tiles on a landscape phone, on Home and in a folder
alike; the folder cards keep their own denser scale.

On a landscape phone the page body is inset on both sides by the larger of the
two safe-area insets, so the writing clears the island, the punch-hole and the
rounded corners whichever side they sit on. The notebook margin line moves with
the content. The app bar keeps its own margins — the island sits at mid-height,
well below it — so no space is wasted around the back button and the actions. The
scrolled app bar draws its bottom hairline in the accent, since the warm rule
colour would read as one more paper rule.

Motion remains 150/250/450ms. Typography scales with the system and app preference.
Golden previews cover light/dark Home, Note, Task and menus in addition to card
states. Structural tests cover the column matrix, long titles and locked content;
widget tests cover keyboard/find behavior. Real-device keyboard, shadow rendering,
performance and native launch validation are still release checks.

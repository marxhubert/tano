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

The FAB uses the site's primary `.btn` treatment, shared by “Read the
documentation” and “Repository”: opaque accent fill, on-accent text and icons,
fully rounded resting/extended forms (with the original menu corner treatment),
and a 1px border mixing 78% accent with 22% black in sRGB. A 1px
white highlight at 25% opacity runs inside the top edge; the outer black shadow
uses 90% opacity, a 10px vertical offset, 18px blur and -14px spread. This replaces
the earlier translucent paper and backdrop blur. Light mode uses #0F766E with
#FDFAF2 content; dark mode uses #5CC9BD with #10241F content. Flutter and browser
rasterization can differ despite these shared source values.

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

Cards have 8px corners, a 1px warm border and a discreet shadow. Their existing
watermarks, covers, locked templates and selection affordances stay intact. List
heights are 100/112px as appropriate, and grow with accessibility text sizing.
Task covers hide their checklist previews. Grid covers occupy the upper half;
list covers occupy the left third. Settings cards use the same paper surface and
fine border. Material Symbols identities and existing navigation are unchanged.

## Responsive layout

Counts follow logical viewport dimensions, including split-screen resizing. A
shortest side of 600px identifies a tablet window; a width of 1440px takes precedence
as the large layout.

| Viewport | Grid columns | List columns |
|---|---:|---:|
| Phone portrait |2|1|
| Phone landscape |3|2|
| Tablet portrait |3|2|
| Tablet landscape |5|4|
| Width 1440px or more |5|5|

Both modes share `EntitySliver`. List rows preserve card widths in an incomplete
last row. Swipe gestures perform no actions; selection and action menus remain
the way to move, delete and undo. Existing sort, folder/search scope and lock rules
are preserved.

Motion remains 150/250/450ms. Typography scales with the system and app preference.
Golden previews cover light/dark Home, Note, Task and menus in addition to card
states. Structural tests cover the column matrix, long titles and locked content;
widget tests cover keyboard/find behavior. Real-device keyboard, shadow rendering,
performance and native launch validation are still release checks.

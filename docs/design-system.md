# Design system

`lib/shared/widgets/theme.dart`, `page_header.dart` and card typography are the
implementation sources. Do not duplicate palettes in screens.

## Surfaces and identity

Use the 60/30/10 balance: dominant background, teal identity and amber accent.
Light background #F8F9FA; dark #121212. Editor surfaces use white / #1E1E1E.
Teal #009688; amber #FF9800 light / #FFB74D dark.

| State | Light | Dark |
|---|---|---|
| Neutral | #90A4AE | #78909C |
| Action | #009688 | #4DB6AC |
| Success | #4CAF50 | #81C784 |
| Warning | #FF9800 | #FFB74D |
| Error | #E53935 | #E57373 |
| Purple | #9C27B0 | #BA68C8 |
| Yellow | #FBC02D | #FDD835 |
| Reference | #2196F3 | #64B5F6 |
| Subtle | #B0BEC5 | #90A4AE |
| Archive | #78909C | #546E7A |

Pastel names below are persisted category identifiers, not documentation language.

| Category | Light | Dark |
|---|---|---|
| menthe | #E0F2F1 | #004D40 |
| citron | #FFF9C4 | #827717 |
| peche | #FFE0B2 | #BF360C |
| lavande | #F3E5F5 | #4A148C |
| rose | #FFEBEE | #880E4F |
| azur | #E1F5FE | #01579B |
| sable | #F5F5DC | #3E2723 |
| sauge | #F1F8E9 | #1B5E20 |
| bonbon | #FCE4EC | #AD1457 |
| nuage (default) | #ECEFF1 | #263238 |

## Layout and type

| Token | Value |
|---|---|
| appPaddingLarge / Medium / Small | 18 / 12 / 6 |
| appBorderRadius | 12 |
| sectionBorderRadius | 18 |
| menuMinWidth | 160 |
| appBarOffset | 56 |
| sectionTitleSize | 24, w600 |
| appBarTextSize | 17; title w600, Cancel w400 |

Shared TanoText sizes: pageTitle 24, emptyState 20, wordmark 18, listTitle 17,
body 16, label 14, tiny 12, badge 10. Card typography has its own compact scale.
Primary/muted text colors adapt to brightness; colored surfaces use contrast-aware
text. Card borders use black alpha .16 in light mode, white alpha .22 in dark mode.
Page cover rules and app-bar borders remain 0.5 in both themes.

Material Symbols sizes: primary FAB 24, app bar 22, back/chevrons 20,
metadata 12, card markers 11. Bookmark is filled amber `label_important` when active.
Back uses `arrow_back_ios`. Use adaptive switches/dialogs and shared rounded sections.
Motion tokens: fast 150 ms, base 250 ms, slow 450 ms. Waiting for I/O is not motion.

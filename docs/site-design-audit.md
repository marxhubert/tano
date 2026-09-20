# Website design audit and app direction

Reviewed 21 September 2026. Scope: `site/index.html`, `site/privacy/index.html`,
`site/site.css`, `site/site.js`, the configuration template, local image assets,
`tool/site_config.sh` and the Pages workflow. This is a source audit, not a native
device or deployed-site audit. The website was not modified by this review.

## Design language

The site uses paper, ink and a warm reading-room palette. The defining combination
is a parchment background, horizontal notebook rules, serif editorial headings,
teal actions, amber details and lightly raised paper cards. Dark mode uses warm
brown-black surfaces, not neutral black or blue-grey. These characteristics should
carry into the app without changing navigation, editing, locks or document types.

The hero consists of two distinct layers:

- The page is paper with an SVG fractal-noise grain; the hero adds horizontal rules.
- Floating sheets use a separate card surface, a fine border and a warm shadow.
  Their slight rotations illustrate loose paper; functional editors and cards
  should remain upright to preserve text alignment and interaction geometry.

The site does not define the app's icons, watermarks, category taxonomy or gestures.
The existing Material Symbols and card watermarks remain the app's source for
those elements. The website's decorative SVG icons do not replace them.

## Exact source tokens

Defined in `site/site.css`, under `:root`, `[data-theme="dark"]` and the matching
system-dark media query:

| CSS token | Light | Dark | App role |
| --- | --- | --- | --- |
| `--paper` | `#f2ebdc` | `#18140e` | Shared page background |
| `--paper-2` | `#eae0cb` | `#1f1a12` | Secondary surfaces |
| `--card` | `#fffdf6` | `#221c14` | Document cards and editor paper |
| `--ink` | `#241f18` | `#efe4d0` | Primary text |
| `--ink-soft` | `#4c4437` | `#d9ccb5` | Body and secondary text |
| `--muted` | `#6f6553` | `#b1a288` | Dates, counters and metadata |
| `--rule` | `#d9cbb0` | `#3a3122` | Borders and dividers |
| `--line` | `#e6dac2` | `#2b2417` | Notebook ruling |
| `--accent` | `#0f766e` | `#5cc9bd` | Primary actions and links |
| `--accent-2` | `#009688` | `#4db6ac` | Secondary teal decoration |
| `--amber` | `#b06a0c` | `#dfa14a` | Important/bookmark details |
| `--on-accent` | `#fdfaf2` | `#10241f` | Text on filled actions |

The separate security section uses `--vault-bg` (`#211b13` / `#0f0c08`),
`--vault-fg` (`#f4ecdb` in both themes), `--vault-muted` (`#c5b7a0` / `#c0b299`)
and `--vault-rule` (`#4a3f2c` / `#3d3424`). These are marketing-section tokens;
they are not a reason to give app screens different full-page backgrounds.

| Source selector | Exact source treatment | Flutter translation |
| --- | --- | --- |
| `.hero` | Repeating gradient: transparent through 33px, line from 33 to 34px; vertical offset 22px | Shared non-interactive ruled-paper painter |
| `body` | 160px SVG noise tile; fractal noise frequency 0.9, two octaves, SVG rectangle opacity 0.42 | Subtle local grain; no network-loaded decoration |
| `.masthead` | Paper at 86% opacity, backdrop blur 10px | Clip the FAB to its shape before blurring; keep content opaque |
| `.sheet` | Radius 6px, 1px rule border, padding 1.25rem by 1.4rem | Notebook editor surface with restrained corners |
| `.sheet` shadow | `0 1px 0 rgba(0,0,0,.05)`, `0 26px 44px -28px rgba(38,26,6,.75)` | Soft warm depth, adapted to smaller native surfaces |
| `.card` | Radius 8px, 1px rule border, padding 1.5rem | Shared card shell; retain existing content and watermark |
| `.card` shadow | `0 1px 0 rgba(0,0,0,.04)`, `0 18px 32px -26px rgba(38,26,6,.7)` | Low elevation instead of heavy Material shadows |
| `.card::before` | 3px teal strip at 85% opacity, inset 1.4rem | Category/accent detail, without obscuring existing state indicators |
| `.btn` | Radius 10px, thin darkened-accent border | Compact controls using the same warm palette |
| `.icon` | 42px surface, radius 11px; accent fill 13%, border 22% | Surface styling only; keep existing symbol identities |

The SVG noise opacity is not a direct recommendation for a Flutter overlay alpha:
the browser filter supplies the underlying noise values. A replacement must remain
subtle and must not reduce legibility or repaint expensively on every keystroke.

## Typography and scale

The site intentionally mixes three roles, all using local/system font stacks:

- Serif: `"Iowan Old Style", "Palatino Linotype", Palatino, "Book Antiqua",
  "URW Palladio L", Georgia, "Times New Roman", serif`. Used for editorial
  prose, headings and sheet titles.
- Sans: `-apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial,
  sans-serif`. Used for buttons, navigation and checklist rows.
- Mono: `ui-monospace, "SFMono-Regular", "JetBrains Mono", Menlo, Consolas,
  monospace`. Used for dates, labels, counters and small annotations.

Body size is `clamp(17px, 0.35vw + 15.6px, 19px)` with line-height 1.7.
The hero title is 2.15–3.35rem, weight 600, line-height 1.06. Sheet titles are
1.22rem; card titles 1.18rem; checklist rows .93rem. Small labels are .64–.7rem,
often uppercase with increased letter spacing.

For the app, centralize the three text roles and keep text scaling. Do not copy
marketing-sized headings or tiny uppercase captions indiscriminately. Note prose
can use the editorial serif; task rows should retain the site's readable sans
treatment. A Flutter font-family name is not a guarantee that an OS ships that
font: use explicit fallbacks or licensed bundled fonts where consistency requires
them. Icon-font styling must remain confined to icons, particularly inside rich
text, so linked-note labels keep their ordinary font and case.

The app implementation selects bundled **Noto Serif 2.015**, exposed as
`TanoSerif`, with its OFL license. This provides a predictable local serif across
platforms and requires no runtime font download. It is an equivalent editorial
type choice, not the exact Iowan/Palatino font that a particular browser may use
for the site. Controls and task rows use system sans.

## Layout and interactions

The site has a 1080px maximum content width, normally 2.5rem total horizontal
gutters. It collapses paired feature sections at 920px, reduces ordinary card
grids from three columns to two, then to one at 620px. The navigation disappears
below 620px, gutters shrink to 1.8rem and the hero becomes one sheet. Download
badges stack at 760px. These are website breakpoints, not the requested app grid.

The app's requested layout policy supersedes those website column counts:

| Available device/layout class | Grid cards per row | List cards per row |
| --- | ---: | ---: |
| Phone portrait | 2 | 1 |
| Phone landscape | 3 | 2 |
| Tablet portrait | 3 | 2 |
| Tablet landscape | 5 | 4 |
| Larger available width | 5 | 5 |

Use a single shared policy based on available logical width and orientation.
Large-width classification must take precedence over tablet classification.
The implementation uses a shortest side of at least 600 logical pixels for
tablet layouts and an available width of at least 1440 for the larger-width
layout. These are app layout decisions, not breakpoints copied from the website.
Retain item ordering, filters, selection and explicit action menus. List cards no
longer expose horizontal swipe actions; this does not remove task reordering or
ordinary scrolling. Keep category and lock semantics distinct from decoration.

The website's 160–250ms hover transitions and 600ms reveal animation convey gentle
motion. A typing surface should not replay entrance animations while rebuilding.
Existing native interaction timing can remain where it already serves the UX.

## Accessibility and rendering considerations

The website provides a skip link, semantic section navigation, focus outlines,
decorative-image exclusions and a reduced-motion path. Content is visible with
JavaScript disabled. Preserve these principles in native semantic labels, focus
order and reduced-animation behavior. The 36px website theme toggle should not
be copied as a native touch-target size.

Calculated from the solid CSS tokens using relative luminance, before grain,
transparency or actual glyph rendering:

| Foreground / background | Light contrast | Dark contrast |
| --- | ---: | ---: |
| Ink / paper | 13.78:1 | 14.56:1 |
| Muted / paper | 4.83:1 | 7.33:1 |
| Muted / card | 5.63:1 | 6.75:1 |
| Accent / paper | 4.61:1 | 9.21:1 |
| Amber / paper | 3.60:1 | 8.15:1 |
| On-accent / accent | 5.25:1 | 8.15:1 |

Light amber is unsuitable as the default small-text color at normal contrast
targets; keep it for icons or use a darker variant for small text. Translucent FAB
content must be checked over images and colored cards, not only plain paper.
Notebook rules should stay behind text and controls, without intercepting taps.
Text scale, long translations, landscape and keyboard insets remain layout inputs.

## Runtime, assets and privacy

The site has no package manager or build step. It uses local CSS/JS, local raster
assets and inline SVG, with no external font request or analytics script. The
JavaScript stores only the theme preference in `localStorage`, fetches local
`config.json`, swaps theme-specific screenshots, adds decorative lines, updates
the footer year and reveals cards with `IntersectionObserver`.

Configuration text uses `textContent`, avoiding HTML insertion. Configured links
are assigned to `href` without protocol validation, so deployment configuration
must be trusted and should reject unsupported schemes before publication.
`site/config.json` is ignored by Git but is published as a public asset: the
`SITE_CONFIG_JSON` workflow secret must contain public publisher values, never
credentials. The template contains placeholder store/support URLs. Its fallback
does not establish a production-ready deployment.

`tool/site_config.sh` obtains the version from `pubspec.yaml`. The Pages workflow
currently triggers on `site/**` and the workflow itself, not on `pubspec.yaml` or
the generator; a version-only commit does not automatically republish the site.
The “Read the documentation” hero CTA uses `repoUrl` rather than `docsUrl`.

The six PNG/JPEG assets total about 1.6MB on disk. Each theme displays two
screenshots and two bezels; the images use lazy loading and asynchronous decoding.
Switching themes loads the alternate screenshots. Those screenshots depict the
app and should be replaced after the redesign has been validated, rather than
used as the new design specification.

The website privacy text accurately distinguishes optional diagnostic data and
network metadata from stored document content. Hosting request logs and deployed
HTTP headers were not inspected; absence of tracking code does not establish
anything about host-side log retention. Do not import website fetching or theme
storage code into the native app merely to match its appearance.

## Content inconsistencies to resolve before publication

1. The status block says the app is available on both stores and its projects are
   stable. `docs/product-rules.md` and `docs/roadmap.md` say the app has never
   shipped, while `Project` is only a model foundation. Store URLs include a
   placeholder App Store ID. Keep unreleased status explicit until publication.
2. The support introduction says projects are free, but the project and Premium
   sections say they are paid. Current `PremiumAccess` reserves projects, sharing
   and collaboration for Premium; notes, standalone tasks and folders are free.
3. Several feature paragraphs call folders “projects”. The app treats folders
   and future project boards as different entities; marketing should do the same.
4. The seal says nothing leaves the phone except exports, while the same page and
   privacy policy describe optional crash reports and store update checks. The
   stronger claim needs qualification.
5. The privacy policy's “Last updated: September” year is changed by the same
   `data-year` script as the copyright. A legal revision date should reflect an
   actual policy edit rather than automatically change each January.
6. `docs/privacy.md` still groups task persistence with planned projects, although
   tasks are now persisted. This is a documentation alignment issue, not a reason
   to disable implemented tasks.

These are separate from the visual implementation. Do not add boards, billing,
sharing or network behavior during the redesign to make marketing claims true.

## Implementation and validation boundaries

Keep palette, typography, paper painting and responsive column selection shared.
Reuse the existing card and editor components instead of duplicating Note/Task
screens or creating tiny wrappers for every individual control. Consolidate
background ownership so settings, folders, trash and editors do not accidentally
retain old grey surfaces behind the new palette. Preserve lock, watermark,
category, link, selection and attachment behavior.

Editors use the shared ruled paper as their notebook surface. A notebook
margin line is an app adaptation to the paper motif, not a feature of the site's
hero CSS. Native launch/splash surfaces should use the same light and dark paper
colors so the design does not flash between unrelated palettes during startup.

Validation must cover both themes; the requested grid/list column matrix; long
titles, text scaling and translations; lock-hidden content; cover/no-cover cards;
and editor caret/search scrolling with the keyboard and expanded FAB. The site
reference does not justify changing data models, migrations or security rules.

For this audit, `node --check site/site.js` passed and all relative HTML asset
references resolved locally. The contrast figures above were calculated from
source tokens. No browser visual, screen-reader, native-device, store-availability
or production-hosting verification is claimed here.

## Implemented branch verification

On `feature/site-inspired-design`, the redesign passes all 366 Flutter tests and
static analysis without issues. The 28 reference images include card states and
Home, Note, Task and expanded menus in both themes; the new page renderings were
visually inspected. Column geometry is tested at phone, tablet and large-window
sizes; widget tests retain keyboard, search, locking and selection coverage.
Native splash background assets were regenerated and their exact colors checked.
No simulator or physical device was launched. Font rendering, backdrop blur cost,
native keyboard behavior and launch transitions still need real-device review.

# History

This file replaces the separate audit and consolidation journals that used to
live next to the reference documents. Each section keeps the durable decisions
those documents established; their full text stays available in git history
(see the commit that removed the individual files). They are historical
records, not current contracts: where a rule still applies it is now stated in
the corresponding reference document.

## UI polish (superseded operational conclusions)

The polish cycle consolidated the palettes into `TanoPastels`/`TanoStates`,
replaced accidental blue accents with teal, centralised spacing and eight text
sizes, and standardised empty states and feedback. `body` (16) and
`listTitle` (17) stay intentionally distinct; the small/caption aliases were
removed in favour of label/tiny. Settings use shared rounded cards, destructive
colours do not depend on the language, and move/link menus disable actions
without a valid target. Current rules live in [design system](design-system.md).

## Project review and FAB consolidation

The FAB instability was caused by presentation state being rebuilt during
layout. The fix moved every mutation into lifecycle methods or explicit
actions, kept one field identity across rebuilds, and split the FAB into
lifecycle, bars and menus. Current rules live in [fab](fab.md).

## Website design audit and app direction

The site defines the paper identity: parchment background, horizontal notebook
rules, serif editorial headings, teal actions, amber details and lightly raised
paper cards, with warm brown-black dark surfaces. That language was carried
into the app. Current rules live in [design system](design-system.md).

## Security and consolidation audit (18 September 2026)

A source review and local validation report — not a certification or native
penetration test. It confirmed working local persistence and shared UI, called
out Task/Project as prototypes rather than complete workflows, and identified
native lock/privacy validation, recovery UX, transactional commands and orphan
handling as the most important remaining work. The follow-up items were tracked
in step 2 and in the roadmap; residual risks live in [security](security.md).

## Consolidation step 2

Background privacy and reauthentication: `PrivacyGuard` sits above
navigation, hides every inactive frame, invalidates a protected session on a
real background transition, keeps draft widgets mounted but offstage, and
requires a fresh credential on return. Storage failures surface a
non-destructive retry instead of resetting data, editor write failures are
recoverable, and orphan attachments are collected at startup from the complete
reference set (shared, trash and corrupt references included). Current rules
live in [security](security.md) and [tests](tests.md).

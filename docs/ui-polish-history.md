# UI polish history

Historical summary, not a current security audit. Superseded operational conclusions
are replaced by [audit](audit-2026-09-18.md) and [roadmap](roadmap.md).

The prior polish cycle consolidated palettes into `TanoPastels`/`TanoStates`,
replaced accidental blue accents with teal, centralized spacing and eight text sizes,
and standardized empty states and feedback. `body` 16 and `listTitle` 17 remain
intentionally distinct; small/caption aliases were removed in favor of label/tiny.

Settings use shared rounded cards; reset covers notes, folders and attachments,
although exhaustive crash recovery and orphan handling still need validation.
Destructive action colors do not depend on language. Move/link menus disable actions
without valid targets, and the current folder is not a move destination. The wordmark
adapts to dark mode; publisher identity is provided by build configuration.

Animation tokens: fast 150 ms, base 250 ms, slow 450 ms. Operational waiting periods
are not animation tokens. A possible Hero transition remains a future design choice.
Cards remain flat, use a stronger dark-mode border and retain their locked template.
Detailed implementation chronology remains in git rather than duplicated here.

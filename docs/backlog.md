# Backlog

Unscheduled proposals. Accepted work moves to [roadmap](roadmap.md).

## Product and UX

Custom tags, note duplication/templates, date picker, richer editor toolbar,
configurable trash retention, scheduled local exports, tablet layouts, guided first
note creation, transition polish and improved failure/empty states. Cloud backup
is not selected and must not contradict the no-central-content-storage objective.

## Technical

Large-volume search/FTS and pagination, typed menu models, stricter lints, explicit
load failures and accessibility checks. Recheck Kotlin/Gradle and Swift Package
Manager/CocoaPods compatibility when upgrading Flutter or native plugins; previous
warnings are not evidence about future package versions. Desktop/web are separate
porting projects, not proof that native encryption works on those targets.

## Decisions already made

Keep `develop`; protect `master` with PR, CI and independent approval. Premium covers
projects/sharing/collaboration, billing later. Existing test data is disposable.

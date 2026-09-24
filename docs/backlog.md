# Backlog

Unscheduled proposals. Accepted work moves to [roadmap](roadmap.md).

## Product and UX

Custom tags, note duplication/templates, date picker, richer editor toolbar,
configurable trash retention, scheduled local exports, tablet layouts, guided first
note creation, transition polish and improved failure/empty states. Cloud backup
is not selected and must not contradict the no-central-content-storage objective.

## Technical

Typed menu models, stricter lints, explicit load failures and accessibility checks.
Migrate the app and `sentry_flutter` off the Kotlin Gradle Plugin to Flutter's
Built-in Kotlin before a future Flutter upgrade starts failing the release build
(Flutter 3.47 warns about it). Recheck Kotlin/Gradle and Swift Package
Manager/CocoaPods compatibility when upgrading Flutter or native plugins; previous
warnings are not evidence about future package versions. Desktop/web are separate
porting projects, not proof that native encryption works on those targets.

## Decisions already made

Keep `develop`; protect `master` with PR, CI and independent approval. Premium covers
projects/sharing/collaboration, billing later. Existing test data is disposable.

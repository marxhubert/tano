# Backlog

Unscheduled proposals. Accepted work moves to [roadmap](roadmap.md).

## Product and UX

Custom tags, note duplication/templates, date picker, richer editor toolbar,
configurable trash retention, scheduled local exports, tablet layouts, guided first
note creation, transition polish and improved failure/empty states. Cloud backup
is not selected and must not contradict the no-central-content-storage objective.

## Technical

Typed menu models, stricter lints, explicit load failures and accessibility checks.
Built-in Kotlin: the app runs AGP 9.1.0 / Kotlin 2.3.20 with
`android.builtInKotlin=false` and `android.newDsl=false` in
`android/gradle.properties`, and both `android/app/build.gradle.kts` and
`sentry_flutter` apply the Kotlin Gradle Plugin. Flutter 3.47 warns that a future
version will fail on plugin-supplied KGP. Removing the app's own `kotlin-android`
line alone would not silence it and turning the flags on would touch every other
plugin, so the migration waits for a `sentry_flutter` release that supports
Built-in Kotlin. Recheck Kotlin/Gradle and Swift Package Manager/CocoaPods
compatibility when upgrading Flutter or native plugins; previous warnings are not
evidence about future package versions. Desktop/web are separate
porting projects, not proof that native encryption works on those targets.

## Decisions already made

Keep `develop`; protect `master` with PR, CI and independent approval. Premium covers
projects/sharing/collaboration, billing later. Existing test data is disposable.

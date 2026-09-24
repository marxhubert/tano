# Diagnostics and external connections

Crash reports require consent, default off. Builds without `SENTRY_DSN` do not
initialize Sentry. A DSN is a write-only ingestion address, not an administration
secret, but it is kept out of the public repository: put it in the ignored
`identity.json` and build with `--dart-define-from-file=identity.json`.
Symbol-upload tokens and project configuration stay outside git.

## Allowed diagnostic payload

`CrashReports.scrub` reconstructs an event with release/build, timestamp, severity,
filtered exception type and stack symbols/line numbers. It may keep device model,
manufacturer, architecture, simulator flag, OS name and version. Device region comes
from the OS locale country code; it is not physical location or IP geolocation.
These coarse fields help reproduce a bug but should still be minimized to avoid
unnecessary combinations that distinguish people.

No note content, arbitrary exception values, free-form messages, paths, variables,
device hostname, serial/unique identifier, user identity, request data, custom context
or breadcrumbs. Event IDs identify individual reports, not a persistent person.
No analytics, traces, replay, screenshots or session tracking. Native crash handling
is disabled until its payload can be filtered as strictly as Dart events.

## Operational requirements

A remote endpoint necessarily sees network metadata including IP. Configure Sentry
not to retain IPs or derive user profiles, restrict project access and set an explicit
retention period. The client cannot certify service-side behavior by itself.
Inspect actual envelopes after native enrichment on Android/iOS before enabling a
release DSN. Verify offline queues, consent withdrawal and restart without consent.
`Sentry.close()` may flush existing queues: stopping new capture does not recall
already transmitted reports or prove queued reports were purged.
`CrashReports.sendTestError`, reached from the debug-only Labs section, sends one
event typed `TanoLabsTestException` so the pipeline can be checked on a device.

Store update checks are user-triggered and contact Apple/Google without note content.
Those providers process connection metadata. Core notes/folders work offline, but
the application is not devoid of network calls.

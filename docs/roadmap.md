# Consolidation roadmap

Updated 19 September 2026. The app has never shipped; old test data is disposable.

## Completed in this consolidation

- Archive bounds/path validation, import collision handling and SQLite batch rollback.
- Search/navigation/export parent-folder access policy and explicit lock rules.
- Removal of fixed fallback keys; single-flight key/database initialization.
- Plaintext temporary-cache cleanup and memory-only cover decoding.
- Removal of legacy plaintext data recovery and known test backups.
- Common entity/sorting/category/copy semantics.
- Consent-gated diagnostic allowlist, including coarse device/OS/locale-region data.
- Premium policy foundation for projects, sharing and collaboration; no billing yet.
- English documentation and filenames, updated current/future distinction.
- Lifecycle privacy guard and native snapshot covers; draft-preserving reauthentication.
- Non-destructive startup retry and editor write-failure recovery.
- Startup orphan collection using complete references, including trash and covers.

## Before first public release

1. Validate native encryption, backup/restore, key loss, app-switcher protection and
   authentication-session invalidation.
2. Extend transaction-aware recovery to remaining commands and validate exhaustive reset.
3. Inspect Sentry envelopes, queues and service-side non-retention settings before
   configuring a production DSN.
4. Establish a non-destructive migration policy for all data created after release.
5. Test native builds, distribution signing and store declarations.

## Domain and backup work

Task lists now share note editing and storage; see [task lists](tasks.md).
Manifest v2 preserves task types. A future format must carry folders and relations.
Extract transaction-aware commands, measure large-data search/pagination and move
expensive work off the UI. Project persistence remains separate future work.

## Premium and collaboration

Choose billing later and implement verified entitlements/restoration. Follow
[collaboration](collaboration.md) for peer authentication, remote transport, permissions,
replication and conflict testing. No central content storage. Premium is independent
from a collaborator's permission to a shared resource.

Use `develop` for integration and PRs into protected `master` for release promotion.

Implementation details and limits: [consolidation step 2](consolidation-step-2.md).

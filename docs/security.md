# Security

This is an implementation reference, not a security certification.
See [audit](audit-2026-09-18.md) for evidence and residual risks.

## Current protections

Production SQLite uses SQLCipher and an installation key stored by the OS.
Attachments and sensitive preferences are encrypted. Concurrent first key/database
access is serialized. There is no fixed fallback key when secure storage fails.

UI locks use the OS credential, not per-note passwords. Lock actions are disabled
when the device cannot authenticate. Access rules and search exclusions are defined
in [product rules](product-rules.md). UI authentication is not remote authorization.

Attachment names cannot be paths. Import validates archive version, names, entry
types, duplicates, references and CRC; limits are 64 MiB input, 128 MiB expanded,
32 MiB per entry, 4 MiB manifest and 2,000 entries. Inflation is bounded even when
metadata understates size. Add fuzzing and memory profiling before release.

Clear exports contain readable data and remove object lock flags. Encrypted exports
use Argon2id and AES-GCM. Authentication precedes exporting protected content.
Imported locks survive when OS authentication is available; otherwise they are
removed for the imported objects. V1 exports notes/files, not a full app backup.

## Pre-release cleanup

The app has never shipped. Old plaintext test databases, JSON and their known
backups are discarded; there is no recovery requirement. This deliberately removes
the former plaintext migration/backup risk. Released user databases must never be
subjected to this policy: define forward migrations before the first public release.

## Remaining release work

- Validate the implemented reauthentication guard and native app-switcher covers on devices.
- Verify the retry screen with native keystore/database failures and key-loss scenarios.
- Expire temporary external-viewer files safely; copies made by other apps are
  outside TanoNote's control. Startup/reset already clear local materialized files.
- Verify startup orphan collection on devices; full reset is still not one atomic operation.
- Verify SQLCipher, backup/restore policies, key loss and native logs on real devices.
- Inspect complete Sentry envelopes and consent withdrawal; native crashes remain
  disabled until equivalent filtering is validated.

FFI tests do not validate native SQLCipher. A Pub advisory scan does not cover all
native SDKs. Reference: [OWASP MASVS Storage](https://mas.owasp.org/MASVS/05-MASVS-STORAGE/).

See [step 2](consolidation-step-2.md) for the implemented protections and their limits.

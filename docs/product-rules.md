# Product rules

Confirmed on 19 September 2026. These rules take precedence over older plans.

## Storage, locks and export

Encryption at rest and an object's UI lock are different protections. All local
production storage uses installation keys. A lock requires the OS credential.
The lock action is disabled when no device credential is available, and the
mutation checks capability again before applying a lock.

Opening a locked folder authenticates the user. Its objects do not prompt again
within that folder, even if their own lock flag is set. The flag is preserved:
moving a locked object to an unlocked folder does not unlock it. An unlocked source
note linking to locked note A must authenticate before opening A. An authenticated
folder grants inherited access only inside that same folder, not to arbitrary links.

Export offers encrypted and cleartext files. Both require legitimate access to
protected source objects. In a cleartext export, encrypted local content is decoded
and object lock flags are cleared. In a password-encrypted export, lock flags remain.
The current manifests support notes (v1) and task lists (v2), with attachments.
Neither carries folders or projects. Task lists are free and follow note access rules.
These rules apply to those future objects when their format and persistence ship.

Import preserves locks on a device with a credential. On a device without one, it
unlocks imported objects and reports the number affected. Existing local objects
are never overwritten. Device capability is not a password belonging to the export.

## Search

Locked objects are never search results, even after authentication. Home searches
across notes, including notes in folders, but excludes notes protected by their own
lock or a locked parent, and notes in deleted/missing folders. Folder search is
limited to that folder and excludes each object's own lock. An already-open locked
folder can search its unlocked children. Find-in-note is separate and operates
only on the note already opened by its user.

## Product scope

Notes, folders, standalone tasks and import/export belong to the free tier.
Projects, sharing and collaboration require Premium. Additional paid features and
the payment model are undecided. No purchase, price or subscription is offered yet.

Collaboration must work remotely without centrally stored content. Optional crash
diagnostics may retain technical app/device/OS data and configured device region,
but never user identity, note content, device names, stable identifiers or precise
location. Consent is required. See the operational limits in [observability](observability.md).

## Development and release

The app has never been published and existing test data need not be preserved.
Legacy plaintext databases/JSON and their known backup files are discarded instead
of migrated. Do not extend this destructive policy to released user data.
Use feature branches and PRs to `develop`; promote releases through a PR to `master`.
Master requires successful CI and an independent approval.

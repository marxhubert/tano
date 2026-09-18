# Remote collaboration without central content storage

Product decision: remote collaboration, not LAN-only sharing. **Target, not implemented.**
Projects, sharing and collaboration belong to Premium; permissions remain independent.

## Connectivity

Content resides on participant devices. Use end-to-end encrypted peer connections.
Remote NAT/firewall combinations can require signaling and a TURN relay. Relays
forward encrypted packets transiently, not store inboxes or backups. Without an
available peer or intermediate storage, changes wait locally until peers reconnect.
Rendezvous metadata and logs need explicit minimization and expiry. IP addresses are
necessarily visible to network intermediaries; do not promise otherwise. Out-of-band
invitations can reduce centralized discovery but cannot guarantee NAT reachability.

## Identity and access

Use local cryptographic identity without mandatory email/account. Authenticate an
invitation through a QR/fingerprint or trusted channel; bound lifetime and reuse.
Adopt a reviewed protocol, distinguishing signatures (e.g. Ed25519) from key agreement
(e.g. X25519). Do not invent a cryptographic composition. Keep per-space keys and epochs
separate from installation storage keys. Validate read/write/admin permissions on every
received operation. Revocation and rotation block future participation, not copies
already received by an authorized participant.

## Replication

Define shared-space ID, entity ID, operation ID, signing author, per-author counter,
causal dependencies, schema version and key epoch. Validate signature, authorization,
size and replay before applying. Persist each mutation with its outbound operation
in one local transaction. Wall-clock timestamps do not solve ordering or replay.

Test rich-text edits, task status, card order, move/rename and delete-vs-edit conflicts.
Compare a Dart-compatible CRDT and an operation log with explicit conflicts before
choosing a dependency. No Yjs/Yrs implementation is assumed. Replicated deletions need
tombstones, retention and snapshot resynchronization for stale peers; today's local
trash is not a sync protocol. Otherwise an old peer can resurrect deleted objects.

Files need identities independent of display names, integrity checks, per-space keys,
quotas and path rejection. Distinguish internal content hashes from publicly exposed
identifiers to limit correlation.

## Prototype acceptance

Two devices on distinct networks, with/without relay; disconnection, duplicate and
reordered delivery, long-offline peers, forged invitations, revocation and quotas.
Measure memory, battery and bandwidth before shipping collaborative screens.
References: [WebRTC peer connections](https://webrtc.org/getting-started/peer-connections)
and [TURN](https://webrtc.org/getting-started/turn-server).

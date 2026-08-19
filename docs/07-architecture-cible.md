# 07 — Architecture cible : stockage, synchronisation et chiffrement

> **Document de référence** pour l'évolution majeure de TanoNote : passage du
> JSON monofichier à une base **SQLite (Drift)**, ajout des entités (dossiers,
> tâches/checklist, projets/tickets, pièces jointes) et de la **collaboration
> temps réel pair-à-pair via internet** (expérience type Trello, sans serveur
> central de données).

## 1. Décisions structurantes (validées)

| Décision | Choix retenu |
|---|---|
| Stockage | **SQLite via Drift** (ORM réactif) — remplace le JSON monofichier |
| Synchronisation | **Maillage WebRTC** (data channels), temps réel, **internet uniquement** |
| Signalisation | Serveurs **publics** + mot de passe de salon (prototype), puis serveur **auto-hébergé** en premier endpoint (publics en secours) |
| Serveur de données | **Aucun** : le serveur de signalisation est aveugle et ne stocke rien |
| Chiffrement | **E2E** (AES-GCM) + identités **Ed25519** |
| Texte collaboratif | **CRDT Yjs** (`y_crdt`) |

**Principe fondamental** : le serveur de signalisation n'intervient que quelques
millisecondes pour la « poignée de main » (échange SDP/ICE), puis s'efface. La
connexion devient **directe** entre les pairs ; si un NAT l'empêche, un relais
TURN transporte uniquement du trafic déjà chiffré E2E.

## 2. Choix technologiques

| Besoin | Choix | Justification |
|---|---|---|
| Base de données | `drift` | ORM SQLite réactif, mature (1,12 M dl), type-safe, transactions, migrations, streams |
| CRDT texte | `y_crdt` | Port Dart de Yjs (via WASM), référence pour la co-édition sans conflit |
| Transport temps réel | `flutter_webrtc` | Data Channels sur Android/iOS/desktop/web (290 k dl), mature |
| Crypto | `cryptography` / `pointycastle` | AES-GCM, Ed25519, PBKDF2 — pur Dart |
| Hors-ligne optionnel | `nearby_connections` (Android) + `flutter_blue_plus` | Mode de proximité secondaire (non prioritaire) |

## 3. Schéma de données (v1)

Toutes les entités portent des **UUID globaux** (`id TEXT PRIMARY KEY`), un
`created_at`, un `updated_at` et un `deleted_at` (suppression logique).

### Entités principales

```text
folders          (id, parent_id, name, color, is_shared, created_at, updated_at, deleted_at)
notes            (id, folder_id, title, content, important, category, created_at, updated_at, deleted_at)
projects         (id, folder_id, name, description, is_shared, created_at, updated_at, deleted_at)
tickets          (id, project_id, title, description, status, lane_order, created_at, updated_at, deleted_at)
```

- `notes.content` : contenu texte (markdown léger + checklist), indexé en FTS5
  pour la recherche multi-entités.
- `tickets.status` : état Kanban (ex. `backlog`, `todo`, `doing`, `done`) ;
  `lane_order` : position au sein d'une colonne.

### Liens, tâches et pièces jointes

```text
checklist_items  (id, owner_id, owner_type, text, checked, position, created_at, updated_at, deleted_at)
attachments      (id, owner_id, owner_type, path, mime, size_bytes, sha256, created_at, updated_at, deleted_at)
memberships      (id, scope_id, scope_type, peer_id, role, key_wrap, created_at, updated_at)
```

- `owner_type` ∈ {`note`, `ticket`, `project`} : une note et un ticket peuvent
  contenir des cases à cocher et des pièces jointes.
- `attachments.path` : fichier binaire stocké **hors SQLite** (répertoire
  `attachments/`), dédupliqué par `sha256`.
- `memberships` : permissions et enveloppes de clés par projet/dossier partagé.

### Journal de synchronisation

```text
sync_log         (id, entity, entity_id, op_type, payload, peer_id, vector_clock, created_at)
```

- `op_type` ∈ {`create`, `update`, `delete`} ; `payload` : le delta chiffré ;
  `vector_clock` : horloge vectorielle pour l'ordre causal et l'anti-rejeu.

## 4. Règles de données (non négociables)

1. **UUID globaux** partout : jamais d'auto-incrément ni de `Random().nextInt`
   (ce qui permet de merger des copies indépendantes entre pairs).
2. **Suppression logique** (`deleted_at`) : un *tombstone* doit se propager ;
   on ne supprime physiquement qu'après une purge planifiée.
3. **Conflits** : *last-write-wins* par champ avec horloge vectorielle pour la
   structure ; CRDT pour les champs texte.
4. **Clés étrangères + cascade** : la suppression d'un dossier entraîne la
   suppression logique de son contenu (arbre cohérent).
5. **Anti-rejeu** : chaque opération est signée et horodatée par son auteur ;
   les opérations déjà appliquées sont ignorées.

## 5. Synchronisation P2P Internet (le cœur)

### 5.1 Topologie : maillage WebRTC

Chaque collaborateur maintient une connexion **directe** vers chacun des autres
(maillage). Les opérations sont propagées de proche en proche, quasi
instantanément — c'est l'expérience Trello.

- **Limite assumée** : ~20-35 pairs par document (borne de y-webrtc). Pour des
  projets de 2 à 10 collaborateurs, c'est confortable.
- **Présence** (*awareness*) : qui est en ligne, qui tape où — propagé via le
  même canal.

### 5.2 Signalisation (rendez-vous)

1. Le pair publie son **offre SDP + ICE candidates** sur le serveur de
   signalisation (WebSocket), dans un *salon* identifié par l'id du projet.
2. Les pairs présents répondent ; la connexion WebRTC s'établit **directement**.
3. Le serveur s'efface : il ne voit que des informations d'établissement,
   chiffrées par le **mot de passe de salon** (le serveur est donc aveugle).

**Endpoints** : serveurs publics en secours (`wss://signaling.yjs.dev`, etc.)
au démarrage, puis serveur auto-hébergé (`tools/signaling-server/`) comme
premier endpoint. Le client se connecte à **plusieurs signalings en parallèle**.

### 5.3 Modèle de synchronisation : oplog + CRDT

- **Structure** (création, déplacement de ticket, statut, dossiers, suppression) :
  journal d'opérations (`sync_log`) + *last-write-wins* par champ.
- **Texte collaboratif** (contenu d'une note ou d'un ticket) : **CRDT Yjs** —
  chaque frappe est une *update* fusionnable sans conflit, même hors-ligne puis
  re-synchronisé.
- **Cycle de sync** : pull (demander les opérations manquantes) → résolution de
  conflits → push des opérations locales → transfert des binaires manquants
  (par `sha256`).

## 6. Abstraction `SyncTransport`

Le transport est découplé du protocole de sync pour rester remplaçable :

```dart
abstract class SyncTransport {
  Future<void> start(String roomId);          // rejoindre un salon (projet/dossier)
  Stream<EncryptedEnvelope> get incoming;     // opérations reçues
  Future<void> send(EncryptedEnvelope env);   // envoyer une opération
  Stream<PeerInfo> get peers;                 // présence des pairs
  Future<void> close();
}
```

### Implémentations

| Transport | Rôle | Statut |
|---|---|---|
| `WebRtcTransport` | **Principal** : temps réel internet (data channels) | Cible prioritaire |
| `FileEnvelopeTransport` | **Filet de sécurité** : export/import de fichiers chiffrés (sauvegarde, sync manuelle) | Dès la P1 |
| `NearbyTransport` | Hors-ligne de proximité (BLE/Wi-Fi Direct), optionnel | Secondaire |

Un **routeur** choisit le transport selon la disponibilité des pairs et la
nature du payload (métadonnées vs binaire volumineux).

## 7. Chiffrement de bout en bout

### 7.1 Identités

- Chaque appareil génère localement une **paire de clés Ed25519** ; le `peer_id`
  est l'empreinte (hash) de la clé publique.
- Chaque opération est **signée** : un pair ne peut pas usurper un autre.

### 7.2 Clés de salon

- Chaque **projet** ou **dossier partagé** possède une clé de chiffrement
  symétrique (AES-256-GCM) générée à sa création.
- Cette clé est distribuée aux membres via des **enveloppes de clés**
  (`memberships.key_wrap`) : la clé de salon est chiffrée avec la clé publique
  de chaque membre.
- Le serveur de signalisation ne connaît **jamais** ces clés.

### 7.3 Export / import chiffré (réutilise ce socle)

- **Sauvegarde** : mot de passe → **PBKDF2/Argon2** → clé AES-GCM → fichier
  d'échange JSON versionné (`schemaVersion`, `exportedAt`, `appVersion`).
- **Partage** : clé aléatoire à transmettre hors bande (QR / message).
- Ce format d'échange est **indépendant du stockage** (SQLite) et reste le
  contrat de compatibilité et de sauvegarde.

## 8. Pièces jointes

- Binaires **hors SQLite** : répertoire `attachments/`, indexés par `sha256`
  (déduplication), référencés par `attachments.path`.
- **Synchronisation découplée** de celle des métadonnées : transfert différé,
  reprise sur interruption, vérification du hash à l'arrivée.
- Transfert P2P direct quand les pairs sont connectés (efficace en WebRTC) ;
  sinon via le fichier chiffré.
- Limites de taille et stratégie (miniature → version intégrale) à définir.

## 9. Dossiers

- Arbre hiérarchique (`folders.parent_id`), cycle interdit par contrainte.
- Chaque dossier a une couleur ; un dossier peut être **partagé** (comme un
  projet) via `memberships`.
- Règles de permission : `read` / `write` / `admin`, héritées de l'arbre.
- Organisation type **Notes d'Apple** : notes, tâches et projets vivent dans
  les dossiers.

## 10. Migration depuis le JSON actuel

- À la première ouverture post-migration : lire `local_persistence.json`,
  créer la base Drift, insérer chaque note (`important`, `category` conservés),
  générer les UUID manquants, puis **sauvegarder l'ancien fichier** (renommage
  `.bak`) sans le supprimer.
- Le format d'export chiffré JSON reste **importable** (compatibilité ascendante).
- `FileNotesRepository` est remplacé par `DatabaseRepository` + des repositories
  par entité ; **les ViewModels purs Dart restent inchangés dans leur principe**.

## 11. Phasage de mise en œuvre

| Phase | Contenu | Livrable |
|---|---|---|
| P0 | Drift + schéma v1 + migration JSON→SQLite | App fonctionne comme avant, en SQLite |
| P1 | Dossiers + checklist + export/import chiffré | Organisation + sauvegarde |
| P2 | **Prototype sync** : identités, chiffrement E2E, `WebRtcTransport` + signalisation publique | Une note partagée temps réel entre 2 appareils (France–Japon) |
| P3 | Projets / tickets Kanban (colonnes, drag & drop) | Écran projet collaboratif |
| P4 | Pièces jointes | Images/PDF/docx attachés + sync |
| P5 | Serveur de signalisation auto-hébergé + TURN | Disponibilité maîtrisée |
| P6 | Industrialisation : tests, CI, golden, purge des tombstones | Qualité et exploitation |

> Le **prototype sync (P2)** est critique et doit être validé **avant** de
> construire toute l'UI Kanban (P3), pour éviter une refonte coûteuse.
>
> Ce phasage est la **vue macro** de l'architecture ; la numérotation détaillée
> et priorisée (incluant les fondations code et les quick wins UI/UX) se trouve
> dans la feuille de route [`06-roadmap.md`](./06-roadmap.md).



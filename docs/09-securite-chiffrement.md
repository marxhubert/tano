# 09 — Sécurité : chiffrement du stockage et export

> Statut : **validé**, implémentation en cours (branche `feature/encrypted-storage`).

Ce document décrit la politique de protection des données de TanoNote **au repos**
et le format de partage/transfert. Il fait autorité : toute implémentation doit
s'y conformer.

## 1. Objectif

Protéger les données de l'utilisateur contre **le monde extérieur à l'application** :
une personne qui obtient une copie des fichiers de A ne doit rien pouvoir en lire,
**même si elle installe TanoNote sur son propre téléphone**.

À l'intérieur de l'application, A utilise tout normalement. Toute personne qui a le
téléphone de A peut voir ses notes non verrouillées : c'est accepté.

## 2. Modèle de menaces

| Menace | Exemple | Protection |
|---|---|---|
| Quelqu'un a **le téléphone de A** | B tient l'iPhone de A | Il voit les notes non verrouillées. Les notes verrouillées exigent le verrou de A. |
| Quelqu'un **copie les fichiers de A** | extraction de la base / de la sandbox | **Rien n'est lisible**, même avec l'app installée sur un autre téléphone. |
| Téléphone **piraté / rooté** | extraction de la clé | **Hors périmètre actuel** (décision explicite). |

## 3. Clé de chiffrement

- Clé **propre à l'installation**, générée aléatoirement (32 octets) au premier lancement.
- Stockée dans le coffre sécurisé de l'OS :
  - **iOS** : Keychain, accessible `...ThisDeviceOnly` → pas de synchro iCloud, pas de restauration sur un autre appareil.
  - **Android** : Keystore (AES-GCM + enveloppe RSA/OAEP).
- **Jamais demandée à l'utilisateur**, aucune friction à l'ouverture.
- **Aucun mot de passe supplémentaire à mémoriser** : le verrou système suffit pour la fonctionnalité *lock*. Si l'appareil n'a pas de verrou, c'est un choix de l'utilisateur.

Conséquence : la base de A copiée sur l'appareil de B est illisible, car B a une
clé différente. La portabilité des données passe donc **uniquement par l'export/import**.

## 4. Périmètre du chiffrement

| Donnée | Emplacement | Chiffrement |
|---|---|---|
| Notes | base SQLite `tano_notes.db` | SQLCipher (AES-256), clé d'installation |
| Pièces jointes | fichiers `<documents>/attachments/` | AES-GCM par fichier (clé d'installation + nonce aléatoire) |
| Images de couverture | mêmes fichiers `attachments/` | idem pièces jointes |
| Préférences | `shared_preferences` | valeurs chiffrées par un wrapper (les noms de clés restent lisibles, non sensibles) |

## 5. Export / import

**L'export contient uniquement les notes et leurs attaches** (pièces jointes +
couvertures). Il **n'inclut pas** les préférences.

### Export
1. L'utilisateur déclenche l'export : l'app lui **laisse toujours le choix** de chiffrer ou non.
2. **Export chiffré** : un mot de passe est demandé. La dérivation utilise une KDF forte
   (Argon2id, à défaut PBKDF2-HMAC-SHA256 ≥ 600 000 itérations) et le contenu est
   chiffré en AES-GCM.
3. **Export en clair** : aucune protection ; c'est un partage volontaire.
   - Si au moins une note est verrouillée, l'app **alerte** que l'export doit être chiffré.
   - Si l'utilisateur insiste pour le clair, les notes verrouillées sont **déverrouillées
     dans l'export** (`isLocked = false`).
4. **Export chiffré et notes verrouillées** : le flag `isLocked` est conservé.

Le mot de passe d'export ne sert **qu'à ouvrir le fichier** : il ne devient jamais
un mot de passe de note.

### Import
1. Fichier **en clair** → import direct.
2. Fichier **chiffré** → le mot de passe est **obligatoire** ; un mauvais mot de passe
   échoue proprement (aucune donnée modifiée).
3. **Fusion, jamais de suppression** : les données importées s'ajoutent aux existantes.
   - Collision d'id : **l'existante est conservée, l'importée est ignorée**.
4. **Règle de déverrouillage après import réussi** :
   - Si l'appareil d'import **a** un verrou système : les notes importées qui étaient
     verrouillées **restent verrouillées** (le déverrouillage se fera avec le verrou local).
   - Si l'appareil d'import **n'a pas** de verrou système : ces notes sont
     **déverrouillées** (sinon elles seraient inutilisables).

### Format
- Extension unique **`.tano`**, avec un en-tête versionné indiquant notamment si le
  contenu est clair ou chiffré (et les paramètres KDF le cas échéant).
- Charge utile : `manifest.json` (notes) + `attachments/` (fichiers), empaquetés en ZIP.

## 6. Sauvegardes du système d'exploitation

Les sauvegardes OS (auto-backup Android, sauvegarde iCloud) **excluent** la base et
les fichiers chiffrés : la clé n'y étant pas, une restauration sur un autre appareil
produirait une base indéchiffrable. La sauvegarde « officielle » est **l'export**.

## 7. Migration

Au premier lancement de la version chiffrée, une base existante en clair est convertie
vers le format chiffré, **sans perte** (lecture des lignes, écriture dans la base
chiffrée, conservation de l'ancienne base en `.bak`).

## 8. Décisions validées

- Collision d'id à l'import : conserver l'existante, ignorer l'importée.
- Mot de passe d'export : longueur minimale requise, aucune récupération possible.
- Extension d'export : `.tano` unique.
- Sauvegardes OS : exclues.
- Appareil piraté/rooté : hors périmètre.

## 9. Hors périmètre (pour l'instant)

- Protection contre un appareil rooté/jailbreaké ou un dump mémoire.
- Chiffrement de bout en bout de la future collaboration : une clé de base liée à
  l'installation ne permet pas à B de lire une note partagée ; il faudra une clé
  par note/par partage.

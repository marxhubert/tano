# 10 — Dossiers et organisation

> Statut : **validé**, implémentation en cours (branche `feature/folders`).

Ce document fait autorité sur l'organisation des notes en dossiers.

## 1. Modèle

Un **dossier** (`Folder`) regroupe des notes. Il est traité **comme une note**
pour la plupart des points (thème/couleur, épingle, favori, verrou, couverture,
corbeille, sélection), **sauf** ce qui est spécifique au contenu d'une note
(`content`, `attachments`, checklists, liens, recherche plein texte).

| Champ | Rôle |
|---|---|
| `id` | identifiant UUID |
| `name` | nom du dossier |
| `date` | date de création |
| `important` | favori (bookmark), comme les notes |
| `category` | thème de couleur, comme les notes |
| `isPinned` | épinglé, remonte en tête de son groupe |
| `isLocked` | dossier verrouillé (voir §7) |
| `coverImage` | image de couverture, comme les notes |
| `isDeleted` / `deletedAt` | corbeille |

Une note reçoit un champ `folderId` (nullable) : `null` = note **non rangée**.
Une note rangée dans un dossier disparaît du groupe « My notes » de l'accueil.

**Pas de dossiers imbriqués** : un dossier ne peut pas contenir un dossier.

## 2. Création via le FAB

- Taper le bouton **add** du FAB l'élargit **vers le haut** et **double sa hauteur**
  pour afficher deux actions, **le dossier AU-DESSUS de la note** (comme à l'écran) :
  1. **Add folder** — `create_new_folder`
  2. **Add note** — `note_add` (fonction existante)
- Une **ligne de séparation** sépare les deux actions.
- **Add folder** ouvre un prompt de saisie du nom. Si l'utilisateur valide sans
  rien saisir, le nom par défaut est **`Folder X`**, où X est le plus petit entier
  tel que le nom n'existe pas déjà (ex. « Folder 2 » s'il existe déjà « Folder 1 »).

## 3. Affichage des cartes

Un dossier est une **carte** comme une note, dans les deux vues (grid et list) :

| | Grid | List |
|---|---|---|
| Icône | `folder_open` dans le **coin haut/gauche** | `folder_open` **à gauche**, centrée verticalement |
| Nom | **en bas**, aligné à gauche | **à droite** de l'icône |
| Titre | max **3 lignes** | max **2 lignes** |
| Métadonnées | **sous le titre**, en gris | idem |

- Les métadonnées sont composées d'**icônes + compteur** (ex. nombre de notes).
  Elles **ne sont pas affichées** s'il n'y a rien à afficher.
- Le nom du dossier ne dépasse pas la limite de lignes (ellipsis).

## 4. Accueil (vue principale)

- La vue est subdivisée en **deux groupes** : **dossiers en haut**, **notes non
  rangées en bas**. Un **gap** sépare les deux groupes.
- Le groupe notes garde le titre actuel **« My notes »**. Ce titre reste le titre
  de la page tant qu'il n'y a **aucun dossier**.
- Dès qu'au moins un dossier existe, le titre de la page devient **« My folders »**.
- Les dossiers sont **toujours avant** les notes.

### Tri, épinglage, favoris
- Le **système de tri actuel** s'applique aussi aux dossiers (alpha, date, thème…),
  mais chaque groupe reste à sa place.
- **Épingler** un dossier se comporte exactement comme pour une note (il remonte en
  tête **de son groupe**). **Bookmark** (important) : idem.

### Sélection multiple
La barre de sélection passe de **3 à 4 actions**, dans cet ordre :

| Position | Action | Icône |
|---|---|---|
| 1 | **Move** | `drive_file_move_outline` |
| 2 | Delete | (existant) |
| 3 | Select all | (existant) |
| 4 | Select none | (existant) |

- Les **dossiers** sont concernés par la sélection multiple pour la **suppression**.
- Ils sont **exclus du déplacement** (pas de dossiers imbriqués). Si la sélection
  contient un dossier, l'action **Move** est désactivée/refusée.

## 5. Ouvrir un dossier

- Le **nom du dossier devient le titre de la page**.
- Ses notes s'affichent **exactement comme dans l'accueil** (mêmes cartes, mêmes
  vues grid/list, mêmes actions).
- Le **tri** s'applique à l'intérieur du dossier.
- La **recherche** et la **sélection multiple** ne concernent que le contenu du
  dossier.
- Le **FAB** se comporte comme dans une note, avec les 4 actions habituelles :
  - **Add** : deux options — **Choose image** (couverture du dossier) et **Add note**
    (créer une nouvelle note dans le dossier).
  - **Color** : change le thème du dossier (inchangé).
  - **More_vert** : **Pin**, **Bookmark**, **Lock**, **Delete**.
  - **Chevron** : ferme/replie.
- **App bar** : l'action **more_vert disparaît** au profit d'une action **Add**
  (icône `add`) qui crée une nouvelle note dans le dossier.
- **Dossier vide** : un message est affiché **au centre** pour l'indiquer.

## 6. Recherche globale (accueil)

- Les dossiers **n'apparaissent pas** dans les résultats.
- Les notes **rangées dans un dossier** sont visibles comme si les dossiers
  n'existaient pas.
- La présentation des résultats ne change pas, mais le **titre devient « Results »**
  (à traduire) au lieu de « My notes » / « My folders ».
- **Les notes verrouillées sont exclues de la recherche.** Pour chercher dans une
  note verrouillée, il faut l'ouvrir puis utiliser « find in note ».

## 7. Verrouillage

- Ouvrir un **dossier verrouillé** demande l'authentification système, comme une note.
- **À l'intérieur d'un dossier verrouillé, les notes ne redemandent pas le code** :
  on est déjà autorisé. Leur flag `isLocked` est **conservé**.
- Si une note verrouillée est **sortie** du dossier verrouillé, elle est
  **immédiatement verrouillée** de nouveau.
- Une note verrouillée dans un dossier **non** verrouillé reste verrouillée.
- Une note **non** verrouillée reste non verrouillée, dans ou hors du dossier.

## 8. Suppression d'un dossier

- Supprimer un dossier **supprime aussi tout son contenu**.
- Le prompt de confirmation **indique le nombre de notes** contenues
  (ex. « Ce dossier contient 5 notes. Les supprimer avec le dossier ? »).

## 9. Menus : retrait de Share et Collaborators

Les options **Share** et **Collaborators** du menu `more_vert` (éditeur de note
**et** menu de dossier) sont **retirées** : elles ne sont pas implémentées et le
chantier est hors de portée pour l'instant.

## 10. Hors périmètre (pour l'instant)

- Imbrication de dossiers (sous-dossiers).
- Implémentation réelle de **Move to** (l'action est ajoutée mais le déplacement
  effectif reste à faire).
- Synchronisation des dossiers.
- Share / Collaborators.

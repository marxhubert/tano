# 11 — État du projet et reste à faire

> Document de travail : inventaire de ce qui reste pour qu'une version soit
> proposable au **grand public**, **hors checklist avancée et projets/Kanban**.
> Il sert de base au chantier de stabilisation ([12 — Plan de refactoring](./12-plan-refactoring.md)).

## 1. Périmètre

Fonctionnalités cœur visées : **note**, **checklist** (avancée) et **projets**
(Kanban type Trello). Checklist et projets sont **volontairement exclus** de ce
document : on stabilise d'abord la note et toute la structure qui les recevra.

Le présent document recense donc :

1. les **bloquants de distribution** (conformité, accessibilité, release) ;
2. les **dettes structurelles** (doublons, modèle, schéma) ;
3. les **manques UX** pour un public non technique ;
4. les **manques de fiabilité** (tests, erreurs, nettoyage) ;
5. les **TODO** laissés dans le code.

## 2. Bloquants distribution & conformité

| # | Point | Constat | Action |
|---|---|---|---|
| 2.1 | **Accessibilité** | Aucun `Semantics`, aucun `tooltip:` : les boutons-icônes n'ont pas de libellé vocal ; pas d'audit contraste ni de respect de la taille de texte système. | Poser des `Semantics` sur toutes les actions, vérifier contrastes et tailles. Bloquant pour un public large et pour les revues stores. |
| 2.2 | **Permissions iOS** | `Info.plist` ne déclare que `NSFaceIDUsageDescription`. Le sélecteur `FileType.image` peut exiger `NSPhotoLibraryUsageDescription` (voire `NSCameraUsageDescription` selon la version de `file_picker`). | Vérifier le comportement réel et compléter `Info.plist`. |
| 2.3 | **Confidentialité** | Pas de politique de confidentialité, pas de `PrivacyInfo.xcprivacy` (iOS 17+), pas de « Data safety » (Play). | Rédiger et déclarer (l'app est 100 % hors-ligne : contenu simple mais **obligatoire**). |
| 2.4 | **Release** | Version `0.8.4-beta`, dernier tag `v0.8.3-beta`. Pas de CHANGELOG. | Bump, notes de version, tag, build signé Play/App Store. |
| 2.5 | **CI** | `.github/workflows/ci.yml` ne fait que `analyze` + `test`. | Ajouter un job de **build** et, à terme, les tests d'intégration. |
| 2.6 | **README** | Décrit un stockage JSON, une arbo `models/pages/services` et « 7 catégories » : ne reflète plus le code (SQLite chiffré, `core/features/shared`, dossiers, verrou, export, couvertures). | Réécrire entièrement. |
| 2.7 | **Branche `develop`** | `origin/master` est 107 commits devant `origin/develop` (0 devant). Le README dit de viser `develop`. | Trancher : supprimer `develop` ou le re-synchroniser. |

## 3. Dettes structurelles

### 3.1 Doublons constatés

| Zone | Doublons | Fichiers |
|---|---|---|
| **Cartes** | Deux cartes quasi identiques, plus des reconstructions locales. | `note_card.dart`, `folder_card.dart`, `note_card_content.dart`, `trash_page.dart`, `folder_page.dart` |
| **Sélection** | `_selected`, `_isInSelectionMode`, entrer/toggle/select-all/exit/delete/move réimplémentés. | `home_view_model.dart`, `folder_page.dart` |
| **Dialogues** | Helper adaptatif central + dialogues Material/Cupertino à la main. | `confirm.dart`, `home_page.dart` (`_promptAndCreateFolder`), `data_transfer.dart` |
| **Couvertures** | Widget `CoverImage` partagé d'un côté, couverture inline (placeholder, bouton supprimer, cache du futur) de l'autre. | `cover_image.dart`, `folder_page.dart` |
| **Grilles/listes** | Quatre widgets + une reconstruction locale dans la page dossier. | `note_grid_view.dart`, `note_list_view.dart`, `folder_grid_view.dart`, `folder_list_view.dart`, `folder_page.dart` |
| **FAB** | Fichier unique de ~1300 lignes mélangeant menus, barres et états. | `app_fab.dart` |

### 3.2 Modèle et schéma

- Pas de `createdAt` / `updatedAt` : impossible de trier « récemment modifié »,
  et la future synchronisation aura besoin de ces champs. **À ajouter avant
  checklist/project** (impact schéma).
- Schéma SQLite en v6 avec `_upgradeSchema`, mais **aucun test de migration**.
- `sqflite` (non chiffré) encore présent à côté de `sqflite_sqlcipher` : à nettoyer.
- Le repository `SqliteNotesRepository` implémente à la fois `NotesRepository` et
  `FoldersRepository` : acceptable, mais la logique de comptage/cascade mériterait
  d'être isolée.

## 4. Manques UX (public non technique)

| # | Point | Constat | Action |
|---|---|---|---|
| 4.1 | **Onboarding** | Splash uniquement, aucun premier pas guidé. | 2-3 écrans (ou un état vide pédagogique). |
| 4.2 | **Undo incohérent** | Home propose « Annuler » après suppression ; le dossier non. | Uniformiser. |
| 4.3 | **Feedback d'action** | Save silencieux (voulu), mais aucun retour sur déplacement/verrouillage. | Confirmations discrètes. |
| 4.4 | **États vides** | Existent (home, dossier, recherche, corbeille) mais non audités systématiquement. | Relecture écran par écran. |
| 4.5 | **Réglages** | Base solide (thème clair/sombre/auto, langue, tri, transfert de données, corbeille, reset, à propos). | Ajouter : taille de texte, retour haptique/son, emplacement de sauvegarde. |
| 4.6 | **Recherche** | Pas d'historique ni de filtres. | Historique + filtres catégorie/favori/dates. |

## 5. Fiabilité & qualité

| # | Point | Constat | Action |
|---|---|---|---|
| 5.1 | **Golden tests** | Absents. | En poser avant tout refactor UI. |
| 5.2 | **Tests d'intégration** | 2 fichiers (`analytics_flow`, `folders_flow`). | Étendre (dossier, export/import, verrou). |
| 5.3 | **DI** | `AttachmentsStore` est un top-level dans `cover_image.dart` ; `AuthService.instance` est un setter mutable. | Tout passer par `getIt` pour des tests isolés. |
| 5.4 | **Logs** | `debugPrint` en production. | Logger silencieux en release. |
| 5.5 | **Erreurs** | Mélange de notices utilisateur et de `debugPrint`. | Uniformiser. |
| 5.6 | **Fixtures** | Génération lourde (~110 notes de ~540 mots). | Ne jamais l'exposer hors chemin de démo. |

## 6. TODO laissés dans le code

| Fichier | TODO | Décision à prendre |
|---|---|---|
| `edit_note_page.dart` | `onShareSelected` / `onCollaboratorsSelected` = no-op (entrées retirées du menu) | Implémenter via la sync **ou** supprimer callbacks + clés l10n `option_share`/`option_collaborators` |
| `analytics_service.dart` | Envoi vers un backend (Sentry/Firebase) | Décider, sinon retirer |
| `about_page.dart` | Vraie vérification de mise à jour ; Premium | Implémenter ou masquer |
| `home_page.dart` | Cas « aucune sélection » | Trancher le comportement |

## 7. Priorisation recommandée

1. **Accessibilité + permissions/privacy + release** — bloquants store.
2. **Refactoring des cartes/sélection/dialogues + `updatedAt`** — voir [12](./12-plan-refactoring.md).
3. **Onboarding + uniformisation undo/feedback**.
4. **Golden tests + CI build**.
5. **README / CHANGELOG / nettoyage TODO**.

> Le refactoring (étape 2) doit précéder l'arrivée de checklist et projets :
> chaque nouvelle entité s'appuiera sur les briques unifiées (carte, sélection,
> liste, dialogues).

# 01 — Analyse de l'état actuel

Analyse complète du projet **TanoNote** (v0.8.4-beta), réalisée le 19/08/2026.

## 1. Vue d'ensemble

| Élément | Valeur |
|---|---|
| Technologie | Flutter 3.32.4 / Dart 3.8.1 |
| Cibles | Android + iOS |
| Stockage | Fichier JSON local (`local_persistence.json`) |
| Préférences | `shared_preferences` (thème, langue, affichage, tri) |
| Localisation | FR / EN, implémentation maison (`lib/shared/config/l10n.dart`) |
| Dépendances | `path_provider`, `shared_preferences`, `package_info_plus`, `material_symbols_icons` |
| Taille du code | ~3 100 lignes Dart (lib) + ~1 000 lignes de tests |

## 2. Architecture

Le projet suit une organisation en **vertical slices** (dossiers par fonctionnalité) :

```
lib/
├── main.dart                     # Point d'entrée, composition root
├── core/
│   ├── models/                   # Note, Database, NoteAction
│   └── repositories/             # NotesRepository (abstrait), FileNotesRepository, fixtures
├── features/
│   ├── notes/                    # home_page.dart (979 lignes) + home_view_model.dart
│   ├── editor/                   # edit_note_page.dart + edit_note_view_model.dart
│   ├── search/                   # search_page.dart + search_view_model.dart
│   └── splash/                   # splash_page.dart
└── shared/
    ├── config/                   # app_config, l10n, theme_controller
    └── widgets/                  # menu, confirm, info, no_record, theme
```

### Pattern utilisé : MVVM "léger"

- Les **ViewModels** (`HomeViewModel`, `EditNoteViewModel`, `SearchViewModel`)
  étendent `ChangeNotifier` et sont **purs Dart** (aucun `BuildContext`, aucun
  widget). C'est un vrai point fort : logique testable, séparée de l'UI.
- Les **pages** écoutent le ViewModel (`AnimatedBuilder` / `ListenableBuilder`)
  et ne contiennent que le rendu + la navigation.
- Le **repository** (`NotesRepository`) est une abstraction injectée dans les
  ViewModels : la couche métier ne dépend pas du stockage concret.

## 3. Fonctionnalités actuelles

- CRUD des notes (titre, contenu, date).
- 7 **catégories fixes** colorées : note, work, personal, travel, life, project, none.
- Marqueur **important** (favori) via une étoile.
- **Recherche** insensible à la casse (titre + contenu) sur une page dédiée.
- 3 **modes d'affichage** : liste, compact, grille.
- 4 **tris** : date, titre, favoris, catégorie.
- **Sélection multiple** (appui long) : suppression groupée, tout sélectionner/désélectionner.
- **Swipe to delete** avec confirmation.
- Thème **clair / sombre / système**.
- Langue **anglais / français**.
- Splash screen natif (Android + iOS) et loader in-app.
- 24 **notes de démonstration** semées au premier lancement.

## 4. Ce qui fonctionne bien ✅

1. **Séparation claire** des responsabilités (models / repositories / viewmodels / widgets).
2. **ViewModels purs Dart**, unit-testables sans framework UI.
3. **Repository abstrait** permettant l'injection d'une implémentation en mémoire
   dans les tests.
4. **Tests existants** couvrant les ViewModels, les modèles, les fixtures et des
   scénarios de non-régression (crash de la page d'édition, smoke tests visuels).
5. **Localisation** et **thème** persistés correctement.
6. Gestion du **mode sombre** cohérente (couleurs `blueGrey` dédiées).

## 5. Problèmes et limites constatés 🔴

### 5.1 Modèle de données

- `Note` (`lib/core/models/note.dart`) utilise des champs **nullables partout**
  (`String?`, `bool?`). Cela oblige à des `?? false`, `?? ''` et des `note.date!`
  partout dans le code, et crée un risque réel de `Null check operator` (ex. :
  `_sortNotes` dans `home_view_model.dart` fait `note2.date!.compareTo(note1.date!)`).
- `NoteAction` (`lib/core/models/action.dart`) repose sur des **chaînes magiques**
  (`'Save'`, `'Delete'`, `'Cancel'`), source d'erreurs silencieuses.
- La classe `Database` n'apporte pas de valeur : elle enveloppe simplement une
  liste de notes.

### 5.2 Code monolithique et duplication

- `lib/features/notes/home_page.dart` fait **979 lignes** : le rendu des 3 layouts,
  le header, la sélection, les menus et les actions sont dans un seul fichier.
- La barre d'actions (`_showActionButtons`) est **dupliquée** entre
  `home_page.dart` et `edit_note_page.dart`.
- `menu.dart` expose des getters qui **reconstruisent les maps à chaque accès**
  (`menuItems`, `categoryElements`) ; `home_page.dart` les recopie ensuite dans
  une liste via `forEach`.

### 5.3 Réactivité / état

- `LocaleController` n'étend pas `ChangeNotifier` : changer la langue dans le menu
  ne **rebuild pas l'interface** de manière fiable et immédiate.
- `ThemeController` et `LocaleController` sont des **singletons** (`instance`) non
  injectables, ce qui couple les tests entre eux et complique l'isolation.
- Le thème clair est déclaré avec `primaryColor`/`canvasColor` seulement, sans
  `ColorScheme` complet ni `useMaterial3`.

### 5.4 Persistance

- `FileNotesRepository` réécrit **tout le fichier** à chaque sauvegarde, sans
  **écriture atomique** (risque de corruption si l'app s'arrête pendant l'écriture).
- Aucune **version de schéma** : pas de migration possible si le format JSON évolue.
- Les erreurs de lecture sont **avalées** (`catch` → liste vide) : un fichier
  corrompu ferait croire à l'utilisateur que ses notes ont disparu.

### 5.5 Détails UI/UX

- Police **`Calibri` codée en dur** (`home_page.dart`) : indisponible sur Android/iOS,
  ce qui donne un rendu incohérent (retour à la police système).
- Les cartes ont un **rayon de 0** (coins carrés) : rendu daté.
- La "recherche" de la page d'accueil est un simple `GestureDetector` statique,
  pas un vrai champ de saisie.
- Les dates sont affichées par `substring(0, 10)` : dépendance fragile au format
  interne, aucune localisation de la date.
- Le mode grille est **fixé à 3 colonnes**, non responsive sur tablette.

### 5.6 Fonctionnalités manquantes

- Pas d'**annulation** (undo) après une suppression (swipe ou groupée).
- Pas de **corbeille** ni d'**archive**.
- Catégories **non personnalisables** (pas de tags utilisateur).
- Pas d'**export / import / sauvegarde** des données.
- Pas de **duplication** de note, ni de partage.
- Pas de **checklist** ni de tâches à cocher (alors que le README parle de
  *"tasks and projects manager"*).
- Pas de **cryptage** des données locales.
- Pas de tri **croissant/décroissant** ni de tri "récemment modifié".
- `debugPrint` encore présent dans le code de production (`file_notes_repository.dart`).

## 6. Couverture de tests

Excellente base de tests unitaires (`home_view_model_test`, `edit_note_view_model_test`,
`search_view_model_test`, `note_model_test`, `fixtures_test`) et quelques tests de
widgets (navigation, menu, crash de la page d'édition, smoke tests visuels).

Manques constatés : pas de test du repository **fichier** (intégration réelle),
pas de **golden tests**, et des singletons qui rendent l'état partagé entre tests.

## 7. Évolution prévue (décisions validées)

L'analyse ci-dessus décrit l'état actuel (JSON monofichier). Les décisions
suivantes ont été actées pour la suite — voir
[`07-architecture-cible.md`](./07-architecture-cible.md) :

- **Stockage** : remplacement du JSON par **SQLite (Drift)**.
- **Entités** : ajout de dossiers, tâches/checklist, projets/tickets Kanban,
  pièces jointes.
- **Collaboration** : synchronisation **temps réel pair-à-pair via internet**
  (maillage WebRTC), **sans serveur central de données** (signalisation aveugle
  + chiffrement de bout en bout).
- **Sauvegarde/partage** : export/import de données **chiffrées** (AES-GCM).

Ces évolutions rendent caduques certaines limites listées en §5 (notamment la
persistance monofichier) ; le reste (nullabilité, chaînes magiques, monolithisme,
réactivité de la langue) reste pleinement d'actualité.


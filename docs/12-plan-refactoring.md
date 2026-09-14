# 12 — Plan de refactoring (stabilisation du cœur)

> Objectif : supprimer les doublons, poser des briques uniques et saines, **sans
> changer le comportement**, avant d'ajouter checklist et projets.
> Complément : [11 — État du projet](./11-etat-et-reste-a-faire.md).
> Branche : `refactor/core-stabilisation`.

## 1. Objectifs

1. **Zéro doublon** sur les briques transverses : carte, liste/grille, sélection,
   dialogues, couverture.
2. **Une base extensible** : ajouter demain un « ticket » ou une « checklist »
   doit réutiliser les mêmes briques, pas les recopier.
3. **Aucune régression** : les 200+ tests restent verts après **chaque** lot.

## 2. Principes

- **Petits lots indépendants**, un par PR, chacun livrable seul.
- **Refactor pur** (lots 2-4 et 6-7) : aucun changement visible, uniquement du
  déplacement de code et des API.
- **Filet de sécurité d'abord** (lot 0) : on ne touche pas à l'UI sans tests.
- **Une brique, un fichier** : pas de widget de plus de ~250 lignes.

## 3. Architecture cible

| Brique actuelle | Brique cible | Rôle |
|---|---|---|
| `NoteCard` + `FolderCard` | `EntityCard` | Conteneur unique (fond, couverture, bookmark, verrou, sélection). Le contenu vient d'un builder. |
| 4 widgets de liste + `_buildNotes` | `EntitySliver<T>` | Grille/liste générique d'`EntityCard`. |
| `_selected` dans 2 classes | `SelectionController` | Sélection partagée (entrer, toggle, tout, quitter, règle de sélectabilité). |
| Dialogues épars | `showAdaptivePrompt` (dans `confirm.dart`) | Saisie texte adaptative iOS/Material. |
| Couverture dossier inline | `ManageableCover` | Couverture + placeholder + bouton supprimer + état « corrompue ». |
| `app_fab.dart` monolithique | `fab/` (3-4 fichiers) | Menus, barres, items séparés. |

## 4. Lot 0 — Filet de sécurité

**But** : figer le rendu actuel avant de le déplacer.

- **Créer** `test/golden/entity_cards_test.dart` : rendu d'une `NoteCard` et d'une
  `FolderCard` en grille **et** liste, dans les variantes : avec/sans couverture,
  épinglé, favori, verrouillé, sélectionné.
- **Compléter** par des **tests de structure** (positions relatives : metadata en
  bas, bookmark après la couverture) plus robustes que des pixels.
- **Note CI** : les golden tests sont sensibles à la plateforme ; les exécuter sur
  l'image Linux de la CI avec une police figée, ou se limiter aux tests de
  structure si le bruit est trop grand.

**Fait quand** : les références sont générées et la CI les vérifie.

## 5. Lot 1 — Modèle : `updatedAt`

**But** : préparer tri « récemment modifié » et future synchronisation.

- **`Note` / `Folder`** : ajouter `createdAt` (défaut : `date`) et `updatedAt`
  (défaut : `date`), dans le modèle, `fromJson`/`toJson` et `copyWith`.
- **Schéma SQLite v7** : `ALTER TABLE notes ADD COLUMN createdAt/updatedAt`,
  idem `folders`, dans `_createSchema` et `_upgradeSchema`.
- **Écriture** : `EditNoteViewModel.persistSavedNote`, `upsertFolder`,
  `toggleLock`, `toggleFavorite` mettent à jour `updatedAt = now`.
- **Tri** : ajouter l'option « récemment modifié » dans `sorting_section.dart` et
  `HomeViewModel`.
- **Tests** : modèle (aller-retour JSON), **test de migration v6 → v7** avec une base
  temporaire.

**Fait quand** : une note modifiée remonte en tête du tri « récemment modifié ».

## 6. Lot 2 — Carte unifiée `EntityCard`

**But** : une seule carte pour note et dossier.

**API cible**

```dart
typedef EntityCardContentBuilder = Widget Function(
  BuildContext context,
  Color textColor,
  bool hasCover,
);

class EntityCard extends StatelessWidget {
  const EntityCard({
    required this.category,
    required this.builder,
    this.coverImage,
    this.isImportant = false,
    this.isLocked = false,
    this.isListLayout = false,
    this.isSelected = false,
    this.isInSelectionMode = false,
    this.onTap,
    this.onLongPress,
    this.onSelectionToggle,
  });
}
```

- `EntityCard` possède : fond/bordure/ombre, couche couverture, bookmark
  (positions « après la couverture »), overlay verrou (variante note/dossier via un
  `lockedBuilder` optionnel), overlay sélection, et empile le builder.
- **Migrer** `note_grid_view`, `note_list_view`, `folder_grid_view`,
  `folder_list_view`, `trash_page`, `folder_page`.
- **Supprimer** `note_card.dart` et `folder_card.dart` (garder `NoteCounts` et le
  contenu dans `note_card_content.dart`, renommé `note_card_bodies.dart`).

**Fait quand** : plus aucune référence à `NoteCard`/`FolderCard` ; goldens verts.

> **Fait** sur `refactor/core-stabilisation` : `EntityCard` est la carte unique,
> les 6 écrans sont migrés, `NoteCard` / `FolderCard` / `note_card_content.dart`
> sont supprimés. Les corps sont dans `note_card_bodies.dart` et
> `folder_card_bodies.dart`, la typographie dans `card_typography.dart`. Le labo
> (`features/lab/card_lab_page.dart`) est **conservé** comme banc d'essai.

## 7. Lot 3 — Slivers unifiés `EntitySliver<T>`

**API cible**

```dart
class EntitySliver<T> extends StatelessWidget {
  const EntitySliver({
    required this.items,
    required this.isList,
    required this.cardBuilder,
    this.padding = const EdgeInsets.all(12.0),
  });

  final List<T> items;
  final bool isList;
  final Widget Function(BuildContext context, T item, bool isList) cardBuilder;
}
```

- Remplace les 4 widgets de vue et le `_buildNotes` de `folder_page.dart`.
- Le builder de carte est fourni par chaque écran (note : `note_grid/ list content` ;
  dossier : icône + nom + compteur).

**Fait quand** : `SliverGrid`/`SliverList` n'apparaissent plus que dans
`entity_sliver.dart`.

> **Fait** sur `refactor/core-stabilisation` : `EntitySliver<T>` créé et utilisé
> par les 4 écrans de cartes, `folder_page` et la corbeille. API finale sans
> `padding` (les écrans gardent leur `SliverPadding`), `cardBuilder(context, item)`.
> La grille de la corbeille est passée à la config standard (8 px, ratio 0.9).

## 8. Lot 4 — Contrôleur de sélection

**API cible**

```dart
class SelectionController extends ChangeNotifier {
  SelectionController({bool Function(String id)? isSelectable});

  bool get isActive;
  int get count;
  Set<String> get ids;
  bool contains(String id);
  void enter(String id);
  void toggle(String id);
  void selectAll(Iterable<String> ids);
  void clear();   // vide la sélection
  void exit();    // vide et sort du mode
}
```

- `HomeViewModel` **délègue** (les getters publics ne changent pas : `selected`,
  `isInSelectionMode`, etc.), donc aucun impact sur les écrans.
- `FolderPage` **remplace** ses champs `_selected`/`_isSelectionMode` par un
  `SelectionController` (règle : notes lockées sélectionnables).
- Home passe la règle « un dossier locké n'est pas sélectionnable ».

**Fait quand** : `_selected` n'existe plus qu'à un seul endroit.

> **Fait** sur `refactor/core-stabilisation` : `SelectionController`
> (`shared/controllers/selection_controller.dart`). Les getters publics de
> `HomeViewModel` sont inchangés (il délègue et se synchronise via un listener) ;
> `FolderPage` utilise le contrôleur à la place de ses champs. La règle « un
> dossier locké n'est pas sélectionnable » est injectée à la construction du
> contrôleur côté accueil.

## 9. Lot 5 — Dialogues adaptatifs

- **Ajouter** `showAdaptivePrompt` dans `confirm.dart` (iOS : `CupertinoAlertDialog`
  + `CupertinoTextField` ; Material : `AlertDialog` + `TextField`), avec la
  longueur maximale en paramètre.
- **Migrer** `Home._promptAndCreateFolder` et les dialogues de `data_transfer.dart`.
- **Fait quand** : `showDialog`/`showCupertinoDialog` n'apparaissent plus que dans
  `confirm.dart`.

> **Fait** sur `refactor/core-stabilisation` : `showAdaptivePrompt` ajouté, plus
> un `showPlatformDialog` générique pour les formulaires (utilisé par le
> formulaire d'export). Migrés : le prompt « nouveau dossier » (`home_page`) et
> le mot de passe d'import (`data_transfer`). Toutes les ouvertures de dialogue
> passent désormais par `confirm.dart`.

## 10. Lot 6 — Champ couverture unifié

- **Extraire** de `folder_page.dart` : `ManageableCover` (placeholder à hauteur
  réservée, appui long, bouton supprimer, état « Corrupted image », cache du futur).
- Il **réutilise** `CoverImage` pour le dessin et le layer de thème.
- L'utiliser dans la page dossier ; l'éditeur de note peut s'y brancher ensuite.

**Fait quand** : une seule implémentation de couverture « gérable ».

> **Fait** sur `refactor/core-stabilisation` : `ManageableCover`
> (`shared/widgets/manageable_cover.dart`) — hauteur réservée, appui long,
> bouton supprimer + confirmation, état « Corrupted image ». Il réutilise
> `CoverImage` (qui expose maintenant un `onError`). La page dossier **et**
> l'éditeur de note s'y branchent : couverture **pleine largeur**, règles
> **haut / bas** comme la bordure de carte. Dossier = hauteur **160**
> (`BoxFit.cover`) ; éditeur = ratio naturel (`BoxFit.fitWidth`, pas de dim en
> thème clair). Le cache du futur est géré par `CoverImage`.

## 11. Lot 7 — Découpage du FAB

- Scinder `app_fab.dart` (~1300 lignes) en :
  - `fab/app_fab.dart` (état, animation, `collapsedByDefault`, `collapse`) ;
  - `fab/fab_menus.dart` (menus verticaux add/color/more/link) ;
  - `fab/fab_bars.dart` (barres éditeur/sélection/recherche/find) ;
  - `fab/fab_items.dart` (`_VerticalMenuItem`, `_EditorAction`, `_SelectionFabButton`).
- **Refactor pur** : aucune API publique ne change.

## 12. Lot 8 — Nettoyage

- Supprimer les callbacks morts `onShareSelected`/`onCollaboratorsSelected` et les
  clés l10n orphelines `option_share`/`option_collaborators`.
- Retirer `sqflite` des dépendances s'il n'est plus utilisé.
- Passer `AttachmentsStore` et `AuthService` par `getIt` (fin des singletons
  mutables et du top-level dans `cover_image.dart`).
- ~~Retirer le pin~~ : **fait** — `isPinned` (modèle + colonne SQLite),
  `togglePin`/`toggleFolderPin`, le marqueur `push_pin` et l'option FAB sont
  supprimés ; le **bookmark** trie désormais l'élément en tête.
- Trancher les TODO `analytics_service` et `about_page`.

## 13. Lot 9 — Accessibilité

- `tooltip:`/`Semantics` sur toutes les actions-icônes (FAB, app bar, cartes).
- Vérifier contrastes, `textScaler`, et le parcours lecteur d'écran.
- Test widget : chaque `IconButton` possède un libellé sémantique.

## 14. Garde-fous

- `flutter analyze` : **0 issue** ; `flutter test` : **tout vert** après chaque lot.
- Un lot = une PR = un diff relatif.
- Lots 2, 3, 4, 6, 7 : **aucun changement de comportement** (revue ciblée là-dessus).
- Avant le lot 2 : lots 0 et 1 terminés.

## 15. Hors périmètre de ce chantier

- Checklist avancée, projets/Kanban (type Trello), synchronisation P2P, dossiers
  hiérarchiques : ils viendront **après**, en s'appuyant sur `EntityCard`,
  `EntitySliver` et `SelectionController`.

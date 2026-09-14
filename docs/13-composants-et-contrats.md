# 13 — Composants et contrats

> Référence de la refonte : anatomie et **contrat** de chaque brique d'écran
> (AppBar, FAB, Page, TitleLine, Card, Section, Attention).
> Compléments : [11 — État du projet](./11-etat-et-reste-a-faire.md) et
> [12 — Plan de refactoring](./12-plan-refactoring.md).

## 1. Vue d'ensemble

L'app suit une architecture *vertical slice* : le métier (`core`) est séparé de
l'UI (`features` / `shared`). Chaque écran se compose de trois briques :

- **AppBar** — retour, titre, au plus 3 actions ;
- **Page** — le contenu (ligne de titre, metadata, couverture, sections) ;
- **FAB** — les actions contextuelles (3 formes).

Vocabulaire partagé :

| Terme | Définition |
|---|---|
| **TitleLine** | Titre (au plus 2 lignes) + petite metadata à droite |
| **Card** | Représentation d'un élément (folder, note, task, project), en grid ou list |
| **Section** | Bloc de réglages : titre + options + footer (au plus 3 lignes) |
| **Attention** | Feedback : popup pour le majeur, toast/snackbar pour le mineur |

## 2. AppBar

### Anatomie

| Zone | Contenu | Contrainte |
|---|---|---|
| Gauche | Bouton retour | **Toujours présent** (hors accueil) |
| Centre / gauche | Titre | Centré par défaut ; glissé à gauche quand des actions d'édition apparaissent **ou quand le titre est trop long** |
| Droite | Actions | **3 maximum**, icônes ; seule exception : « Cancel » en texte |

### Comportement

- Le grand titre vit dans la **Page** ; il **migre dans l'AppBar au scroll**
  (comportement actuel conservé).
- Quand **« Cancel » s'affiche, les 3 actions sont masquées**.
- Le **toggle de thème** est présent par défaut ; il **disparaît dès que les 3
  actions d'édition (undo, redo, save) apparaissent**, pour rester à 3 au plus.
- L'AppBar est un **widget séparé** (`TanoAppBar`), même s'il est injecté dans
  `PageScaffold`.

## 3. FAB

### Les 3 formes

| Forme | Description |
|---|---|
| **Circular** | Forme de repos (un icône). Forme par défaut. |
| **Extended** | Barre élargie vers la gauche affichant les actions. |
| **Menu** | Menu vertical ouvert par une action de la forme extended. |

### Actions

- **Au plus 3 actions + l'action « réduire » = 4 au total.**
- L'action « réduire » (chevron) **replie** vers la forme circulaire.
- Une page **sans** action « réduire » a la forme **extended comme forme de repos**.
- Une action peut **ouvrir un menu** (vertical) au lieu d'agir directement.

### Comportements (identiques partout)

1. Taper l'icône / le « + » → forme **extended**.
2. Taper une action → exécute l'action **ou** ouvre son menu.
3. Taper l'action « réduire » → forme **circulaire**.
4. **Taper ailleurs** :
   - ferme d'abord un menu ouvert ;
   - puis, si la page a l'action « réduire », replie en **circulaire** ;
   - sinon, revient à la forme de repos (**extended**).

### Cas particulier : le FAB de recherche

La recherche **transforme le FAB** en champ de saisie, avec ses actions propres
(nombre d'occurrences, navigation précédent / suivant, réinitialisation).

### Décision actée

- La **quatrième** forme actuelle du « + » de l'accueil (colonne verticale de 2 icônes)
  **est supprimée** : taper « + » ouvre la forme **extended** avec 2 icônes
  (dossier, note) + l'action « réduire ».
- Quand task et project arriveront, l'accueil aura **4 actions** (folder, note,
  task, project) : la limite est alors atteinte et **le tap extérieur replie**.

## 4. Page

### Anatomie (ordre)

1. **Ligne de titre** : titre (au plus 2 lignes) + petite metadata à droite.
2. **Ligne de metadata** (optionnelle), juste sous le titre.
3. **Couverture** (optionnelle), juste sous la ligne de metadata.
4. **Contenu**.

### Comportement

- Au scroll, le titre **migre dans l'AppBar**.
- Le **fond de la page** est teinté par le thème de l'élément (hors dark/light),
  **comme aujourd'hui** : toute la page (fond immersif), à l'image de la page
  dossier et de l'éditeur.
- **Accueil** : cas particulier à **2 parties** (dossiers, puis notes), chacune
  avec **sa propre ligne de titre**.
- **Corbeille** : la vue **respecte le choix de l'utilisateur** (list ou grid),
  comme l'accueil et les dossiers.

### Décision actée

`PageScaffold` mélange aujourd'hui AppBar + Page + scroll. La refonte **sépare**
`TanoAppBar` de la Page (l'AppBar reste injectée dans `PageScaffold`).

## 5. TitleLine

| Slot | Contenu |
|---|---|
| Titre | Au plus **2 lignes** |
| Metadata | Petite, à droite, sur la même ligne |

## 6. Card

### Deux formes, deux comportements

| Forme | Disposition |
|---|---|
| **Grid** | Couverture sur la **moitié haute**, contenu en bas |
| **List** | Couverture sur le **tiers gauche**, contenu à droite |

Chaque forme peut avoir des comportements propres (ex. swipe en list).

### Slots de base

Couverture · titre · extrait du contenu · metadata · date · pin · bookmark ·
icônes d'indication (ex. `folder_open` pour un dossier).

### Templates par type

Les cards représentent **tous** les éléments : folder, note, task, project.
Un **`EntityCard` commun** est paramétré par un **template** par type : même
anatomie (couverture, pin/bookmark, sélection, verrou), contenu et slots adaptés
par le template.

- **Template « verrouillé »** : identique pour **tous** les éléments.
- **Task** et **project** : même traitement que note et folder ; seuls les
  éléments **propres à chacun** diffèrent.

### Élément distinctif

Pour distinguer un dossier d'une note (les cartes se ressemblent), le dossier
affiche un **filigrane** agissant comme un fond : le pictogramme dossier
(tracé seul), en **72 px** (24 × 3), **décalé hors des bords bas / droit** de la
carte (réglage actuel : **2 px** à droite, **20 px** en bas ; le pictogramme
reste en grande partie visible). Le filigrane est absent des cartes
**verrouillées** (template commun) et des notes.

### Anatomie (refonte, validée au labo)

- **Radius** : formule **radius extérieur − marge = radius intérieur**.
  Extérieur = `appBorderRadius` = **12** ; marge = `contentInset` = **6** ;
  intérieur = **6**. Elle s'applique à la bordure, au contour en points et, si
  un élément est en retrait, à la couverture.
- **Ombre** : **aucune** (carte plate).
- **Bordure** : **sombre en thème clair**, **claire en thème sombre** ; épaisseur
  **1,0 en dark**, **0,5 en light**.
- **Hauteurs** : **3 valeurs seulement**, identiques pour dossier et note :

  | Classe | Cas | Valeur |
  |---|---|---|
  | `compact` | list, sans couverture | 80 |
  | `normal` | list, avec couverture | 92 |
  | `square` | grid | 128 |

  La grille est **subtilement plus haute que large** (pas un vrai 1:1).

- **Marge de contenu** : `contentInset = 6`. Une **seule** marge sert au
  contenu (hors couverture), aux marqueurs (pin / bookmark) et à la bordure des
  cartes verrouillées.
- **Verrouillé** : bordure **en points** (grise, discrète mais visible dans les
  deux thèmes), **en retrait** de `contentInset` par rapport aux bords ; elle
  délimite la zone de contenu. Les points sont **répartis uniformément sur tout
  le périmètre**, coins compris (ni tirets coupés, ni points trop espacés aux
  coins). Le contenu verrouillé reçoit une marge de `contentInset × 2` (**12**),
  portée à **24** de chaque côté en **list**. Le **template verrouillé est
  identique** pour tous les éléments.
- **Date** : format **jj/mm/aaaa** (`14/09/2026`) sur **toutes** les cartes.
- **Typographie** (toutes les cartes ; référence = carte **grille** de la note) :
  titre **11** gras · date **9** · contenu (extrait) **10** · metadata (compteurs)
  texte **9**, icône **11**.
- **Titres — lignes max** : grid **3** (**2** avec couverture) ; list **2**
  (**1** avec couverture), **sauf** le dossier en list et les cartes
  verrouillées en list, qui gardent **2** lignes même avec couverture. Le « … »
  apparaît **automatiquement** dès que le titre dépasse.
- **Contenu** : prend l'**espace restant** ; le nombre de lignes est calculé
  d'après cette hauteur et le texte se termine par **« … » sur une ligne
  complète** (jamais coupé en pleine ligne). Absent d'une carte grille avec
  couverture.
- **Paddings** (hors carte verrouillée) : **grid 8**, **list 12** ; sous une
  couverture de grille, le **gap** couverture → contenu est de **4**.
- **Metadata face au bas** : la ligne de metadata est à **4** du bord bas — sur
  les cards de la **note** (grid et list) et sur le **dossier en grid**
  uniquement (hors lock).
- **Alignement** (hors verrouillé) : le **body** (tout le contenu) est **aligné
  en haut** ; la **metadata** est toujours **en bas** et **alignée à gauche**.
  Exception : le **dossier en list** centre verticalement son nom + sa metadata,
  comme le template verrouillé.
- **Marqueurs** :
  - **Épinglé** : le pin vit dans la **metadata**, en **première position** ;
    Material Symbols `push_pin`, **rotation -90°**, **poids normal** (400).
  - **Bookmark** : sur une **note**, marqueur flottant en haut du card
    (`top: 0`, `right: 2`, bearing du glyphe compensé, et **largeur conservée
    avec 25 % de hauteur en moins**), ou **au bas de la couverture** sur un
    grid-cover ; sur un **dossier**, pas de marqueur : le **filigrane passe en
    ambre**.
  - Les autres icônes de metadata sont en **Material Symbols**
    (`done_all`, `sticky_note_2`, `attachment`, `description`).
- **Dossier** : l'icône `folder_open` est **retirée** du contenu ; le dossier
  se distingue par le **filigrane** bas-droit (§ « Élément distinctif »).
- **Bordure et couverture** : la bordure est **peinte au-dessus du contenu**
  (dernière couche du Stack), sinon la couverture masque les coins arrondis.
- **Placeholder d'image** : le placeholder actuel sera décliné en **10
  variantes** (plus tard).

### État (refonte faite)

`EntityCard` est **la carte unique de l'app** : tous les écrans (accueil,
dossier, corbeille) l'utilisent, les anciennes `NoteCard` / `FolderCard` sont
**supprimées**. Les corps vivent dans `note_card_bodies.dart` et
`folder_card_bodies.dart`, la typographie dans `card_typography.dart`
(cf. [12](./12-plan-refactoring.md), lot 2).

## 7. Section

| Slot | Contenu |
|---|---|
| Titre | Intitulé de la section |
| Options | Liste d'options |
| Footer | Lignes de texte, **3 maximum** |

Utilisée principalement dans les réglages (`SettingsSection` actuel).

## 8. Attention / feedback

| Niveau | Composant |
|---|---|
| **Majeure** (suppression, verrouillage, choix) | Popup **natif par OS** : `CupertinoAlertDialog` (iOS/macOS), `AlertDialog` (Android) |
| **Mineure** (confirmation discrète, undo) | **SnackBar** sur Android ; **toast** sur iOS, en **haut** de la page, **2 s** |

- Le helper central reste `confirm.dart` (`getConfirmation`, `showAdaptiveAlert`,
  `showAdaptiveNotice`, `showAdaptiveChoice`), complété par un **toast iOS**.
- Aucun dialogue ne doit être construit à la main dans les features.

## 9. Icônes

- Les icônes Flutter par défaut (MaterialIcons) **n'ont pas de `weight`
  ajustable**.
- On utilise donc **Material Symbols** (`material_symbols_icons`) pour **toutes**
  nos icônes, afin de piloter le poids (`weight`), le `fill`, le `grade` et la
  taille optique.

## 10. Typographie et comportements

- **Typographie iOS** et **comportement par défaut iOS** partout, sauf pour les
  composants manifestement natifs de l'autre plateforme (ex. **SnackBar** et
  **AlertDialog** Material sur Android).
- C'est déjà presque le cas : ce point **fige la règle**.

## 11. Modularité

Toute fonctionnalité doit être **modulaire** et **pilotable** (feature flags,
gratuit/premium, livraison partielle). Voir
[14 — Modularité et services](./14-modularite.md).

## 12. Décisions actées

1. La **quatrième** forme du FAB est **supprimée** ; le « + » ouvre la forme extended.
2. Limite : **3 actions + réduire = 4**.
3. La forme de repos est **circulaire** par défaut, **étendue** sur les pages
   sans action « réduire ».
4. **Taper ailleurs** ferme le menu puis replie (règle du §3).
5. Le FAB **dossier démarre replié**, comme l'éditeur (le sursaut d'ouverture est
   déjà résolu).
6. **AppBar et Page sont séparées** en widgets distincts.
7. Le titre suit le comportement actuel : centré, glissé à gauche sur édition ou
   titre long ; « Cancel » masque les actions.
8. Ordre de la Page : titre → metadata → couverture → contenu.
9. iOS n'ayant pas de snackbar, on utilise un **toast** pour le feedback mineur.
10. Les cards utilisent des **templates prédéfinis par type**.
11. La **corbeille respecte la vue choisie** (list/grid) par l'utilisateur.
12. Le **toast iOS** s'affiche **en haut** de la page pendant **2 secondes**.
13. Un **`EntityCard` commun** paramétré par un **template** par type.
14. Les **couleurs de page** gardent l'état actuel : **toute la page** est teintée
    par le thème de l'élément (dossier, éditeur).
15. **Material Symbols** pour toutes les icônes (poids ajustable).
16. **Typographie et comportements iOS par défaut**, hors composants natifs de
    l'autre OS (snackbar, dialog).
17. Le **toggle de thème** de l'AppBar disparaît quand les 3 actions d'édition
    apparaissent.
18. Un **template « verrouillé »** commun à tous les éléments. Task et project
    se traitent comme note et folder (spécificités mises à part).
19. L'icône `folder_open` est remplacée par un **filigrane** en bottom / right :
    pictogramme dossier tracé seul, **72 px**, décalé hors des bords bas / droit
    (réglage actuel : 2 px / 20 px).
20. Rayon de carte : `appBorderRadius` (**12**).
21. Carte **plate** : **sans ombre**.
22. Bordure **sombre en thème clair**, **claire en thème sombre** ; épaisseur
    **1,0 en dark**, **0,5 en light**.
23. Hauteurs de carte limitées à **3 valeurs** : `compact` (list sans
    couverture, 80), `normal` (list avec couverture, 92), `square` (grid, 128,
    subtilement plus haute que large).
24. Cartes verrouillées : contour **en points** en retrait de `contentInset`
    (**4**), marge commune au contenu et aux marqueurs, points répartis
    uniformément sur tout le périmètre (coins compris).
25. Formule de radius : **extérieur − marge = intérieur** (12 − 6 = 6), pour la
    bordure, le contour en points et la couverture si elle est en retrait.
26. **Déplacer ne concerne que les notes** : un dossier n'est jamais déplaçable,
    donc l'action est désactivée dès que la sélection contient un dossier
    (`canMove: !hasFolderInSelection`). Le dialogue de déplacement ne s'affiche
    donc jamais pour un dossier.

## 13. Questions ouvertes

- **Placeholders d'image** : proposer **10 variantes** (le placeholder actuel
  sert de base). À faire plus tard.
- **Actions de swipe sur le card-list** : à revoir (les gestes et leurs effets
  restent à définir).

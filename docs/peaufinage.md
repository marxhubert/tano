# Peaufinage

> **Chantier en cours.** Les retouches à faire, mesurées sur le code. Un point
> par ligne, coché au fur et à mesure. Ce document **disparaît** quand le
> chantier est fini : ce n'est pas une référence.

## Méthode

- Un lot à la fois ; `flutter analyze` et les tests avant de passer au suivant.
- **Goldens** après tout lot qui touche une carte : `flutter test test/golden/`
  montre ce qui a bougé. Après un changement voulu :
  `flutter test --update-goldens test/golden/`, puis **regarder les images**.
- Rien n'est commité sans un mot de toi.

---

## 1. Couleurs

**Fait.** 119 références codées en dur → **90**, et surtout **29 valeurs
hexadécimales → 0** : plus une seule couleur écrite à la main hors de
`theme.dart`.

| Fait | Détail |
|---|---|
| La palette n'est plus recopiée | `appearance_section.dart` listait les **20 valeurs** des pastels et des fonds. Elle lit maintenant `TanoPastels.all` et `darkBackground` / `lightBackground` : l'aperçu de thème ne peut plus diverger de la palette réelle. |
| Le rouge des actions destructrices | `0xFFFF8A80`, écrit **8 fois** (`trash_page`, `fab_bars`, `fab_menus`, `data_management_section`), est devenu **`tanoDanger`**. |
| Le seul écart vraiment visible | **`Colors.blue`** (3× : `confirm.dart`, `info.dart`) → **`tanoTeal`**. Un bouton bleu dans une app teal. |
| Le dernier hexadécimal | `data_transfer.dart:135` réécrivait `TanoStates.error.dark` → il l'importe. |

**Vérifié** : les 20 goldens passent **sans régénération** — le lot ne bouge aucun
pixel des cartes. `analyze` 0 issue, 279 tests verts.

### Ce que l'audit exagérait

En lisant le code, deux constats se sont révélés faux :

- les **51 `Colors.white`** sont pour l'essentiel lus **sur le teal** (barres,
  menus, boutons pleins du FAB) : c'est voulu, pas une fuite de thème ;
- les **`Colors.grey`** sont volontairement indépendants du thème (état inactif,
  bouton de développement). Un jeton n'apporterait rien.

### Reste à arbitrer, plus tard

- `app_fab.dart:378` dessine une bordure `white 0.22 / black 0.08` là où
  `cardBorderColor` dit `0.22 / 0.16`. Les rapprocher **change le rendu**, et le
  FAB n'est pas couvert par les goldens : à décider à l'œil.
- `TanoStates.error` et `tanoDanger` sont deux rouges. Les fusionner est un choix
  visuel, pas un rangement.

## 2. Typographie

**Fait. 13 tailles littérales → 4**, et les trois qui restent sont dans le
splash, où elles sont **collées aux PNG générés** (`tool/generate_splash_logo.dart`) :
les changer oblige à régénérer les images. La quatrième est un `fontSize: 0`
volontaire (un span masqué du markdown).

L'échelle vit dans `theme.dart`, sous le nom `TanoText` :

| Jeton | Valeur | Rôle | Usages |
|---|---|---|---|
| `pageTitle` | 24 | titre de page | 5 |
| `emptyState` | 20 | état vide | 4 |
| `wordmark` | 18 | « TanoNote » en dialogue | 2 |
| `listTitle` | 17 | titre de ligne : réglage, action, menu | 17 |
| `body` | 16 | corps de texte, dialogues | 8 |
| `label` | 14 | libellé secondaire | 13 |
| `small` | 13 | petit libellé, footer | 8 |
| `tiny` | 12 | mention | 5 |
| `caption` | 11 | métadonnées d'en-tête de page | 1 |
| `badge` | 10 | compteur sur une barre | 1 |

- Les **14,4** (5 endroits : corps des dialogues, repli du markdown) ont disparu —
  c'était une valeur de repli, jamais choisie.
- Le **15** isolé de `no_record` rejoint `label`.
- **`entity_card.dart` recopiait l'échelle des cartes** (11 et 9 en dur) alors que
  `card_typography.dart` la définit : il lit maintenant `cardTitleSize` et
  `cardMetaSize`. C'est pour ça que les goldens sont **inchangés**.

### Tranché

Quatre questions posées, quatre réponses :

| Question | Décision |
|---|---|
| `body` (16) et `listTitle` (17) | **Garder les deux.** Un pixel suffit à distinguer un corps d'un titre ; fusionner ferait perdre la nuance |
| Les quatre petits textes | **Deux seulement** : `label` (14) et `tiny` (12). `small` (13) et `caption` (11) **disparaissent du thème** — leurs 9 sites lisent `label` ou `tiny` |
| `emptyState` (20) | **Garder.** Un seul écran, et l'écart est voulu : c'est une invitation, pas un élément de liste |
| Le wordmark (18 / 24) | **Garder les deux.** Un dialogue n'est pas une page |

**Effet visible** : les pieds de section des Réglages, la note des Licences et
les libellés des Références linguistiques passent de 13 à **14** ; la ligne de
métadonnées d'un en-tête passe de 11 à **12**. Un pixel, mais c'est voulu.

## 3. Espacements et rayons

**Fait.**

| Fait | Détail |
|---|---|
| Deux rayons nommés | `pillRadius` (55, les boutons pleins) et `settingsCardRadius` (18, une carte de réglages) — 3 sites. |
| Les `EdgeInsets` qui recopiaient un jeton | **19 lignes** écrivaient `6.0`, `12.0` ou `18.0` en dur là où `appPaddingSmall/Medium/Large` existaient déjà. Elles les lisent maintenant. |

**Vérifié** : les 20 goldens passent **sans régénération** (mêmes valeurs),
`analyze` 0 issue, 279 tests verts.

### Reste — et je ne crois pas qu'il faille y toucher

- Les littéraux **restants** sont des valeurs **sans jeton** : 8 (17×), 20, 16, 4, 2,
  24, 40, 48, 10, 3. Inventer dix jetons pour ça serait du zèle : `EdgeInsets.all(8)`
  se lit très bien tel quel.
- **Les jetons couvrent l'usage, mais il leur manque les deux valeurs les plus
  écrites.** Comptes réels (jeton + littéraux avant le lot 3) :

  | Jeton | Usages | Littéraux `18/12/6` | Valeur sans jeton |
  |---|---|---|---|
  | `appPaddingLarge` | **15** | 4 | — |
  | `appPaddingMedium` | **36** | 20 | — |
  | `appPaddingSmall` | **7** | 2 | — |
  | — | — | — | **8** écrit 17 fois |
  | — | — | — | **16** écrit 9 fois |

  **Tranché : les nommer sans rien changer.** `appPaddingTight` (8) et
  `appPaddingWide` (16) rejoignent le barème — 31 lignes d'espacement cessent
  d'écrire une valeur en dur. Le barème est à cinq valeurs, et les fusionner
  reste possible plus tard en changeant un chiffre.

  **Tranché aussi** : le pied de page d'À propos n'écrit plus `90` mais
  `4 * sectionGap` — **96**, quatre fois le rythme de section. Le nouveau jeton
  `sectionGap` (24) remplace au passage les dix autres `24` d'espacement, jusqu'ici
  écrits en dur. Effet visible : le pied de page descend de 6 px.
- **Les « écarts » que j'avais annoncés n'en sont pas** : le `9` était la taille de
  date des cartes (déjà passée en jeton), le `10` aligne trois choses précises (une
  tuile à interrupteur, le champ de recherche, un item de menu), et le `90` est
  **trois valeurs différentes** qui se trouvent valoir 90 (un pied de page, une
  barre d'outils, une illustration). Rien à unifier.
- Les deux micro-rayons de l'aperçu de thème (`5` et `2`) restent littéraux : ils
  dessinent une maquette miniature, pas une surface de l'app.

> **Ce que je ne recommande pas** : tokeniser les `SizedBox(height:)` et les
> `EdgeInsets` restants. Contrairement aux couleurs et aux tailles, une valeur
> d'espacement est **contextuelle** — un `8` entre deux lignes n'a rien à voir
> avec un `8` autour d'une icône. Un jeton les ferait passer pour la même chose.

## 4. iOS

**Rien à faire — le passage iOS était déjà fait.** Vérifié un par un, pas au
motif de recherche :

- l'export et l'import ont **leur variante Cupertino**
  (`isApple ? CupertinoAlertDialog : AlertDialog`), y compris l'interrupteur et le
  champ de mot de passe ;
- le menu « plus » de l'accueil est un **action sheet Cupertino** sur iOS
  (`_buildAdaptiveMenu`) ;
- tous les messages courts passent par `showAdaptiveNotice` — huit appels, **aucun**
  `showSnackBar` direct ;
- interrupteurs, indicateurs et cases de liste sont adaptatifs, aucun ne manque ;
- aucun sélecteur de date, aucun `RefreshIndicator`, aucun `Checkbox`, `Slider` ni
  `Drawer` : les coches de checklist sont des glyphes dessinés à la main.

**Mon audit annonçait « 3 dialogues Material directs » : c'était faux.** Mon motif
de recherche `AlertDialog(` comptait aussi `CupertinoAlertDialog(` — j'ai compté les
branches Cupertino. Le vrai compte est **zéro**.

**Le seul résultat** : `lib/shared/widgets/info.dart` était **entièrement mort** —
92 lignes, une fonction `aboutInfo`, appelée nulle part et importée par personne.
**Supprimé.**

## 5. États

### Un seul état vide — **fait**

Il y avait **quatre** façons de dire « il n'y a rien ici » :

| Endroit | Avant |
|---|---|
| Accueil, première fois | une **illustration maison** (cercle gris, signet, pastille d'avertissement) + « no data » |
| Accueil, recherche sans résultat | un texte de **12 px**, en pleine opacité |
| Dossier vide, recherche | 14 px, atténué, centré |
| Corbeille vide | texte par défaut + une action « Accueil » |

Trois d'entre elles lisent désormais **`emptyState`**
(`lib/shared/widgets/empty_state.dart`) : centré, atténué, à 14 px.

Au passage, `TanoText.emptyState` était **mal nommé** : les quatre textes qu'il
portait sont les actions d'un *action sheet* (20 px, teal, dans l'accueil vide).
Il s'appelle maintenant `TanoText.sheetAction`.

**Fait** : chaque état vide a son illustration, fournie par le propriétaire du
projet — `empty-box` à l'accueil de première fois, `empty-folder` dans un dossier,
`recycle-bin` dans la corbeille, `empty` sur une recherche sans résultat. Le
composant `noRecordFound` et son dessin maison sont supprimés.

**Crédit** : les illustrations sont de **Ghozi Muhtarom**, publiées sur **Flaticon**. Le crédit vit dans un fichier dédié à la racine du dépôt, **`CREDITS.md`**, rédigé dans la forme exacte que Flaticon demande (« Icon made by [auteur] from [www.flaticon.com] », l'auteur et Flaticon étant cliquables). Les fichiers de licences embarqués dans l'app (`assets/licenses/*.txt`) n'ont pas été touchés.

**Retouches demandées après coup.** Le bloc entier remonte de 24 px (une marge
basse de `2 * sectionGap`, dont la moitié passe sous le milieu de l'écran) : les
quatre illustrations sont désormais au-dessus du centre géométrique, ce qui se lit
comme centré. Les quatre messages changent : « No item found » sur une recherche
sans résultat, « Nothing yet » à l'accueil, « Empty trash » dans la corbeille, et
« This folder is empty » reste tel quel dans un dossier. « Empty trash » est une
clé neuve, `trash_empty` : `empty_trash` (« Vider la corbeille ») est l'action,
pas le message. Enfin, dans la corbeille vide, le bouton « Accueil » quitte le
corps pour la barre du haut, tout à droite, en icône seule (`Symbols.home`). Plus
personne n'utilisant `actions`, le paramètre disparaît d'`emptyState`.

**Filigranes figés.** Clavier ouvert (la recherche), le corps de la page
rétrécissait et l'illustration remontait avec lui : elle était un objet dans le
défilement, pas un fond. `PageScaffold` gagne `freezeBody` : le corps est alors
posé sur la hauteur qu'il a clavier fermé, donc le clavier ne le déplace plus du
tout, et sa position de repos ne change pas. Les trois écrans vides l'activent ;
les listes gardent le comportement normal, pour que le dernier élément remonte
bien au-dessus du clavier. Deux tests le tiennent
(`test/empty_state_keyboard_test.dart`).

> La licence gratuite de Flaticon impose l'attribution, et **une ligne par auteur**
> suffit — pas une par icône. L'auteur publie sous le nom **Ghozi Muhtarom** ; le
> dossier local s'appelle `Ghozi_Muhtarom`.

## Correctifs signalés

### Le hard reset ne supprimait que les notes

`deleteAllNotes()` vidait la table `notes` et **laissait les dossiers** — et les
pièces jointes sur le disque. Le contrat des dossiers n'avait même pas de « tout
supprimer » :

- `FoldersRepository.deleteAllFolders()` ajouté (contrat + implémentation SQLite) ;
- `AttachmentsStore.deleteAll()` ajouté : il efface le dossier `attachments/` **et**
  les copies matérialisées, sans quoi un reset laissait des fichiers orphelins ;
- `performHardReset` appelle les trois, dans le même bloc ;
- **un test** verrouille le comportement : `deleteAllFolders` vide les dossiers,
  corbeille comprise.

### Le rouge des actions dangereuses dépendait de la langue

`getConfirmation` décidait qu'une action est destructrice avec
`actionTitle.contains('reset')` — un mot **anglais**. En français le titre est
« Réinitialiser » : l'action du dialogue s'affichait donc **en teal**, alors qu'en
anglais elle était rouge. La comparaison se fait maintenant sur les mots
**traduits** (`tr('delete')`, `tr('reset')`), donc dans toutes les langues.

### Le hors-ligne : rien à ajouter, et c'est volontaire

**Aucun écran ne dépend du réseau.** Il n'y a donc pas d'« état hors-ligne » à
afficher : l'app fonctionne, simplement. La seule fonction qui a besoin du réseau
— la vérification des mises à jour — répond déjà « Vérification indisponible »
quand elle échoue. Une bannière « vous êtes hors-ligne » serait du bruit, et
contredirait le propos du produit.

### Les erreurs : un seul endroit, et c'est le bon

Le **splash** est le seul écran qui peut échouer (charger la base au démarrage) et
il a son état complet : titre, message, **bouton Réessayer**. Tout le reste est
synchrone, et les échecs ponctuels passent par un message adaptatif (import raté,
image corrompue). Un seul point de reprise, donc — mais c'est le seul qui ait un
sens.

### Le FAB ouvert : la règle avait les coins coupés

`app_fab.dart` peignait sa règle dans la `decoration`, donc **sous** l'enfant.
La surface sombre du menu, découpée aux coins en anti-aliasing, la recouvrait
le long de chaque arc : la règle suivait les bords droits puis disparaissait au
virage. Mesuré sur une capture : aucun pixel de règle dans les 33 px du coin,
alors qu'elle est franche sur les bords. Elle passe en `foregroundDecoration`,
au-dessus de l'enfant — exactement le remède déjà appliqué aux pastilles de
couleur, avec le même commentaire dans `fab_menus.dart`.

### Deux actions se refusent quand elles n'ont rien à proposer

`_VerticalMenuItem` sait se refuser : grisé, insensible au tap, mais **à sa
place** — le menu ne se réorganise pas d'une ouverture à l'autre. « Lier une
note » se refuse quand c'est la seule note, « Déplacer vers » quand
l'application ne contient aucun dossier. Les deux listes sont lues à
l'ouverture du menu qui en dépend.

### Le dossier de la note n'est jamais une destination

C'était déjà le cas : `currentFolderId` est retiré de la liste à l'ouverture du
menu, comme le note le contrat d'`AppFab`. Rien à corriger, donc, mais cinq
tests le verrouillent maintenant (`test/fab_menu_test.dart`).

### Le bleu des icônes comme couleur principale — **essai**

Les quatre illustrations partagent un bleu franc, `#2D74FF` (mesuré sur les
PNG : c'est la couleur exacte de leur aplat, le trait étant en `#738BAB`). Le
jeton est devenu `tanoBlue` — le renommer évitait de garder « teal » sur une
couleur bleue — et `TanoStates.action` suit. Les contrastes mesurés donnent
`#2D74FF` au-dessus du teal sur fond clair (3,94 contre 3,48) et en dessous sur
fond sombre (4,51 contre 5,10) ; sur le panneau du FAB, où le contenu est
blanc, le bleu gagne aussi (4,16 contre 3,67). Quatre goldens ont été
régénérés : le rond de sélection des cartes est teinté avec la couleur
principale.

## 6. Animations

| Point | Détail |
|---|---|
| Durées | 150 (2) · 200 (4) · 220 · 250 · 450 (3) · 1200 (2, volontaire pour le reset) → **6 valeurs pour 3 intentions** | Trois jetons : `fast`, `base`, `slow` |
| Transitions | 16 `Navigator.push`, 3 `AnimatedSwitcher`, 1 `AnimatedContainer`, **0 `Hero`** | Voir si l'ouverture d'une note mérite un `Hero` |

---

## Ordre proposé

1. ~~**Couleurs**~~ — **fait** (voir plus haut).
2. ~~**Typographie**~~ — **fait** (voir plus haut) ; la réduction attend ton
   arbitrage.
3. ~~**Espacements et rayons**~~ — **fait** ; les trois écarts (10, 9, 90)
   attendent ton arbitrage.
4. ~~**iOS**~~ — **rien à faire** ; un fichier mort supprimé au passage.
5. ~~**États**~~ — **fait** ; reste l'illustration de l'accueil à trancher.
6. **Animations** — les durées, puis éventuellement les transitions.

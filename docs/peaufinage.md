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

**Déjà bon** : 0 `showModalBottomSheet`, 0 `showSnackBar` direct (tout passe par
`showAdaptiveNotice`), 0 `Switch` ni `CircularProgressIndicator` non adaptatif.

| Point | Détail |
|---|---|
| Dialogues Material sur iOS | `data_transfer.dart` (2), `info.dart` (1) — les 7 autres passent bien par `confirm.dart` | Passer par `showAdaptiveAlert` |
| `PopupMenuButton` | 1 usage | Menu Cupertino sur iOS ? |

## 5. États

| Point | Détail |
|---|---|
| Vide | Présent : `folder_empty` (4), `no_note_found` (6), `empty` (1) |
| Erreur | `load_error_*` utilisé 8 fois, mais **un seul** point de reprise (`retry`) |
| Chargement | 5 indicateurs, tous adaptatifs |
| Hors-ligne | **Rien de spécifique** — l'app ne dit pas qu'elle fonctionne sans réseau, alors que c'est son argument |

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
4. **iOS** — trois dialogues, un menu.
5. **États** — l'angle hors-ligne, et la reprise après erreur.
6. **Animations** — les durées, puis éventuellement les transitions.

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

### La réduction, maintenant qu'elle coûte une ligne

Les jetons sont en place : réduire l'échelle, c'est changer **une valeur dans
`theme.dart`**, et tout suit. Quatre questions, chacune avec son compromis :

1. **`body` (16) et `listTitle` (17)** — un pixel d'écart, deux rôles proches.
   Les fusionner à 17 ? *(+1 px sur tout le corps de texte)*
2. **`label` (14), `small` (13), `tiny` (12), `caption` (11)** — quatre tailles
   en quatre pixels, pour les mêmes « petits textes ». En garder deux ? *(14 et
   12 : les footers grossissent d'un pixel, les mentions aussi)*
3. **`emptyState` (20)** — un seul écran (l'accueil vide) l'utilise. L'aligner sur
   `listTitle` (17) ?
4. **Le wordmark** — 18 dans le dialogue, 24 dans À propos. Même mot, deux
   tailles : voulu (dialogue vs page) ou à unifier ?

## 3. Espacements et rayons

| Point | Détail | Proposition |
|---|---|---|
| Espacements | 25 `EdgeInsets` littéraux contre 39 usages des jetons | Ramener au barème |
| Valeurs en présence | 2 · 4 · 6 · 8 · 10 · 12 · 16 · 18 · 20 · 24 · 40 · 90 | Une échelle nommée ; 6, 12, 18 sont déjà les jetons |
| `SizedBox(height:)` | 8 · 16 · 4 · 6 · 24 · 2 · 12 | Idem |
| Rayons | quasi tous passés par `appBorderRadius` ✓ ; restent **55** (pilule), **18** (carte de réglages), `5` et `2` | Deux jetons : `pillRadius`, `settingsCardRadius` |

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
3. **Espacements et rayons** — finit le barème.
4. **iOS** — trois dialogues, un menu.
5. **États** — l'angle hors-ligne, et la reprise après erreur.
6. **Animations** — les durées, puis éventuellement les transitions.

# Charte graphique

> **Référence.** Identité visuelle, palettes et *design tokens* de TanoNote.
> Ce document fait autorité sur toutes les valeurs visuelles ; toute valeur
> codée en dur ailleurs doit venir d'ici ou de `theme.dart`.

## 1. Principe 60/30/10

L'interface répartit les surfaces pour guider vers l'action sans surcharger.

| Part | Rôle | Couleur |
|---|---|---|
| **60 %** | Dominante (fond) | clair `#F8F9FA` / sombre `#121212` (éditeur clair blanc, sombre `#1E1E1E`) |
| **30 %** | Identité | **Teal `#009688`** — AppBar, FAB, titres, états actifs |
| **10 %** | Accent | **Ambre `#FF9800`** (clair) / `#FFB74D` (sombre) — bookmark, item actif, validation |

## 2. Palettes

### États (tickets / projets)

| État | Light | Dark | Usage |
|---|---|---|---|
| Neutral | `#90A4AE` | `#78909C` | À faire / en attente |
| Action | `#009688` | `#4DB6AC` | En cours |
| Success | `#4CAF50` | `#81C784` | Terminé / validé |
| Warning | `#FF9800` | `#FFB74D` | Bloqué / attention |
| Error | `#E53935` | `#E57373` | Bug / urgent |
| Purple | `#9C27B0` | `#BA68C8` | En revue / design |
| Yellow | `#FBC02D` | `#FDD835` | Idée |
| Reference | `#2196F3` | `#64B5F6` | Documentation / lien |
| Subtle | `#B0BEC5` | `#90A4AE` | Basse priorité |
| Archive | `#78909C` | `#546E7A` | Archivé |

> Implémenté dans `TanoStates` (`theme.dart`).

### Pastels (notes / dossiers)

Fond des notes et dossiers. Texte noir/gris foncé en clair, blanc en sombre.

| Nom | Light | Dark | Ambiance |
|---|---|---|---|
| Menthe | `#E0F2F1` | `#004D40` | Fraîcheur |
| Citron | `#FFF9C4` | `#827717` | Lumière |
| Pêche | `#FFE0B2` | `#BF360C` | Douceur |
| Lavande | `#F3E5F5` | `#4A148C` | Zen |
| Rose | `#FFEBEE` | `#880E4F` | Personnel |
| Azur | `#E1F5FE` | `#01579B` | Technologie |
| Sable | `#F5F5DC` | `#3E2723` | Papier |
| Sauge | `#F1F8E9` | `#1B5E20` | Nature |
| Bonbon | `#FCE4EC` | `#AD1457` | Créatif |
| Nuage | `#ECEFF1` | `#263238` | Neutre (défaut) |

> Implémenté dans `TanoPastels` (`theme.dart`) ; `themeCategory(name, ...)`
> résout une catégorie vers sa couleur.

## 3. Tokens

### Espacements & rayons

| Token | Valeur | Contexte |
|---|---|---|
| `appPaddingLarge` | **18.0** | Marge des titres, contenu de l'accueil, réglages |
| `appPaddingMedium` | **12.0** | Espacement des cartes, padding vertical des titres |
| `appPaddingSmall` | **6.0** | Marge des icônes d'AppBar |
| `appBorderRadius` | **12.0** | Cartes, menus |
| `sectionBorderRadius` | **18.0** | Sections de réglages, FAB ouvert |
| `menuMinWidth` | **160.0** | Largeur minimale des `PopupMenu` |

### Typographie

| Élément | Taille | Graisse | Couleur |
|---|---|---|---|
| Titre de page / section (`sectionTitleSize`) | **24.0** | `w600` | `primaryTextColor` (letterSpacing −0.41) |
| Titre AppBar réduit + « Cancel » (`appBarTextSize`) | **17.0** | `w600` / `w400` | `primaryTextColor` |
| Metadata de ligne de titre | **13.0** | `w400` | `mutedTextColor` |
| Ligne metadata (date, compteurs) | **11.0** | — | `mutedTextColor` |
| Carte — titre / date / contenu / meta | 11 / 9 / 10 / 9 | `Bold` / — | `getTextColor(bg)` |

> Titres, metadata de ligne de titre et ligne metadata passent par les briques
> `SectionTitleLine` / `MetadataLine` (`page_header.dart`).

### Icônes

- **Material Symbols** partout (`material_symbols_icons`), avec les axes
  `weight` (100–700 ; `900` pour `more_horiz`/`more_vert`) et `fill`.
- Taille : **24** (FAB / actions principales), **22** (AppBar), **20** (retour,
  chevrons, indicateurs), **12** (glyphes de la ligne metadata), **11**
  (marqueurs de carte).
- Bookmark = `Symbols.label_important`, **rempli** et ambre quand actif.
- Retour = `Symbols.arrow_back_ios` (20).

### Menus & navigation

| Token | Valeur | Contexte |
|---|---|---|
| `appBarOffset` | **56.0** | Décalage du `PopupMenu` sous l'AppBar |
| Zone de la barre FAB | **64.0** | Hauteur de la barre / rayon de repos |
| FAB ouvert | rayon **24** (haut) | le menu se fond dans le menu |
| Item de menu vertical | padding vertical **12**, horizontal **4** | `_VerticalMenuItem` |

## 4. Règles d'implémentation

```dart
// Texte sur un fond coloré (carte, couverture).
Color getTextColor(Color background) =>
    ThemeData.estimateBrightnessForColor(background) == Brightness.light
        ? Colors.black87
        : Colors.white;

// Texte principal / secondaire.
Color primaryTextColor(BuildContext c); // #212121 (clair) / grey.300 (sombre)
Color mutedTextColor(BuildContext c);   // black54 (clair) / grey.500 (sombre)

// Bordure partagée : cards, règles de couverture, AppBar.
Color cardBorderColor(bool isDark) =>
    isDark ? Colors.white.withValues(alpha: 0.22)
           : Colors.black.withValues(alpha: 0.16);
```

Largeurs de bordure : carte `isDark ? 1.0 : 0.5` ; couverture (règles haut/bas)
et AppBar (bas) **0.5** dans les deux thèmes.

## 5. Plateforme

- Contrôles adaptatifs (`Switch.adaptive`, feuilles de dialogue Cupertino sur iOS).
- Retour : `Symbols.arrow_back_ios`, collé au bord gauche.
- Rayons « squircle » sur le FAB et les sections de réglages.

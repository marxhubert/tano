# Charte Graphique - TanoNote

Ce document définit l'identité visuelle de TanoNote, basée sur une couleur d'identité forte (**Teal #009688**) et le respect de la règle de design **60/30/10** pour assurer un espace de travail clair, hiérarchisé et apaisant.

---

## 1. Principes Fondamentaux (60/30/10)

L'application utilise cette répartition pour guider l'utilisateur vers les actions importantes sans le surcharger.

### Thème Clair (Light)
*   **60% — Dominante (Arrière-plan)** : `#F8F9FA` (Gris très clair)
    *   *Rôle* : Fond de l'application, fond des colonnes Kanban.
    *   *Note* : Les tickets blancs (`#FFFFFF`) se détachent sur ce fond grâce à une légère élévation.
*   **30% — Secondaire (Identité)** : `#009688` (Teal)
    *   *Rôle* : AppBar, boutons principaux (FAB), titres de structures, icônes actives.
*   **10% — Accent (Points d'attention)** : `#FF9800` (Ambre)
    *   *Rôle* : Favoris, rappels urgents, indicateurs de notification.

### Thème Sombre (Dark)
*   **60% — Dominante (Arrière-plan)** : `#121212` (Noir pur / Gris très profond)
*   **30% — Secondaire (Identité)** : `#009688` (Teal conservé pour la marque)
*   **10% — Accent (Points d'attention)** : `#FFB74D` (Ambre plus clair pour le contraste)

---

## 2. Palette des États (Tickets de Projet)

Ces couleurs servent à marquer le type ou l'avancement des tickets. **Texte conseillé : Blanc pour le mode sombre.**

| État / Type | Hex (Light) | Hex (Dark) | Usage |
| :--- | :--- | :--- | :--- |
| **Neutral** | `#90A4AE` | `#78909C` | À faire / En attente |
| **Action** | `#009688` | `#4DB6AC` | En cours (Identity) |
| **Success** | `#4CAF50` | `#81C784` | Terminé / Validé |
| **Warning** | `#FF9800` | `#FFB74D` | Bloqué / Attention |
| **Error** | `#E53935` | `#E57373` | Bug / Urgent / Critique |
| **Purple** | `#9C27B0` | `#BA68C8` | En revue / Design |
| **Yellow** | `#FBC02D` | `#FDD835` | Idée / Brainstorming |
| **Reference**| `#2196F3` | `#64B5F6` | Documentation / Lien |
| **Subtle** | `#B0BEC5` | `#90A4AE` | Basse priorité |
| **Archive** | `#78909C` | `#546E7A` | Archivé / Muted |

---

## 3. Palette Pastel (Notes de Recherche)

Conçues pour le fond des notes.
*   **En mode Clair** : utiliser du texte **Noir/Gris foncé** (`#212121`).
*   **En mode Sombre** : utiliser du texte **Blanc** (`#FFFFFF`).

| Nom | Hex (Light) | Hex (Dark) | Ambiance |
| :--- | :--- | :--- | :--- |
| **Menthe** | `#E0F2F1` | `#004D40` | Fraîcheur / Calme |
| **Citron** | `#FFF9C4` | `#827717` | Lumière / Gaieté |
| **Pêche** | `#FFE0B2` | `#BF360C` | Douceur / Échange |
| **Lavande** | `#F3E5F5` | `#4A148C` | Zen / Focus |
| **Rose** | `#FFEBEE` | `#880E4F` | Personnel / Important |
| **Azur** | `#E1F5FE` | `#01579B` | Technologie / Horizon |
| **Sable** | `#F5F5DC` | `#3E2723` | Papier / Neutre |
| **Sauge** | `#F1F8E9` | `#1B5E20` | Nature / Équilibre |
| **Bonbon** | `#FCE4EC` | `#AD1457` | Ludique / Créatif |
| **Nuage** | `#ECEFF1` | `#263238` | Universel / Discret |

---

## 4. Implémentation Flutter (Accessibilité)

Pour garantir que le texte soit toujours lisible sur ces fonds, utilisez cette logique :

```dart
Color getTextColor(Color background) {
  // Calcule la luminosité pour choisir entre texte noir ou blanc
  return ThemeData.estimateBrightnessForColor(background) == Brightness.light
      ? Colors.black87
      : Colors.white;
}
```

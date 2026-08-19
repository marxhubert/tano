# 02 — Plan d'amélioration UI/UX

Objectif : moderniser l'interface, améliorer l'ergonomie et l'accessibilité sans
compromettre la légèreté et la simplicité qui font l'identité de TanoNote.

Chaque proposition est classée par **priorité** (🔴 haute, 🟠 moyenne, 🟢 basse)
et **effort** (S / M / L).

---

## 1. Typographie et thème

### 🔴 S — Supprimer la police `Calibri` codée en dur
- **Constat** : `fontFamily: 'Calibri'` est utilisé dans `home_page.dart`, mais cette
  police n'existe ni sur Android ni sur iOS → rendu incohérent.
- **Proposition** : retirer `fontFamily` et s'appuyer sur la police système, ou
  déclarer une typographie complète dans `ThemeData.textTheme` via
  `ThemeData(colorScheme: ..., useMaterial3: true, textTheme: ...)`.
- **Bénéfice** : rendu homogène sur toutes les plateformes.

### 🟠 M — Adopter un vrai `ColorScheme` Material 3
- **Constat** : le thème clair (`main.dart`) n'utilise que `primaryColor`/`canvasColor`.
- **Proposition** : construire les deux thèmes avec `ColorScheme.fromSeed(seedColor: Colors.blueGrey, brightness: ...)`
  et `useMaterial3: true`. Conserver la teinte `blueGrey` pour préserver l'identité.
- **Bénéfice** : composants Material cohérents (surfaces, états, contrastes), meilleur
  support du mode sombre, préparation aux futures évolutions.

---

## 2. Composants et rendu des listes

### 🔴 S — Coins arrondis et élévation des cartes
- **Constat** : les cartes utilisent `BorderRadius.all(Radius.circular(0.0))` (coins carrés).
- **Proposition** : passer à un rayon de 12–16 px, élévation douce (0.6 → 1.0), et
  padding interne homogène.
- **Bénéfice** : look moderne, meilleure séparation visuelle.

### 🔴 M — Vraie barre de recherche sur la page d'accueil
- **Constat** : le champ "Search" de l'accueil est un `GestureDetector` statique qui
  ouvre la page de recherche.
- **Proposition** : intégrer un `SearchBar` (ou `TextField`) en lecture seule qui, au
  tap, ouvre la recherche ; ou mieux, une recherche **inline** qui filtre la liste
  sans changer d'écran.
- **Bénéfice** : gain de fluidité, accès plus rapide.

### 🟠 S — Date lisible et localisée
- **Constat** : `date.toString().substring(0, 10)` partout.
- **Proposition** : formater la date avec `intl` (`DateFormat.yMMMd(LocaleController.instance.language)`)
  ou un formateur relatif ("il y a 3 j").
- **Bénéfice** : dates compréhensibles, localisées FR/EN.

### 🟠 M — Aperçu du contenu dans le mode liste
- **Constat** : le mode liste affiche titre + date, sans extrait du contenu.
- **Proposition** : ajouter une ligne d'aperçu (2 lignes max, `maxLines: 2`,
  `overflow: ellipsis`).
- **Bénéfice** : identification rapide d'une note sans l'ouvrir.

### 🟢 M — Grille responsive
- **Constat** : `GridView.count(crossAxisCount: 3)` fixe.
- **Proposition** : utiliser `SliverGridDelegateWithMaxCrossAxisExtent` (largeur
  max par tuile, ex. 180 px) pour s'adapter aux tablettes et grands écrans.

### 🟢 S — Sélection visuelle améliorée
- **Proposition** : surligner la carte sélectionnée (bordure de la couleur primaire),
  coché visuel plus net, et afficher une barre d'actions contextuelle en haut plutôt
  que dans la `BottomAppBar` de 36 px.

---

## 3. Navigation et feedback

### 🔴 M — SnackBar d'annulation après suppression
- **Constat** : une suppression (swipe ou groupée) est définitive et sans retour.
- **Proposition** : afficher une `SnackBar` avec action **"Annuler"** qui restaure
  la note (voir plan fonctionnalités pour le mécanisme d'undo).
- **Bénéfice** : sécurité utilisateur, évite les pertes accidentelles.

### 🟠 S — Animations de transition
- **Proposition** : animer les changements de layout (`AnimatedSwitcher`) et les
  ajouts/suppressions (`AnimatedList`), transitions de page fluides.
- **Bénéfice** : sensation de fluidité, feedback visuel.

### 🟠 S — États vides et erreurs explicites
- **Constat** : l'écran vide (`no_record.dart`) est minimal ; les erreurs de
  chargement sont un simple `SnackBar` brut.
- **Proposition** : proposer un état vide plus guidant (bouton "Ajouter une note"),
  et des messages d'erreur lisibles et localisés.

---

## 4. Éditeur de note

### 🔴 M — Barre d'outils d'édition
- **Constat** : l'éditeur est un simple `TextField` sans mise en forme.
- **Proposition** : ajouter une barre d'outils (gras, italique, listes à puces,
  cases à cocher) en option, sans imposer un format complexe.
- **Bénéfice** : notes plus riches, aligné sur la promesse "tasks and projects".

### 🟠 S — Compteur de caractères plus lisible
- **Constat** : un simple nombre affiché en italique 9 px.
- **Proposition** : afficher "123 caractères" / "12 mots", éventuellement à côté
  de la date, dans un style discret mais lisible.

### 🟠 S — Sélecteur de date
- **Constat** : la date est automatique (`DateTime.now()`), non modifiable.
- **Proposition** : permettre de modifier la date via un `showDatePicker`.
- **Bénéfice** : utile pour les notes rétro-datées.

---

## 5. Accessibilité

### 🔴 S — Taille de texte dynamique
- **Proposition** : vérifier que tous les écrans respectent les tailles de texte
  système (le dialog est déjà `scrollable`), éviter les `Row` non scrollables,
  et tester à grande échelle de texte.

### 🟠 S — Contraste et cibles tactiles
- **Proposition** : s'assurer que les cibles tactiles font ≥ 44 px, et que le
  contraste des couleurs de catégories sur fond sombre/clair respecte les WCAG AA.

### 🟠 S — Semantics
- **Proposition** : ajouter des `Semantics`/`Tooltip` sur les icônes (étoile,
  menu, suppression) pour les lecteurs d'écran.

---

## 6. Cohérence du thème sombre

- 🟠 **S** — Vérifier que toutes les couleurs codées en dur (`Colors.orange`,
  `Colors.blue`, etc. dans `confirm.dart`, `info.dart`) passent par le thème ou
  restent lisibles en mode sombre.

> La **feuille de route** ([`06-roadmap.md`](./06-roadmap.md)) ordonne ces actions.

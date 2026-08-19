# 04 — Plan d'amélioration architecture & qualité du code

Objectif : consolider les fondations techniques (modèle, état, persistance) pour
supporter sereinement les futures fonctionnalités.

Priorités : 🔴 haute / 🟠 moyenne / 🟢 basse — Effort : S / M / L.

---

## 1. Modèle de données

### 🔴 M — Rendre `Note` immuable et non nullable
- **Constat** : tous les champs sont nullables (`String?`, `bool?`), ce qui force
  des `?? ''`, `?? false` et des `note.date!` à risque.
- **Proposition** :
  ```dart
  class Note {
    final String id;
    final String title;
    final String content;
    final DateTime date;      // ou String ISO, mais typé DateTime
    final bool important;
    final String category;
    final DateTime? updatedAt; // optionnel, pour le tri "modifié"

    const Note({required this.id, required this.title, ...});

    Note copyWith({...}) => ...;
    Map<String, dynamic> toJson() => ...;
    factory Note.fromJson(Map<String, dynamic> json) => ...;
  }
  ```
- **Impact** : nettoyage des `!` et `??` dans les ViewModels et pages ; suppression
  du risque de crash dans `_sortNotes`.
- **Bénéfice** : code plus sûr, plus simple, moins de branches.

### 🔴 S — Remplacer `NoteAction` par un enum
- **Constat** : `NoteAction.action` est une `String` (`'Save'`/`'Delete'`/`'Cancel'`).
- **Proposition** :
  ```dart
  enum NoteActionKind { save, delete, cancel }

  class NoteAction {
    final NoteActionKind kind;
    final Note? note;
    const NoteAction({required this.kind, this.note});
  }
  ```
- **Impact** : `switch` exhaustifs, plus de valeurs magiques.
- **Bénéfice** : robustesse, lisibilité.

### 🟠 S — Retirer la classe `Database`
- **Constat** : `Database` enveloppe inutilement une `List<Note>`.
- **Proposition** : `NotesRepository` manipule directement `List<Note>` ;
  le codec JSON devient une simple fonction `encodeNotes(List<Note>)`/`decodeNotes(String)`.
- **Bénéfice** : moins de couches, moins de code à maintenir.

---

## 2. State management

### 🔴 S — Rendre la langue réactive
- **Constat** : `LocaleController` n'étend pas `ChangeNotifier` ; changer la langue
  ne rebuild pas immédiatement l'UI.
- **Proposition** : faire de `LocaleController` un `ChangeNotifier`, émettre
  `notifyListeners()` dans `setLanguage`, et envelopper `MaterialApp` dans un
  `ListenableBuilder` (comme `ThemeController`).
- **Bénéfice** : changement de langue instantané et fiable.

### 🟠 M — Injection des singletons
- **Constat** : `ThemeController.instance` / `LocaleController.instance` sont
  accédés globalement.
- **Proposition** : les passer en dépendances via le constructeur de `Tano`
  (déjà amorcé avec `repository` et `themeMode`), ou utiliser un `InheritedWidget`
  / provider léger. Conserver les singletons comme valeur par défaut pour la
  rétrocompatibilité.
- **Bénéfice** : tests isolés, moins d'état global partagé.

### 🟢 S — Extraire la logique de tri dans un comparateur réutilisable
- **Constat** : le tri est dupliqué (`HomeViewModel._sortNotes` et
  `SearchViewModel.load`).
- **Proposition** : une fonction `sortNotes(List<Note>, String sortBy, {bool ascending})`.

---

## 3. Découpage des widgets

### 🔴 M — Découper `home_page.dart` (979 lignes)
- **Proposition** : extraire des widgets dédiés dans `features/notes/widgets/` :
  - `NoteListLayout`, `NoteCompactLayout`, `NoteGridLayout` (ou un `NoteCard` commun) ;
  - `HomeAppBar` (titre, boutons) ;
  - `SelectionAppBar` / `HomeBottomBar` ;
  - `NoteSearchEntry`.
- **Bénéfice** : fichiers lisibles, testables individuellement, réutilisables.

### 🟠 S — Factoriser `_showActionButtons`
- **Constat** : méthode dupliquée entre `home_page.dart` et `edit_note_page.dart`.
- **Proposition** : déplacer dans un widget partagé `ActionButtonsBar` (shared/widgets).
- **Bénéfice** : DRY.

### 🟠 S — `menu.dart` : maps statiques
- **Constat** : les getters `menuItems`/`categoryElements` reconstruisent les maps
  à chaque accès.
- **Proposition** : les définir en `static const`/`final` (attention aux `Icon`
  non-const) ou en `late final` figé, et construire une fois la liste des entrées.

---

## 4. Persistance : migration vers SQLite (Drift)

La décision a été prise de **remplacer le JSON monofichier par SQLite (Drift)**,
prérequis des entités relationnelles (dossiers, projets, tickets, checklists,
pièces jointes) et de la synchronisation. Voir
[`07-architecture-cible.md`](./07-architecture-cible.md).

### 🔴 M — Intégrer Drift + schéma v1
- **Proposition** : ajouter `drift` (+ `drift_flutter`), définir les tables
  (folders, notes, projects, tickets, checklist_items, attachments, memberships,
  sync_log), les index et les migrations.
- **Bénéfice** : type-safe, réactif (streams), transactions, prêt pour la sync.

### 🔴 M — Migration des données JSON existantes
- **Proposition** : au premier lancement, lire `local_persistence.json`, insérer
  les notes dans Drift (UUID, `important`, `category` conservés), puis renommer
  l'ancien fichier en `.bak` (sans le supprimer).
- **Bénéfice** : aucune perte de données, retour arrière possible.

### 🔴 S — Remplacer `FileNotesRepository`
- **Proposition** : `DatabaseRepository` + repositories par entité (notes,
  projets, dossiers…), derrière des abstractions testables ; les ViewModels purs
  Dart restent inchangés dans leur principe.
- **Bénéfice** : même pattern MVVM, nouveau stockage.

### 🟠 S — UUID globaux
- **Constat** : `Random().nextInt(999999)` génère des ids à collision possible.
- **Proposition** : générer des **UUID v4** (`uuid`), indispensables pour la
  fusion entre pairs.
- **Bénéfice** : unicité globale, prépare la sync.

### 🟠 S — Gestion d'erreur explicite
- **Constat** : `loadNotes()` avale les erreurs et retourne `[]`.
- **Proposition** : lever une exception typée et afficher un message localisé ;
  ne jamais confondre "vide" et "erreur".

---

## 5. Recherche

### 🟠 S — Optimiser la recherche
- **Constat** : `RegExp(keyword, caseSensitive: false)` créé à chaque note, et
  `note.title!.contains` sans null-check.
- **Proposition** : précompiler le motif ou utiliser `toLowerCase().contains` ;
  nettoyer les null-checks une fois `Note` non nullable.

---

## 6. Thème

### 🟠 S — Centraliser les couleurs
- **Proposition** : regrouper les couleurs (catégories, barres, éditeur) dans un
  seul endroit (`shared/widgets/theme.dart` ou une `ThemeExtension`) et les dériver
  du `ColorScheme` plutôt que de `Colors.*` codés en dur.

> Ces fondations sont un **prérequis** à de nombreuses fonctionnalités du plan
> [`03-plan-fonctionnalites.md`](./03-plan-fonctionnalites.md) ; le détail
> technique (schéma, synchronisation, chiffrement) est dans
> [`07-architecture-cible.md`](./07-architecture-cible.md).

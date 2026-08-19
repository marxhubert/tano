# 05 — Plan tests & qualité

Objectif : renforcer la confiance dans le code, prévenir les régressions et
automatiser la qualité.

L'application possède déjà une **bonne base de tests unitaires**. Ce plan vise à
combler les manques identifiés.

---

## 1. Tests unitaires (ViewModels & modèles)

### 🟠 S — Tester les cas limites des ViewModels
- `HomeViewModel` : tri par favoris, tri par catégorie, `toggleFavorite` sur un
  index hors bornes, `selectAll`/`clearSelection`, suppression avec liste vide.
- `EditNoteViewModel` : `isValid` avec contenu vide, `isDirty` sur changement de
  titre uniquement, génération d'id unique.
- `SearchViewModel` : requête avec espaces, accents, casse, note sans titre.

### 🟠 S — Tester le nouveau modèle `Note` immuable
- `copyWith`, sérialisation/désérialisation des nouveaux champs (`updatedAt`),
  valeur par défaut de `category`.

---

## 2. Tests du repository fichier (intégration)

### 🔴 M — Test d'intégration de `FileNotesRepository`
- **Constat** : aucun test n'exerce la lecture/écriture réelle sur disque.
- **Proposition** : injecter un répertoire temporaire (`Directory.systemTemp`)
  et vérifier :
  - la création du fichier au premier `loadNotes()` (seeding des fixtures) ;
  - la persistance puis la relecture (`saveNotes` → `loadNotes`) ;
  - l'écriture atomique (pas de fichier partiel) ;
  - la lecture d'un fichier corrompu (erreur explicite, pas de crash).
- **Bénéfice** : couvre le chemin de persistance réel, le plus critique.

---

## 3. Tests de widgets et golden tests

### 🟠 M — Golden tests
- **Proposition** : capturer les 3 layouts (liste/compact/grille), le mode sombre,
  l'écran vide et l'éditeur, avec `golden_toolkit` ou `matchesGoldenFile`.
- **Bénéfice** : détecte les régressions visuelles.

### 🟠 S — Tests de la réactivité de la langue et du thème
- **Proposition** : vérifier que le changement de langue rebuild l'UI
  (après refactor de `LocaleController` en `ChangeNotifier`).

---

## 4. Isolation et état global

### 🟠 M — Réinitialiser les singletons entre tests
- **Constat** : `ThemeController.instance` / `LocaleController.instance` gardent
  leur état entre les tests.
- **Proposition** : ajouter une méthode `reset()` ou injecter des instances neuves
  dans `Tano` (voir plan architecture). À défaut, un `tearDown` qui restaure
  l'état par défaut.

---

## 5. Automatisation de la qualité

### 🟠 S — CI (GitHub Actions)
- **Proposition** : pipeline qui exécute `flutter analyze` + `flutter test` à
  chaque PR, et `flutter build apk`/`build ios --no-codesign` pour valider la
  compilation.
- **Bénéfice** : détection précoce des régressions.

### 🟠 S — Règles d'analyse plus strictes
- **Proposition** : activer des lints supplémentaires dans `analysis_options.yaml`
  (`unawaited_futures`, `prefer_const_constructors`, `require_trailing_commas`)
  et traiter les warnings.
- **Bénéfice** : code plus homogène.

### 🟢 S — `dart format` en pre-commit
- **Proposition** : ajouter un hook de formatage automatique.

---

## 6. Indicateurs de qualité cibles

| Indicateur | Cible |
|---|---|
| Couverture des ViewModels | ≥ 90 % |
| Couverture du repository | ≥ 80 % |
| `flutter analyze` | 0 erreur, 0 warning |
| Tests verts en CI | requis avant merge |

> Ces actions s'appuient sur les refactorings du plan
> [`04-plan-architecture-code.md`](./04-plan-architecture-code.md) (modèle `Note`
> immuable, enums, singletons injectables).

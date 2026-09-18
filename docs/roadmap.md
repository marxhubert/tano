# Feuille de route

> **Plan vivant.** Où en est TanoNote, ce qui vient ensuite et dans quel ordre.
> Les idées non planifiées vivent dans [backlog.md](./backlog.md).

TanoNote : **notes, tâches et projets**, 100 % hors-ligne, chiffré au repos.

## État actuel

- Cœur **note + dossiers** stable : cartes unifiées (`EntityCard`), listes
  (`EntitySliver`), sélection (`SelectionController`), corbeille, verrou
  biométrie, couvertures, pièces jointes, checklist basique.
- Persistance **SQLite chiffrée** (`sqflite_sqlcipher`, schéma v7) ; export /
  import `.tano` chiffré (AES-GCM, PBKDF2).
- FAB refondu (zones, menus de 2nd degré, couleur partagée), accessibilité
  (libellés sur toutes les actions-icônes), DI via `getIt`.
- `flutter analyze` 0 issue, **294 tests** verts (dont 20 goldens, joués en
  local), CI `analyze` + `test` + un build de débogage des deux cibles.
- **Premier lancement** : une introduction de 3 écrans, rejouable depuis
  À propos, sur une base **vide** (plus de données de démonstration).
- **Suppression** : une annulation unique pour la note comme pour le dossier.
- Chantier de **refactoring du cœur terminé** (cartes, slivers, sélection,
  dialogues, couvertures, FAB, nettoyage, accessibilité).

## 1. Livraison store *(bloquant)*

- [x] **Permissions iOS** : `NSFaceIDUsageDescription` en place. Ni
  photothèque ni caméra nécessaires — PHPicker, vérifié dans le paquet.
  Voir [confidentialité](./confidentialite.md).
- [x] **Confidentialité in-app** : politique FR / EN / MG (`PrivacyPage`),
  accessible depuis À propos. Voir [confidentialité](./confidentialite.md).
- [x] **Manifeste de confidentialité** : `ios/Runner/PrivacyInfo.xcprivacy`,
  déclaré et câblé dans la cible Runner.
- [ ] **Fiches store** : la page de politique est prête à publier
  (`site/privacy/`, GitHub Pages) et tous les textes à coller sont dans
  [store-listing.md](./store-listing.md) — il reste à les saisir dans les deux
  consoles.
- [x] **Rapports de crash** : Sentry derrière le consentement, sans IP ni
  identifiant stable, zéro breadcrumb (voir
  [observabilité](./observabilite.md)).
- [x] **Mises à jour** : store-native (Play In-App Updates + lookup App Store),
  entrée « Vérifier les mises à jour » dans À propos. Voir
  [observabilité](./observabilite.md).
- [x] **Release, la préparation** : `CHANGELOG.md` en place, version passée en
  `0.9.0-beta`, et la signature Android branchée sur un keystore qui vit hors du
  dépôt. La recette complète est dans [livraison](./livraison.md).
- [ ] **Release, le jour J** : tag `v0.9.0-beta`, build signé Play / App Store.
- [x] **CI** : job de *build* — `flutter build apk --debug` sur Ubuntu et
  `flutter build ios --debug --no-codesign` sur macOS.
- [x] **README racine** : SQLite chiffré, `core/features/shared`, dossiers,
  verrou, export, couvertures, plus une entrée vers `docs/`.

## 2. Qualité

- [x] **Golden tests** des cartes (grille/liste, thèmes, états) —
  `test/golden/`, vingt images, hors CI. Voir [tests](./tests.md).
- [ ] Étendre les **tests d'intégration** (dossiers, export/import, verrou).
- [ ] **Logs** silencieux en release ; erreurs utilisateur uniformisées.

## 3. UX grand public

- [x] **Onboarding** : trois écrans au premier lancement, rejouables depuis
  À propos. La base démarre vide.
- [x] **Undo uniformisé** : une seule annulation, partagée par l'accueil et le
  dossier.
- [x] **Feedback** sur déplacement / verrouillage : un avis court après
  l'action. Android garde son SnackBar, iOS a un toast qui s'efface seul.
- [x] **Réglages** : quatre tailles de texte (appliquées par-dessus l'échelle du
  système) et deux interrupteurs, retour haptique et son.
- [ ] **Recherche** : historique + filtres (catégorie, favori, dates).

## 4. Cœur produit

- [ ] **Checklist avancée** (réordonnable, liée à une note ou un ticket).
- [ ] **Projets / Kanban** (colonnes, drag & drop, statut/ordre).

## 5. Collaboration *(plus tard)*

- [ ] **Dossiers hiérarchiques** (arborescence, `parent_id`).
- [ ] **Synchronisation P2P** temps réel, chiffrée de bout en bout.

> Le **prototype de synchronisation** doit être validé **avant** de construire
> le Kanban, pour éviter une refonte coûteuse. Détails techniques :
> [architecture.md](./architecture.md).

## Ordre recommandé

`1 → 2 → 3 → 4`, puis `5`. Chaque étape livre de la valeur seule ; la
livraison store (1) est le prérequis à toute diffusion.

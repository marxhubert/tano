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
- `flutter analyze` 0 issue, **300 tests** verts (dont 20 goldens, joués en
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
- [x] **Fiches store** : tout est prêt (page de politique dans `site/privacy/`,
  textes dans [store-listing.md](./store-listing.md)). La saisie dans les deux
  consoles se fera le moment venu, à la demande.
- [x] **Rapports de crash** : Sentry derrière le consentement, sans IP ni
  identifiant, zéro breadcrumb (voir
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
- [x] Étendre les **tests d'intégration** (dossiers, export/import, verrou) :
  cinq scénarios sur appareil, dont l'aller-retour `.tano` sur **deux bases
  chiffrées réelles**.
- [x] **Logs** silencieux en release (`appLog` derrière `kDebugMode`, plus aucun
  `debugPrint` qui traîne) ; erreurs utilisateur uniformisées.

## 3. UX grand public

- [x] **Onboarding** : trois écrans au premier lancement, rejouables depuis
  À propos. La base démarre vide.
- [x] **Undo uniformisé** : une seule annulation, partagée par l'accueil et le
  dossier.
- [x] **Feedback** sur déplacement / verrouillage : un avis court après
  l'action. Android garde son SnackBar, iOS a un toast qui s'efface seul.
- [x] **Réglages** : quatre tailles de texte (appliquées par-dessus l'échelle du
  système) et deux interrupteurs, retour haptique et son.
- [x] **Recherche** : l'historique des requêtes récentes, proposé quand le
  champ est vide, effaçable d'un geste. Les filtres (catégorie, favori, dates)
  sont écartés pour l'instant.

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

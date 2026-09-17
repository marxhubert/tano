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
- `flutter analyze` 0 issue, **~250 tests** verts, CI `analyze` + `test`.
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
- [ ] **Fiches store** : politique de confidentialité App Store, « Data
  safety » Play. Contenu simple mais **obligatoire** ; le texte est prêt dans
  [confidentialité](./confidentialite.md).
- [x] **Rapports de crash** : Sentry derrière le consentement, sans IP ni
  identifiant stable, zéro breadcrumb (voir
  [observabilité](./observabilite.md)).
- [ ] **Mises à jour** : store-native (Play In-App Updates + lookup App Store).
- [ ] **Release** : CHANGELOG, bump de version, tag, build signé Play / App Store.
- [ ] **CI** : job de *build* (`build apk` / `build ios --no-codesign`).
- [ ] **README racine** : à réécrire (SQLite chiffré, `core/features/shared`,
  dossiers, verrou, export, couvertures).

## 2. Qualité

- [ ] **Golden tests** des cartes (grille/liste, thèmes, états).
- [ ] Étendre les **tests d'intégration** (dossiers, export/import, verrou).
- [ ] **Logs** silencieux en release ; erreurs utilisateur uniformisées.

## 3. UX grand public

- [ ] **Onboarding** (2-3 écrans, ou état vide pédagogique).
- [ ] **Undo uniformisé** (le dossier n'a pas l'undo de l'accueil).
- [ ] **Feedback** sur déplacement / verrouillage.
- [ ] **Réglages** : taille de texte, retour haptique / son.
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

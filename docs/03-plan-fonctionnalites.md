# 03 — Plan d'amélioration des fonctionnalités

Objectif : enrichir l'application de fonctionnalités à forte valeur, en restant
fidèle à la promesse "notes, tâches et projets", **100 % hors-ligne**.

Priorités : 🔴 haute / 🟠 moyenne / 🟢 basse — Effort : S / M / L.

---

## 1. Sécurité des données utilisateur

### 🔴 M — Annulation de suppression (Undo)
- **Constat** : suppression définitive, sans retour.
- **Proposition** : conserver la note supprimée en mémoire (et/ou dans le ViewModel)
  pendant quelques secondes, afficher une `SnackBar` **"Annuler"** qui la restaure.
- **Implémentation suggérée** : `HomeViewModel.removeNote()` retourne l'index et
  la note supprimée ; un `undoRemoveNote(index, note)` la réinsère à la bonne place.
- **Bénéfice** : évite les pertes accidentelles.

### 🟠 M — Corbeille / Archive
- **Proposition** : ajouter un état `deleted`/`archived` sur la note au lieu de la
  supprimer physiquement, avec un écran "Corbeille" et une purge automatique.
- **Bénéfice** : récupération possible, sérénité.

---

## 2. Organisation des notes

### 🔴 M — Catégories / tags personnalisés
- **Constat** : 7 catégories fixes, non personnalisables.
- **Proposition** : permettre la création, le renommage et la suppression de
  catégories (avec une couleur au choix). Migrer la valeur `category` (String)
  vers un identifiant de catégorie stable, tout en gardant les catégories par
  défaut pour la rétrocompatibilité.
- **Bénéfice** : répond au besoin réel d'organisation, différencie l'app.

### 🟠 S — Duplication de note
- **Proposition** : action "Dupliquer" dans l'éditeur ou par appui long.
- **Bénéfice** : gain de temps pour les modèles de notes récurrentes.

### 🟠 S — Tri croissant / décroissant
- **Constat** : les tris sont fixes (date décroissante, titre croissant).
- **Proposition** : ajouter un toggle d'ordre (ascendant/descendant) persistant.
- **Bénéfice** : contrôle total sur l'affichage.

### 🟢 S — Tri "récemment modifié"
- **Proposition** : ajouter un champ `updatedAt` et un tri correspondant.

---

## 3. Recherche

### 🟠 S — Recherche sur la page d'accueil
- **Proposition** : filtre inline de la liste sans ouvrir une page dédiée
  (réutiliser la logique de `SearchViewModel`).
- **Bénéfice** : fluidité, moins de navigation.

### 🟢 S — Recherche avancée
- **Proposition** : filtres par catégorie, par favori, ou par plage de dates dans
  la page de recherche.

---

## 4. Sauvegarde et partage

### 🔴 M — Export / Import JSON
- **Constat** : aucune sauvegarde possible ; les données sont piégées sur l'appareil.
- **Proposition** : boutons **Exporter** (écrire le JSON dans un emplacement
  partageable via `share_plus`) et **Importer** (lire un JSON et valider avant de
  fusionner/remplacer).
- **Bénéfice** : portabilité, sauvegarde manuelle, confiance utilisateur.

### 🟢 L — Sauvegarde automatique optionnelle
- **Proposition** : option de sauvegarde vers le cloud (iCloud/Drive) ou export
  planifié — hors périmètre initial, à évaluer.

---

## 5. Tâches, projets et collaboration

Ces fonctionnalités constituent le nouveau périmètre « notes, tâches et projets »
et reposent sur l'architecture décrite dans [`07-architecture-cible.md`](./07-architecture-cible.md).

### 🟠 M — Checklist liée aux notes et aux tickets
- **Proposition** : cases à cocher attachées à une note **ou** à un ticket
  (table `checklist_items`), réordonnables, synchronisées.
- **Bénéfice** : aligne le produit sur sa promesse « tasks ».

### 🔴 M — Projets / tickets Kanban (type Trello)
- **Proposition** : un projet contient des **tickets** organisés en colonnes
  (backlog/todo/doing/done), avec drag & drop, statut et ordre dans la colonne.
  Un ticket peut contenir des notes, des checklists et des pièces jointes.
- **Bénéfice** : différenciant majeur, gestion de projet visuelle.

### 🔴 M — Dossiers hiérarchiques (type Notes d'Apple)
- **Proposition** : arborescence de dossiers (`parent_id`), notes/tâches/projets
  organisés dedans, partage possible par dossier.
- **Bénéfice** : organisation naturelle, prépare le partage.

### 🟠 M — Pièces jointes (images, PDF, docx)
- **Proposition** : attacher des fichiers binaires aux notes et tickets, stockés
  hors base, dédupliqués par hash, synchronisés.
- **Bénéfice** : complète la prise de notes.

### 🔴 L — Collaboration temps réel pair-à-pair (internet)
- **Proposition** : projets et dossiers **partagés** synchronisés en temps réel
  entre collaborateurs (France ↔ Japon) via maillage WebRTC, **sans serveur
  central de données** (signalisation aveugle + chiffrement E2E).
- **Bénéfice** : expérience type Trello, souveraineté des données.

---

## 6. Sécurité et confidentialité

### 🔴 M — Chiffrement de bout en bout pour la collaboration
- **Proposition** : identités Ed25519, clés de salon AES-GCM, enveloppes de clés
  par membre (voir `07` §7). Le serveur de signalisation ne voit rien.
- **Bénéfice** : collaboration sans compromettre la confidentialité.

### 🟠 M — Verrouillage local (code/PIN ou biométrie)
- **Proposition** : option de chiffrement du stockage au repos
  (`flutter_secure_storage` pour la clé + AES), optionnelle.
- **Bénéfice** : sécurité des données locales.

### 🟢 S — Suppression du `debugPrint` en production
- **Proposition** : remplacer par un logger silencieux en release (`kDebugMode`).

---

## 7. Compatibilité et plateformes

### 🟢 M — Cible Desktop / Web (optionnel)
- **Constat** : le projet est configuré Android/iOS uniquement ; Drift et
  `flutter_webrtc` supportent desktop et web.
- **Proposition** : évaluer `flutter create --platforms=macos,linux,windows,web`
  (utile pour tester la sync en local).
- **Bénéfice** : portée élargie, débug facilité.

> Voir [`07-architecture-cible.md`](./07-architecture-cible.md) pour le détail
> technique, et [`04-plan-architecture-code.md`](./04-plan-architecture-code.md)
> pour les fondations (migration Drift, modèle enrichi).

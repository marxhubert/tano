# Backlog

> Idées et propositions **non planifiées**. Une fois retenues, elles montent
> dans [roadmap.md](./roadmap.md). Rien ici n'engage une date ni un effort.

## Produit

- **Catégories / tags personnalisables** (aujourd'hui 10 pastels fixes).
- **Duplication de note** (modèles récurrents).
- **Sélecteur de date** : rétro-dater une note.
- **Barre d'outils d'édition** : gras, italique, listes.
- **Corbeille** : purge configurable (30 jours aujourd'hui).
- **Sauvegarde automatique** : cloud (iCloud/Drive) ou export planifié.

## UX

- **Aperçu du contenu** en mode liste.
- **Grille responsive** : largeur max par tuile (tablettes / grands écrans).
- **Animations de transition** : layout (`AnimatedSwitcher`), ajout/suppression.
- **États vides et erreurs** plus guidants.
- **Couleurs codées en dur** : auditer leur lisibilité en thème sombre.

## Technique

- **Recherche** : requête SQL + index.
- **`menu.dart`** : remplacer les maps statiques par un modèle typé.
- **Erreurs de chargement** explicites et localisées.
- **Lints plus strictes** (`unawaited_futures`, `prefer_const_constructors`…) +
  `dart format` en pre-commit.
- **Cibles desktop / web** (utile pour tester la synchronisation en local).

## À trancher

- **À propos** : « Premium » (implémenter ou masquer). La vérification de mise
  à jour est planifiée : voir [observabilité](./observabilite.md).
- **Accueil** : comportement quand aucune sélection n'est active.
- **Branche `develop`** : supprimer ou resynchroniser sur `master`.

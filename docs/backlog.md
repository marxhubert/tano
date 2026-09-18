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
- **Tutoriel au lancement** : au-delà des trois écrans d'introduction, un guide
  pratique des gestes et de la création de la première note. À mettre en place
  le moment venu, une fois la première note créée depuis un accueil vide.
- **Couleurs codées en dur** : auditer leur lisibilité en thème sombre.

## Technique

- **Recherche** : requête SQL + index.
- **`menu.dart`** : remplacer les maps statiques par un modèle typé.
- **Erreurs de chargement** explicites et localisées.
- **Lints plus strictes** (`unawaited_futures`, `prefer_const_constructors`…) +
  `dart format` en pre-commit.
- **Kotlin Gradle Plugin** : `sentry_flutter` et `shared_preferences_android`
  l'appliquent encore ; Flutter annonce que le build échouera quand il passera
  au Kotlin intégré. Même famille que le point SPM ci-dessous : à surveiller aux
  upgrades, monter les paquets.
- **Swift Package Manager** : `open_filex` et `sqflite_sqlcipher` ne le
  supportent pas encore ; Flutter les fait passer par CocoaPods et prévient que
  l'avertissement deviendra une **erreur**. Rien à faire tant que ça reste un
  avertissement. À l'upgrade Flutter qui le durcira, dans cet ordre : monter
  les deux paquets, sinon couper SPM (`flutter config
  --no-enable-swift-package-manager`) — et retirer alors `ios/**/Package.resolved`
  du suivi, qui perdrait son sens.
- **Cibles desktop / web** (utile pour tester la synchronisation en local).

## À trancher

- **À propos** : « Premium » (implémenter ou masquer). La vérification de mise
  à jour, elle, est en place : voir [observabilité](./observabilite.md).
- **Accueil** : comportement quand aucune sélection n'est active.
- **Branche `develop`** : supprimer ou resynchroniser sur `master`.

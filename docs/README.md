# 📚 Documentation — Plans d'amélioration de TanoNote

Ce dossier regroupe l'analyse complète de l'application **TanoNote** et les plans
d'amélioration proposés, organisés par catégorie.

> ⚠️ Ces documents sont des **propositions** : rien n'est implémenté tant qu'une
> décision n'a pas été validée. Ils servent de base de discussion et de feuille
> de route.

## Contenu du dossier

| Fichier | Contenu |
|---|---|
| [`01-analyse-etat-actuel.md`](./01-analyse-etat-actuel.md) | Analyse complète : architecture, ce qui fonctionne bien, les problèmes constatés. |
| [`02-plan-ui-ux.md`](./02-plan-ui-ux.md) | Améliorations **UI/UX** : design, navigation, accessibilité, ergonomie. |
| [`03-plan-fonctionnalites.md`](./03-plan-fonctionnalites.md) | Nouvelles **fonctionnalités** métier : catégories personnalisées, undo, export, recherche, etc. |
| [`04-plan-architecture-code.md`](./04-plan-architecture-code.md) | Améliorations **architecture & qualité du code** : modèle, state management, persistance. |
| [`05-plan-tests-qualite.md`](./05-plan-tests-qualite.md) | Plan **tests & qualité** : couverture, intégration, automatisation. |
| [`06-roadmap.md`](./06-roadmap.md) | **Feuille de route** priorisée par phases. |
| [`07-architecture-cible.md`](./07-architecture-cible.md) | **Architecture cible** : stockage SQLite/Drift, synchronisation P2P WebRTC, chiffrement E2E. |

## Résumé exécutif

**TanoNote** est une application de notes Flutter, rapide, légère et 100 % hors-ligne
(Android/iOS). Son architecture en *vertical slices* avec ViewModels purs Dart, son
repository abstrait et ses tests unitaires constituent une excellente base.

**Évolution stratégique validée** : TanoNote s'oriente vers un gestionnaire
« notes, tâches et projets » avec dossiers, checklists, Kanban (tickets) et
pièces jointes, ainsi qu'une **collaboration temps réel pair-à-pair via internet**
(sans serveur central de données). Cela implique le passage du JSON monofichier à
**SQLite (Drift)** — voir [`07-architecture-cible.md`](./07-architecture-cible.md).

Les principaux axes d'amélioration sont :

1. **UI/UX** — moderniser l'interface (coins arrondis, typographie système,
   animations, vrais champs de recherche, barre d'outils d'édition), rendre la
   langue réactive, améliorer l'accessibilité.
2. **Fonctionnalités** — dossiers hiérarchiques, checklist, projets Kanban,
   pièces jointes, export/import chiffré, collaboration P2P temps réel.
3. **Architecture / code** — migration SQLite/Drift, modèle `Note` enrichi,
   enums, découpage de `home_page.dart`, UUID, chiffrement E2E.
4. **Tests / qualité** — tests d'intégration (Drift, sync, export), golden tests,
   CI, singletons isolés.

La **feuille de route** ([`06-roadmap.md`](./06-roadmap.md)) classe ces actions par
phases et par effort afin de permettre une implémentation incrémentale.

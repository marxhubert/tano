# Modularité et services

> Principe transversal : un **squelette de base** stable, et des **services** qui
> viennent s'y greffer selon des paramètres et des contextes (gratuit/premium,
> livraison partielle, configuration).
> Complément : [composants](./composants.md).

## 1. Objectif

- Pouvoir **décider de livrer ou non** un élément ou une fonctionnalité, et que
  **tout le reste continue de fonctionner**.
- Séparer les services selon le **plan** (gratuit / premium) : sur une version
  gratuite, certaines fonctionnalités sont absentes.
- Faciliter les **mises à jour** (à confirmer) : greffer un service sans toucher
  au squelette.

## 2. Principe

Le squelette ne **connaît pas** les services. Il expose des **points d'extension**
que les services remplissent.

| Point d'extension | Contenu |
|---|---|
| Routes | Pages ajoutées par un service |
| Actions du FAB | Actions disponibles selon les services actifs |
| Actions d'AppBar | Actions contextuelles |
| Sections de réglages | Options apportées par un service |
| Templates de card | Un template par type d'élément |
| Menus | Entrées de menu contextuelles |
| Tâches de démarrage | Initialisation d'un service |

## 3. Fonctionnalité et service

```dart
enum TanoFeature {
  folders,
  covers,
  attachments,
  lock,
  search,
  export,
  task,
  project,
  // ...
}

class FeatureFlags {
  const FeatureFlags(this.enabled);

  final Set<TanoFeature> enabled;

  bool isEnabled(TanoFeature feature) => enabled.contains(feature);
}
```

Un service déclare son identité et ses contributions :

```dart
abstract class FeatureService {
  TanoFeature get id;
  String get labelKey;
  IconData get icon;

  List<Route<dynamic>> routes(FeatureContext context);
  List<FabAction> fabActions(FeatureContext context);
  List<AppBarAction> appBarActions(FeatureContext context);
  List<SectionContribution> settings(FeatureContext context);
  EntityCardTemplate? cardTemplate(EntityKind kind);
}
```

## 4. Résolution

- Un `FeatureRegistry` agrège les services **activés** par la politique courante.
- Les écrans (AppBar, FAB, Page, Réglages) interrogent le registre et ne listent
  **jamais** une fonctionnalité en dur.
- Une fonctionnalité désactivée : ses **points d'entrée disparaissent** (routes,
  actions, sections), mais **les données restent intactes**.

## 5. Implications sur la refonte

- Le **FAB** construit ses actions depuis le registre (au plus 3 + réduire).
- L'**AppBar** construit ses actions depuis le registre.
- Les **réglages** construisent leurs sections depuis le registre.
- Les **cards** reçoivent un template ; le template « verrouillé » est commun.
- Les **routes** sont déclarées par les services, plus en dur dans `main.dart`.

## 6. Gratuit / premium

- Aucune solution arrêtée : on prépare seulement le **point d'injection**.
- Un service déclare éventuellement le **plan minimal** qui l'inclut ; le registre
  filtre selon le plan courant.
- Le plan est **une politique** parmi d'autres : on pourra le brancher sur un achat
  intégré, un build flavor ou une configuration distante.

## 7. Tests

- L'app **démarre et fonctionne** avec **chaque** fonctionnalité désactivée.
- Un test paramétré vérifie qu'un service désactivé n'expose ni route, ni action,
  ni section.

## 8. Hors périmètre (pour l'instant)

- L'implémentation réelle du paiement / achat intégré.
- La configuration distante.

# Observabilité et confidentialité

> **Plan.** Ce que l'app envoie — ou pas — vers l'extérieur : rapports de crash
> et vérification des mises à jour. Les décisions produit y sont actées.

## Décisions

- **Pas de feedback in-app** : les avis et notes des stores suffisent, surtout
  pour les premiers clients.
- **Rapports de crash via Sentry**, **sans IP ni identifiant stable**, et
  **rien n'est envoyé sans le consentement** de l'utilisateur.
- **Mises à jour natives aux stores** : aucune infrastructure à maintenir.
- **Aucune collecte « premier lancement »** : Sentry porte déjà le contexte
  technique (appareil, OS, app, version).
- **Zéro breadcrumb** : seuls l'erreur, la pile, l'appareil et la version
  partent. Pas de fil de navigation, donc rien à expurger.

## État actuel

Le nettoyage est fait : plus de feedback, plus d'analytics, plus d'écran
« mise à jour » factice.

- supprimés : `feedback_page`, `update_page`, `analytics_service`,
  leurs tests, les clés l10n `option_feedback` / `option_check_update`, et la
  dépendance `device_info_plus` ;
- conservé comme **porte de consentement** : `option_bug_report`,
  `desc_bug_report` et `bugReportEnabled` ;
- l'écran À propos affiche désormais la **vraie version** (lue depuis le
  package) au lieu d'un « Version 1.0 » codé en dur.

## Étape 1 — Sentry derrière le consentement — **faite**

Le principe : **l'interrupteur est la seule porte**. Tant qu'il est faux, Sentry
n'est pas initialisé et rien ne quitte l'appareil.

- `lib/core/services/crash_reports.dart` porte tout : `hasConsent()`,
  `start()`, `stop()`, `apply(bool)` et `scrub` ;
- `main()` lit le consentement **avant** `runApp` et n'initialise le SDK que
  s'il est vrai — sinon l'app démarre sans Sentry du tout ;
- l'interrupteur **persiste** son état (`bugReportEnabled`, chiffré comme le
  reste des préférences) puis appelle `apply` : le couper ferme le SDK
  immédiatement (`Sentry.close()`), et l'activer l'initialise ;
- une réinitialisation des préférences **révoque** le consentement, puisque la
  clé disparaît avec elles ;
- configuration anonyme :
  - `sendDefaultPii: false` ;
  - `maxBreadcrumbs: 0` **et** un `beforeBreadcrumb` qui jette tout ;
  - `tracesSampleRate`, `enableLogs`, replay (`sessionSampleRate` et
    `onErrorSampleRate` à 0), `attachScreenshot`, breadcrumbs natifs,
    `enableWatchdogTerminationTracking` et `enableAppHangTracking` coupés ;
  - `beforeSend` = `CrashReports.scrub`, qui efface `user`, `request` et
    `breadcrumbs` de **chaque** événement : même un `setUser` ajouté par
    erreur ne sortirait pas ;
  - **IP non stockée** : réglage projet Sentry « Prevent Storing of IP
    Addresses » — un réglage de console, pas de code ;
  - **jamais** de `setUser`, ni d'identifiant d'installation ajouté à la main.
- le DSN vit dans `AppConfig.sentryDsn`, surchargeable au build par
  `--dart-define=SENTRY_DSN=…` ; ce n'est pas un secret, seulement une clé en
  écriture seule. Il a été **vérifié** : un événement de test a été accepté
  (HTTP 200) ;
- `release` = `tano@<version>` et `dist` = numéro de build, la forme que le
  plugin dart calcule de son côté pour retrouver les symboles.

### Câblage du plugin

`sentry_dart_plugin` est en dev dependency : il n'envoie les symboles de debug
que sur un build release, et il lui faut `SENTRY_AUTH_TOKEN` — ou
`sentry.properties`, **ignoré par git**, à ne jamais commiter. Sans ce jeton le
build échoue : à poser en secret CI le jour du job de build.
`upload_source_maps` est passé à `false`, c'est un artefact web et l'app vise
Android et iOS.

## Étape 2 — Politique de confidentialité in-app — **faite**

Pas de domaine pour l'instant : la politique vit donc **dans l'app**.

- page `PrivacyPage` (FR / EN / MG) avec cinq sections : données locales,
  chiffrement au repos, rapports de crash, aucun pistage, suppression ;
- une entrée : À propos → Confidentialité, en tête de la carte légale (avant
  Licences) ;
- le paragraphe « rapports de crash » cite le libellé de l'interrupteur et
  rappelle l'absence d'IP et d'identifiant stable ;
- `desc_bug_report` dit désormais explicitement « sans adresse IP ni
  identifiant stable » ;
- texte canonique et réponses « Data safety » / « App Privacy » à recopier :
  [confidentialite.md](./confidentialite.md).

**Reste hors code** : déclarer les fiches store (voir la
[feuille de route](./roadmap.md)).

## Étape 3 — Mises à jour store-native

Aucun serveur : les stores font le travail.

- **Android** : **Play In-App Updates** — déclenche le flux de mise à jour
  natif, immédiat ou flexible.
- **iOS** : API publique `itunes.apple.com/lookup?bundleId=…` — détecte une
  version plus récente, puis propose le lien App Store.
- On rouvrira à ce moment-là une entrée « Mise à jour » dans À propos, cette
  fois adossée à la vraie vérification.

Un manifeste JSON ne devient nécessaire que pour du sideload ou du desktop.

## Étape 4 — Vérifications

Fait, dans `test/crash_reports_test.dart` :

- « sans consentement, rien n'est initialisé » ;
- « l'interrupteur persiste le consentement » (et survit à un redémarrage) ;
- « l'interrupteur transmet le consentement au SDK », une seule fois par
  changement ;
- « un événement ne porte ni user, ni request, ni breadcrumb ».

Reste, à faire sur un appareil :

- activer l'interrupteur, provoquer une erreur, la voir arriver dans Sentry ;
- vérifier qu'aucun `setUser` n'existe nulle part ;
- vérifier côté console que l'IP est bien exclue du projet.

## Hors périmètre

- Feedback in-app : écarté (les stores suffisent).
- Analytics produit : non nécessaire pour les premiers clients — les consoles
  de store (installations, rétention, avis, crashs natifs) couvrent le besoin.
- Statistiques d'usage par fonctionnalité : à trancher plus tard (PostHog,
  Matomo ou relais maison), sans dette à prévoir maintenant.

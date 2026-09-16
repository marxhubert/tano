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

## Étape 1 — Sentry derrière le consentement

Le principe : **le toggle existant est la seule porte**. Tant qu'il est faux,
Sentry n'est pas initialisé et rien ne quitte l'appareil.

- Ajouter `sentry_flutter`.
- Lire `bugReportEnabled` depuis `SecurePreferences` **avant** `runApp`, et
  n'initialiser Sentry que s'il est vrai.
- Configuration anonyme :
  - `sendDefaultPii: false` ;
  - **IP non stockée** (réglage projet « Prevent Storing of IP Addresses ») ;
  - breadcrumbs limités (ou désactivés) ;
  - traces de performance désactivées ;
  - **jamais** de `setUser`, ni d'identifiant d'installation ajouté à la main.
- `release` = version de l'app, pour lire les erreurs par version.

**À trancher** : zéro breadcrumb (le plus strict) ou la fenêtre par défaut
bridée. Et le DSN, fourni par le propriétaire du projet Sentry.

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

- test : « Sentry n'est pas initialisé sans consentement » ;
- test : « avec consentement, un crash est capturé » ;
- vérifier qu'un `setUser` n'existe nulle part et que l'IP est bien exclue
  côté projet.

## Hors périmètre

- Feedback in-app : écarté (les stores suffisent).
- Analytics produit : non nécessaire pour les premiers clients — les consoles
  de store (installations, rétention, avis, crashs natifs) couvrent le besoin.
- Statistiques d'usage par fonctionnalité : à trancher plus tard (PostHog,
  Matomo ou relais maison), sans dette à prévoir maintenant.

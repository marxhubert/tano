# Confidentialité

> **Référence.** Le texte de la politique affichée dans l'app, et les réponses
> à recopier dans les consoles de store. Les décisions produit, elles, sont
> dans [observabilite.md](./observabilite.md).

## Où elle vit

- Page `PrivacyPage` (`lib/features/settings/privacy_page.dart`) ; les titres et
  les corps sont des clés `privacy*` de `l10n.dart`.
- Une seule entrée : **À propos → Confidentialité**, en première position de
  la carte, juste avant **Licences**.
- Pas de site web pour l'instant : la politique vit **dans l'app**, et le même
  texte se recopie dans les fiches store.
- Le texte canonique est l'anglais (`_en`) ; le français et le malgache en
  découlent. La date affichée est « September 2026 » — à faire bouger avec le
  contenu.

## Ce qu'elle promet

| Section | Promesse tenue par le code |
|---|---|
| Data stored on your device | Notes, dossiers, tâches, projets, pièces jointes et préférences restent dans le stockage privé de l'app |
| Encryption at rest | Base SQLCipher + pièces jointes chiffrées ; la clé vit dans le stockage sécurisé du système (voir [securite.md](./securite.md)) |
| Crash reports (optional) | Sentry, **désactivé par défaut**, activé seulement par l'interrupteur « {option_bug_report} » ; erreur, version, modèle et OS — jamais l'IP, jamais d'identifiant stable, jamais de contenu de note |
| No tracking, no ads | Aucun analytics, aucune publicité, aucun traceur tiers, aucune vente |
| Deleting your data | Tout s'efface depuis les paramètres ; rien n'est conservé côté éditeur |

Le paragraphe « Crash reports » cite le libellé exact de l'interrupteur : si
`option_bug_report` change, la politique suit automatiquement.

## Réponses « Data safety » (Play)

- **Collecte** : « Journaux de plantage » (*Crash logs*) uniquement, et
  **seulement si l'utilisateur active l'interrupteur**.
- **Partage** : aucun. Les journaux vont au sous-traitant Sentry
  (Functional Software, Inc.) pour le compte de l'éditeur, pas à des tiers
  publicitaires.
- **Chiffré en transit** : oui (HTTPS vers Sentry).
- **Suppression** : côté appareil, tout s'efface depuis les paramètres ; côté
  Sentry, régler la **rétention** du projet (30 jours) — c'est un réglage de la
  console, pas du code.
- **Aucun autre type** déclaré : pas de position, pas de contacts, pas
  d'identifiant d'appareil, pas d'activité, pas de contenu.

## Réponses « App Privacy » (App Store)

- **Diagnostics → Crash Data** : collecté, **non lié à l'identité**, **non
  utilisé pour le suivi**, et seulement après consentement.
- Tout le reste : *Not collected*.
- `PrivacyInfo.xcprivacy` doit déclarer la même chose (à faire, section 1 de la
  [feuille de route](./roadmap.md)).

## Points de vigilance

- **Jamais de `setUser`** ni d'identifiant d'installation ajouté à la main :
  sinon la déclaration passe de « non lié » à « lié à l'identité ».
- **IP non stockée** : réglage projet Sentry « Prevent Storing of IP
  Addresses ».
- Les **mises à jour store-native** (étape 3) feront un appel réseau
  `itunes.apple.com` / Play : à mentionner dans la politique le jour où elles
  arrivent.
- Toute nouvelle donnée collectée impose de mettre à jour **les deux** : la
  page in-app et les fiches store.

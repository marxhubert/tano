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
| Crash reports (optional) | Sentry, **désactivé par défaut**, activé seulement par l'interrupteur « {option_bug_report} » ; erreur, version, modèle et OS — jamais l'IP, jamais d'identifiant, jamais de contenu de note |
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
- Tout le reste : *Not collected* — y compris la **vérification des mises à
  jour**, qui ne transmet que le nom de l'app et ne collecte rien.

## Ce que le bundle déclare

### `ios/Runner/PrivacyInfo.xcprivacy`

Créé et **câblé dans la cible Runner** (référence de fichier, phase *Copy
Bundle Resources*) : sans ce câblage le fichier resterait sur le disque et ne
partirait pas dans l'app.

- `NSPrivacyTracking: false` et aucun domaine de suivi ;
- un seul type collecté, **`CrashData`**, marqué *non lié* et *non utilisé pour
  le suivi*, avec pour finalité *AppFunctionality* — exactement ce que dit la
  politique in-app ;
- les *required reason APIs* : `UserDefaults` (CA92.1), `FileTimestamp`
  (C617.1), `SystemBootTime` (35F9.1) et `DiskSpace` (E174.1). Le moteur
  Flutter et la plupart des paquets livrent leur propre manifeste ; celui-ci
  couvre l'app et les paquets qui n'en ont pas.

### `ios/Runner/Info.plist`

- **`NSFaceIDUsageDescription`** : présent, et c'est le **seul** descriptif
  d'usage nécessaire — l'app lit les notes verrouillées derrière Face ID.
- **Pas de `NSPhotoLibraryUsageDescription`** : le sélecteur d'image passe par
  **PHPicker**, qui s'exécute hors processus et ne demande **aucune**
  autorisation sur la photothèque. Vérifié dans le code du paquet
  (`file_picker_darwin`, `PHPickerViewController` seul, aucun
  `requestAuthorization`) ; la cible de déploiement est iOS 15, donc jamais le
  chemin `UIImagePickerController`.
- **Pas de `NSCameraUsageDescription`** : l'app ne propose aucune prise de vue.
- **Pas de `LSApplicationQueriesSchemes`** : `canLaunchUrl` n'est jamais
  appelé, seulement `launchUrl`.
- **Pas d'exception ATS** : tout passe en HTTPS. Si l'on ajoute un jour la
  caméra ou `canLaunchUrl`, il faudra revenir ici.

### `android/app/src/main/AndroidManifest.xml`

- `INTERNET` (les rapports de crash et, plus tard, la vérification de version),
  `USE_BIOMETRIC` et `USE_FINGERPRINT` pour le verrou.
- `android:allowBackup="false"` : rien ne part dans les sauvegardes système.

## Points de vigilance

- **Jamais de `setUser`** ni d'identifiant d'installation ajouté à la main :
  sinon la déclaration passe de « non lié » à « lié à l'identité ».
- **IP non stockée** : réglage projet Sentry « Prevent Storing of IP
  Addresses ».
- La **vérification des mises à jour** fait un appel réseau
  (`itunes.apple.com` ou l'API Play) : elle est mentionnée dans la politique
  in-app et dans la page publiée. Rien à déclarer aux stores, elle ne collecte
  rien.
- Le manifeste Android **retire** les permissions média que `open_filex`
  déclare pour son compte : sans ça, Play afficherait « Photos et vidéos » sur
  la fiche, ce que l'app n'a aucune raison de demander.
- Toute nouvelle donnée collectée impose de mettre à jour **les deux** : la
  page in-app et les fiches store.

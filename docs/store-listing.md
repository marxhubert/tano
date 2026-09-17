# Fiches store

> **Kit de publication.** Ce qu'il faut recopier dans App Store Connect et dans
> la Play Console. Les déclarations de confidentialité détaillées, elles, sont
> dans [confidentialite.md](./confidentialite.md).

## URL de la politique de confidentialité

Les deux stores **exigent une URL publique** : la politique in-app ne suffit
pas. Les pages vivent dans `site/privacy/` — `index.html` en anglais,
`fr.html` en français — **autonomes** : aucun script, aucune ressource
externe, aucun cookie, aucune mesure d'audience. `site/` est le **seul**
dossier publié ; `docs/` reste interne.

| Store | URL à coller |
|---|---|
| App Store Connect → *App Privacy* → Privacy Policy URL | `https://marxhubert.github.io/tano/privacy/` |
| Play Console → *Contenu de l'application* → Politique de confidentialité | `https://marxhubert.github.io/tano/privacy/` |

**Pour l'activer**, une fois :

1. GitHub → *Settings* → *Pages* → *Source* : **GitHub Actions**.
2. Onglet *Actions* → *Publish the privacy policy* → *Run workflow*.

Ensuite le workflow `.github/workflows/pages.yml` republie le site à chaque
poussée qui touche `site/` sur `master`. Un déploiement qui échoue **ne coupe
pas** le site : la dernière version publiée reste en ligne — la page promise aux
stores ne disparaît pas sur une panne de CI.

> L'alternative, sans CI, est une branche `gh-pages` ne contenant que
> `privacy/` et Pages pointé dessus. Elle supprime le workflow mais déplace le
> contenu hors de `master`, donc hors de la relecture habituelle. À garder si
> le workflow pose problème.
>
> Un domaine dédié (`tanonote.app`) ferait plus soigné pour une app grand
> public, mais n'apporte rien au référencement et oblige à republier la page
> ailleurs. La page est portable telle quelle.

## Fiche App Store

| Champ | Anglais | Français |
|---|---|---|
| Nom | `TanoNote` | `TanoNote` |
| Sous-titre (30) | `Notes, offline, encrypted` | `Notes, hors-ligne, chiffrées` |
| Catégorie | Productivité (secondaire : Utilitaires) | idem |
| Classification | 4+ | idem |

**Texte promotionnel (170)**

- EN : `Everything stays on your device. No account, no cloud, no tracking — just your notes, encrypted and always available offline.`
- FR : `Tout reste sur votre appareil. Sans compte, sans cloud, sans pistage — juste vos notes, chiffrées et toujours disponibles hors-ligne.`

**Description**

EN :

```
TanoNote is a note-taking app that keeps everything on your device.

No account, no cloud, no tracking. Your notes are encrypted at rest, lockable
behind Face ID, and they work offline — always.

WHAT'S INSIDE
• Notes, folders, tasks and projects in one place
• Lock a note behind Face ID, Touch ID or your passcode
• Attach photos and files, set a cover image
• A recycle bin, so a delete is never final
• Light and dark themes, grid or list view
• Export and import a single encrypted .tano file

PRIVATE BY DESIGN
• Everything stays on your device; there is no server of ours
• Encrypted at rest
• No analytics, no advertising, no third-party tracker
• Crash reports are off by default, anonymous, and you decide
```

FR :

```
TanoNote est une application de prise de notes qui garde tout sur votre appareil.

Sans compte, sans cloud, sans pistage. Vos notes sont chiffrées au repos,
verrouillables derrière Face ID, et elles fonctionnent hors-ligne — toujours.

CE QU'ELLE CONTIENT
• Notes, dossiers, tâches et projets au même endroit
• Verrouiller une note derrière Face ID, Touch ID ou votre code
• Joindre photos et fichiers, choisir une image de couverture
• Une corbeille : supprimer n'est jamais définitif
• Thèmes clair et sombre, vue en grille ou en liste
• Export et import d'un seul fichier .tano chiffré

PRIVÉE PAR CONSTRUCTION
• Tout reste sur votre appareil ; nous n'avons aucun serveur
• Chiffrement au repos
• Aucune analyse d'usage, aucune publicité, aucun traceur tiers
• Les rapports de crash sont désactivés par défaut, anonymes, et c'est vous qui décidez
```

**Mots-clés (100 caractères, séparés par des virgules, sans espace)**

- EN : `notes,notepad,offline,private,encrypted,secure,folder,tasks,todo,no ads`
- FR : `notes,bloc-notes,hors-ligne,privé,chiffré,sécurisé,dossier,tâches,à faire`

## Fiche Play

| Champ | Valeur |
|---|---|
| Titre (30) | `TanoNote — notes chiffrées` |
| Description courte (80) | `Notes chiffrées et hors-ligne. Sans compte, sans cloud, sans pistage.` |
| Description complète | le texte « FR » ci-dessus |
| Catégorie | Productivité |
| Classification du contenu | questionnaire : aucune des catégories proposées |

## App Privacy (App Store Connect)

- **Tracking** : *No*.
- **Data linked to you** : rien.
- **Data not linked to you** : *Diagnostics → Crash Data*, avec la mention que
  la collecte est **facultative** et que l'utilisateur peut la désactiver.
- Détail et justifications : [confidentialite.md](./confidentialite.md).

## Data safety (Play Console)

- **Collecte** : « Journaux de plantage », facultatifs, non partagés à des fins
  publicitaires, non liés à l'identité.
- **Chiffré en transit** : oui.
- **Aucun autre type** : pas de position, pas de contacts, pas d'identifiant
  d'appareil, pas d'activité, pas de contenu.
- Détail : [confidentialite.md](./confidentialite.md).

## Avant de soumettre

- [ ] Pages activé, l'URL de la politique répond bien (ouvre-la depuis un
      téléphone, en clair et en sombre).
- [ ] Version montée dans `pubspec.yaml` (`version: X.Y.Z+build`).
- [ ] `CHANGELOG.md` à jour, tag posé.
- [ ] Captures d'écran : accueil (grille), note ouverte, corbeille, réglages —
      en clair **et** en sombre, FR et EN.
- [ ] Textes de la fiche relus dans les deux langues.

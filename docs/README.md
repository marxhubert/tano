# Documentation TanoNote

Deux familles de documents.

## Référence — font autorité

| Document | Contenu |
|---|---|
| [Charte graphique](./charte-graphique.md) | Identité visuelle, palettes, design tokens |
| [Architecture](./architecture.md) | Couches, persistance, synchronisation, données |
| [Composants](./composants.md) | Anatomie et **contrats** des briques d'écran |
| [Sécurité](./securite.md) | Chiffrement au repos, export / import, verrou |
| [Observabilité](./observabilite.md) | Rapports de crash (Sentry) et mises à jour stores |
| [Confidentialité](./confidentialite.md) | Politique in-app, déclarations Play / App Store |
| [Modularité](./modularite.md) | Services et découpage gratuit / premium |
| [Dossiers](./dossiers.md) | Contrat de l'organisation en dossiers |

## Pilotage

| Document | Contenu |
|---|---|
| [Feuille de route](./roadmap.md) | Où on en est, ce qui vient ensuite |
| [Fiches store](./store-listing.md) | Textes à coller dans les deux consoles, URL de la politique |
| [Backlog](./backlog.md) | Idées non planifiées |

## Conventions

- Une valeur ne s'invente pas : elle vient du code (`theme.dart`,
  `page_header.dart`, `card_typography.dart`) et de la charte graphique.
- `site/` est le **site publié** par GitHub Pages — aujourd'hui la seule
  politique de confidentialité ; `docs/` reste interne (voir
  [fiches store](./store-listing.md)).
- `flutter analyze` 0 issue et tests verts avant tout merge.
- La documentation est en français ; le code et les commits en anglais.

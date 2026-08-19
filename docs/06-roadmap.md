# 06 — Feuille de route

Synthèse priorisée des actions proposées, alignée sur le phasage de
[`07-architecture-cible.md`](./07-architecture-cible.md).

Légende effort : S (petit), M (moyen), L (grand).

---

## Phase 0 — Fondations techniques (prérequis)

| # | Action | Effort | Réf. |
|---|---|---|---|
| 0.1 | Rendre `Note` immuable et non nullable | M | [04 §1](./04-plan-architecture-code.md) |
| 0.2 | Remplacer `NoteAction` par un enum | S | [04 §1](./04-plan-architecture-code.md) |
| 0.3 | Rendre la langue réactive (`LocaleController` en `ChangeNotifier`) | S | [04 §2](./04-plan-architecture-code.md) |
| 0.4 | Factoriser `_showActionButtons` (DRY) | S | [04 §3](./04-plan-architecture-code.md) |

---

## Phase 1 — Quick wins UI/UX

| # | Action | Effort | Réf. |
|---|---|---|---|
| 1.1 | Supprimer la police `Calibri` codée en dur | S | [02 §1](./02-plan-ui-ux.md) |
| 1.2 | Coins arrondis et élévation des cartes | S | [02 §2](./02-plan-ui-ux.md) |
| 1.3 | Dates lisibles et localisées | S | [02 §2](./02-plan-ui-ux.md) |
| 1.4 | SnackBar d'annulation après suppression (undo) | M | [02 §3](./02-plan-ui-ux.md) / [03 §1](./03-plan-fonctionnalites.md) |
| 1.5 | Taille de texte dynamique + contrastes | S | [02 §5](./02-plan-ui-ux.md) |
| 1.6 | Vrai thème Material 3 (`ColorScheme.fromSeed`) | M | [02 §1](./02-plan-ui-ux.md) |

---

## Phase 2 — Migration SQLite (Drift)

| # | Action | Effort | Réf. |
|---|---|---|---|
| 2.1 | Intégrer Drift + schéma v1 | M | [04 §4](./04-plan-architecture-code.md) / [07 §3](./07-architecture-cible.md) |
| 2.2 | Migration des données JSON existantes | M | [04 §4](./04-plan-architecture-code.md) / [07 §10](./07-architecture-cible.md) |
| 2.3 | Remplacer `FileNotesRepository` + UUID globaux | S | [04 §4](./04-plan-architecture-code.md) |

---

## Phase 3 — Dossiers, checklist, export chiffré

| # | Action | Effort | Réf. |
|---|---|---|---|
| 3.1 | Dossiers hiérarchiques (type Notes d'Apple) | M | [03 §5](./03-plan-fonctionnalites.md) / [07 §9](./07-architecture-cible.md) |
| 3.2 | Checklist liée aux notes et tickets | M | [03 §5](./03-plan-fonctionnalites.md) |
| 3.3 | Export / import chiffré (AES-GCM, PBKDF2) | M | [03 §4](./03-plan-fonctionnalites.md) / [07 §7](./07-architecture-cible.md) |

---

## Phase 4 — Prototype de synchronisation (critique)

| # | Action | Effort | Réf. |
|---|---|---|---|
| 4.1 | Identités Ed25519 + chiffrement E2E | M | [07 §7](./07-architecture-cible.md) |
| 4.2 | `WebRtcTransport` + signalisation publique (mot de passe de salon) | L | [07 §5-6](./07-architecture-cible.md) |
| 4.3 | **Preuve de bout en bout : une note partagée temps réel France ↔ Japon** | L | [07 §11](./07-architecture-cible.md) |

> Valider ce prototype **avant** de construire l'UI Kanban (Phase 5).

---

## Phase 5 — Projets / Kanban + pièces jointes

| # | Action | Effort | Réf. |
|---|---|---|---|
| 5.1 | Projets / tickets Kanban (drag & drop) | M | [03 §5](./03-plan-fonctionnalites.md) |
| 5.2 | Pièces jointes (images, PDF, docx) | M | [03 §5](./03-plan-fonctionnalites.md) / [07 §8](./07-architecture-cible.md) |
| 5.3 | Serveur de signalisation auto-hébergé + TURN | M | [07 §5](./07-architecture-cible.md) |

---

## Phase 6 — Qualité et pérennité

| # | Action | Effort | Réf. |
|---|---|---|---|
| 6.1 | Tests d'intégration (Drift, sync, export) | M | [05 §2](./05-plan-tests-qualite.md) |
| 6.2 | Golden tests | M | [05 §3](./05-plan-tests-qualite.md) |
| 6.3 | CI GitHub Actions (analyze + test + build) | S | [05 §5](./05-plan-tests-qualite.md) |
| 6.4 | Injection des singletons + tests isolés | M | [04 §2](./04-plan-architecture-code.md) |
| 6.5 | Cibles desktop/web (optionnel) | M | [03 §7](./03-plan-fonctionnalites.md) |

---

## Ordre recommandé

1. **Phase 0** : sécurise le code existant.
2. **Phase 1** : quick wins visibles immédiatement.
3. **Phase 2** : bascule SQLite/Drift (fondation des entités).
4. **Phase 3** : dossiers + checklist + export chiffré.
5. **Phase 4** : **prototype sync** — le jalon critique à valider.
6. **Phase 5 puis 6** : Kanban, pièces jointes, industrialisation.

> Chaque phase livre de la valeur indépendamment ; la Phase 4 (sync) doit être
> validée avant la Phase 5 (Kanban) pour éviter une refonte coûteuse.

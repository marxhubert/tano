# Tests & qualité

Comment les tests sont organisés, comment on les lance, et ce qu'ils ne couvrent
pas. Ce document décrit l'état **réel** ; les décisions de fond vivent dans la
[feuille de route](./roadmap.md).

## Les familles de tests

| Famille | Où | Ce qu'elle vérifie |
|---|---|---|
| Unitaires et ViewModels | `test/*_test.dart` | Tri, sélection, édition, recherche, formats de date |
| Dépôts | `test/sqlite_notes_repository_test.dart` | La vraie base chiffrée, sur un fichier temporaire |
| Export / import | `test/export_import_test.dart` | L'aller-retour `.tano`, en clair et chiffré |
| Widgets | `test/*_test.dart` | Les écrans réels, avec des faux en mémoire |
| Goldens | `test/golden/` | Les cartes, vingt images, jamais en CI |
| Intégration | `integration_test/` | L'app entière sur un appareil : dossiers, verrou |

**294 tests** dans `flutter test` (goldens compris), plus les deux fichiers
d'intégration, qui demandent un appareil ou un simulateur.

## Les lancer

    flutter analyze                      # doit rester à 0
    flutter test                         # tout, goldens compris
    flutter test --exclude-tags golden   # ce que fait la CI
    flutter test integration_test        # sur un appareil

## Les goldens

Ils comparent des pixels, donc ils dépendent de la machine : ils sont générés et
relus **en local**, et la CI les exclut (`dart_test.yaml` déclare le tag).

    flutter test --update-goldens test/golden/

puis **regarder les PNG**. Le diff git dit combien d'octets ont bougé ; l'image
dit quoi. Les vraies polices sont chargées par `test/golden/golden_setup.dart` —
Roboto depuis le cache de Flutter, Material Symbols depuis le paquet résolu. Sans
elles, tout serait des rectangles.

## Les conventions des tests de widgets

- Un faux dépôt en mémoire plutôt que la base, branché par
  `getIt.registerSingleton`.
- `SharedPreferences.setMockInitialValues` et `PackageInfo.setMockInitialValues`
  avant de pomper l'app.
- `LocaleController.instance.init()` et `ThemeController.instance.init()` en
  tête, comme le fait `main`.
- `AuthService` remplacé dans `getIt` : le prompt biométrique ne se pilote pas.

## Ce que les tests ne couvrent pas

- **Le sélecteur de fichiers** de l'export : c'est un dialogue système. C'est la
  limite du test d'export — tout ce qui est en dessous (l'archive, le
  chiffrement, la fusion, les pièces jointes) est couvert au niveau des services,
  dans `test/export_import_test.dart`.
- **Le vrai prompt biométrique** : remplacé par un faux qui répond, pour vérifier
  ce que l'app fait de la réponse.
- **Le trousseau du système** : `flutter_secure_storage` n'existe pas sous
  `flutter test`, donc les tests exercent son chemin de repli. C'est visible dans
  la sortie (« secure storage unavailable ») et c'est attendu.

## Ce qui est exigé

| Règle | Comment |
|---|---|
| `flutter analyze` à 0 | La CI, à chaque PR |
| Tests verts | La CI, avant tout merge |
| Goldens relus à l'œil | En local, après tout changement voulu |
| Les deux cibles compilent | La CI : `build apk` sur Ubuntu, `build ios --no-codesign` sur macOS |

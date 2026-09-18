# Livraison

Ce qui reste à faire pour livrer, dans l'ordre. Les textes à coller dans les
deux consoles vivent dans [store-listing.md](./store-listing.md).

## 0. L'identité du build

L'app ne porte aucune information personnelle : un build sans fichier d'identité
n'affiche ni auteur ni page de soutien (voir le README, « Identity »).

    cp identity.json.dist identity.json   # puis le remplir
    flutter build appbundle --release --dart-define-from-file=identity.json

## 1. La version

- `pubspec.yaml`, `version:` — le numéro affiché dans À propos. Ajouter `+N` à
  chaque envoi sur les stores : c'est le `versionCode` Android, et le Play
  Console refuse un code déjà utilisé.
- `README.md`, le badge de version.
- `CHANGELOG.md` : renommer `[Unreleased]` en `[0.9.0-beta] - la date`.

## 2. La signature Android

Le keystore vit **hors du dépôt** : `android/key.properties` est ignoré par git,
et `android/app/build.gradle.kts` retombe sur la signature debug s'il est absent
— compilable, mais pas publiable.

    keytool -genkey -v -keystore ~/tano-release.jks -keyalg RSA \
      -keysize 2048 -validity 10000 -alias tano

puis `android/key.properties` :

    storePassword=…
    keyPassword=…
    keyAlias=tano
    storeFile=/Users/…/tano-release.jks

Le keystore et ses mots de passe se sauvegardent ailleurs que sur la machine :
sans eux, une app publiée ne peut plus être mise à jour.

## 3. Le build

    flutter clean
    flutter build appbundle --release --dart-define-from-file=identity.json
    flutter build ipa --release --dart-define-from-file=identity.json

- Android : le paquet est dans `build/app/outputs/bundle/release/`.
- iOS : `open ios/Runner.xcworkspace`, l'équipe de signature dans Signing &
  Capabilities, puis Product → Archive → Distribute App.

## 4. Le tag et la release

    git tag v0.9.0-beta
    git push origin v0.9.0-beta

puis la release GitHub, avec la section correspondante du `CHANGELOG.md`.

## 5. Après la livraison

- Cocher les cases de [roadmap.md](./roadmap.md).
- Vérifier sur l'appareil : la page de politique publiée, « Vérifier les mises à
  jour » dans À propos, et le rapport de crash après avoir donné le consentement.

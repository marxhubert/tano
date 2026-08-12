# 📝 TanoNote

[![Version](https://img.shields.io/badge/version-0.8.4--beta-orange)](https://github.com/marxhubert/tano/releases)
[![Licence](https://img.shields.io/badge/Licence-Apache%202.0-blue.svg)](LICENSE)
[![Plateformes](https://img.shields.io/badge/Plateformes-Android%20%7C%20iOS-brightgreen)](https://flutter.dev)
[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-%3E%3D3.8-0175C2?logo=dart&logoColor=white)](https://dart.dev)
[![Stars](https://img.shields.io/github/stars/marxhubert/tano?style=social)](https://github.com/marxhubert/tano)

**TanoNote** est une application de gestion de notes, de tâches et de projets, développée avec [Flutter](https://flutter.dev) pour Android et iOS. Rapide, légère et **100 % hors ligne** : toutes vos données restent sur votre appareil, rien n'est envoyé sur un serveur.

## ✨ Fonctionnalités

- 📝 **Notes** — création, édition et suppression de notes avec titre, contenu et date.
- 🗂 **Catégories colorées** — organisez vos notes par thème, chacune avec sa couleur.
- ⭐ **Notes importantes** — mettez vos notes en avant d'un simple clic sur l'étoile.
- 🔍 **Recherche instantanée** — insensible à la casse, dans les titres et les contenus.
- 🎛 **Trois modes d'affichage** — liste, compact et grille.
- ↕️ **Tri flexible** — par date, titre, favoris ou catégorie.
- ☑️ **Sélection multiple** — appui long pour sélectionner, suppression en masse, tout sélectionner / désélectionner.
- 👆 **Balayage pour supprimer** — glissez une note vers la gauche ou la droite pour la supprimer.
- 🔒 **100 % local** — stockage dans un fichier JSON sur l'appareil, aucune donnée personnelle n'est transmise.

## 🗂 Catégories

| Catégorie  | Couleur  |
|------------|----------|
| Note       | 🟠 Orange |
| Travail    | 🔴 Rouge  |
| Personnel  | 🔵 Bleu   |
| Voyage     | 🟢 Vert   |
| Vie        | 🟣 Violet |
| Projet     | 🟡 Jaune  |
| Libre      | ⚪ Gris   |

## 🚀 Démarrage

### Prérequis

- [Flutter](https://docs.flutter.dev/get-started/install) **3.x** (Dart **≥ 3.8.0**)
- Android Studio / Xcode selon la plateforme cible

### Installation

```bash
# Récupérer les dépendances
flutter pub get

# Lancer l'application (appareil ou émulateur connecté)
flutter run
```

### Construire une version de production

```bash
# Android (APK)
flutter build apk

# iOS (nécessite macOS et Xcode)
flutter build ios
```

## 🧪 Tests

```bash
flutter test
```

## 🛠 Technologies utilisées

| Dépendance          | Rôle                                            |
|---------------------|-------------------------------------------------|
| `path_provider`     | Accès au répertoire de documents de l'appareil  |
| `shared_preferences`| Persistance des préférences (affichage, tri)    |
| `package_info_plus` | Informations sur la version de l'application    |
| `flutter_lints`     | Analyse statique du code                        |

## 📁 Structure du projet

```
lib/
├── main.dart               # Point d'entrée de l'application
├── models/
│   └── note.dart           # Modèle de données Note
├── pages/
│   ├── home.dart           # Écran principal (liste des notes)
│   ├── edit.dart           # Édition d'une note
│   ├── search.dart         # Recherche
│   └── splash.dart         # Écran de démarrage
├── services/
│   └── database.dart       # Lecture / écriture du stockage local
├── utils/                  # Menus, actions, dialogues…
└── widgets/                # Composants réutilisables
```

## 🤝 Contribuer

Les contributions sont les bienvenues ! Ouvrez une *issue* pour signaler un bug ou proposer une fonctionnalité, ou soumettez une *pull request* sur la branche `develop`.

## 📄 Licence

Ce projet est distribué sous la licence **Apache License 2.0**. Voir le fichier [LICENSE](LICENSE) pour plus de détails.

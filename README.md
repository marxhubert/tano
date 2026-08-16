# 📝 TanoNote

[![Version](https://img.shields.io/badge/version-0.8.4--beta-orange)](https://github.com/marxhubert/tano/releases)
[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](LICENSE)
[![Platforms](https://img.shields.io/badge/Platforms-Android%20%7C%20iOS-brightgreen)](https://flutter.dev)
[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-%3E%3D3.8-0175C2?logo=dart&logoColor=white)](https://dart.dev)
[![Stars](https://img.shields.io/github/stars/marxhubert/tano?style=social)](https://github.com/marxhubert/tano)

**TanoNote** is a notes, tasks and projects management application built with [Flutter](https://flutter.dev) for Android and iOS. Fast, lightweight and **100 % offline**: all your data stays on your device, nothing is sent to a server.

## ✨ Features

- 📝 **Notes** — create, edit and delete notes with a title, content and date.
- 🗂 **Colored categories** — organize your notes by theme, each with its own color.
- ⭐ **Important notes** — highlight your notes with a single tap on the star.
- 🔍 **Instant search** — case-insensitive, across titles and contents.
- 🎛 **Three display modes** — list, compact and grid.
- ↕️ **Flexible sorting** — by date, title, favorites or category.
- ☑️ **Multiple selection** — long press to select, bulk delete, select all / deselect all.
- 👆 **Swipe to delete** — swipe a note left or right to delete it.
- 🔒 **100 % local** — stored in a JSON file on the device, no personal data is transmitted.

## 🗂 Categories

| Category  | Color    |
|-----------|----------|
| Note      | 🟠 Orange |
| Work      | 🔴 Red    |
| Personal  | 🔵 Blue   |
| Travel    | 🟢 Green  |
| Life      | 🟣 Purple |
| Project   | 🟡 Yellow |
| Free      | ⚪ Gray   |

## 🚀 Getting started

### Prerequisites

- [Flutter](https://docs.flutter.dev/get-started/install) **3.x** (Dart **≥ 3.8.0**)
- Android Studio / Xcode depending on the target platform

### Installation

```bash
# Fetch the dependencies
flutter pub get

# Run the application (connected device or emulator)
flutter run
```

### Build a production version

```bash
# Android (APK)
flutter build apk

# iOS (requires macOS and Xcode)
flutter build ios
```

## 🧪 Tests

```bash
flutter test
```

## 🛠 Technologies used

| Dependency          | Role                                            |
|---------------------|-------------------------------------------------|
| `path_provider`     | Access to the device's documents directory       |
| `shared_preferences`| Persistence of preferences (display, sorting)    |
| `package_info_plus` | Application version information                   |
| `flutter_lints`     | Static code analysis                             |

## 📁 Project structure

```
lib/
├── main.dart               # Application entry point
├── models/
│   └── note.dart           # Note data model
├── pages/
│   ├── home.dart           # Main screen (note list)
│   ├── edit.dart           # Note editing
│   ├── search.dart         # Search
│   └── splash.dart         # Splash screen
├── services/
│   └── database.dart       # Local storage read / write
├── utils/                  # Menus, actions, dialogs…
└── widgets/                # Reusable components
```

## 🤝 Contributing

Contributions are welcome! Open an *issue* to report a bug or suggest a feature, or submit a *pull request* against the `develop` branch.

## 📄 License

This project is distributed under the **Apache License 2.0**. See the [LICENSE](LICENSE) file for more details.

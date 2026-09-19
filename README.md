# TanoNote

[![Version](https://img.shields.io/badge/version-0.9.0--beta-orange)](https://github.com/marxhubert/tano/releases)
[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](LICENSE)
[![Platforms](https://img.shields.io/badge/Platforms-Android%20%7C%20iOS-brightgreen)](https://flutter.dev)
[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white)](https://flutter.dev)

**TanoNote** is a notes, tasks and projects application built with
[Flutter](https://flutter.dev) for Android and iOS. Notes, task lists and folders
work locally without a connection. Projects and remote collaboration remain future
work. Optional crash reports and user-requested store updates
use the network. See the [audit and release blockers](docs/audit-2026-09-18.md).

## Features

### Task lists
- Free checklist documents using the same editor and local protections as notes.
- Active rows above, completed rows below a divider, with a total item count.
- Mixed note/task cards on Home and in folders, with a distinct Task watermark.
- See [Task lists](docs/tasks.md) for behavior and validation.

### Notes
- Create, edit and delete notes with a title and rich content.
- Lightweight markdown: headings, checklists, bullet lists, bold, inline code
  and `[[note links]]` to other notes.
- Optional cover image per note.
- Attachments (images, PDF, documents), opened with the system viewer.

### Organisation
- Folders with their own colour theme, cover, bookmark and lock.
- Bookmark notes and folders.
- Search notes; notes locked directly or through their folder are excluded.
- Multi-selection of notes and folders: move, delete with confirmation. The home
  list also offers an undo after a swipe-to-delete.
- Sorting (date, title, favourites, colour theme) and grid or list layouts.

### Security and privacy
- The database is SQLite encrypted with SQLCipher. Its key lives in the OS
  secure storage (`flutter_secure_storage`) and never leaves the device.
- Locked notes and folders are gated by the device credential (biometrics, PIN
  or passcode). The app never stores a password of its own.
- Export is either a plain ZIP (cleartext) or an Argon2id + AES-GCM container.
  Import merges: it never overwrites or deletes existing notes.
- Deleted items go to a recycle bin before being permanently removed.

### Interface
- Light, dark and system themes.
- Per-item pastel colour themes.
- English, French and Malagasy.

## Requirements

- [Flutter](https://docs.flutter.dev/get-started/install) **3.x**
  (Dart **>= 3.8.0**)
- Android Studio or Xcode, depending on the target platform

## Getting started

```bash
# Fetch the dependencies
flutter pub get

# Run the application (connected device or simulator)
flutter run
```

## Build

```bash
# Add --dart-define-from-file=identity.json to name the build (see below).

# Android (App Bundle for the Play Store)
flutter build appbundle

# iOS (requires macOS and Xcode)
flutter build ipa
```

The full recipe — keystore, archive, tag, release — lives in
[docs/release.md](docs/release.md).

### Identity

The in-app author, contact address and support links are read from build settings.
The repository still contains public author attribution, privacy-policy contact
details and the application bundle identifier. Configure your own signing team
locally for iOS; no team is selected in the shared project. `identity.json.dist` is the
template — copy it, fill it in, and point the tool at it. The filled file is
ignored by git, the template is not.

```bash
cp identity.json.dist identity.json   # then fill it in

flutter run --dart-define-from-file=identity.json
flutter build appbundle --dart-define-from-file=identity.json
flutter build ipa --dart-define-from-file=identity.json
```

## Tests

```bash
# Static analysis
flutter analyze

# Unit and widget tests
flutter test

# Integration tests (device or simulator required)
flutter test integration_test
```

The GitHub Actions workflow (`.github/workflows/ci.yml`) runs `flutter analyze`,
`flutter test` (the golden tests are compared locally: they depend on how the
host rasterises text) and a debug build of both targets — Android on Ubuntu, iOS
on macOS without a signing profile — on every push to `master` and on every pull
request.

## Technologies

| Dependency | Role |
|---|---|
| `sqflite_sqlcipher` | Encrypted SQLite storage |
| `flutter_secure_storage` | Installation key and preferences |
| `cryptography` | AES-GCM and Argon2id (export/import) |
| `local_auth` | Device credential for locked notes and folders |
| `file_picker` / `open_filex` | Attachments |
| `archive` | ZIP and `.tano` containers |
| `path_provider` | Documents and cache directories |
| `shared_preferences` | User preferences |
| `get_it` | Dependency injection |
| `uuid` | Identifiers |
| `package_info_plus` | Version and device information |
| `material_symbols_icons` | Icon set |
| `url_launcher` | External links |

## Project structure

```
lib/
├── main.dart
├── core/
│   ├── models/          # Note, Folder, JSON codecs
│   ├── repositories/    # Encrypted SQLite storage, attachments
│   └── services/        # Authentication, cipher, export / import
├── features/
│   ├── notes/           # Home: notes and folders, search, sorting
│   ├── folder/          # Folder page
│   ├── editor/          # Note editor
│   ├── trash/           # Recycle bin
│   ├── settings/        # Settings and sub-pages
│   └── splash/          # Splash screen
└── shared/
    ├── config/          # Localisation, theme, service locator, preferences
    └── widgets/         # Cards, floating action button, dialogs, layout
```

## Documentation

`docs/` holds the reference (architecture, security, components, privacy) and the
steering documents: [roadmap](docs/roadmap.md), [backlog](docs/backlog.md),
[store listings](docs/store-listing.md) and [release](docs/release.md). See the [current audit](docs/audit-2026-09-18.md) and
[remote collaboration design](docs/collaboration.md).

## Contributing

Feature work targets `develop`. Promote releases to `master` through a pull request
with successful CI and an independent approval. Premium is planned for projects,
sharing and collaboration; billing is not enabled yet.

Contributions are welcome. Open an *issue* to report a bug or suggest a feature,
or submit a *pull request* against `develop`. Please run `flutter analyze` and
`flutter test` before opening a pull request.

## License

This project is distributed under the **Apache License 2.0**. See the
[LICENSE](LICENSE) file for more details.

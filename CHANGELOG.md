# Changelog

All notable changes to TanoNote are recorded here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and the versions
follow [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

Older releases are described on the
[releases page](https://github.com/marxhubert/tano/releases).

## [Unreleased]

### Added

- The four empty screens share one component and one illustration each — empty
  box, empty folder, recycle bin, no result — tinted with the app's colour.
- A `CheckDisc` mark for every "this one is chosen": the settings' selected row,
  the theme previews, and the cards in selection mode.
- The About page reads its identity from the build (see the README, "Identity").
  A build that names no author shows no author and no support page.
- The Malagasy word look-up opens from the language references.
- An introduction of three screens on the first launch, reachable again from
  About: what the app is, the lock that protects a note, and where things are
  kept.
- One undo for every deletion: the home list and the folder page now build the
  same notice and put the notes back the same way.
- Moving notes and locking a note or a folder now say so. Android keeps its
  SnackBar; iOS gets a toast that fades away on its own instead of an alert.
- The settings offer four text sizes, and switches for the haptic feedback and
  the sound. The chosen size multiplies the system's own text scale.

### Changed

- **The app ships empty.** The demo folders and notes that used to fill a fresh
  install are gone; the first launch opens the introduction on a blank slate.
- **The core was rebuilt** around `lib/core`, `lib/features` and `lib/shared`:
  unified cards (`EntityCard`), list rendering (`EntitySliver`), selection
  (`SelectionController`), dialogs, covers and a rewritten FAB.
- The type scale holds eight sizes; colours, spacings and radii are named
  tokens, and the theme preview reads them instead of copying them.
- The editor's title, metadata line and content share the same inset, and the
  empty screens hold their place when the keyboard opens.
- The app's animations read three named durations instead of six loose ones.
- The privacy policy, the licences and the About notice read the current year.

### Fixed

- **A hard reset left the folders and the attachments behind.** It wipes
  everything now.
- The destructive action of the reset dialog was not red: the check compared
  the English word "reset" against a translated label.
- The FAB's rule had its corners cut off; it is painted above the clipped menu
  surface now.
- "Link a note" is refused when the note is the only one, and "Move to" when
  the app holds no folder at all.

### Security

- The repository carries no personal information: the author's name, the
  contact address and the support links are read from the build, and
  `identity.json` is ignored by git.

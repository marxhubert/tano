# Release workflow

The app has never been published. Complete [release gates](roadmap.md) before shipping.

## Branches

`develop` is the verified GitHub default branch. Feature branches target `develop`. Release promotion targets `master` through a PR,
successful Analyze & test / Android build / iOS build checks and one independent
approval. A PR author cannot provide that approval. Do not bypass protection to
publish an unreviewed change. Release tags should identify the reviewed master commit.

## Identity and signing

Copy `identity.json.dist` to ignored `identity.json` and supply
`--dart-define-from-file=identity.json`. The repository retains publisher attribution,
public policy contact and the existing bundle ID. Configure the iOS signing team
locally; it is intentionally absent from the shared project.

Android signing uses ignored `android/key.properties` and an external keystore.
Without it the project falls back to debug signing, which is not a store release.
Back up signing material securely outside the repository. Never put secrets in
Dart defines: compiled application values are recoverable.

## Validation and builds

```sh
flutter pub get
flutter analyze
flutter test
flutter build appbundle --release --dart-define-from-file=identity.json
flutter build ipa --release --dart-define-from-file=identity.json
```

CI builds both targets in debug and release (release without a signing profile), so
tree shaking, AOT and R8 breakage is caught before the signed step above.

Increase `pubspec.yaml` version/build number and update changelog/release notes.
Use Xcode Archive/Distribute with the correct signing team. Configure the Sentry
DSN in the ignored `identity.json` only after envelope/consent/non-retention
validation; symbol upload requires external
credentials and project settings. Review permissions, privacy manifests and actual
store disclosures. Premium purchases are not configured and must not be advertised
as purchasable until store verification and restoration are tested.

# Build and release

## Requirements

* Flutter 3.47 or newer on the stable channel (`flutter --version`)
* Android SDK: platform 36, build tools, platform tools (Android Studio or
  `sdkmanager`), and a JDK 17+
* Internet access to `dl.google.com`, `maven.google.com`,
  `repo.maven.apache.org`, `plugins.gradle.org`, `services.gradle.org`,
  `storage.googleapis.com` (Flutter engine) and `github.com` (the SQLite
  build hook downloads pinned, checksum-verified SQLite binaries) for the
  first build

```sh
flutter doctor            # Android toolchain must be ✓
flutter pub get
flutter test
```

## 1. Create the release signing key (once)

Every update must be signed with the same key, forever. Create it outside
the repository and back it up in two safe places (for example an encrypted
USB drive and a password manager). **Never commit it.**

```sh
keytool -genkeypair -v \
  -keystore ~/keys/dawasa-release.jks \
  -storetype PKCS12 -keyalg RSA -keysize 4096 -validity 36500 \
  -alias dawasa
```

Then create `android/key.properties` (ignored by Git; see
`android/key.properties.example`):

```properties
storeFile=/home/you/keys/dawasa-release.jks
storePassword=...
keyAlias=dawasa
keyPassword=...
```

Release builds fail with a clear message when this file is missing; they
are never signed with the debug key.

The SHA-256 of the signing certificate (useful for
`--signing-cert-sha256` in the update manifest):

```sh
keytool -list -v -keystore ~/keys/dawasa-release.jks -alias dawasa | grep SHA256
```

## 2. Build configuration

`config/dawasa.json` (copy of `config/dawasa.example.json`, ignored by Git):

| Key | Meaning |
|-----|---------|
| `DAWASA_UPDATE_BASE_URL` | HTTPS folder with `manifest.json` and APKs, e.g. `https://<your-domain>/downloads/dawasa/`. Empty = no built-in update server (users can still enter one). |
| `DAWASA_UPDATE_MANIFEST` | Manifest file name (default `manifest.json`) |
| `DAWASA_SELF_UPDATE` | `false` for app-store builds |
| `DAWASA_DEVELOPER_WEBSITE`, `DAWASA_DEVELOPER_EMAIL` | Shown in About only when set; use verified details only |

Nothing in this file is secret, and nothing secret may be added to it:
values passed with `--dart-define` end up inside the APK.

## 3. Version numbers

`pubspec.yaml`: `version: <versionName>+<versionCode>`, e.g. `1.1.0+2`.
The `versionCode` must increase with every release; the updater and Android
compare it. Database schema versions are separate (see
[DATABASE.md](DATABASE.md)).

## 4. Build

```sh
scripts/build_release.sh --notes-en "What changed" --notes-si "වෙනස් වූ දේ"
```

The script runs `pub get`, `gen-l10n`, `analyze` and all tests, then

```sh
flutter build apk --release --dart-define-from-file=config/dawasa.json \
  --obfuscate --split-debug-info=build/symbols
```

and creates `dist/dawasa/` (`dawasa-<version>-<code>.apk`,
`manifest.json`, `SHA256SUMS`) with `tool/generate_manifest.dart`.

* Keep `build/symbols` for each release to decode crash stack traces
  (`flutter symbolize`).
* One universal APK is published so that the updater has a single file per
  version. (`--split-per-abi` would produce smaller files but needs one
  manifest entry per ABI.)

Check the signature before publishing:

```sh
apksigner verify --print-certs dist/dawasa/dawasa-*.apk
```

## 5. Publish

See [UPDATE_SERVER.md](UPDATE_SERVER.md):

```sh
scripts/deploy_update.sh deploy@<server> /var/www/dawasa/downloads/dawasa
```

## App-store builds

Stores deliver their own updates and restrict `REQUEST_INSTALL_PACKAGES`.
For such a build set `"DAWASA_SELF_UPDATE": "false"` and remove the
permission for that build, e.g. with a `src/store/AndroidManifest.xml`
containing `<uses-permission android:name="android.permission.REQUEST_INSTALL_PACKAGES" tools:node="remove" />`
in a separate product flavor.

## What is never committed

`android/key.properties`, `*.jks`, `*.keystore`, `config/dawasa.json`,
`dist/`, `release/`, `*.apk`, `*.aab` (all in `.gitignore`).

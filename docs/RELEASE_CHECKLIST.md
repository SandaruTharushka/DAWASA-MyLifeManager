# Release checklist

Copy this list into the release notes or an issue for every version.

## Before building

- [ ] `pubspec.yaml` version increased (`x.y.z+<higher versionCode>`)
- [ ] Database changes? New schema version, snapshot (`make-migrations`),
      migration step that keeps all data, migration test updated
- [ ] New or changed texts exist in **both** `app_en.arb` and `app_si.arb`
      (`flutter test test/core/l10n_test.dart`)
- [ ] `config/dawasa.json` points to the verified HTTPS update folder (or is
      empty on purpose)
- [ ] Release notes written in English and Sinhala

## Build

- [ ] `scripts/build_release.sh …` finished: analyzer clean, all tests pass
- [ ] `apksigner verify --print-certs` shows the release certificate
      (same SHA-256 as previous releases)
- [ ] `build/symbols` archived with the release
- [ ] `dist/dawasa/SHA256SUMS` matches the APK (`sha256sum -c`)

## Test on real phones (at least one old and one new Android version)

- [ ] Fresh install: welcome guide in Sinhala and English, add an expense,
      income and transfer; balances correct
- [ ] **Update over the previous version**: all data still there, database
      migrated, reminders still scheduled
- [ ] Reminder notification arrives (task and bill), tapping opens the item
- [ ] Create a backup, restore it on a second phone (or after clearing
      data); wrong password is rejected
- [ ] PIN lock, wrong PIN pause, fingerprint unlock, lock after timeout
- [ ] Screen protection hides the app in recent apps
- [ ] In-app update from the previous version: download, cancel, resume,
      "Wi-Fi only" prompt on mobile data, Android install screen appears,
      app restarts on the new version with data intact
- [ ] Offline: everything except the update check works in airplane mode
- [ ] Large text (Android font size largest) and TalkBack on the home screen
- [ ] Dark theme

## Publish

- [ ] Upload with `scripts/deploy_update.sh` (APK first, manifest last)
- [ ] `curl -sI` checks from [UPDATE_SERVER.md](UPDATE_SERVER.md) pass
- [ ] Download page shows the new version and SHA-256
- [ ] A phone on the previous version finds the update
- [ ] Git tag `v<versionName>` pushed

## After release

- [ ] Keep the previous APK on the server for a while
- [ ] Note any issues for the next release

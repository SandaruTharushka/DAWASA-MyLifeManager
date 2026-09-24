# Testing

```sh
flutter analyze          # strict lints (analysis_options.yaml)
flutter test             # all tests below, no device needed (~45 s)
flutter test test/drift  # schema migrations only
flutter test integration_test/app_test.dart   # on a phone/emulator
```

All automated tests run on the computer against real SQLite (in memory or
in a temporary file), real encryption and real isolates. Widget tests run
the complete app (`AppRoot`) with in-memory doubles for the Android-only
services (secure storage, biometrics, notifications, installer, network).

## What is covered

| File | Tests | Covers |
|------|------:|--------|
| `test/core/money_test.dart` | 9 | Parsing amounts into minor units without floating-point errors, invalid and oversized input, zero-decimal currencies, formatting, compact format, integer percent helpers |
| `test/core/time_test.dart` | 13 | `LocalDate` validation, month-end clamping, DST-independent day arithmetic, first weekday, range presets, recurrence (31st of the month, 29 February, weekdays, count/until) |
| `test/core/l10n_test.dart` | 3 | Sinhala and English contain the same messages and placeholders; Sinhala is translated |
| `test/core/database/smoke_test.dart` | 1 | Fresh database with default categories |
| `test/drift/dawasa/migration_test.dart` | 4 | Every schema version upgrades to every later one and matches a fresh schema; a realistic v1 database keeps all data |
| `test/features/finance_core_test.dart` | 18 | Balances, transfers without income/spending, archive instead of delete, saving the same draft twice creates one record, validation, totals and search, idempotent recurring catch-up, daily budget allowance |
| `test/features/planner_money_test.dart` | 12 | Budget periods, progress and one-time alerts, bills (pay, undo, loan instalments not counted as spending), task views, reminder planning and stable notification ids |
| `test/features/life_reports_test.dart` | 11 | Savings goals, loans and settlement, habit targets and streaks, check-ins that never touch money, birthdays and ages, reports, CSV escaping and formula-injection protection |
| `test/features/backup_test.dart` | 17 | Backup container (tampering, wrong password, truncation, crafted KDF parameters), backup → change → restore → undo, malicious archive names, corrupted databases, newer-version backups, restoring and migrating a v1 backup, production Argon2id settings |
| `test/features/security_test.dart` | 15 | PIN policy, Argon2id hashing, persistent back-off, clock changes, lock timeout, grace period for pickers, biometric unlock, removing all secrets |
| `test/features/update_test.dart` | 23 | Manifest validation (HTTPS, same host, sizes, hashes), client against a mock server (resume with Range, servers without Range, tampered files, cancel, redirects), update controller states, APK package/version/signature checks, install permission flow |
| `test/tool/generate_manifest_test.dart` | 4 | Release manifest generator, round trip through the app's client, refuses older versions and plain HTTP |
| `test/performance/large_database_test.dart` | 4 | 50,000 transactions: exact balances, fast totals, list pages, search and a 12-month report |
| `test/widgets/app_flow_test.dart` | 4 | Onboarding, double-tap protection when saving an expense, Sinhala home screen, hidden balances |
| `test/widgets/planner_flow_test.dart` | 2 | Create and complete a task, money hub tabs |
| `test/widgets/security_flow_test.dart` | 7 | Locked start, wrong PIN, background lock, fingerprint unlock, set/remove PIN, screen protection, backup password validation, restore from the welcome guide, delete all data |
| `test/widgets/update_flow_test.dart` | 2 | Update banner after the automatic check, Wi-Fi-only confirmation, custom update server (HTTPS only) |
| `test/widgets/backup_reminder_test.dart` | 2 | Backup reminder rules and snoozing |
| `test/widgets/accessibility_test.dart` | 3 | Android tap-target size, labelled buttons and WCAG text contrast on all main screens, onboarding and the lock screen; 2× text size in Sinhala on every tab |

Result on the build machine: **154 tests, all passing; `flutter analyze`
reports no issues.**

## Not covered automatically

These need a real phone and are part of the
[release checklist](RELEASE_CHECKLIST.md):

* Android code in `MainActivity.kt` / `ApkUpdates.kt` (screen protection,
  APK inspection, `PackageInstaller` session, install permission screen)
* Delivery of scheduled notifications and rescheduling after reboot
* The system biometric prompt, Android Keystore-backed storage
* File picker, share sheet, camera and photo picker
* The on-device test `integration_test/app_test.dart`
* A real update from an older installed version

## Writing widget tests

Use `test/helpers/test_harness.dart`:

* `pumpDawasaApp(tester, preferences: onboardedPrefs, platform: TestPlatform())`
* `runDb(tester, () => …)` for database work inside a widget test (it
  advances fake time; never use `tester.runAsync` with Drift)
* `settle(tester)` after taps
* Real file IO and isolates do not complete inside `testWidgets`; test that
  logic in plain `test()`s (see `backup_test.dart`).

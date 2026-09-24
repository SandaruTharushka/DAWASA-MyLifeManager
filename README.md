# DAWASA — Daily Life Manager

**Your Money. Your Plans. Your Day.** · **ඔබේ මුදල්. ඔබේ සැලසුම්. ඔබේ දවස.**

DAWASA is an offline-first Android app for Sri Lankan users that combines a
money manager and a daily planner, in Sinhala and English, with Sri Lankan
Rupees (LKR) as the default currency.

* **100% free** — no ads, no subscriptions, no trial, no paywalls.
* **No login, no cloud account, no tracking or analytics.**
* **Everything works offline.** Financial data never leaves the phone,
  except in a password-encrypted backup file the user saves or shares.

Developer: Sandaru Tharushka

## Features

| Area | What it does |
|------|--------------|
| Welcome guide | 6 steps: welcome, language, currency, opening balances, daily budget, reminders; or restore a backup instead |
| Home | Available balance, today's income/spending, "left to spend today", quick add, pending tasks, upcoming bills and loans, savings progress, 7-day chart, recent transactions, backup and update notices |
| Money | Expenses, income, transfers between own accounts, cash, bank, e-wallet and savings accounts, balance correction, categories, recurring transactions, receipt photos, search and filters |
| Budgets | Daily, weekly, monthly or custom-period budgets per category or overall, daily allowance, alerts at a chosen percentage (80% by default) and when exceeded |
| Bills | Recurring bills, "mark paid" that records a new expense, links an existing one or records nothing (no double counting), payment history |
| Planner | Tasks with priorities, due dates, repeat rules, reminders; shopping lists that can be recorded as one expense; habits with streaks; important dates (birthdays, anniversaries) with calendar view |
| Savings & loans | Savings goals (transfers to a savings account, never counted as spending), money lent and borrowed with repayments |
| Reports | Date ranges, income vs expenses, category breakdown, 6-month trend, budget performance, balances, CSV export (Excel-safe, formula-injection protected) and a text summary to share |
| Backup | AES-256-GCM encrypted `.dawasa` file (Argon2id key from the user's password); validated restore with a safety copy and undo; delete all data |
| Privacy | Optional PIN lock (Argon2id hash in Android Keystore storage, back-off after wrong attempts), fingerprint/face unlock, lock timeout, hide balances, block screenshots |
| Reminders | Local notifications for tasks, bills, budgets, loans, savings, habits, important dates and a daily planning nudge (inexact alarms; rescheduled after reboot) |
| Updates | Optional self-update from your own HTTPS server: manifest check, resumable download, SHA-256 and signature verification, Android installer with user confirmation |

## Project layout

```
lib/
  app/        app root, router, shell, lock gate, startup tasks
  core/       database (Drift), money & date types, settings, security,
              backup format, notifications, platform bridges
  features/   one folder per feature (data / presentation)
  ui/         theme, formatters, charts, shared widgets
  l10n/       ARB files (English, Sinhala) and generated localizations
android/      Android project (MainActivity, updater bridge, icons)
drift_schemas/ schema snapshots used by migration tests
test/         unit, database, migration, widget, performance tests
integration_test/ on-device end-to-end test
tool/         release manifest generator, icon rendering
scripts/      build, deploy and checksum scripts
website/      static download page and nginx example
docs/         documentation (below)
```

## Development

Requirements: Flutter 3.47 (Dart 3.13), Android SDK with API 36 and a JDK 17+.

```sh
flutter pub get
flutter gen-l10n                    # after editing lib/l10n/*.arb
dart run build_runner build         # after changing Drift tables
flutter analyze
flutter test
flutter run                         # on a phone or emulator
```

## Documentation

* [Architecture](docs/ARCHITECTURE.md)
* [Database and migrations](docs/DATABASE.md)
* [Build and release](docs/BUILD_AND_RELEASE.md) · [Release checklist](docs/RELEASE_CHECKLIST.md)
* [Update server](docs/UPDATE_SERVER.md)
* [Installing on a phone](docs/INSTALL.md)
* [Privacy](docs/PRIVACY.md)
* [Testing](docs/TESTING.md)

## License

All rights reserved by the developer unless a license file says otherwise.
Bundled fonts (Noto Sans Sinhala) are under the SIL Open Font License, see
`assets/fonts/OFL.txt`.

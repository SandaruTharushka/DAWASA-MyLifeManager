# Architecture

DAWASA is a single Flutter app with a feature-first structure. All data is
local; the only network use is the optional update check.

```
┌──────────────────────────── lib/app ────────────────────────────┐
│ AppRoot: opens the database, owns the ProviderScope, reloads it  │
│ DawasaApp → MaterialApp.router (GoRouter) → AppGate (lock)       │
│ StartupTasks: recurring transactions, reminder sync, update check│
└──────────────────────────────────────────────────────────────────┘
          │ providers (Riverpod)
┌──────────────── lib/features/<feature> ──────────────────────────┐
│ presentation/  screens, widgets, providers (StreamProvider,      │
│                Notifier)                                          │
│ data/          repositories and services over Drift              │
│ domain/        pure Dart rules and models                         │
└──────────────────────────────────────────────────────────────────┘
          │
┌──────────────────────────── lib/core ────────────────────────────┐
│ database (Drift/SQLite) · money · time · settings · security     │
│ backup format · notifications · platform bridges · l10n helpers  │
└──────────────────────────────────────────────────────────────────┘
```

## Layers

* **`lib/core`** has no feature knowledge. It holds the Drift database and
  tables, `Money`/`Currency` (integer minor units), `LocalDate`,
  `DateRange` and the RFC 5545 subset `RecurrenceRule`, preferences
  (SharedPreferences, device-only) and user settings (in the database, so
  they travel with backups), the secure store, PIN hashing, biometrics,
  the backup container, notification gateway and platform channels.
* **`lib/features`** contains one folder per feature (accounts,
  transactions, budgets, bills, tasks, shopping, savings, loans, habits,
  events, reports, home, backup, security, updates, reminders, settings,
  onboarding). Repositories are plain classes that take the database, so
  they are tested directly against an in-memory SQLite database.
* **`lib/ui`** has the theme (Material 3, light and dark, WCAG AA contrast),
  formatters, charts (fl_chart) and shared widgets.
* **`lib/app`** wires everything together.

## State management

Riverpod 3. Repositories are exposed with `Provider`; screens watch
`StreamProvider`s built on Drift's reactive queries, so every screen updates
by itself when data changes anywhere. App-wide state uses `Notifier`s
(preferences, user settings, today's date with midnight roll-over, the app
lock, the update controller).

`AppRoot` creates the database and a `ProviderScope`. Restoring a backup or
deleting all data goes through `appReloaderProvider`: the database is
closed, files are swapped while nothing holds them open, and a fresh scope
is created, so no provider can keep stale data.

## Navigation

GoRouter with a `StatefulShellRoute` for the five tabs (Home, Money,
Planner, Reports, Settings); detail and form pages open above the shell. A
redirect keeps first-time users in the welcome guide (the restore screen is
allowed there). Notification taps carry a route as payload.

## Money and dates

* Amounts are `int` minor units everywhere (database, calculations, CSV).
  Parsing and formatting never use floating point.
* Calendar dates are `LocalDate` values stored as `YYYY-MM-DD`; date
  arithmetic is done in UTC so daylight-saving changes cannot shift a
  day. Instants are stored as UTC ISO-8601 text.
* Reports group by the stored `local_date` of each transaction.

## Correctness rules

* **No double counting** — `TransactionRules` is the single source of
  truth: only `expense` counts as spending and only `income` counts as
  income. Transfers, savings deposits, loans, repayments and balance
  corrections move money between accounts without being income or
  spending. Account balances are the opening balance plus the signed sum of
  all movements, computed in SQL.
* **Duplicate taps** — forms create their record id when they open and
  saving is idempotent; `SubmitButton` ignores taps while saving. Records
  created automatically (recurring transactions, next task occurrence, loan
  and savings transactions, habit check-ins) use deterministic ids, so
  running the same step twice cannot create two rows.
* **Bills and shopping lists** can link an existing expense instead of
  recording a new one.

## Reminders

`planReminders` (pure function) turns tasks, bills, budgets, loans, savings
goals, habits and important dates into a list of notifications for the next
days. `ReminderSyncService` cancels everything and schedules that list on
launch, on resume, whenever a relevant table changes and when reminder
settings change. Alarms are inexact (`inexactAllowWhileIdle`); no exact-alarm
permission is requested. Notification ids are stable hashes of the source.

## Security and privacy

* Optional PIN lock: only an Argon2id hash (random salt) is stored, in
  `flutter_secure_storage` (Android Keystore). Wrong attempts are counted
  persistently with increasing pauses. Fingerprint/face unlock via
  `local_auth`. The lock screen sits above the router and hides the
  content from screen readers while locked.
* `FLAG_SECURE` (optional) blocks screenshots and the recent-apps preview.
* Android cloud backup and device transfer are disabled for app data.
* See [PRIVACY.md](PRIVACY.md).

## Backups

`.dawasa` files: magic, version, a JSON header (authenticated, not secret),
then AES-256-GCM ciphertext of a zlib-compressed archive containing a
`VACUUM INTO` snapshot of the database and the receipt photos. The key is
derived with Argon2id (32 MiB, 3 passes) from the user's password; the
parameters are stored in the header and bounded when read. Encryption,
decryption and validation run in a background isolate. A restore is fully
validated (authentication, `PRAGMA integrity_check`, schema version,
required tables, safe file names) before a safety copy is taken and the
database is swapped; the new database is opened once to run and verify
migrations before it is accepted.

## Updates

See [UPDATE_SERVER.md](UPDATE_SERVER.md). The app never downloads or runs
code itself; it downloads an APK over HTTPS, verifies SHA-256, size,
package name, version and signing certificate, and hands it to Android's
`PackageInstaller`, which asks the user to confirm.

## Localization

`lib/l10n/app_en.arb` and `app_si.arb` (generated Dart in
`lib/l10n/generated`). Screens use `context.l10n`; code outside widgets
(notifications) uses `lookupAppLocalizations`. Noto Sans Sinhala is bundled
so Sinhala renders correctly on every phone. A test checks that both
languages have the same messages and placeholders.

## Errors and logging

There is no crash reporting or analytics. Errors are printed to the local
log only. Recoverable problems (network, secure storage, notifications)
never block the rest of the app.

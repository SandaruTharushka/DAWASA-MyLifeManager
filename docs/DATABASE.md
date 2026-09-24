# Database

SQLite through [Drift](https://drift.simonbinder.eu/), file
`dawasa.sqlite` in the app's private support directory, opened in a
background isolate with `foreign_keys = ON`, WAL journal and
`synchronous = NORMAL`.

Conventions:

* Primary keys are UUID text (`newId()`), or deterministic UUID v5
  (`deterministicId(...)`) for rows created automatically.
* Money: `INTEGER` minor units (`amount_minor`), always positive; the
  direction comes from the row type. Currency: ISO code, `LKR` by default.
* Calendar dates: `TEXT 'YYYY-MM-DD'`. Instants: UTC ISO-8601 text.
* `created_at` / `updated_at` on user-editable tables.
* `CHECK` constraints guard amounts, transfer consistency, date ranges and
  percentages. Transactions `RESTRICT` deleting the accounts they use;
  child rows (budget categories, task reminders, bill payments, shopping
  items, savings movements, repayments, habit check-ins) `CASCADE` with
  their parent; optional links are `SET NULL`.

## Schema

Current version: **3** (`AppDatabase.latestSchemaVersion`).

### Version 1 — money

| Table | Purpose |
|-------|---------|
| `accounts` | Cash, bank, e-wallet, savings accounts; opening balance and date, archive flag |
| `transaction_categories` | Built-in (by `system_key`) and custom expense/income categories; unique `(kind, system_key)` |
| `transactions` | Every money movement: `type` (expense, income, transfer, reimbursement, loan given/received, repayments, adjustments), account, optional destination account (transfers only), category, instant and `local_date`, description, note, receipt, recurring rule, source record |
| `recurring_rules` | Templates that generate transactions on their due dates |
| `attachments` | Receipt photos stored in the app's private folder |
| `app_settings` | User settings that travel with backups (currency, daily budget, first day of week, date format, name) |
| `schema_migrations` | Log of applied schema versions |

Indexes: `transactions(local_date)`, `(account_id)`, `(to_account_id)`,
`(category_id)`, `(type, local_date)`, `(recurring_rule_id)`,
`transaction_categories(kind)`.

### Version 2 — planner

| Table | Purpose |
|-------|---------|
| `budgets`, `budget_categories` | Daily/weekly/monthly/custom budgets; no categories = overall budget; warning percentage; last alert (prevents repeated alerts) |
| `tasks`, `task_reminders` | Tasks with priority, due date/time, repeat rule, reminders (minutes before) |
| `bills`, `bill_payments` | Recurring bills and their payments; unique `(bill_id, due_date)` so a due date can be paid only once; a payment may link a transaction |
| `shopping_lists`, `shopping_items` | Lists and items; purchased items record the transaction they were paid with |

### Version 3 — life

| Table | Purpose |
|-------|---------|
| `savings_goals`, `savings_movements` | Goals and deposits/withdrawals (a movement may link its transfer) |
| `loans`, `loan_repayments` | Money lent/borrowed and repayments (each may link its transaction) |
| `habits`, `habit_logs` | Habits and daily check-ins; unique `(habit_id, date)` |
| `personal_events` | Birthdays, anniversaries and other important dates with yearly/other repeat rules and reminders |

## Migrations

Rules: **migrations never drop or rewrite user data**, and they are
independent of APK updates (a phone may jump from any old version to the
newest one).

* `drift_schemas/dawasa/drift_schema_vN.json` is a snapshot of every
  released schema.
* `lib/core/database/app_database.steps.dart` (generated) gives typed
  access to each historical schema; `onUpgrade` runs `stepByStep` with one
  function per version step inside a transaction. Foreign keys are off
  during the steps and switched back on when the database opens (debug
  builds also run `PRAGMA foreign_key_check`; restores always do).
* `test/drift/dawasa/migration_test.dart` migrates every old version to
  every newer one and compares the result with a fresh database of that
  version, and upgrades a realistic version 1 database checking that every
  account, category, transaction and setting survives unchanged.
* Restoring an older backup runs the same migrations (tested in
  `test/features/backup_test.dart`).

### Adding a schema version

1. Change the tables and increase `latestSchemaVersion`.
2. `dart run build_runner build --delete-conflicting-outputs`
3. `dart run drift_dev make-migrations` (writes the new snapshot, steps
   file and generated test schemas).
4. Add the `fromNToN+1` step: only `createTable`, `addColumn` (with a
   default), `createIndex`, or data copies that keep every row.
5. Extend the migration test with data of the previous version and run
   `flutter test test/drift`.

## Performance

Aggregates (balances, totals, category sums, daily sums) are computed in SQL
with indexes. `test/performance/large_database_test.dart` uses 50,000
transactions: balances ≈ 35 ms, month totals ≈ 5 ms, first page of the list
≈ 40 ms, search ≈ 12 ms, a 12-month report ≈ 150 ms (on the build machine).

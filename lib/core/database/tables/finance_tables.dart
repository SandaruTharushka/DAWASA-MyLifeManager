import 'package:drift/drift.dart';

import '../converters.dart';
import '../enums.dart';
import 'common.dart';

@DataClassName('Account')
class Accounts extends Table with UuidPrimaryKey, Timestamps {
  TextColumn get name => text().withLength(min: 1, max: 60)();
  TextColumn get type => textEnum<AccountType>()();
  TextColumn get currencyCode =>
      text().withLength(min: 3, max: 3).withDefault(const Constant('LKR'))();

  /// Balance before the first recorded transaction, in minor units.
  IntColumn get openingBalanceMinor =>
      integer().withDefault(const Constant(0))();
  TextColumn get openingDate =>
      text().map(const LocalDateConverter()).nullable()();
  IntColumn get colorValue => integer().nullable()();
  TextColumn get iconKey => text().nullable()();

  /// Whether this account counts towards the "available balance" total.
  BoolColumn get includeInTotal =>
      boolean().withDefault(const Constant(true))();
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
}

@DataClassName('TxCategory')
@TableIndex(name: 'idx_categories_kind', columns: {#kind})
class TransactionCategories extends Table with UuidPrimaryKey, Timestamps {
  TextColumn get kind => textEnum<CategoryKind>()();

  /// Stable key of a built-in category (e.g. `food`). Its label is localized
  /// unless the user renamed it ([name] not null).
  TextColumn get systemKey => text().nullable()();

  /// User supplied name. Required for custom categories.
  TextColumn get name => text().nullable().withLength(max: 40)();
  TextColumn get iconKey => text().withDefault(const Constant('category'))();
  IntColumn get colorValue =>
      integer().withDefault(const Constant(0xFF64748B))();
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
    {kind, systemKey},
  ];

  @override
  List<String> get customConstraints => [
    'CHECK (system_key IS NOT NULL OR name IS NOT NULL)',
  ];
}

@DataClassName('Attachment')
class Attachments extends Table with UuidPrimaryKey {
  /// Path relative to the app's private attachments directory.
  TextColumn get relativePath => text()();
  TextColumn get mimeType => text()();
  IntColumn get sizeBytes => integer()();
  DateTimeColumn get createdAt => dateTime().clientDefault(nowUtc)();
}

/// A recurring transaction template (e.g. monthly salary or rent).
@DataClassName('RecurringRuleRow')
class RecurringRules extends Table with UuidPrimaryKey, Timestamps {
  /// Encoded [RecurrenceRule].
  TextColumn get rule => text()();
  TextColumn get startDate => text().map(const LocalDateConverter())();

  /// Next occurrence that has not been generated yet; null once finished.
  TextColumn get nextDate =>
      text().map(const LocalDateConverter()).nullable()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();

  TextColumn get type => textEnum<TransactionType>()();
  IntColumn get amountMinor => integer()();
  TextColumn get currencyCode =>
      text().withLength(min: 3, max: 3).withDefault(const Constant('LKR'))();
  @ReferenceName('recurringRulesFrom')
  TextColumn get accountId =>
      text().references(Accounts, #id, onDelete: KeyAction.cascade)();
  @ReferenceName('recurringRulesTo')
  TextColumn get toAccountId => text().nullable().references(
    Accounts,
    #id,
    onDelete: KeyAction.cascade,
  )();
  TextColumn get categoryId => text().nullable().references(
    TransactionCategories,
    #id,
    onDelete: KeyAction.setNull,
  )();
  TextColumn get description => text().withDefault(const Constant(''))();
  TextColumn get note => text().nullable()();

  /// Local time of day used for generated transactions.
  IntColumn get timeOfDayMinutes =>
      integer().withDefault(const Constant(12 * 60))();

  @override
  List<String> get customConstraints => [
    'CHECK (amount_minor > 0)',
    "CHECK (type IN ('expense', 'income', 'transfer'))",
  ];
}

@DataClassName('MoneyTransaction')
@TableIndex(name: 'idx_tx_local_date', columns: {#localDate})
@TableIndex(name: 'idx_tx_account', columns: {#accountId})
@TableIndex(name: 'idx_tx_to_account', columns: {#toAccountId})
@TableIndex(name: 'idx_tx_category', columns: {#categoryId})
@TableIndex(name: 'idx_tx_type_date', columns: {#type, #localDate})
@TableIndex(name: 'idx_tx_recurring', columns: {#recurringRuleId})
class Transactions extends Table with UuidPrimaryKey, Timestamps {
  TextColumn get type => textEnum<TransactionType>()();

  /// Always positive; the direction is defined by [type].
  IntColumn get amountMinor => integer()();
  TextColumn get currencyCode =>
      text().withLength(min: 3, max: 3).withDefault(const Constant('LKR'))();

  /// Account the money leaves (outflows, transfers) or enters (inflows).
  @ReferenceName('transactionsFrom')
  TextColumn get accountId =>
      text().references(Accounts, #id, onDelete: KeyAction.restrict)();

  /// Destination account; only for transfers.
  @ReferenceName('transactionsTo')
  TextColumn get toAccountId => text().nullable().references(
    Accounts,
    #id,
    onDelete: KeyAction.restrict,
  )();
  TextColumn get categoryId => text().nullable().references(
    TransactionCategories,
    #id,
    onDelete: KeyAction.setNull,
  )();

  /// Exact instant (UTC).
  DateTimeColumn get occurredAt => dateTime()();

  /// Calendar date chosen by the user; all reports group by this column.
  TextColumn get localDate => text().map(const LocalDateConverter())();
  TextColumn get description => text().withDefault(const Constant(''))();
  TextColumn get note => text().nullable()();
  TextColumn get attachmentId => text().nullable().references(
    Attachments,
    #id,
    onDelete: KeyAction.setNull,
  )();
  TextColumn get recurringRuleId => text().nullable().references(
    RecurringRules,
    #id,
    onDelete: KeyAction.setNull,
  )();
  TextColumn get source => textEnum<TransactionSource>().withDefault(
    Constant(TransactionSource.manual.name),
  )();

  /// Id of the bill payment / shopping list / savings movement / loan record
  /// that created this transaction (informational).
  TextColumn get sourceRefId => text().nullable()();

  @override
  List<String> get customConstraints => [
    'CHECK (amount_minor > 0)',
    "CHECK ((type = 'transfer') = (to_account_id IS NOT NULL))",
    'CHECK (to_account_id IS NULL OR to_account_id <> account_id)',
  ];
}

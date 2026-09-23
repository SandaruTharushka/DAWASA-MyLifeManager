import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';

import '../../ui/format/formatters.dart';
import '../database/app_database.dart';
import '../money/currency.dart';

/// Settings that belong to the user's data and travel with backups.
@immutable
class UserSettings {
  const UserSettings({
    this.currencyCode = 'LKR',
    this.dailyBudgetMinor,
    this.firstDayOfWeek = DateTime.monday,
    this.dateFormat = DateDisplayFormat.medium,
    this.userName,
  });

  final String currencyCode;

  /// Optional daily spending budget in minor units.
  final int? dailyBudgetMinor;

  /// ISO weekday the week starts on (1 = Monday, 7 = Sunday).
  final int firstDayOfWeek;
  final DateDisplayFormat dateFormat;
  final String? userName;

  Currency get currency => Currencies.byCode(currencyCode);

  UserSettings copyWith({
    String? currencyCode,
    int? dailyBudgetMinor,
    bool clearDailyBudget = false,
    int? firstDayOfWeek,
    DateDisplayFormat? dateFormat,
    String? userName,
    bool clearUserName = false,
  }) {
    return UserSettings(
      currencyCode: currencyCode ?? this.currencyCode,
      dailyBudgetMinor: clearDailyBudget
          ? null
          : (dailyBudgetMinor ?? this.dailyBudgetMinor),
      firstDayOfWeek: firstDayOfWeek ?? this.firstDayOfWeek,
      dateFormat: dateFormat ?? this.dateFormat,
      userName: clearUserName ? null : (userName ?? this.userName),
    );
  }
}

/// Persists [UserSettings] in the `app_settings` table.
class UserSettingsRepository {
  UserSettingsRepository(this._db);

  final AppDatabase _db;

  static const kCurrency = 'currency_code';
  static const kDailyBudget = 'daily_budget_minor';
  static const kFirstDayOfWeek = 'first_day_of_week';
  static const kDateFormat = 'date_format';
  static const kUserName = 'user_name';

  Future<UserSettings> load() async {
    final rows = await _db.select(_db.appSettings).get();
    final map = {for (final r in rows) r.key: r.value};
    return UserSettings(
      currencyCode: map[kCurrency] ?? 'LKR',
      dailyBudgetMinor: int.tryParse(map[kDailyBudget] ?? ''),
      firstDayOfWeek: (int.tryParse(map[kFirstDayOfWeek] ?? '') ?? 1).clamp(
        1,
        7,
      ),
      dateFormat: DateDisplayFormat.fromName(map[kDateFormat]),
      userName: (map[kUserName]?.trim().isEmpty ?? true)
          ? null
          : map[kUserName]!.trim(),
    );
  }

  Future<void> save(UserSettings s) async {
    await _db.transaction(() async {
      await _put(kCurrency, s.currencyCode);
      await _put(kDailyBudget, s.dailyBudgetMinor?.toString());
      await _put(kFirstDayOfWeek, s.firstDayOfWeek.toString());
      await _put(kDateFormat, s.dateFormat.name);
      await _put(kUserName, s.userName);
    });
  }

  Future<String?> getRaw(String key) async {
    final row = await (_db.select(
      _db.appSettings,
    )..where((t) => t.key.equals(key))).getSingleOrNull();
    return row?.value;
  }

  Future<void> putRaw(String key, String? value) => _put(key, value);

  Future<void> _put(String key, String? value) async {
    if (value == null) {
      await (_db.delete(_db.appSettings)..where((t) => t.key.equals(key))).go();
      return;
    }
    await _db
        .into(_db.appSettings)
        .insertOnConflictUpdate(
          AppSettingsCompanion.insert(
            key: key,
            value: value,
            updatedAt: Value(nowUtc()),
          ),
        );
  }
}

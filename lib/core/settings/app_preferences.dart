import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Device-local, non-sensitive preferences (SharedPreferences).
///
/// These are intentionally NOT part of backups: they describe this phone
/// (theme, notification choices, update settings) rather than the user's
/// records.
@immutable
class AppPreferences {
  const AppPreferences({
    this.languageCode,
    this.themeMode = ThemeMode.system,
    this.onboardingComplete = false,
    this.hideBalancesOnStart = false,
    this.screenProtection = false,
    this.lockTimeoutSeconds = 0,
    this.notificationsEnabled = true,
    this.notifyTasks = true,
    this.notifyBills = true,
    this.notifyEvents = true,
    this.notifyBudgets = true,
    this.notifyLoans = true,
    this.notifySavings = true,
    this.notifyHabits = true,
    this.dailyPlanningEnabled = false,
    this.dailyPlanningMinutes = 20 * 60,
    this.autoCheckUpdates = true,
    this.wifiOnlyUpdates = true,
    this.customUpdateUrl,
    this.lastUpdateCheck,
    this.lastBackupAt,
  });

  /// `en` or `si`; null until the user picks one.
  final String? languageCode;
  final ThemeMode themeMode;
  final bool onboardingComplete;
  final bool hideBalancesOnStart;
  final bool screenProtection;

  /// Seconds in background before the app locks again (0 = immediately).
  final int lockTimeoutSeconds;

  final bool notificationsEnabled;
  final bool notifyTasks;
  final bool notifyBills;
  final bool notifyEvents;
  final bool notifyBudgets;
  final bool notifyLoans;
  final bool notifySavings;
  final bool notifyHabits;
  final bool dailyPlanningEnabled;
  final int dailyPlanningMinutes;

  final bool autoCheckUpdates;
  final bool wifiOnlyUpdates;

  /// Optional override of the build-time update server URL.
  final String? customUpdateUrl;
  final DateTime? lastUpdateCheck;
  final DateTime? lastBackupAt;

  AppPreferences copyWith({
    String? languageCode,
    ThemeMode? themeMode,
    bool? onboardingComplete,
    bool? hideBalancesOnStart,
    bool? screenProtection,
    int? lockTimeoutSeconds,
    bool? notificationsEnabled,
    bool? notifyTasks,
    bool? notifyBills,
    bool? notifyEvents,
    bool? notifyBudgets,
    bool? notifyLoans,
    bool? notifySavings,
    bool? notifyHabits,
    bool? dailyPlanningEnabled,
    int? dailyPlanningMinutes,
    bool? autoCheckUpdates,
    bool? wifiOnlyUpdates,
    String? customUpdateUrl,
    bool clearCustomUpdateUrl = false,
    DateTime? lastUpdateCheck,
    DateTime? lastBackupAt,
  }) {
    return AppPreferences(
      languageCode: languageCode ?? this.languageCode,
      themeMode: themeMode ?? this.themeMode,
      onboardingComplete: onboardingComplete ?? this.onboardingComplete,
      hideBalancesOnStart: hideBalancesOnStart ?? this.hideBalancesOnStart,
      screenProtection: screenProtection ?? this.screenProtection,
      lockTimeoutSeconds: lockTimeoutSeconds ?? this.lockTimeoutSeconds,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      notifyTasks: notifyTasks ?? this.notifyTasks,
      notifyBills: notifyBills ?? this.notifyBills,
      notifyEvents: notifyEvents ?? this.notifyEvents,
      notifyBudgets: notifyBudgets ?? this.notifyBudgets,
      notifyLoans: notifyLoans ?? this.notifyLoans,
      notifySavings: notifySavings ?? this.notifySavings,
      notifyHabits: notifyHabits ?? this.notifyHabits,
      dailyPlanningEnabled: dailyPlanningEnabled ?? this.dailyPlanningEnabled,
      dailyPlanningMinutes: dailyPlanningMinutes ?? this.dailyPlanningMinutes,
      autoCheckUpdates: autoCheckUpdates ?? this.autoCheckUpdates,
      wifiOnlyUpdates: wifiOnlyUpdates ?? this.wifiOnlyUpdates,
      customUpdateUrl: clearCustomUpdateUrl
          ? null
          : (customUpdateUrl ?? this.customUpdateUrl),
      lastUpdateCheck: lastUpdateCheck ?? this.lastUpdateCheck,
      lastBackupAt: lastBackupAt ?? this.lastBackupAt,
    );
  }
}

/// Reads and writes [AppPreferences] to SharedPreferences.
class PreferencesStore {
  PreferencesStore(this._prefs);

  final SharedPreferences _prefs;

  static const _kLanguage = 'pref.language';
  static const _kTheme = 'pref.theme';
  static const _kOnboarding = 'pref.onboardingComplete';
  static const _kHideBalances = 'pref.hideBalancesOnStart';
  static const _kScreenProtection = 'pref.screenProtection';
  static const _kLockTimeout = 'pref.lockTimeoutSeconds';
  static const _kNotif = 'pref.notif.enabled';
  static const _kNotifTasks = 'pref.notif.tasks';
  static const _kNotifBills = 'pref.notif.bills';
  static const _kNotifEvents = 'pref.notif.events';
  static const _kNotifBudgets = 'pref.notif.budgets';
  static const _kNotifLoans = 'pref.notif.loans';
  static const _kNotifSavings = 'pref.notif.savings';
  static const _kNotifHabits = 'pref.notif.habits';
  static const _kDailyPlanning = 'pref.notif.dailyPlanning';
  static const _kDailyPlanningMinutes = 'pref.notif.dailyPlanningMinutes';
  static const _kAutoUpdate = 'pref.update.autoCheck';
  static const _kWifiOnly = 'pref.update.wifiOnly';
  static const _kUpdateUrl = 'pref.update.customUrl';
  static const _kLastUpdateCheck = 'pref.update.lastCheck';
  static const _kLastBackup = 'pref.backup.last';

  AppPreferences load() {
    const d = AppPreferences();
    DateTime? readDate(String key) {
      final v = _prefs.getString(key);
      return v == null ? null : DateTime.tryParse(v);
    }

    return AppPreferences(
      languageCode: _prefs.getString(_kLanguage),
      themeMode:
          ThemeMode.values
              .where((m) => m.name == _prefs.getString(_kTheme))
              .firstOrNull ??
          d.themeMode,
      onboardingComplete: _prefs.getBool(_kOnboarding) ?? false,
      hideBalancesOnStart: _prefs.getBool(_kHideBalances) ?? false,
      screenProtection: _prefs.getBool(_kScreenProtection) ?? false,
      lockTimeoutSeconds: _prefs.getInt(_kLockTimeout) ?? 0,
      notificationsEnabled: _prefs.getBool(_kNotif) ?? d.notificationsEnabled,
      notifyTasks: _prefs.getBool(_kNotifTasks) ?? true,
      notifyBills: _prefs.getBool(_kNotifBills) ?? true,
      notifyEvents: _prefs.getBool(_kNotifEvents) ?? true,
      notifyBudgets: _prefs.getBool(_kNotifBudgets) ?? true,
      notifyLoans: _prefs.getBool(_kNotifLoans) ?? true,
      notifySavings: _prefs.getBool(_kNotifSavings) ?? true,
      notifyHabits: _prefs.getBool(_kNotifHabits) ?? true,
      dailyPlanningEnabled: _prefs.getBool(_kDailyPlanning) ?? false,
      dailyPlanningMinutes:
          _prefs.getInt(_kDailyPlanningMinutes) ?? d.dailyPlanningMinutes,
      autoCheckUpdates: _prefs.getBool(_kAutoUpdate) ?? true,
      wifiOnlyUpdates: _prefs.getBool(_kWifiOnly) ?? true,
      customUpdateUrl: _prefs.getString(_kUpdateUrl),
      lastUpdateCheck: readDate(_kLastUpdateCheck),
      lastBackupAt: readDate(_kLastBackup),
    );
  }

  Future<void> save(AppPreferences p) async {
    Future<void> setOrRemove(String key, String? value) async {
      if (value == null) {
        await _prefs.remove(key);
      } else {
        await _prefs.setString(key, value);
      }
    }

    await Future.wait([
      setOrRemove(_kLanguage, p.languageCode),
      _prefs.setString(_kTheme, p.themeMode.name),
      _prefs.setBool(_kOnboarding, p.onboardingComplete),
      _prefs.setBool(_kHideBalances, p.hideBalancesOnStart),
      _prefs.setBool(_kScreenProtection, p.screenProtection),
      _prefs.setInt(_kLockTimeout, p.lockTimeoutSeconds),
      _prefs.setBool(_kNotif, p.notificationsEnabled),
      _prefs.setBool(_kNotifTasks, p.notifyTasks),
      _prefs.setBool(_kNotifBills, p.notifyBills),
      _prefs.setBool(_kNotifEvents, p.notifyEvents),
      _prefs.setBool(_kNotifBudgets, p.notifyBudgets),
      _prefs.setBool(_kNotifLoans, p.notifyLoans),
      _prefs.setBool(_kNotifSavings, p.notifySavings),
      _prefs.setBool(_kNotifHabits, p.notifyHabits),
      _prefs.setBool(_kDailyPlanning, p.dailyPlanningEnabled),
      _prefs.setInt(_kDailyPlanningMinutes, p.dailyPlanningMinutes),
      _prefs.setBool(_kAutoUpdate, p.autoCheckUpdates),
      _prefs.setBool(_kWifiOnly, p.wifiOnlyUpdates),
      setOrRemove(_kUpdateUrl, p.customUpdateUrl),
      setOrRemove(_kLastUpdateCheck, p.lastUpdateCheck?.toIso8601String()),
      setOrRemove(_kLastBackup, p.lastBackupAt?.toIso8601String()),
    ]);
  }

  /// Before the user picks a language, follow the device (Sinhala or
  /// English).
  Future<void> ensureLanguage(String deviceLanguageCode) async {
    if (_prefs.getString(_kLanguage) != null) return;
    await _prefs.setString(
      _kLanguage,
      deviceLanguageCode == 'si' ? 'si' : 'en',
    );
  }

  Future<void> clear() => _prefs.clear();

  /// Removes every preference except the chosen language, so the welcome
  /// guide after "delete all data" appears in the user's language.
  Future<void> resetKeepingLanguage() async {
    final language = _prefs.getString(_kLanguage);
    await _prefs.clear();
    if (language != null) await _prefs.setString(_kLanguage, language);
  }

  static const _kNotice = 'app.notice';

  /// One-time message shown after the app reloads (restore, delete all).
  Future<void> setNotice(String notice) => _prefs.setString(_kNotice, notice);

  String? takeNotice() {
    final notice = _prefs.getString(_kNotice);
    if (notice != null) _prefs.remove(_kNotice);
    return notice;
  }
}

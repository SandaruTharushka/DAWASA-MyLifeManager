import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../ui/format/formatters.dart';
import 'database/app_database.dart';
import 'money/currency.dart';
import 'settings/app_preferences.dart';
import 'settings/user_settings.dart';
import 'time/local_date.dart';

/// The open database. Overridden in `bootstrap()` and in tests.
final databaseProvider = Provider<AppDatabase>(
  (ref) => throw UnimplementedError('databaseProvider must be overridden'),
);

final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) =>
      throw UnimplementedError('sharedPreferencesProvider must be overridden'),
);

/// User settings loaded before the first frame. Overridden in bootstrap.
final initialUserSettingsProvider = Provider<UserSettings>(
  (ref) => const UserSettings(),
);

/// Current time source; overridable in tests.
final clockProvider = Provider<DateTime Function()>((ref) => DateTime.now);

final preferencesStoreProvider = Provider<PreferencesStore>(
  (ref) => PreferencesStore(ref.watch(sharedPreferencesProvider)),
);

class PreferencesController extends Notifier<AppPreferences> {
  @override
  AppPreferences build() => ref.watch(preferencesStoreProvider).load();

  Future<void> update(AppPreferences Function(AppPreferences) change) async {
    final next = change(state);
    state = next;
    await ref.read(preferencesStoreProvider).save(next);
  }
}

final preferencesProvider =
    NotifierProvider<PreferencesController, AppPreferences>(
      PreferencesController.new,
    );

final userSettingsRepositoryProvider = Provider<UserSettingsRepository>(
  (ref) => UserSettingsRepository(ref.watch(databaseProvider)),
);

class UserSettingsController extends Notifier<UserSettings> {
  @override
  UserSettings build() => ref.watch(initialUserSettingsProvider);

  Future<void> update(UserSettings Function(UserSettings) change) async {
    final next = change(state);
    state = next;
    await ref.read(userSettingsRepositoryProvider).save(next);
  }
}

final userSettingsProvider =
    NotifierProvider<UserSettingsController, UserSettings>(
      UserSettingsController.new,
    );

/// The user's display currency.
final currencyProvider = Provider<Currency>(
  (ref) => ref.watch(userSettingsProvider.select((s) => s.currency)),
);

final localeNameProvider = Provider<String>(
  (ref) => ref.watch(preferencesProvider.select((p) => p.languageCode)) ?? 'en',
);

final dateFormatterProvider = Provider<AppDateFormatter>((ref) {
  return AppDateFormatter(
    localeName: ref.watch(localeNameProvider),
    format: ref.watch(userSettingsProvider.select((s) => s.dateFormat)),
  );
});

/// Today's calendar date. Rolls over automatically at local midnight and can
/// be refreshed when the app resumes (e.g. after the user changed the clock).
class TodayController extends Notifier<LocalDate> {
  Timer? _timer;

  @override
  LocalDate build() {
    ref.onDispose(() => _timer?.cancel());
    final now = ref.watch(clockProvider)();
    _schedule(now);
    return LocalDate.fromDateTime(now);
  }

  void _schedule(DateTime now) {
    _timer?.cancel();
    final nextMidnight = DateTime(now.year, now.month, now.day + 1);
    final wait = nextMidnight.difference(now) + const Duration(seconds: 1);
    _timer = Timer(wait, refresh);
  }

  void refresh() {
    final now = ref.read(clockProvider)();
    final today = LocalDate.fromDateTime(now);
    if (today != state) state = today;
    _schedule(now);
  }
}

final todayProvider = NotifierProvider<TodayController, LocalDate>(
  TodayController.new,
);

/// Whether monetary balances are currently masked on screen.
class BalancesHiddenController extends Notifier<bool> {
  @override
  bool build() =>
      ref.read(preferencesProvider.select((p) => p.hideBalancesOnStart));

  void toggle() => state = !state;

  void set(bool hidden) => state = hidden;
}

final balancesHiddenProvider = NotifierProvider<BalancesHiddenController, bool>(
  BalancesHiddenController.new,
);

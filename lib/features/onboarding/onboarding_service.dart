import '../../core/database/app_database.dart';
import '../../core/settings/app_preferences.dart';
import '../../core/settings/user_settings.dart';
import '../../core/time/local_date.dart';
import '../accounts/data/account_repository.dart';

/// Choices collected during onboarding.
class OnboardingResult {
  const OnboardingResult({
    required this.languageCode,
    required this.currencyCode,
    this.cashMinor,
    this.bankMinor,
    this.walletMinor,
    this.dailyBudgetMinor,
    required this.cashName,
    required this.bankName,
    required this.walletName,
  });

  final String languageCode;
  final String currencyCode;
  final int? cashMinor;
  final int? bankMinor;
  final int? walletMinor;
  final int? dailyBudgetMinor;

  /// Localized default account names.
  final String cashName;
  final String bankName;
  final String walletName;
}

/// Applies onboarding choices. Safe to run again when the user replays the
/// welcome guide: accounts are only created when none exist yet.
class OnboardingService {
  OnboardingService({required this.accounts, required this.settingsRepository});

  final AccountRepository accounts;
  final UserSettingsRepository settingsRepository;

  Future<bool> hasAccounts() async =>
      (await accounts.accounts(includeArchived: true)).isNotEmpty;

  Future<
    ({UserSettings settings, AppPreferences Function(AppPreferences) prefs})
  >
  complete(OnboardingResult r, UserSettings current, LocalDate today) async {
    if (!await hasAccounts()) {
      await accounts.create(
        name: r.cashName,
        type: AccountType.cash,
        currencyCode: r.currencyCode,
        openingBalanceMinor: r.cashMinor ?? 0,
        openingDate: today,
      );
      if (r.bankMinor != null) {
        await accounts.create(
          name: r.bankName,
          type: AccountType.bank,
          currencyCode: r.currencyCode,
          openingBalanceMinor: r.bankMinor!,
          openingDate: today,
        );
      }
      if (r.walletMinor != null) {
        await accounts.create(
          name: r.walletName,
          type: AccountType.eWallet,
          currencyCode: r.currencyCode,
          openingBalanceMinor: r.walletMinor!,
          openingDate: today,
        );
      }
    }
    final settings = current.copyWith(
      currencyCode: r.currencyCode,
      dailyBudgetMinor: r.dailyBudgetMinor,
      clearDailyBudget: r.dailyBudgetMinor == null,
    );
    await settingsRepository.save(settings);
    return (
      settings: settings,
      prefs: (AppPreferences p) =>
          p.copyWith(languageCode: r.languageCode, onboardingComplete: true),
    );
  }
}

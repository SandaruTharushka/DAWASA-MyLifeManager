// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'DAWASA';

  @override
  String get appTitle => 'DAWASA — Daily Life Manager';

  @override
  String get appTagline => 'Your Money. Your Plans. Your Day.';

  @override
  String get navHome => 'Home';

  @override
  String get navMoney => 'Money';

  @override
  String get navPlanner => 'Planner';

  @override
  String get navReports => 'Reports';

  @override
  String get navSettings => 'Settings';

  @override
  String get actionSave => 'Save';

  @override
  String get actionCancel => 'Cancel';

  @override
  String get actionDelete => 'Delete';

  @override
  String get actionEdit => 'Edit';

  @override
  String get actionAdd => 'Add';

  @override
  String get actionDone => 'Done';

  @override
  String get actionNext => 'Next';

  @override
  String get actionBack => 'Back';

  @override
  String get actionSkip => 'Skip';

  @override
  String get actionClose => 'Close';

  @override
  String get actionConfirm => 'Confirm';

  @override
  String get actionRetry => 'Try again';

  @override
  String get actionSearch => 'Search';

  @override
  String get actionFilter => 'Filter';

  @override
  String get actionClear => 'Clear';

  @override
  String get actionDuplicate => 'Duplicate';

  @override
  String get actionShare => 'Share';

  @override
  String get actionExport => 'Export';

  @override
  String get actionChange => 'Change';

  @override
  String get actionUndo => 'Undo';

  @override
  String get actionArchive => 'Archive';

  @override
  String get actionUnarchive => 'Restore from archive';

  @override
  String get actionGetStarted => 'Get started';

  @override
  String get actionContinue => 'Continue';

  @override
  String get actionSeeAll => 'See all';

  @override
  String get actionShow => 'Show';

  @override
  String get actionHide => 'Hide';

  @override
  String get actionSelect => 'Select';

  @override
  String get actionAllow => 'Allow';

  @override
  String get actionNotNow => 'Not now';

  @override
  String get actionOpenSettings => 'Open settings';

  @override
  String get commonAll => 'All';

  @override
  String get commonNone => 'None';

  @override
  String get commonOptional => 'Optional';

  @override
  String get commonAmount => 'Amount';

  @override
  String get commonDate => 'Date';

  @override
  String get commonTime => 'Time';

  @override
  String get commonNote => 'Note';

  @override
  String get commonDescription => 'Description';

  @override
  String get commonCategory => 'Category';

  @override
  String get commonAccount => 'Account';

  @override
  String get commonName => 'Name';

  @override
  String get commonToday => 'Today';

  @override
  String get commonYesterday => 'Yesterday';

  @override
  String get commonTomorrow => 'Tomorrow';

  @override
  String get commonYes => 'Yes';

  @override
  String get commonNo => 'No';

  @override
  String get commonOk => 'OK';

  @override
  String get commonTotal => 'Total';

  @override
  String get commonStartDate => 'Start date';

  @override
  String get commonEndDate => 'End date';

  @override
  String get commonNoDate => 'No date';

  @override
  String get commonNoTime => 'No time';

  @override
  String get commonDetails => 'Details';

  @override
  String get commonHistory => 'History';

  @override
  String get commonActive => 'Active';

  @override
  String get commonArchived => 'Archived';

  @override
  String get commonProgress => 'Progress';

  @override
  String get commonRemaining => 'Remaining';

  @override
  String get commonOverdue => 'Overdue';

  @override
  String get commonCompleted => 'Completed';

  @override
  String get commonPending => 'Pending';

  @override
  String get commonUnknown => 'Unknown';

  @override
  String get commonLoading => 'Loading…';

  @override
  String get commonNotSet => 'Not set';

  @override
  String get commonCurrency => 'Currency';

  @override
  String get commonReminder => 'Reminder';

  @override
  String get commonRepeat => 'Repeat';

  @override
  String commonPercentUsed(int percent) {
    return '$percent% used';
  }

  @override
  String commonOfAmount(String amount, String total) {
    return '$amount of $total';
  }

  @override
  String commonDaysLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days left',
      one: '1 day left',
      zero: 'Due today',
    );
    return '$_temp0';
  }

  @override
  String commonDaysOverdue(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days overdue',
      one: '1 day overdue',
    );
    return '$_temp0';
  }

  @override
  String commonItemsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items',
      one: '1 item',
      zero: 'No items',
    );
    return '$_temp0';
  }

  @override
  String get validationRequired => 'This field is required';

  @override
  String get validationAmountInvalid => 'Enter a valid amount';

  @override
  String get validationAmountPositive => 'Amount must be greater than zero';

  @override
  String get validationAmountTooLarge => 'Amount is too large';

  @override
  String get validationTooManyDecimals => 'Too many decimal places';

  @override
  String get validationNameTooLong => 'Name is too long';

  @override
  String get validationNumberInvalid => 'Enter a valid number';

  @override
  String get validationEndBeforeStart => 'End date cannot be before start date';

  @override
  String get feedbackSaved => 'Saved';

  @override
  String get feedbackDeleted => 'Deleted';

  @override
  String get feedbackError => 'Something went wrong. Please try again.';

  @override
  String get feedbackAlreadySaved => 'Already saved';

  @override
  String get confirmDeleteTitle => 'Delete?';

  @override
  String get confirmDeleteMessage => 'This cannot be undone.';

  @override
  String get emptyGeneric => 'Nothing here yet';

  @override
  String get errorLoading => 'Could not load data';

  @override
  String get greetingMorning => 'Good morning';

  @override
  String get greetingAfternoon => 'Good afternoon';

  @override
  String get greetingEvening => 'Good evening';

  @override
  String greetingWithName(String greeting, String name) {
    return '$greeting, $name';
  }

  @override
  String get weekdayMon => 'Monday';

  @override
  String get weekdayTue => 'Tuesday';

  @override
  String get weekdayWed => 'Wednesday';

  @override
  String get weekdayThu => 'Thursday';

  @override
  String get weekdayFri => 'Friday';

  @override
  String get weekdaySat => 'Saturday';

  @override
  String get weekdaySun => 'Sunday';

  @override
  String get repeatNever => 'Does not repeat';

  @override
  String get repeatDaily => 'Daily';

  @override
  String get repeatWeekly => 'Weekly';

  @override
  String get repeatMonthly => 'Monthly';

  @override
  String get repeatYearly => 'Yearly';

  @override
  String get repeatCustom => 'Custom';

  @override
  String get repeatEvery => 'Repeat every';

  @override
  String get repeatUnitDays => 'days';

  @override
  String get repeatUnitWeeks => 'weeks';

  @override
  String get repeatUnitMonths => 'months';

  @override
  String get repeatUnitYears => 'years';

  @override
  String repeatEveryDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Every $count days',
      one: 'Every day',
    );
    return '$_temp0';
  }

  @override
  String repeatEveryWeeks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Every $count weeks',
      one: 'Every week',
    );
    return '$_temp0';
  }

  @override
  String repeatEveryMonths(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Every $count months',
      one: 'Every month',
    );
    return '$_temp0';
  }

  @override
  String repeatEveryYears(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Every $count years',
      one: 'Every year',
    );
    return '$_temp0';
  }

  @override
  String repeatUntilDate(String date) {
    return 'until $date';
  }

  @override
  String repeatTimesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count times',
      one: 'once',
    );
    return '$_temp0';
  }

  @override
  String get repeatOnDays => 'On days';

  @override
  String get repeatEnds => 'Ends';

  @override
  String get repeatEndsNever => 'Never';

  @override
  String get repeatEndsOnDate => 'On a date';

  @override
  String get repeatEndsAfter => 'After a number of times';

  @override
  String get repeatOccurrences => 'Number of times';

  @override
  String get rangeToday => 'Today';

  @override
  String get rangeYesterday => 'Yesterday';

  @override
  String get rangeLast7Days => 'Last 7 days';

  @override
  String get rangeThisMonth => 'This month';

  @override
  String get rangeLastMonth => 'Previous month';

  @override
  String get rangeCustom => 'Custom range';

  @override
  String get onbWelcomeTitle => 'Welcome to DAWASA';

  @override
  String get onbWelcomeBody =>
      'Manage your money, plans and daily life in one simple app.';

  @override
  String get onbPointFree => '100% free — no ads, no subscriptions';

  @override
  String get onbPointOffline => 'Works fully offline';

  @override
  String get onbPointPrivate => 'Your data stays on your phone';

  @override
  String get onbPointNoLogin => 'No login or registration';

  @override
  String get onbLanguageTitle => 'Choose your language';

  @override
  String get onbLanguageBody => 'You can change this later in Settings.';

  @override
  String get onbCurrencyTitle => 'Choose your currency';

  @override
  String get onbCurrencyBody => 'All amounts will be shown in this currency.';

  @override
  String get onbBalancesTitle => 'Your current balances';

  @override
  String get onbBalancesBody =>
      'Enter how much money you have now. You can skip this and add accounts later.';

  @override
  String get onbCashBalance => 'Cash in hand';

  @override
  String get onbBankBalance => 'Bank balance';

  @override
  String get onbWalletBalance => 'Other wallet balance';

  @override
  String get onbBudgetTitle => 'Daily spending budget';

  @override
  String get onbBudgetBody =>
      'Set how much you want to spend per day. DAWASA will show what is left each day.';

  @override
  String get onbBudgetLabel => 'Daily budget';

  @override
  String get onbRemindersTitle => 'Reminders';

  @override
  String get onbRemindersBody =>
      'DAWASA can remind you about tasks, bills and important dates. Reminders are created on your phone — nothing is sent to the internet.';

  @override
  String get onbEnableReminders => 'Enable reminders';

  @override
  String get onbRemindersEnabled => 'Reminders are enabled';

  @override
  String get onbRemindersDenied =>
      'Permission was not granted. You can enable it later in Settings.';

  @override
  String get onbFinish => 'Start using DAWASA';

  @override
  String onbStepOf(int step, int total) {
    return 'Step $step of $total';
  }

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsGeneral => 'General';

  @override
  String get settingsSecurity => 'Security & privacy';

  @override
  String get settingsReminders => 'Reminders';

  @override
  String get settingsData => 'Data';

  @override
  String get settingsUpdates => 'Updates';

  @override
  String get settingsAbout => 'About';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsCurrency => 'Currency';

  @override
  String get settingsTheme => 'Theme';

  @override
  String get settingsThemeSystem => 'System default';

  @override
  String get settingsThemeLight => 'Light';

  @override
  String get settingsThemeDark => 'Dark';

  @override
  String get settingsDateFormat => 'Date format';

  @override
  String get settingsFirstDayOfWeek => 'First day of week';

  @override
  String get settingsYourName => 'Your name';

  @override
  String get settingsYourNameHint =>
      'Used only for the greeting on the home screen';

  @override
  String get settingsDailyBudget => 'Daily budget';

  @override
  String get settingsCategories => 'Categories';

  @override
  String get settingsCurrencyChangeNote =>
      'Changing the currency only changes how new amounts are shown. Existing amounts are not converted.';

  @override
  String get settingsPrivacyMode => 'Hide balances when the app opens';

  @override
  String get settingsPrivacyModeDesc => 'Useful when you open DAWASA in public';

  @override
  String get settingsScreenProtection => 'Protect screen contents';

  @override
  String get settingsScreenProtectionDesc =>
      'Blocks screenshots and hides DAWASA in the recent apps view';

  @override
  String get settingsNotifications => 'Notifications';

  @override
  String get settingsNotificationsEnabled => 'Allow reminders';

  @override
  String get settingsNotifyTasks => 'Task reminders';

  @override
  String get settingsNotifyBills => 'Bill reminders';

  @override
  String get settingsNotifyEvents => 'Important date reminders';

  @override
  String get settingsNotifyBudgets => 'Budget alerts';

  @override
  String get settingsNotifyLoans => 'Loan repayment reminders';

  @override
  String get settingsNotifySavings => 'Savings goal reminders';

  @override
  String get settingsNotifyHabits => 'Habit reminders';

  @override
  String get settingsDailyPlanning => 'Daily planning reminder';

  @override
  String get settingsDailyPlanningDesc =>
      'A daily nudge to review your day and record spending';

  @override
  String get settingsDailyPlanningTime => 'Reminder time';

  @override
  String get settingsNotificationsBlocked =>
      'Notifications are turned off for DAWASA in Android settings.';

  @override
  String get settingsBatteryNote =>
      'Some phones delay reminders to save battery. If reminders arrive late, allow DAWASA to run without battery restrictions.';

  @override
  String get settingsBackup => 'Create backup';

  @override
  String get settingsBackupDesc =>
      'Encrypted file protected with your password';

  @override
  String get settingsRestore => 'Restore from backup';

  @override
  String get settingsExportCsv => 'Export transactions (CSV)';

  @override
  String get settingsDeleteAll => 'Delete all personal data';

  @override
  String get settingsDeleteAllDesc => 'Erases every record from this phone';

  @override
  String get settingsUninstallWarning =>
      'Your data is stored only on this phone. Uninstalling DAWASA or clearing its storage deletes it permanently unless you keep a backup file somewhere safe.';

  @override
  String get settingsCurrentVersion => 'Current version';

  @override
  String get settingsCheckUpdates => 'Check for updates';

  @override
  String get settingsAutoCheckUpdates => 'Check for updates automatically';

  @override
  String get settingsAutoCheckUpdatesDesc =>
      'At most once a day, only when connected';

  @override
  String get settingsWifiOnly => 'Download updates on Wi-Fi only';

  @override
  String get settingsUpdateServer => 'Update server';

  @override
  String get settingsUpdateServerHint =>
      'HTTPS address of the DAWASA update folder';

  @override
  String get settingsUpdateServerInvalid => 'Enter a valid https:// address';

  @override
  String get settingsUpdateServerReset => 'Use default server';

  @override
  String get settingsReleaseNotes => 'Release notes';

  @override
  String get settingsReplayOnboarding => 'Show welcome guide again';

  @override
  String get settingsLicenses => 'Open-source licenses';

  @override
  String get settingsPrivacyPolicy => 'Privacy';

  @override
  String get aboutDeveloper => 'Developer';

  @override
  String get aboutDeveloperName => 'Sandaru Tharushka';

  @override
  String get aboutFree => '100% Free';

  @override
  String get aboutNoAds => 'No Ads';

  @override
  String get aboutNoSubscription => 'No Subscription';

  @override
  String get aboutWebsite => 'Website';

  @override
  String get aboutContact => 'Contact';

  @override
  String aboutVersion(String version, String code) {
    return 'Version $version ($code)';
  }

  @override
  String get privacyTitle => 'Your privacy';

  @override
  String get privacyBody =>
      'DAWASA stores all of your financial and personal records only on this phone, in the app\'s private storage.\n\n• No account, login or registration.\n• No advertising, analytics or tracking.\n• No financial data is ever sent to any server.\n• Android cloud backup of app data is disabled, so your records are not copied to online storage.\n• Backups are encrypted with a password only you know (AES-256-GCM). Without the password nobody — including the developer — can read them.\n• The only internet connection DAWASA makes is to the update server, and only to download the update description and the new app file. No personal data is included in these requests.\n• Receipt photos are copied into the app\'s private storage and never uploaded.';

  @override
  String get securityPin => 'PIN lock';

  @override
  String get securityPinDesc => 'Ask for a PIN when DAWASA opens';

  @override
  String get securitySetPin => 'Set PIN';

  @override
  String get securityChangePin => 'Change PIN';

  @override
  String get securityRemovePin => 'Remove PIN';

  @override
  String get securityBiometric => 'Unlock with fingerprint or face';

  @override
  String get securityBiometricUnavailable =>
      'Biometric unlock is not available on this phone';

  @override
  String get securityLockTimeout => 'Lock after';

  @override
  String get securityLockImmediately => 'Immediately';

  @override
  String securityLockAfterMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'After $count minutes',
      one: 'After 1 minute',
    );
    return '$_temp0';
  }

  @override
  String get securityEnterPin => 'Enter your PIN';

  @override
  String get securityCreatePin => 'Create a PIN';

  @override
  String get securityCreatePinDesc =>
      'Use 4 to 6 digits. Do not use your bank card PIN.';

  @override
  String get securityConfirmPin => 'Enter the PIN again';

  @override
  String get securityPinMismatch => 'PINs do not match. Try again.';

  @override
  String securityWrongPin(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Wrong PIN. $count attempts left before a pause.',
      one: 'Wrong PIN. 1 attempt left before a pause.',
    );
    return '$_temp0';
  }

  @override
  String securityLockedOut(int seconds) {
    return 'Too many attempts. Try again in $seconds seconds.';
  }

  @override
  String get securityUnlockTitle => 'DAWASA is locked';

  @override
  String get securityUseBiometric => 'Use fingerprint / face';

  @override
  String get securityBiometricReason => 'Unlock DAWASA';

  @override
  String get securityPinSet => 'PIN lock enabled';

  @override
  String get securityPinRemoved => 'PIN lock removed';

  @override
  String get securityForgotPin => 'Forgot PIN?';

  @override
  String get securityForgotPinBody =>
      'For your privacy the PIN cannot be recovered. You can erase all data on this phone and restore from a backup file.';

  @override
  String get securityDeleteAndReset => 'Erase data and reset';

  @override
  String get backupTitle => 'Backup & restore';

  @override
  String get backupIntro =>
      'A backup is a single encrypted file with all your records and receipt photos. Keep it somewhere safe, such as Google Drive, a computer or a memory card.';

  @override
  String get backupPassword => 'Backup password';

  @override
  String get backupPasswordConfirm => 'Confirm password';

  @override
  String get backupPasswordRules =>
      'At least 8 characters. You will need this password to restore. It cannot be recovered.';

  @override
  String get backupPasswordTooShort => 'Use at least 8 characters';

  @override
  String get backupPasswordMismatch => 'Passwords do not match';

  @override
  String get backupCreating => 'Encrypting your data…';

  @override
  String get backupCreated => 'Backup created';

  @override
  String get backupSaveToDevice => 'Save to a folder';

  @override
  String get backupShareFile => 'Share / send file';

  @override
  String get backupSavedTo => 'Backup saved';

  @override
  String backupLastBackup(String date) {
    return 'Last backup: $date';
  }

  @override
  String get backupNever => 'No backup made yet';

  @override
  String get restoreChooseFile => 'Choose backup file';

  @override
  String get restoreEnterPassword => 'Enter the password used for this backup';

  @override
  String get restoreVerifying => 'Checking backup…';

  @override
  String get restoreConfirmTitle => 'Replace all data?';

  @override
  String get restoreConfirmBody =>
      'Restoring replaces ALL data currently in DAWASA on this phone with the contents of the backup. A safety copy of your current data is saved first.';

  @override
  String restoreBackupInfo(String date, String version) {
    return 'Backup from $date · app $version';
  }

  @override
  String restoreContents(int transactions, int accounts, int tasks) {
    return 'Contains $transactions transactions, $accounts accounts, $tasks tasks';
  }

  @override
  String get restoreAction => 'Replace and restore';

  @override
  String get restoreInProgress => 'Restoring…';

  @override
  String get restoreDone => 'Restore complete. DAWASA will reload.';

  @override
  String get restoreErrorWrongPassword =>
      'Wrong password, or the file was changed or damaged.';

  @override
  String get restoreErrorNotBackup => 'This is not a DAWASA backup file.';

  @override
  String get restoreErrorCorrupted =>
      'The backup file is damaged and cannot be restored.';

  @override
  String get restoreErrorNewer =>
      'This backup was made by a newer version of DAWASA. Update the app first.';

  @override
  String get restoreSafetyNote =>
      'Safety copy saved in the app before restoring.';

  @override
  String get deleteAllTitle => 'Delete all personal data?';

  @override
  String get deleteAllBody =>
      'Every account, transaction, task, bill, receipt photo and setting will be erased from this phone. This cannot be undone. Type DELETE to confirm.';

  @override
  String get deleteAllConfirmWord => 'DELETE';

  @override
  String get deleteAllDone => 'All data deleted';

  @override
  String get updateTitle => 'App updates';

  @override
  String get updateChecking => 'Checking for updates…';

  @override
  String get updateUpToDate => 'DAWASA is up to date';

  @override
  String updateAvailable(String version) {
    return 'Update available: $version';
  }

  @override
  String get updateRequired =>
      'This version is no longer supported. Please update.';

  @override
  String updateDownloading(int percent) {
    return 'Downloading… $percent%';
  }

  @override
  String get updateVerifying => 'Verifying download…';

  @override
  String get updateReady => 'Ready to install';

  @override
  String get updateInstallCancelled => 'Installation cancelled';

  @override
  String get updateDownloadFailed => 'Download failed';

  @override
  String get updateInstalling => 'Opening Android installer…';

  @override
  String get updateOffline =>
      'No internet connection. Everything else in DAWASA keeps working offline.';

  @override
  String get updateServerUnavailable =>
      'The update server could not be reached. Try again later.';

  @override
  String get updateNotConfigured => 'No update server is configured.';

  @override
  String get updateInvalidManifest =>
      'The update information from the server is invalid.';

  @override
  String get updateChecksumMismatch =>
      'The downloaded file failed the security check and was deleted.';

  @override
  String get updatePackageMismatch =>
      'The downloaded file is not a valid DAWASA update and was deleted.';

  @override
  String get updateNow => 'Update now';

  @override
  String get updateInstall => 'Install';

  @override
  String get updateCancelDownload => 'Cancel download';

  @override
  String updateSize(String size) {
    return 'Download size: $size';
  }

  @override
  String get updateWifiOnlyBlocked =>
      'You are on mobile data and \"Wi-Fi only\" is on.';

  @override
  String get updateDownloadAnyway => 'Download anyway';

  @override
  String get updatePermissionTitle => 'Allow installing the update';

  @override
  String get updatePermissionBody =>
      'Android asks you to allow DAWASA to install its own updates. On the next screen, turn on \"Allow from this source\", then come back.';

  @override
  String get updateDataSafe => 'Updating keeps all your data.';

  @override
  String updateLastChecked(String date) {
    return 'Last checked: $date';
  }

  @override
  String get updateNewVersionBanner => 'A new version of DAWASA is available';

  @override
  String get updateWhatsNew => 'What\'s new';

  @override
  String get moneyTitle => 'Money';

  @override
  String get tabTransactions => 'Transactions';

  @override
  String get tabAccounts => 'Accounts';

  @override
  String get tabBudgets => 'Budgets';

  @override
  String get tabBills => 'Bills';

  @override
  String get tabSavings => 'Savings';

  @override
  String get tabLoans => 'Loans';

  @override
  String get homeAvailableBalance => 'Available balance';

  @override
  String get homeTodayIncome => 'Today\'s income';

  @override
  String get homeTodayExpenses => 'Today\'s expenses';

  @override
  String get homeTodayNet => 'Today\'s net cash flow';

  @override
  String get homeRemainingBudget => 'Left to spend today';

  @override
  String homeBudgetExceeded(String amount) {
    return 'Over today\'s budget by $amount';
  }

  @override
  String get homeNoBudget => 'Set a daily budget';

  @override
  String get homeBudgetFromMonthly => 'Based on your monthly budget';

  @override
  String get homePendingTasks => 'Tasks for today';

  @override
  String get homeNoPendingTasks => 'No tasks left for today';

  @override
  String get homeUpcomingPayments => 'Upcoming payments';

  @override
  String get homeNoUpcomingPayments => 'No payments due in the next 7 days';

  @override
  String get homeSavingsProgress => 'Savings goals';

  @override
  String get homeNoSavingsGoals =>
      'Create a savings goal to track your progress';

  @override
  String get homeLast7Days => 'Spending — last 7 days';

  @override
  String get homeRecentTransactions => 'Recent transactions';

  @override
  String get homeNoTransactions =>
      'No transactions yet. Tap + to add your first expense or income.';

  @override
  String get homeHideBalances => 'Hide balances';

  @override
  String get homeShowBalances => 'Show balances';

  @override
  String get homeQuickActions => 'Quick actions';

  @override
  String get quickAddExpense => 'Add expense';

  @override
  String get quickAddIncome => 'Add income';

  @override
  String get quickAddTask => 'Add task';

  @override
  String get quickViewReports => 'View reports';

  @override
  String get quickAddTransfer => 'Transfer';

  @override
  String homeChartSemantics(String summary) {
    return 'Spending for the last 7 days. $summary';
  }

  @override
  String get hiddenAmount => 'Hidden';

  @override
  String get txTypeExpense => 'Expense';

  @override
  String get txTypeIncome => 'Income';

  @override
  String get txTypeTransfer => 'Transfer';

  @override
  String get txTypeReimbursement => 'Reimbursement';

  @override
  String get txTypeLoanGiven => 'Money lent';

  @override
  String get txTypeLoanReceived => 'Money borrowed';

  @override
  String get txTypeLoanRepaymentReceived => 'Loan repayment received';

  @override
  String get txTypeLoanRepaymentPaid => 'Loan repayment paid';

  @override
  String get txTypeAdjustmentIn => 'Balance correction (+)';

  @override
  String get txTypeAdjustmentOut => 'Balance correction (−)';

  @override
  String get txTypeReimbursementHelp =>
      'Money paid back to you for something you paid for someone else. It is not counted as income.';

  @override
  String get txTransferHelp =>
      'Moving money between your own accounts is not income or spending.';

  @override
  String get txAddExpense => 'Add expense';

  @override
  String get txAddIncome => 'Add income';

  @override
  String get txAddTransfer => 'Transfer between accounts';

  @override
  String get txAddReimbursement => 'Add reimbursement';

  @override
  String get txEdit => 'Edit transaction';

  @override
  String get txDetails => 'Transaction';

  @override
  String get txPaidFrom => 'Paid from';

  @override
  String get txReceivedInto => 'Received into';

  @override
  String get txFromAccount => 'From account';

  @override
  String get txToAccount => 'To account';

  @override
  String get txDescriptionHint => 'What was it for?';

  @override
  String get txNoteHint => 'Extra details (optional)';

  @override
  String get txReceipt => 'Receipt photo';

  @override
  String get txAddReceipt => 'Add receipt photo';

  @override
  String get txTakePhoto => 'Take photo';

  @override
  String get txChooseFromGallery => 'Choose from gallery';

  @override
  String get txRemoveReceipt => 'Remove photo';

  @override
  String get txSelectAccount => 'Select account';

  @override
  String get txSelectCategory => 'Select category';

  @override
  String get txErrorSameAccount => 'Choose two different accounts';

  @override
  String get txErrorCurrencyMismatch =>
      'Both accounts must use the same currency';

  @override
  String get txErrorNoAccount => 'Create an account first';

  @override
  String get txErrorCategoryRequired => 'Choose a category';

  @override
  String get txDeleteTitle => 'Delete this transaction?';

  @override
  String get txDeleteLinkedWarning =>
      'This transaction is linked to a bill, shopping list, savings goal or loan. The link will be removed, and the balance will be recalculated.';

  @override
  String get txDuplicated => 'Copy created — check and save';

  @override
  String get txSearchHint => 'Search description, note or amount';

  @override
  String get txNoResults => 'No matching transactions';

  @override
  String get txEmpty => 'No transactions yet';

  @override
  String get txFilterType => 'Type';

  @override
  String get txFilterDates => 'Dates';

  @override
  String get txFilterAnyDate => 'Any date';

  @override
  String get txSourceRecurring => 'Recurring';

  @override
  String get txSourceBill => 'Bill payment';

  @override
  String get txSourceShopping => 'Shopping list';

  @override
  String get txSourceSavings => 'Savings goal';

  @override
  String get txSourceLoan => 'Loan';

  @override
  String get txRepeatSection => 'Make this a recurring transaction';

  @override
  String get txRepeatHelp =>
      'DAWASA will add it automatically on each date. You can edit or delete any of them.';

  @override
  String get txOpeningBalance => 'Opening balance';

  @override
  String get txSplitNote =>
      'Transfers, loans and reimbursements are not counted as income or spending.';

  @override
  String get txMoreTypes => 'More types';

  @override
  String get recurringTitle => 'Recurring transactions';

  @override
  String get recurringEmpty =>
      'No recurring transactions. Turn on \"Repeat\" when adding an expense or income.';

  @override
  String recurringNext(String date) {
    return 'Next: $date';
  }

  @override
  String get recurringEnded => 'Ended';

  @override
  String get recurringPause => 'Pause';

  @override
  String get recurringResume => 'Resume';

  @override
  String get recurringStop => 'Stop repeating';

  @override
  String get recurringStopBody =>
      'Future transactions will no longer be added. Transactions already recorded are kept.';

  @override
  String recurringGenerated(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count recurring transactions added',
      one: '1 recurring transaction added',
    );
    return '$_temp0';
  }

  @override
  String get catFood => 'Food';

  @override
  String get catTransport => 'Transport';

  @override
  String get catShopping => 'Shopping';

  @override
  String get catBills => 'Bills';

  @override
  String get catHealthcare => 'Healthcare';

  @override
  String get catEducation => 'Education';

  @override
  String get catEntertainment => 'Entertainment';

  @override
  String get catFamily => 'Family';

  @override
  String get catFuel => 'Fuel';

  @override
  String get catRent => 'Rent';

  @override
  String get catInterestFees => 'Interest & fees';

  @override
  String get catOther => 'Other';

  @override
  String get catSalary => 'Salary';

  @override
  String get catBusiness => 'Business';

  @override
  String get catFreelancing => 'Freelancing';

  @override
  String get catInterest => 'Interest';

  @override
  String get catGifts => 'Gifts';

  @override
  String get categoriesTitle => 'Categories';

  @override
  String get categoriesExpense => 'Expense categories';

  @override
  String get categoriesIncome => 'Income sources';

  @override
  String get categoryAdd => 'New category';

  @override
  String get categoryAddIncome => 'New income source';

  @override
  String get categoryEdit => 'Edit category';

  @override
  String get categoryName => 'Category name';

  @override
  String get categoryIcon => 'Icon';

  @override
  String get categoryColor => 'Colour';

  @override
  String get categoryArchiveHelp =>
      'Archived categories are hidden from new entries but kept in old transactions.';

  @override
  String get categoryDuplicateName =>
      'A category with this name already exists';

  @override
  String get categoryUncategorized => 'Uncategorised';

  @override
  String get accountsTitle => 'Accounts';

  @override
  String get accountAdd => 'Add account';

  @override
  String get accountEdit => 'Edit account';

  @override
  String get accountName => 'Account name';

  @override
  String get accountType => 'Account type';

  @override
  String get accountTypeCash => 'Cash';

  @override
  String get accountTypeBank => 'Bank account';

  @override
  String get accountTypeEWallet => 'E-wallet';

  @override
  String get accountTypeSavings => 'Savings account';

  @override
  String get accountTypeOther => 'Other';

  @override
  String get accountDefaultCash => 'Cash';

  @override
  String get accountDefaultBank => 'Bank';

  @override
  String get accountDefaultWallet => 'Wallet';

  @override
  String get accountOpeningBalance => 'Opening balance';

  @override
  String get accountOpeningBalanceHelp =>
      'Money in this account before you started using DAWASA';

  @override
  String get accountIncludeInTotal => 'Include in available balance';

  @override
  String get accountBalance => 'Balance';

  @override
  String accountTotalBalance(String currency) {
    return 'Total in $currency';
  }

  @override
  String get accountCorrectBalance => 'Correct balance';

  @override
  String get accountCorrectBalanceBody =>
      'Enter the actual balance of this account. DAWASA records the difference as a balance correction — it is not counted as income or spending.';

  @override
  String get accountActualBalance => 'Actual balance';

  @override
  String accountCorrectionPreview(String amount) {
    return 'A correction of $amount will be recorded';
  }

  @override
  String get accountCorrectionNone => 'The balance is already correct';

  @override
  String get accountDeleteBlocked =>
      'This account has transactions. Archive it instead to keep your history.';

  @override
  String get accountEmpty => 'No accounts yet';

  @override
  String get accountArchivedSection => 'Archived accounts';

  @override
  String get accountHistory => 'Account history';

  @override
  String get accountOtherCurrencies =>
      'Accounts in other currencies are not added to this total.';

  @override
  String get accountCurrencyLocked =>
      'The currency cannot be changed after transactions are recorded.';

  @override
  String get plannerTitle => 'Planner';

  @override
  String get tabTasks => 'Tasks';

  @override
  String get tabShopping => 'Shopping';

  @override
  String get tabHabits => 'Habits';

  @override
  String get tabEvents => 'Dates';

  @override
  String get budgetsTitle => 'Budgets';

  @override
  String get budgetAdd => 'New budget';

  @override
  String get budgetEdit => 'Edit budget';

  @override
  String get budgetName => 'Budget name';

  @override
  String get budgetAmount => 'Budget amount';

  @override
  String get budgetPeriod => 'Period';

  @override
  String get budgetPeriodDaily => 'Daily';

  @override
  String get budgetPeriodWeekly => 'Weekly';

  @override
  String get budgetPeriodMonthly => 'Monthly';

  @override
  String get budgetPeriodCustom => 'Custom dates';

  @override
  String get budgetScope => 'Applies to';

  @override
  String get budgetScopeAll => 'All spending';

  @override
  String get budgetScopeCategories => 'Selected categories';

  @override
  String budgetWarnAt(int percent) {
    return 'Warn me at $percent% used';
  }

  @override
  String get budgetNotify => 'Budget notifications';

  @override
  String get budgetSpent => 'Spent';

  @override
  String get budgetLeft => 'Left';

  @override
  String budgetOverBy(String amount) {
    return 'Over by $amount';
  }

  @override
  String budgetDaysLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days left',
      one: '1 day left',
      zero: 'Last day',
    );
    return '$_temp0';
  }

  @override
  String budgetPerDay(String amount) {
    return 'About $amount per day';
  }

  @override
  String get budgetEmpty =>
      'No budgets yet. A budget helps you keep spending under control.';

  @override
  String get budgetNotCounted =>
      'Transfers, savings movements and loan principal are not counted as spending.';

  @override
  String get budgetEnded => 'Ended';

  @override
  String budgetNotStarted(String date) {
    return 'Starts $date';
  }

  @override
  String get budgetDeleteTitle => 'Delete this budget?';

  @override
  String get budgetDeleteBody => 'Your transactions are not affected.';

  @override
  String get budgetChooseCategories => 'Choose at least one category';

  @override
  String get budgetPerformance => 'Budget performance';

  @override
  String get tasksTitle => 'Tasks';

  @override
  String get taskAdd => 'New task';

  @override
  String get taskEdit => 'Edit task';

  @override
  String get taskTitle => 'Title';

  @override
  String get taskTitleHint => 'What do you need to do?';

  @override
  String get taskDescription => 'Details';

  @override
  String get taskDueDate => 'Due date';

  @override
  String get taskDueTime => 'Time';

  @override
  String get taskPriority => 'Priority';

  @override
  String get taskPriorityLow => 'Low';

  @override
  String get taskPriorityMedium => 'Medium';

  @override
  String get taskPriorityHigh => 'High';

  @override
  String get taskReminder => 'Reminder';

  @override
  String get taskReminderNone => 'No reminder';

  @override
  String get taskReminderAtTime => 'At the due time';

  @override
  String taskReminderMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count minutes before',
      one: '1 minute before',
    );
    return '$_temp0';
  }

  @override
  String taskReminderHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count hours before',
      one: '1 hour before',
    );
    return '$_temp0';
  }

  @override
  String taskReminderDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days before',
      one: '1 day before',
    );
    return '$_temp0';
  }

  @override
  String get taskReminderNeedsDate => 'Set a due date to add a reminder';

  @override
  String get taskViewToday => 'Today';

  @override
  String get taskViewTomorrow => 'Tomorrow';

  @override
  String get taskViewUpcoming => 'Upcoming';

  @override
  String get taskViewCompleted => 'Completed';

  @override
  String get taskViewAll => 'All';

  @override
  String get taskOverdue => 'Overdue';

  @override
  String get taskNoDate => 'No due date';

  @override
  String get taskEmptyToday => 'Nothing planned for today. Enjoy your day!';

  @override
  String get taskEmpty => 'No tasks here';

  @override
  String get taskCompleted => 'Task completed';

  @override
  String taskNextCreated(String date) {
    return 'Next repeat scheduled for $date';
  }

  @override
  String get taskMarkDone => 'Mark as done';

  @override
  String get taskMarkNotDone => 'Mark as not done';

  @override
  String get taskSortDue => 'Sort by due date';

  @override
  String get taskSortPriority => 'Sort by priority';

  @override
  String get taskDeleteTitle => 'Delete this task?';

  @override
  String get taskClearCompleted => 'Delete completed tasks';

  @override
  String taskCountToday(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tasks',
      one: '1 task',
      zero: 'No tasks',
    );
    return '$_temp0';
  }

  @override
  String get billsTitle => 'Bills & payments';

  @override
  String get billAdd => 'New bill';

  @override
  String get billEdit => 'Edit bill';

  @override
  String get billName => 'Bill name';

  @override
  String get billNameHint => 'e.g. CEB electricity';

  @override
  String get billCategory => 'Type';

  @override
  String get billCatElectricity => 'Electricity';

  @override
  String get billCatWater => 'Water';

  @override
  String get billCatInternet => 'Internet';

  @override
  String get billCatMobile => 'Mobile';

  @override
  String get billCatRent => 'Rent';

  @override
  String get billCatInsurance => 'Insurance';

  @override
  String get billCatLoan => 'Loan instalment';

  @override
  String get billCatOther => 'Other';

  @override
  String get billAmount => 'Usual amount';

  @override
  String get billDueDate => 'Next due date';

  @override
  String get billRepeat => 'Repeats';

  @override
  String get billOneTime => 'One-time payment';

  @override
  String get billRemind => 'Remind me';

  @override
  String billRemindDaysBefore(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days before',
      one: '1 day before',
      zero: 'On the due date',
    );
    return '$_temp0';
  }

  @override
  String get billPaymentAccount => 'Usually paid from';

  @override
  String get billPaid => 'Paid';

  @override
  String get billUnpaid => 'Unpaid';

  @override
  String get billDueToday => 'Due today';

  @override
  String billDueIn(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Due in $count days',
      one: 'Due tomorrow',
    );
    return '$_temp0';
  }

  @override
  String billOverdueBy(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days overdue',
      one: '1 day overdue',
    );
    return '$_temp0';
  }

  @override
  String get billMarkPaid => 'Mark as paid';

  @override
  String get billPayTitle => 'Record payment';

  @override
  String get billPaidAmount => 'Amount paid';

  @override
  String get billPaidOn => 'Paid on';

  @override
  String get billRecordExpense => 'Record as an expense';

  @override
  String get billRecordExpenseHelp =>
      'Adds an expense in the \"Bills\" category and reduces the account balance.';

  @override
  String get billPossibleDuplicate => 'You already recorded a similar expense';

  @override
  String get billPossibleDuplicateBody =>
      'Link that expense to this bill instead of creating a duplicate?';

  @override
  String get billLinkExisting => 'Link existing expense';

  @override
  String get billCreateNew => 'Create a new expense';

  @override
  String get billDontRecord => 'Just mark as paid';

  @override
  String get billPaymentSaved => 'Payment recorded';

  @override
  String get billAlreadyPaid => 'This due date is already marked as paid';

  @override
  String get billHistory => 'Payment history';

  @override
  String get billNoHistory => 'No payments yet';

  @override
  String get billEmpty =>
      'No bills yet. Add electricity, water, phone and other regular payments to get reminders.';

  @override
  String get billUndoPayment => 'Undo payment';

  @override
  String get billUndoPaymentBody =>
      'The payment record is removed and the bill becomes unpaid again. A linked expense is kept unless you delete it.';

  @override
  String get billExpenseLinked => 'Expense recorded';

  @override
  String get billUpcoming => 'Upcoming';

  @override
  String get billInactive => 'Finished';

  @override
  String get billStop => 'Stop this bill';

  @override
  String get billResume => 'Resume this bill';

  @override
  String get shoppingTitle => 'Shopping lists';

  @override
  String get shoppingNewList => 'New list';

  @override
  String get shoppingListName => 'List name';

  @override
  String get shoppingListNameHint => 'e.g. Weekly groceries';

  @override
  String get shoppingAddItem => 'Add item';

  @override
  String get shoppingEditItem => 'Edit item';

  @override
  String get shoppingItemName => 'Item';

  @override
  String get shoppingQuantity => 'Quantity';

  @override
  String get shoppingUnit => 'Unit';

  @override
  String get shoppingEstimated => 'Estimated price';

  @override
  String get shoppingActual => 'Actual price';

  @override
  String get shoppingPriceHelp => 'Total for this line, not per unit';

  @override
  String get shoppingEstimatedTotal => 'Estimated total';

  @override
  String get shoppingActualTotal => 'Actual total';

  @override
  String get shoppingEstimateNote =>
      'Estimates are only a guide. They never change your balances.';

  @override
  String get shoppingPurchased => 'Purchased';

  @override
  String get shoppingToBuy => 'To buy';

  @override
  String get shoppingEmptyLists =>
      'No shopping lists. Create one before you go to the shop.';

  @override
  String get shoppingEmptyItems => 'This list is empty';

  @override
  String get shoppingRecordExpense => 'Record purchases as expense';

  @override
  String shoppingRecordExpenseBody(int count, String amount) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count purchased items',
      one: '1 purchased item',
    );
    return '$_temp0 not recorded yet · $amount';
  }

  @override
  String get shoppingMissingPrices =>
      'Enter the actual price of every purchased item first';

  @override
  String get shoppingRecorded =>
      'Expense recorded. These items will not be counted again.';

  @override
  String get shoppingAllRecorded => 'All purchases are recorded';

  @override
  String get shoppingCompleteList => 'Mark list as done';

  @override
  String get shoppingReopenList => 'Reopen list';

  @override
  String get shoppingListDone => 'Done';

  @override
  String get shoppingDeleteList => 'Delete list';

  @override
  String get shoppingDeleteListBody =>
      'Expenses already recorded from this list are kept.';

  @override
  String get shoppingItemRecorded => 'Recorded';

  @override
  String shoppingProgress(int done, int total) {
    return '$done of $total bought';
  }

  @override
  String get unitPcs => 'pcs';

  @override
  String get unitKg => 'kg';

  @override
  String get unitG => 'g';

  @override
  String get unitL => 'L';

  @override
  String get unitMl => 'ml';

  @override
  String get unitPack => 'pack';

  @override
  String get unitBottle => 'bottle';

  @override
  String get unitDozen => 'dozen';

  @override
  String get homeSeeTasks => 'See tasks';

  @override
  String get homeSeeBills => 'See bills';

  @override
  String notifTaskTitle(String title) {
    return 'Task: $title';
  }

  @override
  String notifTaskBodyDue(String when) {
    return 'Due $when';
  }

  @override
  String notifBillTitle(String name) {
    return 'Bill due: $name';
  }

  @override
  String notifBillBody(String amount, String when) {
    return '$amount due $when';
  }

  @override
  String notifBudgetWarnTitle(String name) {
    return 'Budget almost used: $name';
  }

  @override
  String notifBudgetWarnBody(int percent, String amount) {
    return 'You have used $percent% of $amount';
  }

  @override
  String notifBudgetOverTitle(String name) {
    return 'Budget exceeded: $name';
  }

  @override
  String notifBudgetOverBody(String spent, String amount) {
    return 'Spent $spent of $amount';
  }

  @override
  String get notifDailyTitle => 'Plan your day with DAWASA';

  @override
  String get notifDailyBody =>
      'Review today\'s tasks and record your spending.';

  @override
  String get notifWhenToday => 'today';

  @override
  String get notifWhenTomorrow => 'tomorrow';

  @override
  String notifWhenOn(String date) {
    return 'on $date';
  }

  @override
  String notifWhenAt(String time) {
    return 'at $time';
  }

  @override
  String get billLoanNote =>
      'Loan instalments are mostly principal, which is not spending. Record the repayment in Loans so what you owe goes down correctly.';

  @override
  String get savingsTitle => 'Savings goals';

  @override
  String get savingsAdd => 'New goal';

  @override
  String get savingsEdit => 'Edit goal';

  @override
  String get savingsName => 'Goal name';

  @override
  String get savingsNameHint => 'e.g. New phone, Emergency fund';

  @override
  String get savingsTarget => 'Target amount';

  @override
  String get savingsTargetDate => 'Target date';

  @override
  String get savingsLinkedAccount => 'Kept in account';

  @override
  String get savingsLinkedAccountHelp =>
      'If you choose a savings account, adding money moves it there as a transfer. It is never counted as spending.';

  @override
  String get savingsNoLinkedAccount => 'Just track it (no account)';

  @override
  String get savingsSaved => 'Saved';

  @override
  String get savingsToGo => 'To go';

  @override
  String get savingsReached => 'Goal reached!';

  @override
  String get savingsDeposit => 'Add money';

  @override
  String get savingsWithdraw => 'Withdraw';

  @override
  String get savingsFromAccount => 'Take money from';

  @override
  String get savingsToAccount => 'Put money into';

  @override
  String savingsDepositNote(String from, String to) {
    return 'The money moves from $from to $to. This is a transfer, not an expense.';
  }

  @override
  String get savingsTrackOnlyNote =>
      'Your balances stay the same; the amount is set aside for this goal.';

  @override
  String get savingsWithdrawTooMuch => 'You cannot withdraw more than is saved';

  @override
  String get savingsEmpty =>
      'No savings goals yet. Save a little every month for something you want.';

  @override
  String get savingsHistory => 'Movements';

  @override
  String savingsMonthlyNeeded(String amount) {
    return 'Save $amount a month to reach it on time';
  }

  @override
  String get savingsRemindMonthly => 'Remind me every month';

  @override
  String get savingsDeleteBody =>
      'Transfers already recorded stay in your accounts.';

  @override
  String get savingsTotalSaved => 'Total saved';

  @override
  String notifSavingsTitle(String name) {
    return 'Savings: $name';
  }

  @override
  String notifSavingsBody(String amount) {
    return '$amount to go. Add a little today?';
  }

  @override
  String get loansTitle => 'Loans & debts';

  @override
  String get loanAdd => 'New loan';

  @override
  String get loanEdit => 'Edit loan';

  @override
  String get loanDirection => 'Type';

  @override
  String get loanLent => 'I lent money';

  @override
  String get loanBorrowed => 'I borrowed money';

  @override
  String get loanOwedToYou => 'Owed to you';

  @override
  String get loanYouOwe => 'You owe';

  @override
  String get loanPerson => 'Person or institution';

  @override
  String get loanPrincipal => 'Amount';

  @override
  String get loanInterestRate => 'Interest rate % per year (optional)';

  @override
  String get loanStartDate => 'Date';

  @override
  String get loanDueDate => 'Due date (optional)';

  @override
  String get loanRecordMovement => 'Record the money movement in an account';

  @override
  String get loanRecordMovementHelp =>
      'Updates the account balance. Loan money is never counted as income or spending.';

  @override
  String get loanOutstanding => 'Outstanding';

  @override
  String get loanRepaid => 'Repaid';

  @override
  String get loanRecordRepayment => 'Record repayment';

  @override
  String get loanRepaymentPrincipal => 'Towards the loan amount';

  @override
  String get loanRepaymentInterest => 'Interest (optional)';

  @override
  String get loanRepaymentInterestHelp =>
      'Interest received is income; interest paid is an expense.';

  @override
  String get loanRepaymentTooMuch => 'This is more than the outstanding amount';

  @override
  String get loanSettle => 'Mark as settled';

  @override
  String get loanSettleBody =>
      'The loan is closed. Any amount still outstanding is written off and no longer counted.';

  @override
  String get loanReopen => 'Reopen loan';

  @override
  String get loanSettled => 'Settled';

  @override
  String get loanActive => 'Active';

  @override
  String get loanEmpty =>
      'No loans. Keep track of money you lent to or borrowed from others.';

  @override
  String get loanHistory => 'Repayments';

  @override
  String get loanNoRepayments => 'No repayments yet';

  @override
  String get loanDeleteBody =>
      'Money movements recorded for this loan are deleted too, and balances are recalculated.';

  @override
  String loanDueOn(String date) {
    return 'Due $date';
  }

  @override
  String loanNotifTitleLent(String name) {
    return '$name should repay you';
  }

  @override
  String loanNotifTitleBorrowed(String name) {
    return 'Repay $name';
  }

  @override
  String loanNotifBody(String amount, String when) {
    return '$amount outstanding, due $when';
  }

  @override
  String get loanTotalOwedToYou => 'Total owed to you';

  @override
  String get loanTotalYouOwe => 'Total you owe';

  @override
  String get habitsTitle => 'Habits';

  @override
  String get habitAdd => 'New habit';

  @override
  String get habitEdit => 'Edit habit';

  @override
  String get habitName => 'Habit';

  @override
  String get habitNameHint => 'e.g. Drink water, Read, Exercise';

  @override
  String get habitFrequency => 'Goal';

  @override
  String get habitDaily => 'Every day';

  @override
  String get habitWeekly => 'Every week';

  @override
  String habitTimesPerDay(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count times a day',
      one: 'Once a day',
    );
    return '$_temp0';
  }

  @override
  String habitTimesPerWeek(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count times a week',
      one: 'Once a week',
    );
    return '$_temp0';
  }

  @override
  String get habitTarget => 'Times';

  @override
  String get habitReminder => 'Daily reminder';

  @override
  String habitStreak(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count day streak',
      one: '1 day streak',
      zero: 'No streak yet',
    );
    return '$_temp0';
  }

  @override
  String habitWeekStreak(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count week streak',
      one: '1 week streak',
      zero: 'No streak yet',
    );
    return '$_temp0';
  }

  @override
  String habitBestStreak(int count) {
    return 'Best: $count';
  }

  @override
  String habitProgressToday(int done, int target) {
    return '$done of $target today';
  }

  @override
  String habitProgressWeek(int done, int target) {
    return '$done of $target this week';
  }

  @override
  String get habitMarkDone => 'Mark done';

  @override
  String get habitUndo => 'Undo';

  @override
  String get habitCalendar => 'Last 5 weeks';

  @override
  String get habitEmpty =>
      'Build good habits one day at a time. Habits never affect your money reports.';

  @override
  String habitNotifTitle(String name) {
    return 'Time for: $name';
  }

  @override
  String get habitNotifBody => 'Keep your streak going!';

  @override
  String get habitDeleteBody => 'The habit and its history will be deleted.';

  @override
  String get eventsTitle => 'Important dates';

  @override
  String get eventAdd => 'New date';

  @override
  String get eventEdit => 'Edit date';

  @override
  String get eventTitle => 'Title';

  @override
  String get eventTitleHint => 'e.g. Amma\'s birthday';

  @override
  String get eventType => 'Type';

  @override
  String get eventBirthday => 'Birthday';

  @override
  String get eventAnniversary => 'Anniversary';

  @override
  String get eventAppointment => 'Appointment';

  @override
  String get eventExam => 'Examination';

  @override
  String get eventOther => 'Other';

  @override
  String get eventDate => 'Date';

  @override
  String get eventRemind => 'Remind me';

  @override
  String get eventNoReminder => 'No reminder';

  @override
  String get eventBudget => 'Budget for this event (optional)';

  @override
  String get eventBudgetHelp =>
      'A plan only — it does not change your balances.';

  @override
  String get eventEmpty =>
      'Never forget a birthday, anniversary or exam again.';

  @override
  String get eventUpcoming => 'Upcoming';

  @override
  String get eventPast => 'Past';

  @override
  String eventInDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'In $count days',
      one: 'Tomorrow',
      zero: 'Today',
    );
    return '$_temp0';
  }

  @override
  String eventTurns(int age) {
    return 'Turns $age';
  }

  @override
  String eventYears(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count years',
      one: '1 year',
    );
    return '$_temp0';
  }

  @override
  String get eventCalendar => 'Calendar';

  @override
  String get eventList => 'List';

  @override
  String get eventNoneThisDay => 'Nothing on this day';

  @override
  String eventNotifTitle(String title) {
    return '$title';
  }

  @override
  String eventNotifBody(String when) {
    return '$when';
  }

  @override
  String get reportsTitle => 'Reports';

  @override
  String get reportTotalIncome => 'Total income';

  @override
  String get reportTotalExpenses => 'Total expenses';

  @override
  String get reportNetCashFlow => 'Net cash flow';

  @override
  String get reportNetHelp => 'Income minus expenses in this period';

  @override
  String get reportOtherMovements => 'Other money movements';

  @override
  String get reportOtherMovementsHelp =>
      'Loans, repayments, reimbursements and balance corrections. Not income or spending.';

  @override
  String get reportMoneyIn => 'Money in';

  @override
  String get reportMoneyOut => 'Money out';

  @override
  String get reportIncomeVsExpenses => 'Income vs expenses';

  @override
  String get reportExpensesByCategory => 'Expenses by category';

  @override
  String get reportIncomeByCategory => 'Income by source';

  @override
  String get reportDailyTrend => 'Daily spending';

  @override
  String get reportMonthlyTrend => 'Monthly spending (last 6 months)';

  @override
  String get reportAccountBalances => 'Account balances (now)';

  @override
  String get reportLoanBalances => 'Loan balances (now)';

  @override
  String get reportSavings => 'Savings';

  @override
  String get reportSavingsTransfers => 'Moved to savings in this period';

  @override
  String get reportNoData => 'No transactions in this period';

  @override
  String reportChartIncomeExpense(String income, String expenses) {
    return 'Income $income, expenses $expenses';
  }

  @override
  String get reportShare => 'Share summary';

  @override
  String get reportExportCsv => 'Export CSV';

  @override
  String get reportShareTitle => 'Share report';

  @override
  String get reportShareIncludeCategories => 'Include category totals';

  @override
  String get reportShareIncludeBalances => 'Include account balances';

  @override
  String get reportSharePrivacy =>
      'Only what you select below is shared. Nothing is sent anywhere unless you choose an app to share with.';

  @override
  String get reportPreview => 'Preview';

  @override
  String get exportTitle => 'Export transactions';

  @override
  String get exportIncludeNotes => 'Include descriptions and notes';

  @override
  String get exportIncludeAccounts => 'Include account names';

  @override
  String exportRows(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count transactions',
      one: '1 transaction',
    );
    return '$_temp0';
  }

  @override
  String get exportDone => 'CSV file ready';

  @override
  String get exportNothing => 'No transactions to export in this period';

  @override
  String get exportPrivacyNote =>
      'A CSV file is not encrypted. Anyone who gets the file can read it.';

  @override
  String get csvDate => 'Date';

  @override
  String get csvTime => 'Time';

  @override
  String get csvType => 'Type';

  @override
  String get csvCategory => 'Category';

  @override
  String get csvAccount => 'Account';

  @override
  String get csvToAccount => 'To account';

  @override
  String get csvAmount => 'Amount';

  @override
  String get csvCurrency => 'Currency';

  @override
  String get csvDescription => 'Description';

  @override
  String get csvNote => 'Note';

  @override
  String get csvCountsAs => 'Counts as';

  @override
  String get csvCountsIncome => 'Income';

  @override
  String get csvCountsExpense => 'Expense';

  @override
  String get csvCountsNeither => 'Not income or expense';

  @override
  String get homeSeeSavings => 'See goals';

  @override
  String securityPinDigitsEntered(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count digits entered',
      one: '1 digit entered',
      zero: 'No digits entered',
    );
    return '$_temp0';
  }

  @override
  String get securityPinDelete => 'Delete last digit';

  @override
  String securityPausedFor(String time) {
    return 'Too many wrong PINs. Try again in $time.';
  }

  @override
  String get securityEnterCurrentPin => 'Enter your current PIN';

  @override
  String get securityPinTooSimple =>
      'That PIN is too easy to guess. Avoid repeated or consecutive digits.';

  @override
  String securityLockAfterSeconds(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'After $count seconds',
      one: 'After 1 second',
    );
    return '$_temp0';
  }

  @override
  String get securityLockNote =>
      'The PIN lock keeps other people who use your phone out of DAWASA. If you forget the PIN, it cannot be recovered.';

  @override
  String get securityBiometricFailed => 'Fingerprint or face was not confirmed';

  @override
  String get deleteAllBackupFirst =>
      'Tip: create a backup first if you may need this data again.';

  @override
  String deleteAllTypeWord(String word) {
    return 'Type $word to confirm';
  }

  @override
  String get deleteAllAction => 'Delete everything';

  @override
  String get backupShowPassword => 'Show password';

  @override
  String get backupHidePassword => 'Hide password';

  @override
  String get backupFailed =>
      'The backup could not be created. Please try again.';

  @override
  String get backupKeepSafe =>
      'Anyone who has both the backup file and its password can read your records, so keep the password private. If you forget it, nobody can open the backup — not even the developer.';

  @override
  String get backupStoredHint =>
      'Saved. Also keep a copy somewhere outside this phone.';

  @override
  String get backupNotStoredYet =>
      'Now save the file to a folder or send it somewhere safe. It is not stored anywhere yet.';

  @override
  String get settingsRestoreDesc =>
      'Replace the data on this phone with a backup file';

  @override
  String get restoreIntro =>
      'Choose a DAWASA backup file (.dawasa). It is checked completely before anything on this phone is changed.';

  @override
  String get restoreCheck => 'Check backup';

  @override
  String get restoreChooseOther => 'Choose a different file';

  @override
  String get restoreVerified => 'The backup is valid and complete';

  @override
  String get restoreCountAccounts => 'Accounts';

  @override
  String get restoreCountTransactions => 'Transactions';

  @override
  String get restoreCountBudgets => 'Budgets';

  @override
  String get restoreCountBills => 'Bills';

  @override
  String get restoreCountTasks => 'Tasks';

  @override
  String get restoreCountSavings => 'Savings goals';

  @override
  String get restoreCountLoans => 'Loans';

  @override
  String get restoreCountPhotos => 'Receipt photos';

  @override
  String get restorePreviousData => 'Data from before the last restore';

  @override
  String restorePreviousDataDesc(String date) {
    return 'Kept on this phone since $date';
  }

  @override
  String get restoreBringBack => 'Bring back previous data';

  @override
  String get restoreBringBackBody =>
      'Your current data will be replaced by the data you had before the last restore.';

  @override
  String get restoreDeleteSafetyCopy => 'Delete this copy';

  @override
  String get restoreCompleted => 'Backup restored';

  @override
  String get restoreFailedKept =>
      'The backup could not be restored. Your previous data was kept.';

  @override
  String get onbRestoreBackup => 'Restore from a backup';
}

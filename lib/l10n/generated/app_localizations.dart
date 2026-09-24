import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_si.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('si'),
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'DAWASA'**
  String get appName;

  /// No description provided for @appTagline.
  ///
  /// In en, this message translates to:
  /// **'Your Money. Your Plans. Your Day.'**
  String get appTagline;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navMoney.
  ///
  /// In en, this message translates to:
  /// **'Money'**
  String get navMoney;

  /// No description provided for @navPlanner.
  ///
  /// In en, this message translates to:
  /// **'Planner'**
  String get navPlanner;

  /// No description provided for @navReports.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get navReports;

  /// No description provided for @navSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// No description provided for @actionSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get actionSave;

  /// No description provided for @actionCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get actionCancel;

  /// No description provided for @actionDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get actionDelete;

  /// No description provided for @actionEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get actionEdit;

  /// No description provided for @actionAdd.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get actionAdd;

  /// No description provided for @actionDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get actionDone;

  /// No description provided for @actionNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get actionNext;

  /// No description provided for @actionBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get actionBack;

  /// No description provided for @actionSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get actionSkip;

  /// No description provided for @actionConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get actionConfirm;

  /// No description provided for @actionRetry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get actionRetry;

  /// No description provided for @actionFilter.
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get actionFilter;

  /// No description provided for @actionClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get actionClear;

  /// No description provided for @actionDuplicate.
  ///
  /// In en, this message translates to:
  /// **'Duplicate'**
  String get actionDuplicate;

  /// No description provided for @actionShare.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get actionShare;

  /// No description provided for @actionUndo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get actionUndo;

  /// No description provided for @actionArchive.
  ///
  /// In en, this message translates to:
  /// **'Archive'**
  String get actionArchive;

  /// No description provided for @actionUnarchive.
  ///
  /// In en, this message translates to:
  /// **'Restore from archive'**
  String get actionUnarchive;

  /// No description provided for @actionGetStarted.
  ///
  /// In en, this message translates to:
  /// **'Get started'**
  String get actionGetStarted;

  /// No description provided for @actionContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get actionContinue;

  /// No description provided for @actionSeeAll.
  ///
  /// In en, this message translates to:
  /// **'See all'**
  String get actionSeeAll;

  /// No description provided for @actionOpenSettings.
  ///
  /// In en, this message translates to:
  /// **'Open settings'**
  String get actionOpenSettings;

  /// No description provided for @commonAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get commonAll;

  /// No description provided for @commonNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get commonNone;

  /// No description provided for @commonAmount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get commonAmount;

  /// No description provided for @commonDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get commonDate;

  /// No description provided for @commonTime.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get commonTime;

  /// No description provided for @commonNote.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get commonNote;

  /// No description provided for @commonDescription.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get commonDescription;

  /// No description provided for @commonCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get commonCategory;

  /// No description provided for @commonAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get commonAccount;

  /// No description provided for @commonToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get commonToday;

  /// No description provided for @commonYesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get commonYesterday;

  /// No description provided for @commonTomorrow.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow'**
  String get commonTomorrow;

  /// No description provided for @commonTotal.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get commonTotal;

  /// No description provided for @commonStartDate.
  ///
  /// In en, this message translates to:
  /// **'Start date'**
  String get commonStartDate;

  /// No description provided for @commonEndDate.
  ///
  /// In en, this message translates to:
  /// **'End date'**
  String get commonEndDate;

  /// No description provided for @commonNoDate.
  ///
  /// In en, this message translates to:
  /// **'No date'**
  String get commonNoDate;

  /// No description provided for @commonNoTime.
  ///
  /// In en, this message translates to:
  /// **'No time'**
  String get commonNoTime;

  /// No description provided for @commonDetails.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get commonDetails;

  /// No description provided for @commonArchived.
  ///
  /// In en, this message translates to:
  /// **'Archived'**
  String get commonArchived;

  /// No description provided for @commonOverdue.
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get commonOverdue;

  /// No description provided for @commonNotSet.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get commonNotSet;

  /// No description provided for @commonCurrency.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get commonCurrency;

  /// No description provided for @commonRepeat.
  ///
  /// In en, this message translates to:
  /// **'Repeat'**
  String get commonRepeat;

  /// No description provided for @commonPercentUsed.
  ///
  /// In en, this message translates to:
  /// **'{percent}% used'**
  String commonPercentUsed(int percent);

  /// No description provided for @validationRequired.
  ///
  /// In en, this message translates to:
  /// **'This field is required'**
  String get validationRequired;

  /// No description provided for @validationAmountInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid amount'**
  String get validationAmountInvalid;

  /// No description provided for @validationAmountPositive.
  ///
  /// In en, this message translates to:
  /// **'Amount must be greater than zero'**
  String get validationAmountPositive;

  /// No description provided for @validationAmountTooLarge.
  ///
  /// In en, this message translates to:
  /// **'Amount is too large'**
  String get validationAmountTooLarge;

  /// No description provided for @validationTooManyDecimals.
  ///
  /// In en, this message translates to:
  /// **'Too many decimal places'**
  String get validationTooManyDecimals;

  /// No description provided for @validationNumberInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid number'**
  String get validationNumberInvalid;

  /// No description provided for @validationEndBeforeStart.
  ///
  /// In en, this message translates to:
  /// **'End date cannot be before start date'**
  String get validationEndBeforeStart;

  /// No description provided for @feedbackSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get feedbackSaved;

  /// No description provided for @feedbackDeleted.
  ///
  /// In en, this message translates to:
  /// **'Deleted'**
  String get feedbackDeleted;

  /// No description provided for @feedbackAlreadySaved.
  ///
  /// In en, this message translates to:
  /// **'Already saved'**
  String get feedbackAlreadySaved;

  /// No description provided for @confirmDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete?'**
  String get confirmDeleteTitle;

  /// No description provided for @confirmDeleteMessage.
  ///
  /// In en, this message translates to:
  /// **'This cannot be undone.'**
  String get confirmDeleteMessage;

  /// No description provided for @emptyGeneric.
  ///
  /// In en, this message translates to:
  /// **'Nothing here yet'**
  String get emptyGeneric;

  /// No description provided for @errorLoading.
  ///
  /// In en, this message translates to:
  /// **'Could not load data'**
  String get errorLoading;

  /// No description provided for @greetingMorning.
  ///
  /// In en, this message translates to:
  /// **'Good morning'**
  String get greetingMorning;

  /// No description provided for @greetingAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good afternoon'**
  String get greetingAfternoon;

  /// No description provided for @greetingEvening.
  ///
  /// In en, this message translates to:
  /// **'Good evening'**
  String get greetingEvening;

  /// No description provided for @greetingWithName.
  ///
  /// In en, this message translates to:
  /// **'{greeting}, {name}'**
  String greetingWithName(String greeting, String name);

  /// No description provided for @weekdayMon.
  ///
  /// In en, this message translates to:
  /// **'Monday'**
  String get weekdayMon;

  /// No description provided for @weekdayTue.
  ///
  /// In en, this message translates to:
  /// **'Tuesday'**
  String get weekdayTue;

  /// No description provided for @weekdayWed.
  ///
  /// In en, this message translates to:
  /// **'Wednesday'**
  String get weekdayWed;

  /// No description provided for @weekdayThu.
  ///
  /// In en, this message translates to:
  /// **'Thursday'**
  String get weekdayThu;

  /// No description provided for @weekdayFri.
  ///
  /// In en, this message translates to:
  /// **'Friday'**
  String get weekdayFri;

  /// No description provided for @weekdaySat.
  ///
  /// In en, this message translates to:
  /// **'Saturday'**
  String get weekdaySat;

  /// No description provided for @weekdaySun.
  ///
  /// In en, this message translates to:
  /// **'Sunday'**
  String get weekdaySun;

  /// No description provided for @repeatNever.
  ///
  /// In en, this message translates to:
  /// **'Does not repeat'**
  String get repeatNever;

  /// No description provided for @repeatDaily.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get repeatDaily;

  /// No description provided for @repeatWeekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get repeatWeekly;

  /// No description provided for @repeatMonthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get repeatMonthly;

  /// No description provided for @repeatYearly.
  ///
  /// In en, this message translates to:
  /// **'Yearly'**
  String get repeatYearly;

  /// No description provided for @repeatCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get repeatCustom;

  /// No description provided for @repeatEvery.
  ///
  /// In en, this message translates to:
  /// **'Repeat every'**
  String get repeatEvery;

  /// No description provided for @repeatUnitDays.
  ///
  /// In en, this message translates to:
  /// **'days'**
  String get repeatUnitDays;

  /// No description provided for @repeatUnitWeeks.
  ///
  /// In en, this message translates to:
  /// **'weeks'**
  String get repeatUnitWeeks;

  /// No description provided for @repeatUnitMonths.
  ///
  /// In en, this message translates to:
  /// **'months'**
  String get repeatUnitMonths;

  /// No description provided for @repeatUnitYears.
  ///
  /// In en, this message translates to:
  /// **'years'**
  String get repeatUnitYears;

  /// No description provided for @repeatEveryDays.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Every day} other{Every {count} days}}'**
  String repeatEveryDays(int count);

  /// No description provided for @repeatEveryWeeks.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Every week} other{Every {count} weeks}}'**
  String repeatEveryWeeks(int count);

  /// No description provided for @repeatEveryMonths.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Every month} other{Every {count} months}}'**
  String repeatEveryMonths(int count);

  /// No description provided for @repeatEveryYears.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Every year} other{Every {count} years}}'**
  String repeatEveryYears(int count);

  /// No description provided for @repeatUntilDate.
  ///
  /// In en, this message translates to:
  /// **'until {date}'**
  String repeatUntilDate(String date);

  /// No description provided for @repeatTimesCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{once} other{{count} times}}'**
  String repeatTimesCount(int count);

  /// No description provided for @repeatOnDays.
  ///
  /// In en, this message translates to:
  /// **'On days'**
  String get repeatOnDays;

  /// No description provided for @repeatEnds.
  ///
  /// In en, this message translates to:
  /// **'Ends'**
  String get repeatEnds;

  /// No description provided for @repeatEndsNever.
  ///
  /// In en, this message translates to:
  /// **'Never'**
  String get repeatEndsNever;

  /// No description provided for @repeatEndsOnDate.
  ///
  /// In en, this message translates to:
  /// **'On a date'**
  String get repeatEndsOnDate;

  /// No description provided for @repeatEndsAfter.
  ///
  /// In en, this message translates to:
  /// **'After a number of times'**
  String get repeatEndsAfter;

  /// No description provided for @repeatOccurrences.
  ///
  /// In en, this message translates to:
  /// **'Number of times'**
  String get repeatOccurrences;

  /// No description provided for @rangeToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get rangeToday;

  /// No description provided for @rangeYesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get rangeYesterday;

  /// No description provided for @rangeLast7Days.
  ///
  /// In en, this message translates to:
  /// **'Last 7 days'**
  String get rangeLast7Days;

  /// No description provided for @rangeThisMonth.
  ///
  /// In en, this message translates to:
  /// **'This month'**
  String get rangeThisMonth;

  /// No description provided for @rangeLastMonth.
  ///
  /// In en, this message translates to:
  /// **'Previous month'**
  String get rangeLastMonth;

  /// No description provided for @rangeCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom range'**
  String get rangeCustom;

  /// No description provided for @onbWelcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome to DAWASA'**
  String get onbWelcomeTitle;

  /// No description provided for @onbWelcomeBody.
  ///
  /// In en, this message translates to:
  /// **'Manage your money, plans and daily life in one simple app.'**
  String get onbWelcomeBody;

  /// No description provided for @onbPointFree.
  ///
  /// In en, this message translates to:
  /// **'100% free — no ads, no subscriptions'**
  String get onbPointFree;

  /// No description provided for @onbPointOffline.
  ///
  /// In en, this message translates to:
  /// **'Works fully offline'**
  String get onbPointOffline;

  /// No description provided for @onbPointPrivate.
  ///
  /// In en, this message translates to:
  /// **'Your data stays on your phone'**
  String get onbPointPrivate;

  /// No description provided for @onbPointNoLogin.
  ///
  /// In en, this message translates to:
  /// **'No login or registration'**
  String get onbPointNoLogin;

  /// No description provided for @onbLanguageTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose your language'**
  String get onbLanguageTitle;

  /// No description provided for @onbLanguageBody.
  ///
  /// In en, this message translates to:
  /// **'You can change this later in Settings.'**
  String get onbLanguageBody;

  /// No description provided for @onbCurrencyTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose your currency'**
  String get onbCurrencyTitle;

  /// No description provided for @onbCurrencyBody.
  ///
  /// In en, this message translates to:
  /// **'All amounts will be shown in this currency.'**
  String get onbCurrencyBody;

  /// No description provided for @onbBalancesTitle.
  ///
  /// In en, this message translates to:
  /// **'Your current balances'**
  String get onbBalancesTitle;

  /// No description provided for @onbBalancesBody.
  ///
  /// In en, this message translates to:
  /// **'Enter how much money you have now. You can skip this and add accounts later.'**
  String get onbBalancesBody;

  /// No description provided for @onbCashBalance.
  ///
  /// In en, this message translates to:
  /// **'Cash in hand'**
  String get onbCashBalance;

  /// No description provided for @onbBankBalance.
  ///
  /// In en, this message translates to:
  /// **'Bank balance'**
  String get onbBankBalance;

  /// No description provided for @onbWalletBalance.
  ///
  /// In en, this message translates to:
  /// **'Other wallet balance'**
  String get onbWalletBalance;

  /// No description provided for @onbBudgetTitle.
  ///
  /// In en, this message translates to:
  /// **'Daily spending budget'**
  String get onbBudgetTitle;

  /// No description provided for @onbBudgetBody.
  ///
  /// In en, this message translates to:
  /// **'Set how much you want to spend per day. DAWASA will show what is left each day.'**
  String get onbBudgetBody;

  /// No description provided for @onbBudgetLabel.
  ///
  /// In en, this message translates to:
  /// **'Daily budget'**
  String get onbBudgetLabel;

  /// No description provided for @onbRemindersTitle.
  ///
  /// In en, this message translates to:
  /// **'Reminders'**
  String get onbRemindersTitle;

  /// No description provided for @onbRemindersBody.
  ///
  /// In en, this message translates to:
  /// **'DAWASA can remind you about tasks, bills and important dates. Reminders are created on your phone — nothing is sent to the internet.'**
  String get onbRemindersBody;

  /// No description provided for @onbEnableReminders.
  ///
  /// In en, this message translates to:
  /// **'Enable reminders'**
  String get onbEnableReminders;

  /// No description provided for @onbRemindersEnabled.
  ///
  /// In en, this message translates to:
  /// **'Reminders are enabled'**
  String get onbRemindersEnabled;

  /// No description provided for @onbRemindersDenied.
  ///
  /// In en, this message translates to:
  /// **'Permission was not granted. You can enable it later in Settings.'**
  String get onbRemindersDenied;

  /// No description provided for @onbFinish.
  ///
  /// In en, this message translates to:
  /// **'Start using DAWASA'**
  String get onbFinish;

  /// No description provided for @onbStepOf.
  ///
  /// In en, this message translates to:
  /// **'Step {step} of {total}'**
  String onbStepOf(int step, int total);

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsGeneral.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get settingsGeneral;

  /// No description provided for @settingsSecurity.
  ///
  /// In en, this message translates to:
  /// **'Security & privacy'**
  String get settingsSecurity;

  /// No description provided for @settingsReminders.
  ///
  /// In en, this message translates to:
  /// **'Reminders'**
  String get settingsReminders;

  /// No description provided for @settingsData.
  ///
  /// In en, this message translates to:
  /// **'Data'**
  String get settingsData;

  /// No description provided for @settingsUpdates.
  ///
  /// In en, this message translates to:
  /// **'Updates'**
  String get settingsUpdates;

  /// No description provided for @settingsAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get settingsAbout;

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// No description provided for @settingsCurrency.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get settingsCurrency;

  /// No description provided for @settingsTheme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get settingsTheme;

  /// No description provided for @settingsThemeSystem.
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get settingsThemeSystem;

  /// No description provided for @settingsThemeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get settingsThemeLight;

  /// No description provided for @settingsThemeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get settingsThemeDark;

  /// No description provided for @settingsDateFormat.
  ///
  /// In en, this message translates to:
  /// **'Date format'**
  String get settingsDateFormat;

  /// No description provided for @settingsFirstDayOfWeek.
  ///
  /// In en, this message translates to:
  /// **'First day of week'**
  String get settingsFirstDayOfWeek;

  /// No description provided for @settingsYourName.
  ///
  /// In en, this message translates to:
  /// **'Your name'**
  String get settingsYourName;

  /// No description provided for @settingsYourNameHint.
  ///
  /// In en, this message translates to:
  /// **'Used only for the greeting on the home screen'**
  String get settingsYourNameHint;

  /// No description provided for @settingsDailyBudget.
  ///
  /// In en, this message translates to:
  /// **'Daily budget'**
  String get settingsDailyBudget;

  /// No description provided for @settingsCategories.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get settingsCategories;

  /// No description provided for @settingsCurrencyChangeNote.
  ///
  /// In en, this message translates to:
  /// **'Changing the currency only changes how new amounts are shown. Existing amounts are not converted.'**
  String get settingsCurrencyChangeNote;

  /// No description provided for @settingsPrivacyMode.
  ///
  /// In en, this message translates to:
  /// **'Hide balances when the app opens'**
  String get settingsPrivacyMode;

  /// No description provided for @settingsPrivacyModeDesc.
  ///
  /// In en, this message translates to:
  /// **'Useful when you open DAWASA in public'**
  String get settingsPrivacyModeDesc;

  /// No description provided for @settingsScreenProtection.
  ///
  /// In en, this message translates to:
  /// **'Protect screen contents'**
  String get settingsScreenProtection;

  /// No description provided for @settingsScreenProtectionDesc.
  ///
  /// In en, this message translates to:
  /// **'Blocks screenshots and hides DAWASA in the recent apps view'**
  String get settingsScreenProtectionDesc;

  /// No description provided for @settingsNotificationsEnabled.
  ///
  /// In en, this message translates to:
  /// **'Allow reminders'**
  String get settingsNotificationsEnabled;

  /// No description provided for @settingsNotifyTasks.
  ///
  /// In en, this message translates to:
  /// **'Task reminders'**
  String get settingsNotifyTasks;

  /// No description provided for @settingsNotifyBills.
  ///
  /// In en, this message translates to:
  /// **'Bill reminders'**
  String get settingsNotifyBills;

  /// No description provided for @settingsNotifyEvents.
  ///
  /// In en, this message translates to:
  /// **'Important date reminders'**
  String get settingsNotifyEvents;

  /// No description provided for @settingsNotifyBudgets.
  ///
  /// In en, this message translates to:
  /// **'Budget alerts'**
  String get settingsNotifyBudgets;

  /// No description provided for @settingsNotifyLoans.
  ///
  /// In en, this message translates to:
  /// **'Loan repayment reminders'**
  String get settingsNotifyLoans;

  /// No description provided for @settingsNotifySavings.
  ///
  /// In en, this message translates to:
  /// **'Savings goal reminders'**
  String get settingsNotifySavings;

  /// No description provided for @settingsNotifyHabits.
  ///
  /// In en, this message translates to:
  /// **'Habit reminders'**
  String get settingsNotifyHabits;

  /// No description provided for @settingsDailyPlanning.
  ///
  /// In en, this message translates to:
  /// **'Daily planning reminder'**
  String get settingsDailyPlanning;

  /// No description provided for @settingsDailyPlanningDesc.
  ///
  /// In en, this message translates to:
  /// **'A daily nudge to review your day and record spending'**
  String get settingsDailyPlanningDesc;

  /// No description provided for @settingsDailyPlanningTime.
  ///
  /// In en, this message translates to:
  /// **'Reminder time'**
  String get settingsDailyPlanningTime;

  /// No description provided for @settingsNotificationsBlocked.
  ///
  /// In en, this message translates to:
  /// **'Notifications are turned off for DAWASA in Android settings.'**
  String get settingsNotificationsBlocked;

  /// No description provided for @settingsBatteryNote.
  ///
  /// In en, this message translates to:
  /// **'Some phones delay reminders to save battery. If reminders arrive late, allow DAWASA to run without battery restrictions.'**
  String get settingsBatteryNote;

  /// No description provided for @settingsBackup.
  ///
  /// In en, this message translates to:
  /// **'Create backup'**
  String get settingsBackup;

  /// No description provided for @settingsRestore.
  ///
  /// In en, this message translates to:
  /// **'Restore from backup'**
  String get settingsRestore;

  /// No description provided for @settingsExportCsv.
  ///
  /// In en, this message translates to:
  /// **'Export transactions (CSV)'**
  String get settingsExportCsv;

  /// No description provided for @settingsDeleteAll.
  ///
  /// In en, this message translates to:
  /// **'Delete all personal data'**
  String get settingsDeleteAll;

  /// No description provided for @settingsDeleteAllDesc.
  ///
  /// In en, this message translates to:
  /// **'Erases every record from this phone'**
  String get settingsDeleteAllDesc;

  /// No description provided for @settingsUninstallWarning.
  ///
  /// In en, this message translates to:
  /// **'Your data is stored only on this phone. Uninstalling DAWASA or clearing its storage deletes it permanently unless you keep a backup file somewhere safe.'**
  String get settingsUninstallWarning;

  /// No description provided for @settingsCurrentVersion.
  ///
  /// In en, this message translates to:
  /// **'Current version'**
  String get settingsCurrentVersion;

  /// No description provided for @settingsCheckUpdates.
  ///
  /// In en, this message translates to:
  /// **'Check for updates'**
  String get settingsCheckUpdates;

  /// No description provided for @settingsAutoCheckUpdates.
  ///
  /// In en, this message translates to:
  /// **'Check for updates automatically'**
  String get settingsAutoCheckUpdates;

  /// No description provided for @settingsAutoCheckUpdatesDesc.
  ///
  /// In en, this message translates to:
  /// **'At most once a day, only when connected'**
  String get settingsAutoCheckUpdatesDesc;

  /// No description provided for @settingsWifiOnly.
  ///
  /// In en, this message translates to:
  /// **'Download updates on Wi-Fi only'**
  String get settingsWifiOnly;

  /// No description provided for @settingsUpdateServer.
  ///
  /// In en, this message translates to:
  /// **'Update server'**
  String get settingsUpdateServer;

  /// No description provided for @settingsUpdateServerHint.
  ///
  /// In en, this message translates to:
  /// **'HTTPS address of the DAWASA update folder'**
  String get settingsUpdateServerHint;

  /// No description provided for @settingsUpdateServerInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid https:// address'**
  String get settingsUpdateServerInvalid;

  /// No description provided for @settingsUpdateServerReset.
  ///
  /// In en, this message translates to:
  /// **'Use default server'**
  String get settingsUpdateServerReset;

  /// No description provided for @settingsReplayOnboarding.
  ///
  /// In en, this message translates to:
  /// **'Show welcome guide again'**
  String get settingsReplayOnboarding;

  /// No description provided for @settingsLicenses.
  ///
  /// In en, this message translates to:
  /// **'Open-source licenses'**
  String get settingsLicenses;

  /// No description provided for @settingsPrivacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get settingsPrivacyPolicy;

  /// No description provided for @aboutDeveloper.
  ///
  /// In en, this message translates to:
  /// **'Developer'**
  String get aboutDeveloper;

  /// No description provided for @aboutFree.
  ///
  /// In en, this message translates to:
  /// **'100% Free'**
  String get aboutFree;

  /// No description provided for @aboutNoAds.
  ///
  /// In en, this message translates to:
  /// **'No Ads'**
  String get aboutNoAds;

  /// No description provided for @aboutNoSubscription.
  ///
  /// In en, this message translates to:
  /// **'No Subscription'**
  String get aboutNoSubscription;

  /// No description provided for @aboutWebsite.
  ///
  /// In en, this message translates to:
  /// **'Website'**
  String get aboutWebsite;

  /// No description provided for @aboutContact.
  ///
  /// In en, this message translates to:
  /// **'Contact'**
  String get aboutContact;

  /// No description provided for @aboutVersion.
  ///
  /// In en, this message translates to:
  /// **'Version {version} ({code})'**
  String aboutVersion(String version, String code);

  /// No description provided for @privacyTitle.
  ///
  /// In en, this message translates to:
  /// **'Your privacy'**
  String get privacyTitle;

  /// No description provided for @privacyBody.
  ///
  /// In en, this message translates to:
  /// **'DAWASA stores all of your financial and personal records only on this phone, in the app\'s private storage.\n\n• No account, login or registration.\n• No advertising, analytics or tracking.\n• No financial data is ever sent to any server.\n• Android cloud backup of app data is disabled, so your records are not copied to online storage.\n• Backups are encrypted with a password only you know (AES-256-GCM). Without the password nobody — including the developer — can read them.\n• The only internet connection DAWASA makes is to the update server, and only to download the update description and the new app file. No personal data is included in these requests.\n• Receipt photos are copied into the app\'s private storage and never uploaded.'**
  String get privacyBody;

  /// No description provided for @securityPin.
  ///
  /// In en, this message translates to:
  /// **'PIN lock'**
  String get securityPin;

  /// No description provided for @securityPinDesc.
  ///
  /// In en, this message translates to:
  /// **'Ask for a PIN when DAWASA opens'**
  String get securityPinDesc;

  /// No description provided for @securitySetPin.
  ///
  /// In en, this message translates to:
  /// **'Set PIN'**
  String get securitySetPin;

  /// No description provided for @securityChangePin.
  ///
  /// In en, this message translates to:
  /// **'Change PIN'**
  String get securityChangePin;

  /// No description provided for @securityRemovePin.
  ///
  /// In en, this message translates to:
  /// **'Remove PIN'**
  String get securityRemovePin;

  /// No description provided for @securityBiometric.
  ///
  /// In en, this message translates to:
  /// **'Unlock with fingerprint or face'**
  String get securityBiometric;

  /// No description provided for @securityBiometricUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Biometric unlock is not available on this phone'**
  String get securityBiometricUnavailable;

  /// No description provided for @securityLockTimeout.
  ///
  /// In en, this message translates to:
  /// **'Lock after'**
  String get securityLockTimeout;

  /// No description provided for @securityLockImmediately.
  ///
  /// In en, this message translates to:
  /// **'Immediately'**
  String get securityLockImmediately;

  /// No description provided for @securityLockAfterMinutes.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{After 1 minute} other{After {count} minutes}}'**
  String securityLockAfterMinutes(int count);

  /// No description provided for @securityEnterPin.
  ///
  /// In en, this message translates to:
  /// **'Enter your PIN'**
  String get securityEnterPin;

  /// No description provided for @securityCreatePin.
  ///
  /// In en, this message translates to:
  /// **'Create a PIN'**
  String get securityCreatePin;

  /// No description provided for @securityCreatePinDesc.
  ///
  /// In en, this message translates to:
  /// **'Use 4 to 6 digits. Do not use your bank card PIN.'**
  String get securityCreatePinDesc;

  /// No description provided for @securityConfirmPin.
  ///
  /// In en, this message translates to:
  /// **'Enter the PIN again'**
  String get securityConfirmPin;

  /// No description provided for @securityPinMismatch.
  ///
  /// In en, this message translates to:
  /// **'PINs do not match. Try again.'**
  String get securityPinMismatch;

  /// No description provided for @securityWrongPin.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Wrong PIN. 1 attempt left before a pause.} other{Wrong PIN. {count} attempts left before a pause.}}'**
  String securityWrongPin(int count);

  /// No description provided for @securityUnlockTitle.
  ///
  /// In en, this message translates to:
  /// **'DAWASA is locked'**
  String get securityUnlockTitle;

  /// No description provided for @securityUseBiometric.
  ///
  /// In en, this message translates to:
  /// **'Use fingerprint / face'**
  String get securityUseBiometric;

  /// No description provided for @securityBiometricReason.
  ///
  /// In en, this message translates to:
  /// **'Unlock DAWASA'**
  String get securityBiometricReason;

  /// No description provided for @securityPinSet.
  ///
  /// In en, this message translates to:
  /// **'PIN lock enabled'**
  String get securityPinSet;

  /// No description provided for @securityPinRemoved.
  ///
  /// In en, this message translates to:
  /// **'PIN lock removed'**
  String get securityPinRemoved;

  /// No description provided for @securityForgotPin.
  ///
  /// In en, this message translates to:
  /// **'Forgot PIN?'**
  String get securityForgotPin;

  /// No description provided for @securityForgotPinBody.
  ///
  /// In en, this message translates to:
  /// **'For your privacy the PIN cannot be recovered. You can erase all data on this phone and restore from a backup file.'**
  String get securityForgotPinBody;

  /// No description provided for @securityDeleteAndReset.
  ///
  /// In en, this message translates to:
  /// **'Erase data and reset'**
  String get securityDeleteAndReset;

  /// No description provided for @backupIntro.
  ///
  /// In en, this message translates to:
  /// **'A backup is a single encrypted file with all your records and receipt photos. Keep it somewhere safe, such as Google Drive, a computer or a memory card.'**
  String get backupIntro;

  /// No description provided for @backupPassword.
  ///
  /// In en, this message translates to:
  /// **'Backup password'**
  String get backupPassword;

  /// No description provided for @backupPasswordConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get backupPasswordConfirm;

  /// No description provided for @backupPasswordRules.
  ///
  /// In en, this message translates to:
  /// **'At least 8 characters. You will need this password to restore. It cannot be recovered.'**
  String get backupPasswordRules;

  /// No description provided for @backupPasswordTooShort.
  ///
  /// In en, this message translates to:
  /// **'Use at least 8 characters'**
  String get backupPasswordTooShort;

  /// No description provided for @backupPasswordMismatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get backupPasswordMismatch;

  /// No description provided for @backupCreating.
  ///
  /// In en, this message translates to:
  /// **'Encrypting your data…'**
  String get backupCreating;

  /// No description provided for @backupCreated.
  ///
  /// In en, this message translates to:
  /// **'Backup created'**
  String get backupCreated;

  /// No description provided for @backupSaveToDevice.
  ///
  /// In en, this message translates to:
  /// **'Save to a folder'**
  String get backupSaveToDevice;

  /// No description provided for @backupShareFile.
  ///
  /// In en, this message translates to:
  /// **'Share / send file'**
  String get backupShareFile;

  /// No description provided for @backupSavedTo.
  ///
  /// In en, this message translates to:
  /// **'Backup saved'**
  String get backupSavedTo;

  /// No description provided for @backupLastBackup.
  ///
  /// In en, this message translates to:
  /// **'Last backup: {date}'**
  String backupLastBackup(String date);

  /// No description provided for @backupNever.
  ///
  /// In en, this message translates to:
  /// **'No backup made yet'**
  String get backupNever;

  /// No description provided for @restoreChooseFile.
  ///
  /// In en, this message translates to:
  /// **'Choose backup file'**
  String get restoreChooseFile;

  /// No description provided for @restoreEnterPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter the password used for this backup'**
  String get restoreEnterPassword;

  /// No description provided for @restoreVerifying.
  ///
  /// In en, this message translates to:
  /// **'Checking backup…'**
  String get restoreVerifying;

  /// No description provided for @restoreConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Replace all data?'**
  String get restoreConfirmTitle;

  /// No description provided for @restoreConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'Restoring replaces ALL data currently in DAWASA on this phone with the contents of the backup. A safety copy of your current data is saved first.'**
  String get restoreConfirmBody;

  /// No description provided for @restoreBackupInfo.
  ///
  /// In en, this message translates to:
  /// **'Backup from {date} · app {version}'**
  String restoreBackupInfo(String date, String version);

  /// No description provided for @restoreAction.
  ///
  /// In en, this message translates to:
  /// **'Replace and restore'**
  String get restoreAction;

  /// No description provided for @restoreInProgress.
  ///
  /// In en, this message translates to:
  /// **'Restoring…'**
  String get restoreInProgress;

  /// No description provided for @restoreErrorWrongPassword.
  ///
  /// In en, this message translates to:
  /// **'Wrong password, or the file was changed or damaged.'**
  String get restoreErrorWrongPassword;

  /// No description provided for @restoreErrorNotBackup.
  ///
  /// In en, this message translates to:
  /// **'This is not a DAWASA backup file.'**
  String get restoreErrorNotBackup;

  /// No description provided for @restoreErrorCorrupted.
  ///
  /// In en, this message translates to:
  /// **'The backup file is damaged and cannot be restored.'**
  String get restoreErrorCorrupted;

  /// No description provided for @restoreErrorNewer.
  ///
  /// In en, this message translates to:
  /// **'This backup was made by a newer version of DAWASA. Update the app first.'**
  String get restoreErrorNewer;

  /// No description provided for @deleteAllTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete all personal data?'**
  String get deleteAllTitle;

  /// No description provided for @deleteAllBody.
  ///
  /// In en, this message translates to:
  /// **'Every account, transaction, task, bill, receipt photo and setting will be erased from this phone. This cannot be undone. Type DELETE to confirm.'**
  String get deleteAllBody;

  /// No description provided for @deleteAllConfirmWord.
  ///
  /// In en, this message translates to:
  /// **'DELETE'**
  String get deleteAllConfirmWord;

  /// No description provided for @deleteAllDone.
  ///
  /// In en, this message translates to:
  /// **'All data deleted'**
  String get deleteAllDone;

  /// No description provided for @updateTitle.
  ///
  /// In en, this message translates to:
  /// **'App updates'**
  String get updateTitle;

  /// No description provided for @updateChecking.
  ///
  /// In en, this message translates to:
  /// **'Checking for updates…'**
  String get updateChecking;

  /// No description provided for @updateUpToDate.
  ///
  /// In en, this message translates to:
  /// **'DAWASA is up to date'**
  String get updateUpToDate;

  /// No description provided for @updateAvailable.
  ///
  /// In en, this message translates to:
  /// **'Update available: {version}'**
  String updateAvailable(String version);

  /// No description provided for @updateRequired.
  ///
  /// In en, this message translates to:
  /// **'This version is no longer supported. Please update.'**
  String get updateRequired;

  /// No description provided for @updateDownloading.
  ///
  /// In en, this message translates to:
  /// **'Downloading… {percent}%'**
  String updateDownloading(int percent);

  /// No description provided for @updateVerifying.
  ///
  /// In en, this message translates to:
  /// **'Verifying download…'**
  String get updateVerifying;

  /// No description provided for @updateReady.
  ///
  /// In en, this message translates to:
  /// **'Ready to install'**
  String get updateReady;

  /// No description provided for @updateInstallCancelled.
  ///
  /// In en, this message translates to:
  /// **'Installation cancelled'**
  String get updateInstallCancelled;

  /// No description provided for @updateInstalling.
  ///
  /// In en, this message translates to:
  /// **'Opening Android installer…'**
  String get updateInstalling;

  /// No description provided for @updateOffline.
  ///
  /// In en, this message translates to:
  /// **'No internet connection. Everything else in DAWASA keeps working offline.'**
  String get updateOffline;

  /// No description provided for @updateServerUnavailable.
  ///
  /// In en, this message translates to:
  /// **'The update server could not be reached. Try again later.'**
  String get updateServerUnavailable;

  /// No description provided for @updateInvalidManifest.
  ///
  /// In en, this message translates to:
  /// **'The update information from the server is invalid.'**
  String get updateInvalidManifest;

  /// No description provided for @updateChecksumMismatch.
  ///
  /// In en, this message translates to:
  /// **'The downloaded file failed the security check and was deleted.'**
  String get updateChecksumMismatch;

  /// No description provided for @updatePackageMismatch.
  ///
  /// In en, this message translates to:
  /// **'The downloaded file is not a valid DAWASA update and was deleted.'**
  String get updatePackageMismatch;

  /// No description provided for @updateNow.
  ///
  /// In en, this message translates to:
  /// **'Update now'**
  String get updateNow;

  /// No description provided for @updateInstall.
  ///
  /// In en, this message translates to:
  /// **'Install'**
  String get updateInstall;

  /// No description provided for @updateCancelDownload.
  ///
  /// In en, this message translates to:
  /// **'Cancel download'**
  String get updateCancelDownload;

  /// No description provided for @updateSize.
  ///
  /// In en, this message translates to:
  /// **'Download size: {size}'**
  String updateSize(String size);

  /// No description provided for @updateWifiOnlyBlocked.
  ///
  /// In en, this message translates to:
  /// **'You are on mobile data and \"Wi-Fi only\" is on.'**
  String get updateWifiOnlyBlocked;

  /// No description provided for @updateDownloadAnyway.
  ///
  /// In en, this message translates to:
  /// **'Download anyway'**
  String get updateDownloadAnyway;

  /// No description provided for @updatePermissionTitle.
  ///
  /// In en, this message translates to:
  /// **'Allow installing the update'**
  String get updatePermissionTitle;

  /// No description provided for @updatePermissionBody.
  ///
  /// In en, this message translates to:
  /// **'Android asks you to allow DAWASA to install its own updates. On the next screen, turn on \"Allow from this source\", then come back.'**
  String get updatePermissionBody;

  /// No description provided for @updateDataSafe.
  ///
  /// In en, this message translates to:
  /// **'Updating keeps all your data.'**
  String get updateDataSafe;

  /// No description provided for @updateLastChecked.
  ///
  /// In en, this message translates to:
  /// **'Last checked: {date}'**
  String updateLastChecked(String date);

  /// No description provided for @updateNewVersionBanner.
  ///
  /// In en, this message translates to:
  /// **'A new version of DAWASA is available'**
  String get updateNewVersionBanner;

  /// No description provided for @updateWhatsNew.
  ///
  /// In en, this message translates to:
  /// **'What\'s new'**
  String get updateWhatsNew;

  /// No description provided for @moneyTitle.
  ///
  /// In en, this message translates to:
  /// **'Money'**
  String get moneyTitle;

  /// No description provided for @tabTransactions.
  ///
  /// In en, this message translates to:
  /// **'Transactions'**
  String get tabTransactions;

  /// No description provided for @tabAccounts.
  ///
  /// In en, this message translates to:
  /// **'Accounts'**
  String get tabAccounts;

  /// No description provided for @tabBudgets.
  ///
  /// In en, this message translates to:
  /// **'Budgets'**
  String get tabBudgets;

  /// No description provided for @tabBills.
  ///
  /// In en, this message translates to:
  /// **'Bills'**
  String get tabBills;

  /// No description provided for @tabSavings.
  ///
  /// In en, this message translates to:
  /// **'Savings'**
  String get tabSavings;

  /// No description provided for @tabLoans.
  ///
  /// In en, this message translates to:
  /// **'Loans'**
  String get tabLoans;

  /// No description provided for @homeAvailableBalance.
  ///
  /// In en, this message translates to:
  /// **'Available balance'**
  String get homeAvailableBalance;

  /// No description provided for @homeTodayIncome.
  ///
  /// In en, this message translates to:
  /// **'Today\'s income'**
  String get homeTodayIncome;

  /// No description provided for @homeTodayExpenses.
  ///
  /// In en, this message translates to:
  /// **'Today\'s expenses'**
  String get homeTodayExpenses;

  /// No description provided for @homeTodayNet.
  ///
  /// In en, this message translates to:
  /// **'Today\'s net cash flow'**
  String get homeTodayNet;

  /// No description provided for @homeRemainingBudget.
  ///
  /// In en, this message translates to:
  /// **'Left to spend today'**
  String get homeRemainingBudget;

  /// No description provided for @homeBudgetExceeded.
  ///
  /// In en, this message translates to:
  /// **'Over today\'s budget by {amount}'**
  String homeBudgetExceeded(String amount);

  /// No description provided for @homeNoBudget.
  ///
  /// In en, this message translates to:
  /// **'Set a daily budget'**
  String get homeNoBudget;

  /// No description provided for @homeBudgetFromMonthly.
  ///
  /// In en, this message translates to:
  /// **'Based on your monthly budget'**
  String get homeBudgetFromMonthly;

  /// No description provided for @homePendingTasks.
  ///
  /// In en, this message translates to:
  /// **'Tasks for today'**
  String get homePendingTasks;

  /// No description provided for @homeNoPendingTasks.
  ///
  /// In en, this message translates to:
  /// **'No tasks left for today'**
  String get homeNoPendingTasks;

  /// No description provided for @homeUpcomingPayments.
  ///
  /// In en, this message translates to:
  /// **'Upcoming payments'**
  String get homeUpcomingPayments;

  /// No description provided for @homeNoUpcomingPayments.
  ///
  /// In en, this message translates to:
  /// **'No payments due in the next 7 days'**
  String get homeNoUpcomingPayments;

  /// No description provided for @homeSavingsProgress.
  ///
  /// In en, this message translates to:
  /// **'Savings goals'**
  String get homeSavingsProgress;

  /// No description provided for @homeNoSavingsGoals.
  ///
  /// In en, this message translates to:
  /// **'Create a savings goal to track your progress'**
  String get homeNoSavingsGoals;

  /// No description provided for @homeLast7Days.
  ///
  /// In en, this message translates to:
  /// **'Spending — last 7 days'**
  String get homeLast7Days;

  /// No description provided for @homeRecentTransactions.
  ///
  /// In en, this message translates to:
  /// **'Recent transactions'**
  String get homeRecentTransactions;

  /// No description provided for @homeNoTransactions.
  ///
  /// In en, this message translates to:
  /// **'No transactions yet. Tap + to add your first expense or income.'**
  String get homeNoTransactions;

  /// No description provided for @homeHideBalances.
  ///
  /// In en, this message translates to:
  /// **'Hide balances'**
  String get homeHideBalances;

  /// No description provided for @homeShowBalances.
  ///
  /// In en, this message translates to:
  /// **'Show balances'**
  String get homeShowBalances;

  /// No description provided for @quickAddExpense.
  ///
  /// In en, this message translates to:
  /// **'Add expense'**
  String get quickAddExpense;

  /// No description provided for @quickAddIncome.
  ///
  /// In en, this message translates to:
  /// **'Add income'**
  String get quickAddIncome;

  /// No description provided for @quickAddTask.
  ///
  /// In en, this message translates to:
  /// **'Add task'**
  String get quickAddTask;

  /// No description provided for @quickViewReports.
  ///
  /// In en, this message translates to:
  /// **'View reports'**
  String get quickViewReports;

  /// No description provided for @quickAddTransfer.
  ///
  /// In en, this message translates to:
  /// **'Transfer'**
  String get quickAddTransfer;

  /// No description provided for @homeChartSemantics.
  ///
  /// In en, this message translates to:
  /// **'Spending for the last 7 days. {summary}'**
  String homeChartSemantics(String summary);

  /// No description provided for @hiddenAmount.
  ///
  /// In en, this message translates to:
  /// **'Hidden'**
  String get hiddenAmount;

  /// No description provided for @txTypeExpense.
  ///
  /// In en, this message translates to:
  /// **'Expense'**
  String get txTypeExpense;

  /// No description provided for @txTypeIncome.
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get txTypeIncome;

  /// No description provided for @txTypeTransfer.
  ///
  /// In en, this message translates to:
  /// **'Transfer'**
  String get txTypeTransfer;

  /// No description provided for @txTypeReimbursement.
  ///
  /// In en, this message translates to:
  /// **'Reimbursement'**
  String get txTypeReimbursement;

  /// No description provided for @txTypeLoanGiven.
  ///
  /// In en, this message translates to:
  /// **'Money lent'**
  String get txTypeLoanGiven;

  /// No description provided for @txTypeLoanReceived.
  ///
  /// In en, this message translates to:
  /// **'Money borrowed'**
  String get txTypeLoanReceived;

  /// No description provided for @txTypeLoanRepaymentReceived.
  ///
  /// In en, this message translates to:
  /// **'Loan repayment received'**
  String get txTypeLoanRepaymentReceived;

  /// No description provided for @txTypeLoanRepaymentPaid.
  ///
  /// In en, this message translates to:
  /// **'Loan repayment paid'**
  String get txTypeLoanRepaymentPaid;

  /// No description provided for @txTypeAdjustmentIn.
  ///
  /// In en, this message translates to:
  /// **'Balance correction (+)'**
  String get txTypeAdjustmentIn;

  /// No description provided for @txTypeAdjustmentOut.
  ///
  /// In en, this message translates to:
  /// **'Balance correction (−)'**
  String get txTypeAdjustmentOut;

  /// No description provided for @txTypeReimbursementHelp.
  ///
  /// In en, this message translates to:
  /// **'Money paid back to you for something you paid for someone else. It is not counted as income.'**
  String get txTypeReimbursementHelp;

  /// No description provided for @txTransferHelp.
  ///
  /// In en, this message translates to:
  /// **'Moving money between your own accounts is not income or spending.'**
  String get txTransferHelp;

  /// No description provided for @txAddExpense.
  ///
  /// In en, this message translates to:
  /// **'Add expense'**
  String get txAddExpense;

  /// No description provided for @txAddIncome.
  ///
  /// In en, this message translates to:
  /// **'Add income'**
  String get txAddIncome;

  /// No description provided for @txAddTransfer.
  ///
  /// In en, this message translates to:
  /// **'Transfer between accounts'**
  String get txAddTransfer;

  /// No description provided for @txAddReimbursement.
  ///
  /// In en, this message translates to:
  /// **'Add reimbursement'**
  String get txAddReimbursement;

  /// No description provided for @txEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit transaction'**
  String get txEdit;

  /// No description provided for @txDetails.
  ///
  /// In en, this message translates to:
  /// **'Transaction'**
  String get txDetails;

  /// No description provided for @txPaidFrom.
  ///
  /// In en, this message translates to:
  /// **'Paid from'**
  String get txPaidFrom;

  /// No description provided for @txReceivedInto.
  ///
  /// In en, this message translates to:
  /// **'Received into'**
  String get txReceivedInto;

  /// No description provided for @txFromAccount.
  ///
  /// In en, this message translates to:
  /// **'From account'**
  String get txFromAccount;

  /// No description provided for @txToAccount.
  ///
  /// In en, this message translates to:
  /// **'To account'**
  String get txToAccount;

  /// No description provided for @txDescriptionHint.
  ///
  /// In en, this message translates to:
  /// **'What was it for?'**
  String get txDescriptionHint;

  /// No description provided for @txNoteHint.
  ///
  /// In en, this message translates to:
  /// **'Extra details (optional)'**
  String get txNoteHint;

  /// No description provided for @txReceipt.
  ///
  /// In en, this message translates to:
  /// **'Receipt photo'**
  String get txReceipt;

  /// No description provided for @txTakePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take photo'**
  String get txTakePhoto;

  /// No description provided for @txChooseFromGallery.
  ///
  /// In en, this message translates to:
  /// **'Choose from gallery'**
  String get txChooseFromGallery;

  /// No description provided for @txRemoveReceipt.
  ///
  /// In en, this message translates to:
  /// **'Remove photo'**
  String get txRemoveReceipt;

  /// No description provided for @txSelectAccount.
  ///
  /// In en, this message translates to:
  /// **'Select account'**
  String get txSelectAccount;

  /// No description provided for @txErrorSameAccount.
  ///
  /// In en, this message translates to:
  /// **'Choose two different accounts'**
  String get txErrorSameAccount;

  /// No description provided for @txErrorCurrencyMismatch.
  ///
  /// In en, this message translates to:
  /// **'Both accounts must use the same currency'**
  String get txErrorCurrencyMismatch;

  /// No description provided for @txErrorNoAccount.
  ///
  /// In en, this message translates to:
  /// **'Create an account first'**
  String get txErrorNoAccount;

  /// No description provided for @txErrorCategoryRequired.
  ///
  /// In en, this message translates to:
  /// **'Choose a category'**
  String get txErrorCategoryRequired;

  /// No description provided for @txDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this transaction?'**
  String get txDeleteTitle;

  /// No description provided for @txDeleteLinkedWarning.
  ///
  /// In en, this message translates to:
  /// **'This transaction is linked to a bill, shopping list, savings goal or loan. The link will be removed, and the balance will be recalculated.'**
  String get txDeleteLinkedWarning;

  /// No description provided for @txSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search description, note or amount'**
  String get txSearchHint;

  /// No description provided for @txNoResults.
  ///
  /// In en, this message translates to:
  /// **'No matching transactions'**
  String get txNoResults;

  /// No description provided for @txEmpty.
  ///
  /// In en, this message translates to:
  /// **'No transactions yet'**
  String get txEmpty;

  /// No description provided for @txFilterType.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get txFilterType;

  /// No description provided for @txFilterDates.
  ///
  /// In en, this message translates to:
  /// **'Dates'**
  String get txFilterDates;

  /// No description provided for @txFilterAnyDate.
  ///
  /// In en, this message translates to:
  /// **'Any date'**
  String get txFilterAnyDate;

  /// No description provided for @txSourceRecurring.
  ///
  /// In en, this message translates to:
  /// **'Recurring'**
  String get txSourceRecurring;

  /// No description provided for @txSourceBill.
  ///
  /// In en, this message translates to:
  /// **'Bill payment'**
  String get txSourceBill;

  /// No description provided for @txSourceShopping.
  ///
  /// In en, this message translates to:
  /// **'Shopping list'**
  String get txSourceShopping;

  /// No description provided for @txSourceSavings.
  ///
  /// In en, this message translates to:
  /// **'Savings goal'**
  String get txSourceSavings;

  /// No description provided for @txSourceLoan.
  ///
  /// In en, this message translates to:
  /// **'Loan'**
  String get txSourceLoan;

  /// No description provided for @txRepeatSection.
  ///
  /// In en, this message translates to:
  /// **'Make this a recurring transaction'**
  String get txRepeatSection;

  /// No description provided for @txRepeatHelp.
  ///
  /// In en, this message translates to:
  /// **'DAWASA will add it automatically on each date. You can edit or delete any of them.'**
  String get txRepeatHelp;

  /// No description provided for @txSplitNote.
  ///
  /// In en, this message translates to:
  /// **'Transfers, loans and reimbursements are not counted as income or spending.'**
  String get txSplitNote;

  /// No description provided for @recurringTitle.
  ///
  /// In en, this message translates to:
  /// **'Recurring transactions'**
  String get recurringTitle;

  /// No description provided for @recurringEmpty.
  ///
  /// In en, this message translates to:
  /// **'No recurring transactions. Turn on \"Repeat\" when adding an expense or income.'**
  String get recurringEmpty;

  /// No description provided for @recurringNext.
  ///
  /// In en, this message translates to:
  /// **'Next: {date}'**
  String recurringNext(String date);

  /// No description provided for @recurringEnded.
  ///
  /// In en, this message translates to:
  /// **'Ended'**
  String get recurringEnded;

  /// No description provided for @recurringPause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get recurringPause;

  /// No description provided for @recurringResume.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get recurringResume;

  /// No description provided for @recurringStop.
  ///
  /// In en, this message translates to:
  /// **'Stop repeating'**
  String get recurringStop;

  /// No description provided for @recurringStopBody.
  ///
  /// In en, this message translates to:
  /// **'Future transactions will no longer be added. Transactions already recorded are kept.'**
  String get recurringStopBody;

  /// No description provided for @catFood.
  ///
  /// In en, this message translates to:
  /// **'Food'**
  String get catFood;

  /// No description provided for @catTransport.
  ///
  /// In en, this message translates to:
  /// **'Transport'**
  String get catTransport;

  /// No description provided for @catShopping.
  ///
  /// In en, this message translates to:
  /// **'Shopping'**
  String get catShopping;

  /// No description provided for @catBills.
  ///
  /// In en, this message translates to:
  /// **'Bills'**
  String get catBills;

  /// No description provided for @catHealthcare.
  ///
  /// In en, this message translates to:
  /// **'Healthcare'**
  String get catHealthcare;

  /// No description provided for @catEducation.
  ///
  /// In en, this message translates to:
  /// **'Education'**
  String get catEducation;

  /// No description provided for @catEntertainment.
  ///
  /// In en, this message translates to:
  /// **'Entertainment'**
  String get catEntertainment;

  /// No description provided for @catFamily.
  ///
  /// In en, this message translates to:
  /// **'Family'**
  String get catFamily;

  /// No description provided for @catFuel.
  ///
  /// In en, this message translates to:
  /// **'Fuel'**
  String get catFuel;

  /// No description provided for @catRent.
  ///
  /// In en, this message translates to:
  /// **'Rent'**
  String get catRent;

  /// No description provided for @catInterestFees.
  ///
  /// In en, this message translates to:
  /// **'Interest & fees'**
  String get catInterestFees;

  /// No description provided for @catOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get catOther;

  /// No description provided for @catSalary.
  ///
  /// In en, this message translates to:
  /// **'Salary'**
  String get catSalary;

  /// No description provided for @catBusiness.
  ///
  /// In en, this message translates to:
  /// **'Business'**
  String get catBusiness;

  /// No description provided for @catFreelancing.
  ///
  /// In en, this message translates to:
  /// **'Freelancing'**
  String get catFreelancing;

  /// No description provided for @catInterest.
  ///
  /// In en, this message translates to:
  /// **'Interest'**
  String get catInterest;

  /// No description provided for @catGifts.
  ///
  /// In en, this message translates to:
  /// **'Gifts'**
  String get catGifts;

  /// No description provided for @categoriesTitle.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get categoriesTitle;

  /// No description provided for @categoriesExpense.
  ///
  /// In en, this message translates to:
  /// **'Expense categories'**
  String get categoriesExpense;

  /// No description provided for @categoriesIncome.
  ///
  /// In en, this message translates to:
  /// **'Income sources'**
  String get categoriesIncome;

  /// No description provided for @categoryAdd.
  ///
  /// In en, this message translates to:
  /// **'New category'**
  String get categoryAdd;

  /// No description provided for @categoryAddIncome.
  ///
  /// In en, this message translates to:
  /// **'New income source'**
  String get categoryAddIncome;

  /// No description provided for @categoryEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit category'**
  String get categoryEdit;

  /// No description provided for @categoryName.
  ///
  /// In en, this message translates to:
  /// **'Category name'**
  String get categoryName;

  /// No description provided for @categoryIcon.
  ///
  /// In en, this message translates to:
  /// **'Icon'**
  String get categoryIcon;

  /// No description provided for @categoryColor.
  ///
  /// In en, this message translates to:
  /// **'Colour'**
  String get categoryColor;

  /// No description provided for @categoryArchiveHelp.
  ///
  /// In en, this message translates to:
  /// **'Archived categories are hidden from new entries but kept in old transactions.'**
  String get categoryArchiveHelp;

  /// No description provided for @categoryDuplicateName.
  ///
  /// In en, this message translates to:
  /// **'A category with this name already exists'**
  String get categoryDuplicateName;

  /// No description provided for @categoryUncategorized.
  ///
  /// In en, this message translates to:
  /// **'Uncategorised'**
  String get categoryUncategorized;

  /// No description provided for @accountsTitle.
  ///
  /// In en, this message translates to:
  /// **'Accounts'**
  String get accountsTitle;

  /// No description provided for @accountAdd.
  ///
  /// In en, this message translates to:
  /// **'Add account'**
  String get accountAdd;

  /// No description provided for @accountEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit account'**
  String get accountEdit;

  /// No description provided for @accountName.
  ///
  /// In en, this message translates to:
  /// **'Account name'**
  String get accountName;

  /// No description provided for @accountType.
  ///
  /// In en, this message translates to:
  /// **'Account type'**
  String get accountType;

  /// No description provided for @accountTypeCash.
  ///
  /// In en, this message translates to:
  /// **'Cash'**
  String get accountTypeCash;

  /// No description provided for @accountTypeBank.
  ///
  /// In en, this message translates to:
  /// **'Bank account'**
  String get accountTypeBank;

  /// No description provided for @accountTypeEWallet.
  ///
  /// In en, this message translates to:
  /// **'E-wallet'**
  String get accountTypeEWallet;

  /// No description provided for @accountTypeSavings.
  ///
  /// In en, this message translates to:
  /// **'Savings account'**
  String get accountTypeSavings;

  /// No description provided for @accountTypeOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get accountTypeOther;

  /// No description provided for @accountDefaultCash.
  ///
  /// In en, this message translates to:
  /// **'Cash'**
  String get accountDefaultCash;

  /// No description provided for @accountDefaultBank.
  ///
  /// In en, this message translates to:
  /// **'Bank'**
  String get accountDefaultBank;

  /// No description provided for @accountDefaultWallet.
  ///
  /// In en, this message translates to:
  /// **'Wallet'**
  String get accountDefaultWallet;

  /// No description provided for @accountOpeningBalance.
  ///
  /// In en, this message translates to:
  /// **'Opening balance'**
  String get accountOpeningBalance;

  /// No description provided for @accountOpeningBalanceHelp.
  ///
  /// In en, this message translates to:
  /// **'Money in this account before you started using DAWASA'**
  String get accountOpeningBalanceHelp;

  /// No description provided for @accountIncludeInTotal.
  ///
  /// In en, this message translates to:
  /// **'Include in available balance'**
  String get accountIncludeInTotal;

  /// No description provided for @accountBalance.
  ///
  /// In en, this message translates to:
  /// **'Balance'**
  String get accountBalance;

  /// No description provided for @accountTotalBalance.
  ///
  /// In en, this message translates to:
  /// **'Total in {currency}'**
  String accountTotalBalance(String currency);

  /// No description provided for @accountCorrectBalance.
  ///
  /// In en, this message translates to:
  /// **'Correct balance'**
  String get accountCorrectBalance;

  /// No description provided for @accountCorrectBalanceBody.
  ///
  /// In en, this message translates to:
  /// **'Enter the actual balance of this account. DAWASA records the difference as a balance correction — it is not counted as income or spending.'**
  String get accountCorrectBalanceBody;

  /// No description provided for @accountActualBalance.
  ///
  /// In en, this message translates to:
  /// **'Actual balance'**
  String get accountActualBalance;

  /// No description provided for @accountCorrectionPreview.
  ///
  /// In en, this message translates to:
  /// **'A correction of {amount} will be recorded'**
  String accountCorrectionPreview(String amount);

  /// No description provided for @accountCorrectionNone.
  ///
  /// In en, this message translates to:
  /// **'The balance is already correct'**
  String get accountCorrectionNone;

  /// No description provided for @accountDeleteBlocked.
  ///
  /// In en, this message translates to:
  /// **'This account has transactions. Archive it instead to keep your history.'**
  String get accountDeleteBlocked;

  /// No description provided for @accountEmpty.
  ///
  /// In en, this message translates to:
  /// **'No accounts yet'**
  String get accountEmpty;

  /// No description provided for @accountArchivedSection.
  ///
  /// In en, this message translates to:
  /// **'Archived accounts'**
  String get accountArchivedSection;

  /// No description provided for @accountHistory.
  ///
  /// In en, this message translates to:
  /// **'Account history'**
  String get accountHistory;

  /// No description provided for @accountOtherCurrencies.
  ///
  /// In en, this message translates to:
  /// **'Accounts in other currencies are not added to this total.'**
  String get accountOtherCurrencies;

  /// No description provided for @accountCurrencyLocked.
  ///
  /// In en, this message translates to:
  /// **'The currency cannot be changed after transactions are recorded.'**
  String get accountCurrencyLocked;

  /// No description provided for @plannerTitle.
  ///
  /// In en, this message translates to:
  /// **'Planner'**
  String get plannerTitle;

  /// No description provided for @tabTasks.
  ///
  /// In en, this message translates to:
  /// **'Tasks'**
  String get tabTasks;

  /// No description provided for @tabShopping.
  ///
  /// In en, this message translates to:
  /// **'Shopping'**
  String get tabShopping;

  /// No description provided for @tabHabits.
  ///
  /// In en, this message translates to:
  /// **'Habits'**
  String get tabHabits;

  /// No description provided for @tabEvents.
  ///
  /// In en, this message translates to:
  /// **'Dates'**
  String get tabEvents;

  /// No description provided for @budgetAdd.
  ///
  /// In en, this message translates to:
  /// **'New budget'**
  String get budgetAdd;

  /// No description provided for @budgetEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit budget'**
  String get budgetEdit;

  /// No description provided for @budgetName.
  ///
  /// In en, this message translates to:
  /// **'Budget name'**
  String get budgetName;

  /// No description provided for @budgetAmount.
  ///
  /// In en, this message translates to:
  /// **'Budget amount'**
  String get budgetAmount;

  /// No description provided for @budgetPeriod.
  ///
  /// In en, this message translates to:
  /// **'Period'**
  String get budgetPeriod;

  /// No description provided for @budgetPeriodDaily.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get budgetPeriodDaily;

  /// No description provided for @budgetPeriodWeekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get budgetPeriodWeekly;

  /// No description provided for @budgetPeriodMonthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get budgetPeriodMonthly;

  /// No description provided for @budgetPeriodCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom dates'**
  String get budgetPeriodCustom;

  /// No description provided for @budgetScope.
  ///
  /// In en, this message translates to:
  /// **'Applies to'**
  String get budgetScope;

  /// No description provided for @budgetScopeAll.
  ///
  /// In en, this message translates to:
  /// **'All spending'**
  String get budgetScopeAll;

  /// No description provided for @budgetScopeCategories.
  ///
  /// In en, this message translates to:
  /// **'Selected categories'**
  String get budgetScopeCategories;

  /// No description provided for @budgetWarnAt.
  ///
  /// In en, this message translates to:
  /// **'Warn me at {percent}% used'**
  String budgetWarnAt(int percent);

  /// No description provided for @budgetNotify.
  ///
  /// In en, this message translates to:
  /// **'Budget notifications'**
  String get budgetNotify;

  /// No description provided for @budgetSpent.
  ///
  /// In en, this message translates to:
  /// **'Spent'**
  String get budgetSpent;

  /// No description provided for @budgetLeft.
  ///
  /// In en, this message translates to:
  /// **'Left'**
  String get budgetLeft;

  /// No description provided for @budgetOverBy.
  ///
  /// In en, this message translates to:
  /// **'Over by {amount}'**
  String budgetOverBy(String amount);

  /// No description provided for @budgetDaysLeft.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Last day} =1{1 day left} other{{count} days left}}'**
  String budgetDaysLeft(int count);

  /// No description provided for @budgetPerDay.
  ///
  /// In en, this message translates to:
  /// **'About {amount} per day'**
  String budgetPerDay(String amount);

  /// No description provided for @budgetEmpty.
  ///
  /// In en, this message translates to:
  /// **'No budgets yet. A budget helps you keep spending under control.'**
  String get budgetEmpty;

  /// No description provided for @budgetNotCounted.
  ///
  /// In en, this message translates to:
  /// **'Transfers, savings movements and loan principal are not counted as spending.'**
  String get budgetNotCounted;

  /// No description provided for @budgetEnded.
  ///
  /// In en, this message translates to:
  /// **'Ended'**
  String get budgetEnded;

  /// No description provided for @budgetNotStarted.
  ///
  /// In en, this message translates to:
  /// **'Starts {date}'**
  String budgetNotStarted(String date);

  /// No description provided for @budgetDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this budget?'**
  String get budgetDeleteTitle;

  /// No description provided for @budgetDeleteBody.
  ///
  /// In en, this message translates to:
  /// **'Your transactions are not affected.'**
  String get budgetDeleteBody;

  /// No description provided for @budgetChooseCategories.
  ///
  /// In en, this message translates to:
  /// **'Choose at least one category'**
  String get budgetChooseCategories;

  /// No description provided for @budgetPerformance.
  ///
  /// In en, this message translates to:
  /// **'Budget performance'**
  String get budgetPerformance;

  /// No description provided for @taskAdd.
  ///
  /// In en, this message translates to:
  /// **'New task'**
  String get taskAdd;

  /// No description provided for @taskEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit task'**
  String get taskEdit;

  /// No description provided for @taskTitle.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get taskTitle;

  /// No description provided for @taskTitleHint.
  ///
  /// In en, this message translates to:
  /// **'What do you need to do?'**
  String get taskTitleHint;

  /// No description provided for @taskDescription.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get taskDescription;

  /// No description provided for @taskDueDate.
  ///
  /// In en, this message translates to:
  /// **'Due date'**
  String get taskDueDate;

  /// No description provided for @taskDueTime.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get taskDueTime;

  /// No description provided for @taskPriority.
  ///
  /// In en, this message translates to:
  /// **'Priority'**
  String get taskPriority;

  /// No description provided for @taskPriorityLow.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get taskPriorityLow;

  /// No description provided for @taskPriorityMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get taskPriorityMedium;

  /// No description provided for @taskPriorityHigh.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get taskPriorityHigh;

  /// No description provided for @taskReminder.
  ///
  /// In en, this message translates to:
  /// **'Reminder'**
  String get taskReminder;

  /// No description provided for @taskReminderAtTime.
  ///
  /// In en, this message translates to:
  /// **'At the due time'**
  String get taskReminderAtTime;

  /// No description provided for @taskReminderMinutes.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 minute before} other{{count} minutes before}}'**
  String taskReminderMinutes(int count);

  /// No description provided for @taskReminderHours.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 hour before} other{{count} hours before}}'**
  String taskReminderHours(int count);

  /// No description provided for @taskReminderDays.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 day before} other{{count} days before}}'**
  String taskReminderDays(int count);

  /// No description provided for @taskReminderNeedsDate.
  ///
  /// In en, this message translates to:
  /// **'Set a due date to add a reminder'**
  String get taskReminderNeedsDate;

  /// No description provided for @taskViewToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get taskViewToday;

  /// No description provided for @taskViewTomorrow.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow'**
  String get taskViewTomorrow;

  /// No description provided for @taskViewUpcoming.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get taskViewUpcoming;

  /// No description provided for @taskViewCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get taskViewCompleted;

  /// No description provided for @taskViewAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get taskViewAll;

  /// No description provided for @taskOverdue.
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get taskOverdue;

  /// No description provided for @taskEmptyToday.
  ///
  /// In en, this message translates to:
  /// **'Nothing planned for today. Enjoy your day!'**
  String get taskEmptyToday;

  /// No description provided for @taskEmpty.
  ///
  /// In en, this message translates to:
  /// **'No tasks here'**
  String get taskEmpty;

  /// No description provided for @taskCompleted.
  ///
  /// In en, this message translates to:
  /// **'Task completed'**
  String get taskCompleted;

  /// No description provided for @taskNextCreated.
  ///
  /// In en, this message translates to:
  /// **'Next repeat scheduled for {date}'**
  String taskNextCreated(String date);

  /// No description provided for @taskMarkDone.
  ///
  /// In en, this message translates to:
  /// **'Mark as done'**
  String get taskMarkDone;

  /// No description provided for @taskMarkNotDone.
  ///
  /// In en, this message translates to:
  /// **'Mark as not done'**
  String get taskMarkNotDone;

  /// No description provided for @taskSortDue.
  ///
  /// In en, this message translates to:
  /// **'Sort by due date'**
  String get taskSortDue;

  /// No description provided for @taskSortPriority.
  ///
  /// In en, this message translates to:
  /// **'Sort by priority'**
  String get taskSortPriority;

  /// No description provided for @taskDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this task?'**
  String get taskDeleteTitle;

  /// No description provided for @taskClearCompleted.
  ///
  /// In en, this message translates to:
  /// **'Delete completed tasks'**
  String get taskClearCompleted;

  /// No description provided for @taskCountToday.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No tasks} =1{1 task} other{{count} tasks}}'**
  String taskCountToday(int count);

  /// No description provided for @billAdd.
  ///
  /// In en, this message translates to:
  /// **'New bill'**
  String get billAdd;

  /// No description provided for @billEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit bill'**
  String get billEdit;

  /// No description provided for @billName.
  ///
  /// In en, this message translates to:
  /// **'Bill name'**
  String get billName;

  /// No description provided for @billNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. CEB electricity'**
  String get billNameHint;

  /// No description provided for @billCategory.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get billCategory;

  /// No description provided for @billCatElectricity.
  ///
  /// In en, this message translates to:
  /// **'Electricity'**
  String get billCatElectricity;

  /// No description provided for @billCatWater.
  ///
  /// In en, this message translates to:
  /// **'Water'**
  String get billCatWater;

  /// No description provided for @billCatInternet.
  ///
  /// In en, this message translates to:
  /// **'Internet'**
  String get billCatInternet;

  /// No description provided for @billCatMobile.
  ///
  /// In en, this message translates to:
  /// **'Mobile'**
  String get billCatMobile;

  /// No description provided for @billCatRent.
  ///
  /// In en, this message translates to:
  /// **'Rent'**
  String get billCatRent;

  /// No description provided for @billCatInsurance.
  ///
  /// In en, this message translates to:
  /// **'Insurance'**
  String get billCatInsurance;

  /// No description provided for @billCatLoan.
  ///
  /// In en, this message translates to:
  /// **'Loan instalment'**
  String get billCatLoan;

  /// No description provided for @billCatOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get billCatOther;

  /// No description provided for @billAmount.
  ///
  /// In en, this message translates to:
  /// **'Usual amount'**
  String get billAmount;

  /// No description provided for @billDueDate.
  ///
  /// In en, this message translates to:
  /// **'Next due date'**
  String get billDueDate;

  /// No description provided for @billRepeat.
  ///
  /// In en, this message translates to:
  /// **'Repeats'**
  String get billRepeat;

  /// No description provided for @billOneTime.
  ///
  /// In en, this message translates to:
  /// **'One-time payment'**
  String get billOneTime;

  /// No description provided for @billRemind.
  ///
  /// In en, this message translates to:
  /// **'Remind me'**
  String get billRemind;

  /// No description provided for @billRemindDaysBefore.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{On the due date} =1{1 day before} other{{count} days before}}'**
  String billRemindDaysBefore(int count);

  /// No description provided for @billPaymentAccount.
  ///
  /// In en, this message translates to:
  /// **'Usually paid from'**
  String get billPaymentAccount;

  /// No description provided for @billDueToday.
  ///
  /// In en, this message translates to:
  /// **'Due today'**
  String get billDueToday;

  /// No description provided for @billDueIn.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Due tomorrow} other{Due in {count} days}}'**
  String billDueIn(int count);

  /// No description provided for @billOverdueBy.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 day overdue} other{{count} days overdue}}'**
  String billOverdueBy(int count);

  /// No description provided for @billMarkPaid.
  ///
  /// In en, this message translates to:
  /// **'Mark as paid'**
  String get billMarkPaid;

  /// No description provided for @billPayTitle.
  ///
  /// In en, this message translates to:
  /// **'Record payment'**
  String get billPayTitle;

  /// No description provided for @billPaidAmount.
  ///
  /// In en, this message translates to:
  /// **'Amount paid'**
  String get billPaidAmount;

  /// No description provided for @billPaidOn.
  ///
  /// In en, this message translates to:
  /// **'Paid on'**
  String get billPaidOn;

  /// No description provided for @billRecordExpense.
  ///
  /// In en, this message translates to:
  /// **'Record as an expense'**
  String get billRecordExpense;

  /// No description provided for @billRecordExpenseHelp.
  ///
  /// In en, this message translates to:
  /// **'Adds an expense in the \"Bills\" category and reduces the account balance.'**
  String get billRecordExpenseHelp;

  /// No description provided for @billPossibleDuplicate.
  ///
  /// In en, this message translates to:
  /// **'You already recorded a similar expense'**
  String get billPossibleDuplicate;

  /// No description provided for @billPossibleDuplicateBody.
  ///
  /// In en, this message translates to:
  /// **'Link that expense to this bill instead of creating a duplicate?'**
  String get billPossibleDuplicateBody;

  /// No description provided for @billLinkExisting.
  ///
  /// In en, this message translates to:
  /// **'Link existing expense'**
  String get billLinkExisting;

  /// No description provided for @billCreateNew.
  ///
  /// In en, this message translates to:
  /// **'Create a new expense'**
  String get billCreateNew;

  /// No description provided for @billPaymentSaved.
  ///
  /// In en, this message translates to:
  /// **'Payment recorded'**
  String get billPaymentSaved;

  /// No description provided for @billAlreadyPaid.
  ///
  /// In en, this message translates to:
  /// **'This due date is already marked as paid'**
  String get billAlreadyPaid;

  /// No description provided for @billHistory.
  ///
  /// In en, this message translates to:
  /// **'Payment history'**
  String get billHistory;

  /// No description provided for @billNoHistory.
  ///
  /// In en, this message translates to:
  /// **'No payments yet'**
  String get billNoHistory;

  /// No description provided for @billEmpty.
  ///
  /// In en, this message translates to:
  /// **'No bills yet. Add electricity, water, phone and other regular payments to get reminders.'**
  String get billEmpty;

  /// No description provided for @billUndoPayment.
  ///
  /// In en, this message translates to:
  /// **'Undo payment'**
  String get billUndoPayment;

  /// No description provided for @billUndoPaymentBody.
  ///
  /// In en, this message translates to:
  /// **'The payment record is removed and the bill becomes unpaid again. A linked expense is kept unless you delete it.'**
  String get billUndoPaymentBody;

  /// No description provided for @billExpenseLinked.
  ///
  /// In en, this message translates to:
  /// **'Expense recorded'**
  String get billExpenseLinked;

  /// No description provided for @billUpcoming.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get billUpcoming;

  /// No description provided for @billInactive.
  ///
  /// In en, this message translates to:
  /// **'Finished'**
  String get billInactive;

  /// No description provided for @billStop.
  ///
  /// In en, this message translates to:
  /// **'Stop this bill'**
  String get billStop;

  /// No description provided for @billResume.
  ///
  /// In en, this message translates to:
  /// **'Resume this bill'**
  String get billResume;

  /// No description provided for @shoppingNewList.
  ///
  /// In en, this message translates to:
  /// **'New list'**
  String get shoppingNewList;

  /// No description provided for @shoppingListName.
  ///
  /// In en, this message translates to:
  /// **'List name'**
  String get shoppingListName;

  /// No description provided for @shoppingListNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Weekly groceries'**
  String get shoppingListNameHint;

  /// No description provided for @shoppingAddItem.
  ///
  /// In en, this message translates to:
  /// **'Add item'**
  String get shoppingAddItem;

  /// No description provided for @shoppingEditItem.
  ///
  /// In en, this message translates to:
  /// **'Edit item'**
  String get shoppingEditItem;

  /// No description provided for @shoppingItemName.
  ///
  /// In en, this message translates to:
  /// **'Item'**
  String get shoppingItemName;

  /// No description provided for @shoppingQuantity.
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get shoppingQuantity;

  /// No description provided for @shoppingUnit.
  ///
  /// In en, this message translates to:
  /// **'Unit'**
  String get shoppingUnit;

  /// No description provided for @shoppingEstimated.
  ///
  /// In en, this message translates to:
  /// **'Estimated price'**
  String get shoppingEstimated;

  /// No description provided for @shoppingActual.
  ///
  /// In en, this message translates to:
  /// **'Actual price'**
  String get shoppingActual;

  /// No description provided for @shoppingPriceHelp.
  ///
  /// In en, this message translates to:
  /// **'Total for this line, not per unit'**
  String get shoppingPriceHelp;

  /// No description provided for @shoppingEstimatedTotal.
  ///
  /// In en, this message translates to:
  /// **'Estimated total'**
  String get shoppingEstimatedTotal;

  /// No description provided for @shoppingActualTotal.
  ///
  /// In en, this message translates to:
  /// **'Actual total'**
  String get shoppingActualTotal;

  /// No description provided for @shoppingEstimateNote.
  ///
  /// In en, this message translates to:
  /// **'Estimates are only a guide. They never change your balances.'**
  String get shoppingEstimateNote;

  /// No description provided for @shoppingPurchased.
  ///
  /// In en, this message translates to:
  /// **'Purchased'**
  String get shoppingPurchased;

  /// No description provided for @shoppingToBuy.
  ///
  /// In en, this message translates to:
  /// **'To buy'**
  String get shoppingToBuy;

  /// No description provided for @shoppingEmptyLists.
  ///
  /// In en, this message translates to:
  /// **'No shopping lists. Create one before you go to the shop.'**
  String get shoppingEmptyLists;

  /// No description provided for @shoppingEmptyItems.
  ///
  /// In en, this message translates to:
  /// **'This list is empty'**
  String get shoppingEmptyItems;

  /// No description provided for @shoppingRecordExpense.
  ///
  /// In en, this message translates to:
  /// **'Record purchases as expense'**
  String get shoppingRecordExpense;

  /// No description provided for @shoppingRecordExpenseBody.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 purchased item} other{{count} purchased items}} not recorded yet · {amount}'**
  String shoppingRecordExpenseBody(int count, String amount);

  /// No description provided for @shoppingMissingPrices.
  ///
  /// In en, this message translates to:
  /// **'Enter the actual price of every purchased item first'**
  String get shoppingMissingPrices;

  /// No description provided for @shoppingRecorded.
  ///
  /// In en, this message translates to:
  /// **'Expense recorded. These items will not be counted again.'**
  String get shoppingRecorded;

  /// No description provided for @shoppingAllRecorded.
  ///
  /// In en, this message translates to:
  /// **'All purchases are recorded'**
  String get shoppingAllRecorded;

  /// No description provided for @shoppingCompleteList.
  ///
  /// In en, this message translates to:
  /// **'Mark list as done'**
  String get shoppingCompleteList;

  /// No description provided for @shoppingReopenList.
  ///
  /// In en, this message translates to:
  /// **'Reopen list'**
  String get shoppingReopenList;

  /// No description provided for @shoppingListDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get shoppingListDone;

  /// No description provided for @shoppingDeleteList.
  ///
  /// In en, this message translates to:
  /// **'Delete list'**
  String get shoppingDeleteList;

  /// No description provided for @shoppingDeleteListBody.
  ///
  /// In en, this message translates to:
  /// **'Expenses already recorded from this list are kept.'**
  String get shoppingDeleteListBody;

  /// No description provided for @shoppingItemRecorded.
  ///
  /// In en, this message translates to:
  /// **'Recorded'**
  String get shoppingItemRecorded;

  /// No description provided for @shoppingProgress.
  ///
  /// In en, this message translates to:
  /// **'{done} of {total} bought'**
  String shoppingProgress(int done, int total);

  /// No description provided for @unitPcs.
  ///
  /// In en, this message translates to:
  /// **'pcs'**
  String get unitPcs;

  /// No description provided for @unitKg.
  ///
  /// In en, this message translates to:
  /// **'kg'**
  String get unitKg;

  /// No description provided for @unitG.
  ///
  /// In en, this message translates to:
  /// **'g'**
  String get unitG;

  /// No description provided for @unitL.
  ///
  /// In en, this message translates to:
  /// **'L'**
  String get unitL;

  /// No description provided for @unitMl.
  ///
  /// In en, this message translates to:
  /// **'ml'**
  String get unitMl;

  /// No description provided for @unitPack.
  ///
  /// In en, this message translates to:
  /// **'pack'**
  String get unitPack;

  /// No description provided for @unitBottle.
  ///
  /// In en, this message translates to:
  /// **'bottle'**
  String get unitBottle;

  /// No description provided for @unitDozen.
  ///
  /// In en, this message translates to:
  /// **'dozen'**
  String get unitDozen;

  /// No description provided for @homeSeeTasks.
  ///
  /// In en, this message translates to:
  /// **'See tasks'**
  String get homeSeeTasks;

  /// No description provided for @homeSeeBills.
  ///
  /// In en, this message translates to:
  /// **'See bills'**
  String get homeSeeBills;

  /// No description provided for @notifTaskTitle.
  ///
  /// In en, this message translates to:
  /// **'Task: {title}'**
  String notifTaskTitle(String title);

  /// No description provided for @notifTaskBodyDue.
  ///
  /// In en, this message translates to:
  /// **'Due {when}'**
  String notifTaskBodyDue(String when);

  /// No description provided for @notifBillTitle.
  ///
  /// In en, this message translates to:
  /// **'Bill due: {name}'**
  String notifBillTitle(String name);

  /// No description provided for @notifBillBody.
  ///
  /// In en, this message translates to:
  /// **'{amount} due {when}'**
  String notifBillBody(String amount, String when);

  /// No description provided for @notifBudgetWarnTitle.
  ///
  /// In en, this message translates to:
  /// **'Budget almost used: {name}'**
  String notifBudgetWarnTitle(String name);

  /// No description provided for @notifBudgetWarnBody.
  ///
  /// In en, this message translates to:
  /// **'You have used {percent}% of {amount}'**
  String notifBudgetWarnBody(int percent, String amount);

  /// No description provided for @notifBudgetOverTitle.
  ///
  /// In en, this message translates to:
  /// **'Budget exceeded: {name}'**
  String notifBudgetOverTitle(String name);

  /// No description provided for @notifBudgetOverBody.
  ///
  /// In en, this message translates to:
  /// **'Spent {spent} of {amount}'**
  String notifBudgetOverBody(String spent, String amount);

  /// No description provided for @notifDailyTitle.
  ///
  /// In en, this message translates to:
  /// **'Plan your day with DAWASA'**
  String get notifDailyTitle;

  /// No description provided for @notifDailyBody.
  ///
  /// In en, this message translates to:
  /// **'Review today\'s tasks and record your spending.'**
  String get notifDailyBody;

  /// No description provided for @notifWhenToday.
  ///
  /// In en, this message translates to:
  /// **'today'**
  String get notifWhenToday;

  /// No description provided for @notifWhenTomorrow.
  ///
  /// In en, this message translates to:
  /// **'tomorrow'**
  String get notifWhenTomorrow;

  /// No description provided for @notifWhenOn.
  ///
  /// In en, this message translates to:
  /// **'on {date}'**
  String notifWhenOn(String date);

  /// No description provided for @notifWhenAt.
  ///
  /// In en, this message translates to:
  /// **'at {time}'**
  String notifWhenAt(String time);

  /// No description provided for @billLoanNote.
  ///
  /// In en, this message translates to:
  /// **'Loan instalments are mostly principal, which is not spending. Record the repayment in Loans so what you owe goes down correctly.'**
  String get billLoanNote;

  /// No description provided for @savingsAdd.
  ///
  /// In en, this message translates to:
  /// **'New goal'**
  String get savingsAdd;

  /// No description provided for @savingsEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit goal'**
  String get savingsEdit;

  /// No description provided for @savingsName.
  ///
  /// In en, this message translates to:
  /// **'Goal name'**
  String get savingsName;

  /// No description provided for @savingsNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. New phone, Emergency fund'**
  String get savingsNameHint;

  /// No description provided for @savingsTarget.
  ///
  /// In en, this message translates to:
  /// **'Target amount'**
  String get savingsTarget;

  /// No description provided for @savingsTargetDate.
  ///
  /// In en, this message translates to:
  /// **'Target date'**
  String get savingsTargetDate;

  /// No description provided for @savingsLinkedAccount.
  ///
  /// In en, this message translates to:
  /// **'Kept in account'**
  String get savingsLinkedAccount;

  /// No description provided for @savingsLinkedAccountHelp.
  ///
  /// In en, this message translates to:
  /// **'If you choose a savings account, adding money moves it there as a transfer. It is never counted as spending.'**
  String get savingsLinkedAccountHelp;

  /// No description provided for @savingsNoLinkedAccount.
  ///
  /// In en, this message translates to:
  /// **'Just track it (no account)'**
  String get savingsNoLinkedAccount;

  /// No description provided for @savingsSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get savingsSaved;

  /// No description provided for @savingsToGo.
  ///
  /// In en, this message translates to:
  /// **'To go'**
  String get savingsToGo;

  /// No description provided for @savingsReached.
  ///
  /// In en, this message translates to:
  /// **'Goal reached!'**
  String get savingsReached;

  /// No description provided for @savingsDeposit.
  ///
  /// In en, this message translates to:
  /// **'Add money'**
  String get savingsDeposit;

  /// No description provided for @savingsWithdraw.
  ///
  /// In en, this message translates to:
  /// **'Withdraw'**
  String get savingsWithdraw;

  /// No description provided for @savingsFromAccount.
  ///
  /// In en, this message translates to:
  /// **'Take money from'**
  String get savingsFromAccount;

  /// No description provided for @savingsToAccount.
  ///
  /// In en, this message translates to:
  /// **'Put money into'**
  String get savingsToAccount;

  /// No description provided for @savingsDepositNote.
  ///
  /// In en, this message translates to:
  /// **'The money moves from {from} to {to}. This is a transfer, not an expense.'**
  String savingsDepositNote(String from, String to);

  /// No description provided for @savingsTrackOnlyNote.
  ///
  /// In en, this message translates to:
  /// **'Your balances stay the same; the amount is set aside for this goal.'**
  String get savingsTrackOnlyNote;

  /// No description provided for @savingsWithdrawTooMuch.
  ///
  /// In en, this message translates to:
  /// **'You cannot withdraw more than is saved'**
  String get savingsWithdrawTooMuch;

  /// No description provided for @savingsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No savings goals yet. Save a little every month for something you want.'**
  String get savingsEmpty;

  /// No description provided for @savingsHistory.
  ///
  /// In en, this message translates to:
  /// **'Movements'**
  String get savingsHistory;

  /// No description provided for @savingsMonthlyNeeded.
  ///
  /// In en, this message translates to:
  /// **'Save {amount} a month to reach it on time'**
  String savingsMonthlyNeeded(String amount);

  /// No description provided for @savingsRemindMonthly.
  ///
  /// In en, this message translates to:
  /// **'Remind me every month'**
  String get savingsRemindMonthly;

  /// No description provided for @savingsDeleteBody.
  ///
  /// In en, this message translates to:
  /// **'Transfers already recorded stay in your accounts.'**
  String get savingsDeleteBody;

  /// No description provided for @savingsTotalSaved.
  ///
  /// In en, this message translates to:
  /// **'Total saved'**
  String get savingsTotalSaved;

  /// No description provided for @notifSavingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Savings: {name}'**
  String notifSavingsTitle(String name);

  /// No description provided for @notifSavingsBody.
  ///
  /// In en, this message translates to:
  /// **'{amount} to go. Add a little today?'**
  String notifSavingsBody(String amount);

  /// No description provided for @loanAdd.
  ///
  /// In en, this message translates to:
  /// **'New loan'**
  String get loanAdd;

  /// No description provided for @loanEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit loan'**
  String get loanEdit;

  /// No description provided for @loanLent.
  ///
  /// In en, this message translates to:
  /// **'I lent money'**
  String get loanLent;

  /// No description provided for @loanBorrowed.
  ///
  /// In en, this message translates to:
  /// **'I borrowed money'**
  String get loanBorrowed;

  /// No description provided for @loanOwedToYou.
  ///
  /// In en, this message translates to:
  /// **'Owed to you'**
  String get loanOwedToYou;

  /// No description provided for @loanYouOwe.
  ///
  /// In en, this message translates to:
  /// **'You owe'**
  String get loanYouOwe;

  /// No description provided for @loanPerson.
  ///
  /// In en, this message translates to:
  /// **'Person or institution'**
  String get loanPerson;

  /// No description provided for @loanPrincipal.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get loanPrincipal;

  /// No description provided for @loanInterestRate.
  ///
  /// In en, this message translates to:
  /// **'Interest rate % per year (optional)'**
  String get loanInterestRate;

  /// No description provided for @loanStartDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get loanStartDate;

  /// No description provided for @loanDueDate.
  ///
  /// In en, this message translates to:
  /// **'Due date (optional)'**
  String get loanDueDate;

  /// No description provided for @loanRecordMovement.
  ///
  /// In en, this message translates to:
  /// **'Record the money movement in an account'**
  String get loanRecordMovement;

  /// No description provided for @loanRecordMovementHelp.
  ///
  /// In en, this message translates to:
  /// **'Updates the account balance. Loan money is never counted as income or spending.'**
  String get loanRecordMovementHelp;

  /// No description provided for @loanOutstanding.
  ///
  /// In en, this message translates to:
  /// **'Outstanding'**
  String get loanOutstanding;

  /// No description provided for @loanRepaid.
  ///
  /// In en, this message translates to:
  /// **'Repaid'**
  String get loanRepaid;

  /// No description provided for @loanRecordRepayment.
  ///
  /// In en, this message translates to:
  /// **'Record repayment'**
  String get loanRecordRepayment;

  /// No description provided for @loanRepaymentPrincipal.
  ///
  /// In en, this message translates to:
  /// **'Towards the loan amount'**
  String get loanRepaymentPrincipal;

  /// No description provided for @loanRepaymentInterest.
  ///
  /// In en, this message translates to:
  /// **'Interest (optional)'**
  String get loanRepaymentInterest;

  /// No description provided for @loanRepaymentInterestHelp.
  ///
  /// In en, this message translates to:
  /// **'Interest received is income; interest paid is an expense.'**
  String get loanRepaymentInterestHelp;

  /// No description provided for @loanRepaymentTooMuch.
  ///
  /// In en, this message translates to:
  /// **'This is more than the outstanding amount'**
  String get loanRepaymentTooMuch;

  /// No description provided for @loanSettle.
  ///
  /// In en, this message translates to:
  /// **'Mark as settled'**
  String get loanSettle;

  /// No description provided for @loanSettleBody.
  ///
  /// In en, this message translates to:
  /// **'The loan is closed. Any amount still outstanding is written off and no longer counted.'**
  String get loanSettleBody;

  /// No description provided for @loanReopen.
  ///
  /// In en, this message translates to:
  /// **'Reopen loan'**
  String get loanReopen;

  /// No description provided for @loanSettled.
  ///
  /// In en, this message translates to:
  /// **'Settled'**
  String get loanSettled;

  /// No description provided for @loanActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get loanActive;

  /// No description provided for @loanEmpty.
  ///
  /// In en, this message translates to:
  /// **'No loans. Keep track of money you lent to or borrowed from others.'**
  String get loanEmpty;

  /// No description provided for @loanHistory.
  ///
  /// In en, this message translates to:
  /// **'Repayments'**
  String get loanHistory;

  /// No description provided for @loanNoRepayments.
  ///
  /// In en, this message translates to:
  /// **'No repayments yet'**
  String get loanNoRepayments;

  /// No description provided for @loanDeleteBody.
  ///
  /// In en, this message translates to:
  /// **'Money movements recorded for this loan are deleted too, and balances are recalculated.'**
  String get loanDeleteBody;

  /// No description provided for @loanDueOn.
  ///
  /// In en, this message translates to:
  /// **'Due {date}'**
  String loanDueOn(String date);

  /// No description provided for @loanNotifTitleLent.
  ///
  /// In en, this message translates to:
  /// **'{name} should repay you'**
  String loanNotifTitleLent(String name);

  /// No description provided for @loanNotifTitleBorrowed.
  ///
  /// In en, this message translates to:
  /// **'Repay {name}'**
  String loanNotifTitleBorrowed(String name);

  /// No description provided for @loanNotifBody.
  ///
  /// In en, this message translates to:
  /// **'{amount} outstanding, due {when}'**
  String loanNotifBody(String amount, String when);

  /// No description provided for @loanTotalOwedToYou.
  ///
  /// In en, this message translates to:
  /// **'Total owed to you'**
  String get loanTotalOwedToYou;

  /// No description provided for @loanTotalYouOwe.
  ///
  /// In en, this message translates to:
  /// **'Total you owe'**
  String get loanTotalYouOwe;

  /// No description provided for @habitAdd.
  ///
  /// In en, this message translates to:
  /// **'New habit'**
  String get habitAdd;

  /// No description provided for @habitEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit habit'**
  String get habitEdit;

  /// No description provided for @habitName.
  ///
  /// In en, this message translates to:
  /// **'Habit'**
  String get habitName;

  /// No description provided for @habitNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Drink water, Read, Exercise'**
  String get habitNameHint;

  /// No description provided for @habitFrequency.
  ///
  /// In en, this message translates to:
  /// **'Goal'**
  String get habitFrequency;

  /// No description provided for @habitDaily.
  ///
  /// In en, this message translates to:
  /// **'Every day'**
  String get habitDaily;

  /// No description provided for @habitWeekly.
  ///
  /// In en, this message translates to:
  /// **'Every week'**
  String get habitWeekly;

  /// No description provided for @habitTimesPerDay.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Once a day} other{{count} times a day}}'**
  String habitTimesPerDay(int count);

  /// No description provided for @habitTimesPerWeek.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Once a week} other{{count} times a week}}'**
  String habitTimesPerWeek(int count);

  /// No description provided for @habitReminder.
  ///
  /// In en, this message translates to:
  /// **'Daily reminder'**
  String get habitReminder;

  /// No description provided for @habitStreak.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No streak yet} =1{1 day streak} other{{count} day streak}}'**
  String habitStreak(int count);

  /// No description provided for @habitWeekStreak.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No streak yet} =1{1 week streak} other{{count} week streak}}'**
  String habitWeekStreak(int count);

  /// No description provided for @habitBestStreak.
  ///
  /// In en, this message translates to:
  /// **'Best: {count}'**
  String habitBestStreak(int count);

  /// No description provided for @habitProgressToday.
  ///
  /// In en, this message translates to:
  /// **'{done} of {target} today'**
  String habitProgressToday(int done, int target);

  /// No description provided for @habitProgressWeek.
  ///
  /// In en, this message translates to:
  /// **'{done} of {target} this week'**
  String habitProgressWeek(int done, int target);

  /// No description provided for @habitMarkDone.
  ///
  /// In en, this message translates to:
  /// **'Mark done'**
  String get habitMarkDone;

  /// No description provided for @habitUndo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get habitUndo;

  /// No description provided for @habitCalendar.
  ///
  /// In en, this message translates to:
  /// **'Last 5 weeks'**
  String get habitCalendar;

  /// No description provided for @habitEmpty.
  ///
  /// In en, this message translates to:
  /// **'Build good habits one day at a time. Habits never affect your money reports.'**
  String get habitEmpty;

  /// No description provided for @habitNotifTitle.
  ///
  /// In en, this message translates to:
  /// **'Time for: {name}'**
  String habitNotifTitle(String name);

  /// No description provided for @habitNotifBody.
  ///
  /// In en, this message translates to:
  /// **'Keep your streak going!'**
  String get habitNotifBody;

  /// No description provided for @habitDeleteBody.
  ///
  /// In en, this message translates to:
  /// **'The habit and its history will be deleted.'**
  String get habitDeleteBody;

  /// No description provided for @eventAdd.
  ///
  /// In en, this message translates to:
  /// **'New date'**
  String get eventAdd;

  /// No description provided for @eventEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit date'**
  String get eventEdit;

  /// No description provided for @eventTitle.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get eventTitle;

  /// No description provided for @eventTitleHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Amma\'s birthday'**
  String get eventTitleHint;

  /// No description provided for @eventBirthday.
  ///
  /// In en, this message translates to:
  /// **'Birthday'**
  String get eventBirthday;

  /// No description provided for @eventAnniversary.
  ///
  /// In en, this message translates to:
  /// **'Anniversary'**
  String get eventAnniversary;

  /// No description provided for @eventAppointment.
  ///
  /// In en, this message translates to:
  /// **'Appointment'**
  String get eventAppointment;

  /// No description provided for @eventExam.
  ///
  /// In en, this message translates to:
  /// **'Examination'**
  String get eventExam;

  /// No description provided for @eventOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get eventOther;

  /// No description provided for @eventDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get eventDate;

  /// No description provided for @eventRemind.
  ///
  /// In en, this message translates to:
  /// **'Remind me'**
  String get eventRemind;

  /// No description provided for @eventBudget.
  ///
  /// In en, this message translates to:
  /// **'Budget for this event (optional)'**
  String get eventBudget;

  /// No description provided for @eventBudgetHelp.
  ///
  /// In en, this message translates to:
  /// **'A plan only — it does not change your balances.'**
  String get eventBudgetHelp;

  /// No description provided for @eventEmpty.
  ///
  /// In en, this message translates to:
  /// **'Never forget a birthday, anniversary or exam again.'**
  String get eventEmpty;

  /// No description provided for @eventUpcoming.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get eventUpcoming;

  /// No description provided for @eventPast.
  ///
  /// In en, this message translates to:
  /// **'Past'**
  String get eventPast;

  /// No description provided for @eventInDays.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Today} =1{Tomorrow} other{In {count} days}}'**
  String eventInDays(int count);

  /// No description provided for @eventTurns.
  ///
  /// In en, this message translates to:
  /// **'Turns {age}'**
  String eventTurns(int age);

  /// No description provided for @eventYears.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 year} other{{count} years}}'**
  String eventYears(int count);

  /// No description provided for @eventCalendar.
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get eventCalendar;

  /// No description provided for @eventList.
  ///
  /// In en, this message translates to:
  /// **'List'**
  String get eventList;

  /// No description provided for @eventNoneThisDay.
  ///
  /// In en, this message translates to:
  /// **'Nothing on this day'**
  String get eventNoneThisDay;

  /// No description provided for @eventNotifTitle.
  ///
  /// In en, this message translates to:
  /// **'{title}'**
  String eventNotifTitle(String title);

  /// No description provided for @eventNotifBody.
  ///
  /// In en, this message translates to:
  /// **'{when}'**
  String eventNotifBody(String when);

  /// No description provided for @reportsTitle.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get reportsTitle;

  /// No description provided for @reportTotalIncome.
  ///
  /// In en, this message translates to:
  /// **'Total income'**
  String get reportTotalIncome;

  /// No description provided for @reportTotalExpenses.
  ///
  /// In en, this message translates to:
  /// **'Total expenses'**
  String get reportTotalExpenses;

  /// No description provided for @reportNetCashFlow.
  ///
  /// In en, this message translates to:
  /// **'Net cash flow'**
  String get reportNetCashFlow;

  /// No description provided for @reportNetHelp.
  ///
  /// In en, this message translates to:
  /// **'Income minus expenses in this period'**
  String get reportNetHelp;

  /// No description provided for @reportOtherMovements.
  ///
  /// In en, this message translates to:
  /// **'Other money movements'**
  String get reportOtherMovements;

  /// No description provided for @reportOtherMovementsHelp.
  ///
  /// In en, this message translates to:
  /// **'Loans, repayments, reimbursements and balance corrections. Not income or spending.'**
  String get reportOtherMovementsHelp;

  /// No description provided for @reportMoneyIn.
  ///
  /// In en, this message translates to:
  /// **'Money in'**
  String get reportMoneyIn;

  /// No description provided for @reportMoneyOut.
  ///
  /// In en, this message translates to:
  /// **'Money out'**
  String get reportMoneyOut;

  /// No description provided for @reportIncomeVsExpenses.
  ///
  /// In en, this message translates to:
  /// **'Income vs expenses'**
  String get reportIncomeVsExpenses;

  /// No description provided for @reportExpensesByCategory.
  ///
  /// In en, this message translates to:
  /// **'Expenses by category'**
  String get reportExpensesByCategory;

  /// No description provided for @reportIncomeByCategory.
  ///
  /// In en, this message translates to:
  /// **'Income by source'**
  String get reportIncomeByCategory;

  /// No description provided for @reportDailyTrend.
  ///
  /// In en, this message translates to:
  /// **'Daily spending'**
  String get reportDailyTrend;

  /// No description provided for @reportMonthlyTrend.
  ///
  /// In en, this message translates to:
  /// **'Monthly spending (last 6 months)'**
  String get reportMonthlyTrend;

  /// No description provided for @reportAccountBalances.
  ///
  /// In en, this message translates to:
  /// **'Account balances (now)'**
  String get reportAccountBalances;

  /// No description provided for @reportLoanBalances.
  ///
  /// In en, this message translates to:
  /// **'Loan balances (now)'**
  String get reportLoanBalances;

  /// No description provided for @reportSavings.
  ///
  /// In en, this message translates to:
  /// **'Savings'**
  String get reportSavings;

  /// No description provided for @reportSavingsTransfers.
  ///
  /// In en, this message translates to:
  /// **'Moved to savings in this period'**
  String get reportSavingsTransfers;

  /// No description provided for @reportNoData.
  ///
  /// In en, this message translates to:
  /// **'No transactions in this period'**
  String get reportNoData;

  /// No description provided for @reportChartIncomeExpense.
  ///
  /// In en, this message translates to:
  /// **'Income {income}, expenses {expenses}'**
  String reportChartIncomeExpense(String income, String expenses);

  /// No description provided for @reportShare.
  ///
  /// In en, this message translates to:
  /// **'Share summary'**
  String get reportShare;

  /// No description provided for @reportExportCsv.
  ///
  /// In en, this message translates to:
  /// **'Export CSV'**
  String get reportExportCsv;

  /// No description provided for @reportShareTitle.
  ///
  /// In en, this message translates to:
  /// **'Share report'**
  String get reportShareTitle;

  /// No description provided for @reportShareIncludeCategories.
  ///
  /// In en, this message translates to:
  /// **'Include category totals'**
  String get reportShareIncludeCategories;

  /// No description provided for @reportShareIncludeBalances.
  ///
  /// In en, this message translates to:
  /// **'Include account balances'**
  String get reportShareIncludeBalances;

  /// No description provided for @reportSharePrivacy.
  ///
  /// In en, this message translates to:
  /// **'Only what you select below is shared. Nothing is sent anywhere unless you choose an app to share with.'**
  String get reportSharePrivacy;

  /// No description provided for @reportPreview.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get reportPreview;

  /// No description provided for @exportTitle.
  ///
  /// In en, this message translates to:
  /// **'Export transactions'**
  String get exportTitle;

  /// No description provided for @exportIncludeNotes.
  ///
  /// In en, this message translates to:
  /// **'Include descriptions and notes'**
  String get exportIncludeNotes;

  /// No description provided for @exportIncludeAccounts.
  ///
  /// In en, this message translates to:
  /// **'Include account names'**
  String get exportIncludeAccounts;

  /// No description provided for @exportDone.
  ///
  /// In en, this message translates to:
  /// **'CSV file ready'**
  String get exportDone;

  /// No description provided for @exportNothing.
  ///
  /// In en, this message translates to:
  /// **'No transactions to export in this period'**
  String get exportNothing;

  /// No description provided for @exportPrivacyNote.
  ///
  /// In en, this message translates to:
  /// **'A CSV file is not encrypted. Anyone who gets the file can read it.'**
  String get exportPrivacyNote;

  /// No description provided for @csvDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get csvDate;

  /// No description provided for @csvTime.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get csvTime;

  /// No description provided for @csvType.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get csvType;

  /// No description provided for @csvCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get csvCategory;

  /// No description provided for @csvAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get csvAccount;

  /// No description provided for @csvToAccount.
  ///
  /// In en, this message translates to:
  /// **'To account'**
  String get csvToAccount;

  /// No description provided for @csvAmount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get csvAmount;

  /// No description provided for @csvCurrency.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get csvCurrency;

  /// No description provided for @csvDescription.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get csvDescription;

  /// No description provided for @csvNote.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get csvNote;

  /// No description provided for @csvCountsAs.
  ///
  /// In en, this message translates to:
  /// **'Counts as'**
  String get csvCountsAs;

  /// No description provided for @csvCountsIncome.
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get csvCountsIncome;

  /// No description provided for @csvCountsExpense.
  ///
  /// In en, this message translates to:
  /// **'Expense'**
  String get csvCountsExpense;

  /// No description provided for @csvCountsNeither.
  ///
  /// In en, this message translates to:
  /// **'Not income or expense'**
  String get csvCountsNeither;

  /// No description provided for @homeSeeSavings.
  ///
  /// In en, this message translates to:
  /// **'See goals'**
  String get homeSeeSavings;

  /// No description provided for @securityPinDigitsEntered.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No digits entered} =1{1 digit entered} other{{count} digits entered}}'**
  String securityPinDigitsEntered(int count);

  /// No description provided for @securityPinDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete last digit'**
  String get securityPinDelete;

  /// No description provided for @securityPausedFor.
  ///
  /// In en, this message translates to:
  /// **'Too many wrong PINs. Try again in {time}.'**
  String securityPausedFor(String time);

  /// No description provided for @securityEnterCurrentPin.
  ///
  /// In en, this message translates to:
  /// **'Enter your current PIN'**
  String get securityEnterCurrentPin;

  /// No description provided for @securityPinTooSimple.
  ///
  /// In en, this message translates to:
  /// **'That PIN is too easy to guess. Avoid repeated or consecutive digits.'**
  String get securityPinTooSimple;

  /// No description provided for @securityLockAfterSeconds.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{After 1 second} other{After {count} seconds}}'**
  String securityLockAfterSeconds(int count);

  /// No description provided for @securityLockNote.
  ///
  /// In en, this message translates to:
  /// **'The PIN lock keeps other people who use your phone out of DAWASA. If you forget the PIN, it cannot be recovered.'**
  String get securityLockNote;

  /// No description provided for @securityBiometricFailed.
  ///
  /// In en, this message translates to:
  /// **'Fingerprint or face was not confirmed'**
  String get securityBiometricFailed;

  /// No description provided for @deleteAllBackupFirst.
  ///
  /// In en, this message translates to:
  /// **'Tip: create a backup first if you may need this data again.'**
  String get deleteAllBackupFirst;

  /// No description provided for @deleteAllTypeWord.
  ///
  /// In en, this message translates to:
  /// **'Type {word} to confirm'**
  String deleteAllTypeWord(String word);

  /// No description provided for @deleteAllAction.
  ///
  /// In en, this message translates to:
  /// **'Delete everything'**
  String get deleteAllAction;

  /// No description provided for @backupShowPassword.
  ///
  /// In en, this message translates to:
  /// **'Show password'**
  String get backupShowPassword;

  /// No description provided for @backupHidePassword.
  ///
  /// In en, this message translates to:
  /// **'Hide password'**
  String get backupHidePassword;

  /// No description provided for @backupFailed.
  ///
  /// In en, this message translates to:
  /// **'The backup could not be created. Please try again.'**
  String get backupFailed;

  /// No description provided for @backupKeepSafe.
  ///
  /// In en, this message translates to:
  /// **'Anyone who has both the backup file and its password can read your records, so keep the password private. If you forget it, nobody can open the backup — not even the developer.'**
  String get backupKeepSafe;

  /// No description provided for @backupStoredHint.
  ///
  /// In en, this message translates to:
  /// **'Saved. Also keep a copy somewhere outside this phone.'**
  String get backupStoredHint;

  /// No description provided for @backupNotStoredYet.
  ///
  /// In en, this message translates to:
  /// **'Now save the file to a folder or send it somewhere safe. It is not stored anywhere yet.'**
  String get backupNotStoredYet;

  /// No description provided for @settingsRestoreDesc.
  ///
  /// In en, this message translates to:
  /// **'Replace the data on this phone with a backup file'**
  String get settingsRestoreDesc;

  /// No description provided for @restoreIntro.
  ///
  /// In en, this message translates to:
  /// **'Choose a DAWASA backup file (.dawasa). It is checked completely before anything on this phone is changed.'**
  String get restoreIntro;

  /// No description provided for @restoreCheck.
  ///
  /// In en, this message translates to:
  /// **'Check backup'**
  String get restoreCheck;

  /// No description provided for @restoreChooseOther.
  ///
  /// In en, this message translates to:
  /// **'Choose a different file'**
  String get restoreChooseOther;

  /// No description provided for @restoreVerified.
  ///
  /// In en, this message translates to:
  /// **'The backup is valid and complete'**
  String get restoreVerified;

  /// No description provided for @restoreCountAccounts.
  ///
  /// In en, this message translates to:
  /// **'Accounts'**
  String get restoreCountAccounts;

  /// No description provided for @restoreCountTransactions.
  ///
  /// In en, this message translates to:
  /// **'Transactions'**
  String get restoreCountTransactions;

  /// No description provided for @restoreCountBudgets.
  ///
  /// In en, this message translates to:
  /// **'Budgets'**
  String get restoreCountBudgets;

  /// No description provided for @restoreCountBills.
  ///
  /// In en, this message translates to:
  /// **'Bills'**
  String get restoreCountBills;

  /// No description provided for @restoreCountTasks.
  ///
  /// In en, this message translates to:
  /// **'Tasks'**
  String get restoreCountTasks;

  /// No description provided for @restoreCountSavings.
  ///
  /// In en, this message translates to:
  /// **'Savings goals'**
  String get restoreCountSavings;

  /// No description provided for @restoreCountLoans.
  ///
  /// In en, this message translates to:
  /// **'Loans'**
  String get restoreCountLoans;

  /// No description provided for @restoreCountPhotos.
  ///
  /// In en, this message translates to:
  /// **'Receipt photos'**
  String get restoreCountPhotos;

  /// No description provided for @restorePreviousData.
  ///
  /// In en, this message translates to:
  /// **'Data from before the last restore'**
  String get restorePreviousData;

  /// No description provided for @restorePreviousDataDesc.
  ///
  /// In en, this message translates to:
  /// **'Kept on this phone since {date}'**
  String restorePreviousDataDesc(String date);

  /// No description provided for @restoreBringBack.
  ///
  /// In en, this message translates to:
  /// **'Bring back previous data'**
  String get restoreBringBack;

  /// No description provided for @restoreBringBackBody.
  ///
  /// In en, this message translates to:
  /// **'Your current data will be replaced by the data you had before the last restore.'**
  String get restoreBringBackBody;

  /// No description provided for @restoreDeleteSafetyCopy.
  ///
  /// In en, this message translates to:
  /// **'Delete this copy'**
  String get restoreDeleteSafetyCopy;

  /// No description provided for @restoreCompleted.
  ///
  /// In en, this message translates to:
  /// **'Backup restored'**
  String get restoreCompleted;

  /// No description provided for @restoreFailedKept.
  ///
  /// In en, this message translates to:
  /// **'The backup could not be restored. Your previous data was kept.'**
  String get restoreFailedKept;

  /// No description provided for @onbRestoreBackup.
  ///
  /// In en, this message translates to:
  /// **'Restore from a backup'**
  String get onbRestoreBackup;

  /// No description provided for @commonSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get commonSaved;

  /// No description provided for @updateDisabledStore.
  ///
  /// In en, this message translates to:
  /// **'This copy of DAWASA is updated through the store it was installed from.'**
  String get updateDisabledStore;

  /// No description provided for @updateNotConfiguredBody.
  ///
  /// In en, this message translates to:
  /// **'To receive updates inside the app, enter the HTTPS address of the DAWASA update folder under \"Update server\".'**
  String get updateNotConfiguredBody;

  /// No description provided for @updateDownloadPaused.
  ///
  /// In en, this message translates to:
  /// **'Download paused. It continues where it stopped.'**
  String get updateDownloadPaused;

  /// No description provided for @updateResume.
  ///
  /// In en, this message translates to:
  /// **'Continue download'**
  String get updateResume;

  /// No description provided for @updateStorageFailed.
  ///
  /// In en, this message translates to:
  /// **'There is not enough free space to download the update.'**
  String get updateStorageFailed;

  /// No description provided for @updateInstallFailed.
  ///
  /// In en, this message translates to:
  /// **'Android could not install the update. Please try again.'**
  String get updateInstallFailed;

  /// No description provided for @updateProgressBytes.
  ///
  /// In en, this message translates to:
  /// **'{received} of {total}'**
  String updateProgressBytes(String received, String total);

  /// No description provided for @updateVerifiedNote.
  ///
  /// In en, this message translates to:
  /// **'The file matches its published SHA-256 fingerprint and is signed like the installed app.'**
  String get updateVerifiedNote;

  /// No description provided for @updateInstallHint.
  ///
  /// In en, this message translates to:
  /// **'Android will ask you to confirm the update.'**
  String get updateInstallHint;

  /// No description provided for @updateNeverChecked.
  ///
  /// In en, this message translates to:
  /// **'Not checked yet'**
  String get updateNeverChecked;

  /// No description provided for @updateInstalledVersion.
  ///
  /// In en, this message translates to:
  /// **'Installed: {version}'**
  String updateInstalledVersion(String version);

  /// No description provided for @updatePrivacyNote.
  ///
  /// In en, this message translates to:
  /// **'Checking for updates only downloads a small description file from the update server. No personal or financial information is sent.'**
  String get updatePrivacyNote;

  /// No description provided for @backupReminderTitle.
  ///
  /// In en, this message translates to:
  /// **'Keep a backup of your records'**
  String get backupReminderTitle;

  /// No description provided for @backupReminderOldTitle.
  ///
  /// In en, this message translates to:
  /// **'Your last backup is more than a month old'**
  String get backupReminderOldTitle;

  /// No description provided for @backupReminderBody.
  ///
  /// In en, this message translates to:
  /// **'Your data is stored only on this phone. If the phone is lost or reset, a backup file is the only way to get it back.'**
  String get backupReminderBody;

  /// No description provided for @backupReminderLater.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get backupReminderLater;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'si'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'si':
      return AppLocalizationsSi();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}

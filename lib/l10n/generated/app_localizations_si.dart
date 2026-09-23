// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Sinhala Sinhalese (`si`).
class AppLocalizationsSi extends AppLocalizations {
  AppLocalizationsSi([String locale = 'si']) : super(locale);

  @override
  String get appName => 'DAWASA';

  @override
  String get appTitle => 'DAWASA — දෛනික ජීවිත කළමනාකරු';

  @override
  String get appTagline => 'ඔබේ මුදල්. ඔබේ සැලසුම්. ඔබේ දවස.';

  @override
  String get navHome => 'මුල් පිටුව';

  @override
  String get navMoney => 'මුදල්';

  @override
  String get navPlanner => 'සැලසුම්';

  @override
  String get navReports => 'වාර්තා';

  @override
  String get navSettings => 'සැකසීම්';

  @override
  String get actionSave => 'සුරකින්න';

  @override
  String get actionCancel => 'අවලංගු කරන්න';

  @override
  String get actionDelete => 'මකන්න';

  @override
  String get actionEdit => 'සංස්කරණය';

  @override
  String get actionAdd => 'එක් කරන්න';

  @override
  String get actionDone => 'හරි';

  @override
  String get actionNext => 'ඊළඟ';

  @override
  String get actionBack => 'ආපසු';

  @override
  String get actionSkip => 'මඟ හරින්න';

  @override
  String get actionClose => 'වසන්න';

  @override
  String get actionConfirm => 'තහවුරු කරන්න';

  @override
  String get actionRetry => 'නැවත උත්සාහ කරන්න';

  @override
  String get actionSearch => 'සොයන්න';

  @override
  String get actionFilter => 'පෙරහන';

  @override
  String get actionClear => 'ඉවත් කරන්න';

  @override
  String get actionDuplicate => 'පිටපත් කරන්න';

  @override
  String get actionShare => 'බෙදාගන්න';

  @override
  String get actionExport => 'අපනයනය';

  @override
  String get actionChange => 'වෙනස් කරන්න';

  @override
  String get actionUndo => 'අහෝසි කරන්න';

  @override
  String get actionArchive => 'සංරක්ෂණය කරන්න';

  @override
  String get actionUnarchive => 'සංරක්ෂණයෙන් ඉවත් කරන්න';

  @override
  String get actionGetStarted => 'ආරම්භ කරන්න';

  @override
  String get actionContinue => 'ඉදිරියට';

  @override
  String get actionSeeAll => 'සියල්ල බලන්න';

  @override
  String get actionShow => 'පෙන්වන්න';

  @override
  String get actionHide => 'සඟවන්න';

  @override
  String get actionSelect => 'තෝරන්න';

  @override
  String get actionAllow => 'ඉඩ දෙන්න';

  @override
  String get actionNotNow => 'දැන් නොවේ';

  @override
  String get actionOpenSettings => 'සැකසීම් විවෘත කරන්න';

  @override
  String get commonAll => 'සියල්ල';

  @override
  String get commonNone => 'කිසිවක් නැත';

  @override
  String get commonOptional => 'අත්‍යවශ්‍ය නැත';

  @override
  String get commonAmount => 'මුදල';

  @override
  String get commonDate => 'දිනය';

  @override
  String get commonTime => 'වේලාව';

  @override
  String get commonNote => 'සටහන';

  @override
  String get commonDescription => 'විස්තරය';

  @override
  String get commonCategory => 'වර්ගය';

  @override
  String get commonAccount => 'ගිණුම';

  @override
  String get commonName => 'නම';

  @override
  String get commonToday => 'අද';

  @override
  String get commonYesterday => 'ඊයේ';

  @override
  String get commonTomorrow => 'හෙට';

  @override
  String get commonYes => 'ඔව්';

  @override
  String get commonNo => 'නැත';

  @override
  String get commonOk => 'හරි';

  @override
  String get commonTotal => 'එකතුව';

  @override
  String get commonStartDate => 'ආරම්භක දිනය';

  @override
  String get commonEndDate => 'අවසාන දිනය';

  @override
  String get commonNoDate => 'දිනයක් නැත';

  @override
  String get commonNoTime => 'වේලාවක් නැත';

  @override
  String get commonDetails => 'විස්තර';

  @override
  String get commonHistory => 'ඉතිහාසය';

  @override
  String get commonActive => 'සක්‍රිය';

  @override
  String get commonArchived => 'සංරක්ෂිත';

  @override
  String get commonProgress => 'ප්‍රගතිය';

  @override
  String get commonRemaining => 'ඉතිරි';

  @override
  String get commonOverdue => 'කල් ඉකුත් වී ඇත';

  @override
  String get commonCompleted => 'සම්පූර්ණයි';

  @override
  String get commonPending => 'ඉතිරිව ඇත';

  @override
  String get commonUnknown => 'නොදනී';

  @override
  String get commonLoading => 'පූරණය වෙමින්…';

  @override
  String get commonNotSet => 'සකසා නැත';

  @override
  String get commonCurrency => 'මුදල් ඒකකය';

  @override
  String get commonReminder => 'සිහිකැඳවීම';

  @override
  String get commonRepeat => 'නැවත නැවත';

  @override
  String commonPercentUsed(int percent) {
    return '$percent% භාවිත කර ඇත';
  }

  @override
  String commonOfAmount(String amount, String total) {
    return '$total න් $amount';
  }

  @override
  String commonDaysLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'තව දින $countයි',
      one: 'තව දින 1යි',
      zero: 'අද නියමිතයි',
    );
    return '$_temp0';
  }

  @override
  String commonDaysOverdue(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'දින $countක් ප්‍රමාදයි',
      one: 'දින 1ක් ප්‍රමාදයි',
    );
    return '$_temp0';
  }

  @override
  String commonItemsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'අයිතම $countයි',
      one: 'අයිතම 1යි',
      zero: 'අයිතම නැත',
    );
    return '$_temp0';
  }

  @override
  String get validationRequired => 'මෙම ක්ෂේත්‍රය අවශ්‍යයි';

  @override
  String get validationAmountInvalid => 'වලංගු මුදලක් ඇතුළත් කරන්න';

  @override
  String get validationAmountPositive => 'මුදල බිංදුවට වඩා වැඩි විය යුතුය';

  @override
  String get validationAmountTooLarge => 'මුදල ඉතා විශාලයි';

  @override
  String get validationTooManyDecimals => 'දශම ස්ථාන වැඩියි';

  @override
  String get validationNameTooLong => 'නම දිග වැඩියි';

  @override
  String get validationNumberInvalid => 'වලංගු අංකයක් ඇතුළත් කරන්න';

  @override
  String get validationEndBeforeStart =>
      'අවසාන දිනය ආරම්භක දිනයට පෙර විය නොහැක';

  @override
  String get feedbackSaved => 'සුරකින ලදී';

  @override
  String get feedbackDeleted => 'මකා දමන ලදී';

  @override
  String get feedbackError => 'යම් දෝෂයක් සිදු විය. කරුණාකර නැවත උත්සාහ කරන්න.';

  @override
  String get feedbackAlreadySaved => 'දැනටමත් සුරකින ලදී';

  @override
  String get confirmDeleteTitle => 'මකන්නද?';

  @override
  String get confirmDeleteMessage => 'මෙය ආපසු හැරවිය නොහැක.';

  @override
  String get emptyGeneric => 'තවම කිසිවක් නැත';

  @override
  String get errorLoading => 'දත්ත පූරණය කළ නොහැකි විය';

  @override
  String get greetingMorning => 'සුබ උදෑසනක්';

  @override
  String get greetingAfternoon => 'සුබ දහවලක්';

  @override
  String get greetingEvening => 'සුබ සන්ධ්‍යාවක්';

  @override
  String greetingWithName(String greeting, String name) {
    return '$greeting, $name';
  }

  @override
  String get weekdayMon => 'සඳුදා';

  @override
  String get weekdayTue => 'අඟහරුවාදා';

  @override
  String get weekdayWed => 'බදාදා';

  @override
  String get weekdayThu => 'බ්‍රහස්පතින්දා';

  @override
  String get weekdayFri => 'සිකුරාදා';

  @override
  String get weekdaySat => 'සෙනසුරාදා';

  @override
  String get weekdaySun => 'ඉරිදා';

  @override
  String get repeatNever => 'නැවත නොවේ';

  @override
  String get repeatDaily => 'දිනපතා';

  @override
  String get repeatWeekly => 'සතිපතා';

  @override
  String get repeatMonthly => 'මාසිකව';

  @override
  String get repeatYearly => 'වාර්ෂිකව';

  @override
  String get repeatCustom => 'අභිරුචි';

  @override
  String get repeatEvery => 'නැවත වරක්';

  @override
  String get repeatUnitDays => 'දින';

  @override
  String get repeatUnitWeeks => 'සති';

  @override
  String get repeatUnitMonths => 'මාස';

  @override
  String get repeatUnitYears => 'වසර';

  @override
  String repeatEveryDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'සෑම දින $countකට වරක්',
      one: 'සෑම දිනකම',
    );
    return '$_temp0';
  }

  @override
  String repeatEveryWeeks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'සෑම සති $countකට වරක්',
      one: 'සෑම සතියකම',
    );
    return '$_temp0';
  }

  @override
  String repeatEveryMonths(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'සෑම මාස $countකට වරක්',
      one: 'සෑම මාසයකම',
    );
    return '$_temp0';
  }

  @override
  String repeatEveryYears(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'සෑම වසර $countකට වරක්',
      one: 'සෑම වසරකම',
    );
    return '$_temp0';
  }

  @override
  String repeatUntilDate(String date) {
    return '$date දක්වා';
  }

  @override
  String repeatTimesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'වාර $countක්',
      one: 'එක් වරක්',
    );
    return '$_temp0';
  }

  @override
  String get repeatOnDays => 'දින';

  @override
  String get repeatEnds => 'අවසන් වන්නේ';

  @override
  String get repeatEndsNever => 'කිසිදා නැත';

  @override
  String get repeatEndsOnDate => 'දිනයක';

  @override
  String get repeatEndsAfter => 'වාර ගණනකට පසු';

  @override
  String get repeatOccurrences => 'වාර ගණන';

  @override
  String get rangeToday => 'අද';

  @override
  String get rangeYesterday => 'ඊයේ';

  @override
  String get rangeLast7Days => 'පසුගිය දින 7';

  @override
  String get rangeThisMonth => 'මෙම මාසය';

  @override
  String get rangeLastMonth => 'පසුගිය මාසය';

  @override
  String get rangeCustom => 'අභිරුචි කාල පරාසය';

  @override
  String get onbWelcomeTitle => 'DAWASA වෙත සාදරයෙන් පිළිගනිමු';

  @override
  String get onbWelcomeBody =>
      'ඔබේ මුදල්, සැලසුම් සහ දෛනික ජීවිතය එකම සරල යෙදුමකින් කළමනාකරණය කරන්න.';

  @override
  String get onbPointFree => '100% නොමිලේ — දැන්වීම් නැත, දායකත්ව ගාස්තු නැත';

  @override
  String get onbPointOffline => 'අන්තර්ජාලය නොමැතිව සම්පූර්ණයෙන් ක්‍රියා කරයි';

  @override
  String get onbPointPrivate => 'ඔබේ දත්ත ඔබේ දුරකථනයේම පවතී';

  @override
  String get onbPointNoLogin => 'පිවිසීමක් හෝ ලියාපදිංචියක් අවශ්‍ය නැත';

  @override
  String get onbLanguageTitle => 'ඔබේ භාෂාව තෝරන්න';

  @override
  String get onbLanguageBody => 'මෙය පසුව සැකසීම් තුළින් වෙනස් කළ හැක.';

  @override
  String get onbCurrencyTitle => 'ඔබේ මුදල් ඒකකය තෝරන්න';

  @override
  String get onbCurrencyBody => 'සියලු මුදල් මෙම ඒකකයෙන් පෙන්වනු ඇත.';

  @override
  String get onbBalancesTitle => 'ඔබේ වත්මන් ශේෂයන්';

  @override
  String get onbBalancesBody =>
      'ඔබ සතුව දැනට ඇති මුදල් ඇතුළත් කරන්න. මෙය මඟ හැර පසුව ගිණුම් එක් කළ හැක.';

  @override
  String get onbCashBalance => 'අතැති මුදල්';

  @override
  String get onbBankBalance => 'බැංකු ශේෂය';

  @override
  String get onbWalletBalance => 'වෙනත් පසුම්බි ශේෂය';

  @override
  String get onbBudgetTitle => 'දෛනික වියදම් අයවැය';

  @override
  String get onbBudgetBody =>
      'දිනකට වියදම් කිරීමට අදහස් කරන මුදල සකසන්න. සෑම දිනකම ඉතිරි මුදල DAWASA පෙන්වයි.';

  @override
  String get onbBudgetLabel => 'දෛනික අයවැය';

  @override
  String get onbRemindersTitle => 'සිහිකැඳවීම්';

  @override
  String get onbRemindersBody =>
      'DAWASA හට කාර්යයන්, බිල්පත් සහ වැදගත් දින ගැන ඔබට මතක් කළ හැක. සිහිකැඳවීම් ඔබේ දුරකථනය තුළම සාදනු ලැබේ — අන්තර්ජාලයට කිසිවක් යවනු නොලැබේ.';

  @override
  String get onbEnableReminders => 'සිහිකැඳවීම් සක්‍රිය කරන්න';

  @override
  String get onbRemindersEnabled => 'සිහිකැඳවීම් සක්‍රියයි';

  @override
  String get onbRemindersDenied =>
      'අවසරය ලබා දුන්නේ නැත. පසුව සැකසීම් තුළින් සක්‍රිය කළ හැක.';

  @override
  String get onbFinish => 'DAWASA භාවිතය අරඹන්න';

  @override
  String onbStepOf(int step, int total) {
    return 'පියවර $total න් $step';
  }

  @override
  String get settingsTitle => 'සැකසීම්';

  @override
  String get settingsGeneral => 'පොදු';

  @override
  String get settingsSecurity => 'ආරක්ෂාව සහ පෞද්ගලිකත්වය';

  @override
  String get settingsReminders => 'සිහිකැඳවීම්';

  @override
  String get settingsData => 'දත්ත';

  @override
  String get settingsUpdates => 'යාවත්කාලීන කිරීම්';

  @override
  String get settingsAbout => 'පිළිබඳව';

  @override
  String get settingsLanguage => 'භාෂාව';

  @override
  String get settingsCurrency => 'මුදල් ඒකකය';

  @override
  String get settingsTheme => 'තේමාව';

  @override
  String get settingsThemeSystem => 'පද්ධති පෙරනිමිය';

  @override
  String get settingsThemeLight => 'ආලෝකමත්';

  @override
  String get settingsThemeDark => 'අඳුරු';

  @override
  String get settingsDateFormat => 'දින ආකෘතිය';

  @override
  String get settingsFirstDayOfWeek => 'සතියේ පළමු දිනය';

  @override
  String get settingsYourName => 'ඔබේ නම';

  @override
  String get settingsYourNameHint =>
      'මුල් පිටුවේ සුබ පැතුම සඳහා පමණක් භාවිත වේ';

  @override
  String get settingsDailyBudget => 'දෛනික අයවැය';

  @override
  String get settingsCategories => 'වර්ග';

  @override
  String get settingsCurrencyChangeNote =>
      'මුදල් ඒකකය වෙනස් කිරීමෙන් නව මුදල් පෙන්වන ආකාරය පමණක් වෙනස් වේ. පවතින මුදල් පරිවර්තනය නොකෙරේ.';

  @override
  String get settingsPrivacyMode => 'යෙදුම විවෘත කරන විට ශේෂයන් සඟවන්න';

  @override
  String get settingsPrivacyModeDesc =>
      'පොදු ස්ථානවල DAWASA විවෘත කරන විට ප්‍රයෝජනවත්';

  @override
  String get settingsScreenProtection => 'තිර අන්තර්ගතය ආරක්ෂා කරන්න';

  @override
  String get settingsScreenProtectionDesc =>
      'තිර රූප ගැනීම අවහිර කර මෑත යෙදුම් දසුනේ DAWASA සඟවයි';

  @override
  String get settingsNotifications => 'දැනුම්දීම්';

  @override
  String get settingsNotificationsEnabled => 'සිහිකැඳවීම්වලට ඉඩ දෙන්න';

  @override
  String get settingsNotifyTasks => 'කාර්ය සිහිකැඳවීම්';

  @override
  String get settingsNotifyBills => 'බිල්පත් සිහිකැඳවීම්';

  @override
  String get settingsNotifyEvents => 'වැදගත් දින සිහිකැඳවීම්';

  @override
  String get settingsNotifyBudgets => 'අයවැය අනතුරු ඇඟවීම්';

  @override
  String get settingsNotifyLoans => 'ණය ගෙවීම් සිහිකැඳවීම්';

  @override
  String get settingsNotifySavings => 'ඉතිරිකිරීම් ඉලක්ක සිහිකැඳවීම්';

  @override
  String get settingsNotifyHabits => 'පුරුදු සිහිකැඳවීම්';

  @override
  String get settingsDailyPlanning => 'දෛනික සැලසුම් සිහිකැඳවීම';

  @override
  String get settingsDailyPlanningDesc =>
      'ඔබේ දවස සමාලෝචනය කර වියදම් සටහන් කිරීමට දිනපතා මතක් කිරීමක්';

  @override
  String get settingsDailyPlanningTime => 'සිහිකැඳවීමේ වේලාව';

  @override
  String get settingsNotificationsBlocked =>
      'Android සැකසීම් තුළ DAWASA සඳහා දැනුම්දීම් අක්‍රිය කර ඇත.';

  @override
  String get settingsBatteryNote =>
      'සමහර දුරකථන බැටරිය ඉතිරි කිරීමට සිහිකැඳවීම් ප්‍රමාද කරයි. සිහිකැඳවීම් ප්‍රමාද වී ලැබේ නම්, බැටරි සීමා නොමැතිව ක්‍රියා කිරීමට DAWASA හට ඉඩ දෙන්න.';

  @override
  String get settingsBackup => 'උපස්ථයක් සාදන්න';

  @override
  String get settingsBackupDesc => 'ඔබේ මුරපදයෙන් ආරක්ෂිත සංකේතිත ගොනුවක්';

  @override
  String get settingsRestore => 'උපස්ථයෙන් ප්‍රතිස්ථාපනය';

  @override
  String get settingsExportCsv => 'ගනුදෙනු අපනයනය (CSV)';

  @override
  String get settingsDeleteAll => 'සියලු පෞද්ගලික දත්ත මකන්න';

  @override
  String get settingsDeleteAllDesc => 'මෙම දුරකථනයේ සියලු වාර්තා මකා දමයි';

  @override
  String get settingsUninstallWarning =>
      'ඔබේ දත්ත මෙම දුරකථනයේ පමණක් ගබඩා වී ඇත. ආරක්ෂිත ස්ථානයක උපස්ථ ගොනුවක් නොතබා DAWASA ඉවත් කිරීම හෝ එහි ගබඩාව හිස් කිරීම මඟින් දත්ත සදහටම මැකී යයි.';

  @override
  String get settingsCurrentVersion => 'වත්මන් අනුවාදය';

  @override
  String get settingsCheckUpdates => 'යාවත්කාලීන කිරීම් පරීක්ෂා කරන්න';

  @override
  String get settingsAutoCheckUpdates =>
      'යාවත්කාලීන කිරීම් ස්වයංක්‍රීයව පරීක්ෂා කරන්න';

  @override
  String get settingsAutoCheckUpdatesDesc =>
      'දිනකට එක් වරක් පමණ, සම්බන්ධ වී ඇති විට පමණි';

  @override
  String get settingsWifiOnly => 'Wi-Fi මඟින් පමණක් යාවත්කාලීන බාගත කරන්න';

  @override
  String get settingsUpdateServer => 'යාවත්කාලීන සේවාදායකය';

  @override
  String get settingsUpdateServerHint =>
      'DAWASA යාවත්කාලීන ෆෝල්ඩරයේ HTTPS ලිපිනය';

  @override
  String get settingsUpdateServerInvalid =>
      'වලංගු https:// ලිපිනයක් ඇතුළත් කරන්න';

  @override
  String get settingsUpdateServerReset => 'පෙරනිමි සේවාදායකය භාවිත කරන්න';

  @override
  String get settingsReleaseNotes => 'නිකුතු සටහන්';

  @override
  String get settingsReplayOnboarding => 'පිළිගැනීමේ මාර්ගෝපදේශය නැවත පෙන්වන්න';

  @override
  String get settingsLicenses => 'විවෘත මූලාශ්‍ර බලපත්‍ර';

  @override
  String get settingsPrivacyPolicy => 'පෞද්ගලිකත්වය';

  @override
  String get aboutDeveloper => 'සංවර්ධකයා';

  @override
  String get aboutDeveloperName => 'Sandaru Tharushka';

  @override
  String get aboutFree => '100% නොමිලේ';

  @override
  String get aboutNoAds => 'දැන්වීම් නැත';

  @override
  String get aboutNoSubscription => 'දායකත්ව ගාස්තු නැත';

  @override
  String get aboutWebsite => 'වෙබ් අඩවිය';

  @override
  String get aboutContact => 'සම්බන්ධ වන්න';

  @override
  String aboutVersion(String version, String code) {
    return 'අනුවාදය $version ($code)';
  }

  @override
  String get privacyTitle => 'ඔබේ පෞද්ගලිකත්වය';

  @override
  String get privacyBody =>
      'DAWASA ඔබේ සියලු මූල්‍ය සහ පෞද්ගලික වාර්තා මෙම දුරකථනයේ, යෙදුමේ පෞද්ගලික ගබඩාවේ පමණක් තබා ගනී.\n\n• ගිණුමක්, පිවිසීමක් හෝ ලියාපදිංචියක් නැත.\n• දැන්වීම්, විශ්ලේෂණ හෝ ලුහුබැඳීම් නැත.\n• කිසිදු මූල්‍ය දත්තයක් කිසිදු සේවාදායකයකට යවනු නොලැබේ.\n• යෙදුම් දත්ත සඳහා Android වලාකුළු උපස්ථය අක්‍රිය කර ඇති බැවින් ඔබේ වාර්තා මාර්ගගත ගබඩාවකට පිටපත් නොවේ.\n• උපස්ථ ඔබ පමණක් දන්නා මුරපදයකින් සංකේතනය කෙරේ (AES-256-GCM). මුරපදය නොමැතිව සංවර්ධකයා ඇතුළු කිසිවෙකුට ඒවා කියවිය නොහැක.\n• DAWASA සිදු කරන එකම අන්තර්ජාල සම්බන්ධතාවය යාවත්කාලීන සේවාදායකයට වන අතර, එය යාවත්කාලීන විස්තරය සහ නව යෙදුම් ගොනුව බාගත කිරීමට පමණි. මෙම ඉල්ලීම්වල කිසිදු පෞද්ගලික දත්තයක් ඇතුළත් නොවේ.\n• රිසිට්පත් ඡායාරූප යෙදුමේ පෞද්ගලික ගබඩාවට පිටපත් කෙරෙන අතර කිසිදා උඩුගත නොකෙරේ.';

  @override
  String get securityPin => 'PIN අගුල';

  @override
  String get securityPinDesc => 'DAWASA විවෘත කරන විට PIN අංකයක් ඉල්ලන්න';

  @override
  String get securitySetPin => 'PIN සකසන්න';

  @override
  String get securityChangePin => 'PIN වෙනස් කරන්න';

  @override
  String get securityRemovePin => 'PIN ඉවත් කරන්න';

  @override
  String get securityBiometric => 'ඇඟිලි සලකුණ හෝ මුහුණෙන් අගුල් හරින්න';

  @override
  String get securityBiometricUnavailable =>
      'මෙම දුරකථනයේ ජෛවමිතික අගුල් හැරීම නොමැත';

  @override
  String get securityLockTimeout => 'අගුලු දැමෙන්නේ';

  @override
  String get securityLockImmediately => 'වහාම';

  @override
  String securityLockAfterMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'විනාඩි $countකට පසු',
      one: 'විනාඩි 1කට පසු',
    );
    return '$_temp0';
  }

  @override
  String get securityEnterPin => 'ඔබේ PIN අංකය ඇතුළත් කරන්න';

  @override
  String get securityCreatePin => 'PIN අංකයක් සාදන්න';

  @override
  String get securityCreatePinDesc =>
      'ඉලක්කම් 4 සිට 6 දක්වා භාවිත කරන්න. ඔබේ බැංකු කාඩ්පතේ PIN අංකය භාවිත නොකරන්න.';

  @override
  String get securityConfirmPin => 'PIN අංකය නැවත ඇතුළත් කරන්න';

  @override
  String get securityPinMismatch => 'PIN අංක නොගැළපේ. නැවත උත්සාහ කරන්න.';

  @override
  String securityWrongPin(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'වැරදි PIN. විරාමයකට පෙර තව උත්සාහ $countක් ඇත.',
      one: 'වැරදි PIN. විරාමයකට පෙර තව එක් උත්සාහයක් ඇත.',
    );
    return '$_temp0';
  }

  @override
  String securityLockedOut(int seconds) {
    return 'උත්සාහයන් වැඩියි. තත්පර $secondsකින් නැවත උත්සාහ කරන්න.';
  }

  @override
  String get securityUnlockTitle => 'DAWASA අගුලු දමා ඇත';

  @override
  String get securityUseBiometric => 'ඇඟිලි සලකුණ / මුහුණ භාවිත කරන්න';

  @override
  String get securityBiometricReason => 'DAWASA අගුල් හරින්න';

  @override
  String get securityPinSet => 'PIN අගුල සක්‍රියයි';

  @override
  String get securityPinRemoved => 'PIN අගුල ඉවත් කරන ලදී';

  @override
  String get securityForgotPin => 'PIN අමතකද?';

  @override
  String get securityForgotPinBody =>
      'ඔබේ පෞද්ගලිකත්වය සඳහා PIN අංකය නැවත ලබාගත නොහැක. මෙම දුරකථනයේ සියලු දත්ත මකා උපස්ථ ගොනුවකින් ප්‍රතිස්ථාපනය කළ හැක.';

  @override
  String get securityDeleteAndReset => 'දත්ත මකා යළි සකසන්න';

  @override
  String get backupTitle => 'උපස්ථය සහ ප්‍රතිස්ථාපනය';

  @override
  String get backupIntro =>
      'උපස්ථයක් යනු ඔබේ සියලු වාර්තා සහ රිසිට්පත් ඡායාරූප අඩංගු එක් සංකේතිත ගොනුවකි. එය Google Drive, පරිගණකයක් හෝ මතක කාඩ්පතක් වැනි ආරක්ෂිත ස්ථානයක තබා ගන්න.';

  @override
  String get backupPassword => 'උපස්ථ මුරපදය';

  @override
  String get backupPasswordConfirm => 'මුරපදය තහවුරු කරන්න';

  @override
  String get backupPasswordRules =>
      'අවම වශයෙන් අක්ෂර 8ක්. ප්‍රතිස්ථාපනය කිරීමට මෙම මුරපදය අවශ්‍ය වේ. එය නැවත ලබාගත නොහැක.';

  @override
  String get backupPasswordTooShort => 'අවම වශයෙන් අක්ෂර 8ක් භාවිත කරන්න';

  @override
  String get backupPasswordMismatch => 'මුරපද නොගැළපේ';

  @override
  String get backupCreating => 'ඔබේ දත්ත සංකේතනය කරමින්…';

  @override
  String get backupCreated => 'උපස්ථය සාදන ලදී';

  @override
  String get backupSaveToDevice => 'ෆෝල්ඩරයකට සුරකින්න';

  @override
  String get backupShareFile => 'ගොනුව බෙදාගන්න / යවන්න';

  @override
  String get backupSavedTo => 'උපස්ථය සුරකින ලදී';

  @override
  String backupLastBackup(String date) {
    return 'අවසන් උපස්ථය: $date';
  }

  @override
  String get backupNever => 'තවම උපස්ථයක් සාදා නැත';

  @override
  String get restoreChooseFile => 'උපස්ථ ගොනුව තෝරන්න';

  @override
  String get restoreEnterPassword =>
      'මෙම උපස්ථය සඳහා භාවිත කළ මුරපදය ඇතුළත් කරන්න';

  @override
  String get restoreVerifying => 'උපස්ථය පරීක්ෂා කරමින්…';

  @override
  String get restoreConfirmTitle => 'සියලු දත්ත ප්‍රතිස්ථාපනය කරන්නද?';

  @override
  String get restoreConfirmBody =>
      'ප්‍රතිස්ථාපනය කිරීමෙන් මෙම දුරකථනයේ DAWASA හි දැනට ඇති සියලු දත්ත උපස්ථයේ අන්තර්ගතයෙන් ප්‍රතිස්ථාපනය වේ. පළමුව ඔබේ වත්මන් දත්තවල ආරක්ෂිත පිටපතක් සුරකිනු ලැබේ.';

  @override
  String restoreBackupInfo(String date, String version) {
    return '$date උපස්ථය · යෙදුම $version';
  }

  @override
  String restoreContents(int transactions, int accounts, int tasks) {
    return 'ගනුදෙනු $transactionsක්, ගිණුම් $accountsක්, කාර්ය $tasksක් අඩංගුයි';
  }

  @override
  String get restoreAction => 'ප්‍රතිස්ථාපනය කරන්න';

  @override
  String get restoreInProgress => 'ප්‍රතිස්ථාපනය කරමින්…';

  @override
  String get restoreDone => 'ප්‍රතිස්ථාපනය සම්පූර්ණයි. DAWASA නැවත පූරණය වේ.';

  @override
  String get restoreErrorWrongPassword =>
      'වැරදි මුරපදයක්, නැතහොත් ගොනුව වෙනස් කර හෝ හානි වී ඇත.';

  @override
  String get restoreErrorNotBackup => 'මෙය DAWASA උපස්ථ ගොනුවක් නොවේ.';

  @override
  String get restoreErrorCorrupted =>
      'උපස්ථ ගොනුව හානි වී ඇති බැවින් ප්‍රතිස්ථාපනය කළ නොහැක.';

  @override
  String get restoreErrorNewer =>
      'මෙම උපස්ථය DAWASA හි නව අනුවාදයකින් සාදා ඇත. පළමුව යෙදුම යාවත්කාලීන කරන්න.';

  @override
  String get restoreSafetyNote =>
      'ප්‍රතිස්ථාපනයට පෙර ආරක්ෂිත පිටපතක් යෙදුම තුළ සුරකින ලදී.';

  @override
  String get deleteAllTitle => 'සියලු පෞද්ගලික දත්ත මකන්නද?';

  @override
  String get deleteAllBody =>
      'සියලු ගිණුම්, ගනුදෙනු, කාර්ය, බිල්පත්, රිසිට්පත් ඡායාරූප සහ සැකසීම් මෙම දුරකථනයෙන් මකා දමනු ලැබේ. මෙය ආපසු හැරවිය නොහැක. තහවුරු කිරීමට DELETE ලෙස ටයිප් කරන්න.';

  @override
  String get deleteAllConfirmWord => 'DELETE';

  @override
  String get deleteAllDone => 'සියලු දත්ත මකා දමන ලදී';

  @override
  String get updateTitle => 'යෙදුම් යාවත්කාලීන කිරීම්';

  @override
  String get updateChecking => 'යාවත්කාලීන කිරීම් පරීක්ෂා කරමින්…';

  @override
  String get updateUpToDate => 'DAWASA යාවත්කාලීනයි';

  @override
  String updateAvailable(String version) {
    return 'යාවත්කාලීනයක් ඇත: $version';
  }

  @override
  String get updateRequired =>
      'මෙම අනුවාදයට තවදුරටත් සහාය නොදක්වයි. කරුණාකර යාවත්කාලීන කරන්න.';

  @override
  String updateDownloading(int percent) {
    return 'බාගත කරමින්… $percent%';
  }

  @override
  String get updateVerifying => 'බාගැනීම තහවුරු කරමින්…';

  @override
  String get updateReady => 'ස්ථාපනයට සූදානම්';

  @override
  String get updateInstallCancelled => 'ස්ථාපනය අවලංගු කරන ලදී';

  @override
  String get updateDownloadFailed => 'බාගැනීම අසාර්ථකයි';

  @override
  String get updateInstalling => 'Android ස්ථාපකය විවෘත කරමින්…';

  @override
  String get updateOffline =>
      'අන්තර්ජාල සම්බන්ධතාවයක් නැත. DAWASA හි අනෙක් සියල්ල නොබැඳිව දිගටම ක්‍රියා කරයි.';

  @override
  String get updateServerUnavailable =>
      'යාවත්කාලීන සේවාදායකයට සම්බන්ධ විය නොහැකි විය. පසුව නැවත උත්සාහ කරන්න.';

  @override
  String get updateNotConfigured => 'යාවත්කාලීන සේවාදායකයක් සකසා නැත.';

  @override
  String get updateInvalidManifest =>
      'සේවාදායකයෙන් ලැබුණු යාවත්කාලීන තොරතුරු වලංගු නැත.';

  @override
  String get updateChecksumMismatch =>
      'බාගත කළ ගොනුව ආරක්ෂක පරීක්ෂාව අසමත් වූ බැවින් මකා දමන ලදී.';

  @override
  String get updatePackageMismatch =>
      'බාගත කළ ගොනුව වලංගු DAWASA යාවත්කාලීනයක් නොවන බැවින් මකා දමන ලදී.';

  @override
  String get updateNow => 'දැන් යාවත්කාලීන කරන්න';

  @override
  String get updateInstall => 'ස්ථාපනය කරන්න';

  @override
  String get updateCancelDownload => 'බාගැනීම අවලංගු කරන්න';

  @override
  String updateSize(String size) {
    return 'බාගැනීමේ ප්‍රමාණය: $size';
  }

  @override
  String get updateWifiOnlyBlocked =>
      'ඔබ ජංගම දත්ත භාවිත කරන අතර \"Wi-Fi පමණි\" සක්‍රියයි.';

  @override
  String get updateDownloadAnyway => 'කෙසේ වෙතත් බාගත කරන්න';

  @override
  String get updatePermissionTitle => 'යාවත්කාලීනය ස්ථාපනයට ඉඩ දෙන්න';

  @override
  String get updatePermissionBody =>
      'DAWASA හට තමන්ගේම යාවත්කාලීන ස්ථාපනය කිරීමට ඉඩ දෙන ලෙස Android ඉල්ලා සිටී. ඊළඟ තිරයේ \"මෙම මූලාශ්‍රයෙන් ඉඩ දෙන්න\" සක්‍රිය කර ආපසු එන්න.';

  @override
  String get updateDataSafe => 'යාවත්කාලීන කිරීමෙන් ඔබේ සියලු දත්ත ආරක්ෂා වේ.';

  @override
  String updateLastChecked(String date) {
    return 'අවසන් වරට පරීක්ෂා කළේ: $date';
  }

  @override
  String get updateNewVersionBanner => 'DAWASA හි නව අනුවාදයක් ඇත';

  @override
  String get updateWhatsNew => 'අලුත් දේ';

  @override
  String get moneyTitle => 'මුදල්';

  @override
  String get tabTransactions => 'ගනුදෙනු';

  @override
  String get tabAccounts => 'ගිණුම්';

  @override
  String get tabBudgets => 'අයවැය';

  @override
  String get tabBills => 'බිල්පත්';

  @override
  String get tabSavings => 'ඉතිරිකිරීම්';

  @override
  String get tabLoans => 'ණය';

  @override
  String get homeAvailableBalance => 'පවතින ශේෂය';

  @override
  String get homeTodayIncome => 'අද ආදායම';

  @override
  String get homeTodayExpenses => 'අද වියදම්';

  @override
  String get homeTodayNet => 'අද ශුද්ධ මුදල් ප්‍රවාහය';

  @override
  String get homeRemainingBudget => 'අද වියදම් කිරීමට ඉතිරි';

  @override
  String homeBudgetExceeded(String amount) {
    return 'අද අයවැය $amount කින් ඉක්මවා ඇත';
  }

  @override
  String get homeNoBudget => 'දෛනික අයවැයක් සකසන්න';

  @override
  String get homeBudgetFromMonthly => 'ඔබේ මාසික අයවැය මත පදනම්ව';

  @override
  String get homePendingTasks => 'අද කාර්යයන්';

  @override
  String get homeNoPendingTasks => 'අදට කාර්ය ඉතිරි නැත';

  @override
  String get homeUpcomingPayments => 'ඉදිරි ගෙවීම්';

  @override
  String get homeNoUpcomingPayments => 'ඉදිරි දින 7 තුළ නියමිත ගෙවීම් නැත';

  @override
  String get homeSavingsProgress => 'ඉතිරිකිරීම් ඉලක්ක';

  @override
  String get homeNoSavingsGoals =>
      'ඔබේ ප්‍රගතිය නිරීක්ෂණයට ඉතිරිකිරීම් ඉලක්කයක් සාදන්න';

  @override
  String get homeLast7Days => 'වියදම් — පසුගිය දින 7';

  @override
  String get homeRecentTransactions => 'මෑත ගනුදෙනු';

  @override
  String get homeNoTransactions =>
      'තවම ගනුදෙනු නැත. ඔබේ පළමු වියදම හෝ ආදායම එක් කිරීමට + ඔබන්න.';

  @override
  String get homeHideBalances => 'ශේෂයන් සඟවන්න';

  @override
  String get homeShowBalances => 'ශේෂයන් පෙන්වන්න';

  @override
  String get homeQuickActions => 'ඉක්මන් ක්‍රියා';

  @override
  String get quickAddExpense => 'වියදමක් එක් කරන්න';

  @override
  String get quickAddIncome => 'ආදායමක් එක් කරන්න';

  @override
  String get quickAddTask => 'කාර්යයක් එක් කරන්න';

  @override
  String get quickViewReports => 'වාර්තා බලන්න';

  @override
  String get quickAddTransfer => 'මාරු කරන්න';

  @override
  String homeChartSemantics(String summary) {
    return 'පසුගිය දින 7 වියදම්. $summary';
  }

  @override
  String get hiddenAmount => 'සඟවා ඇත';

  @override
  String get txTypeExpense => 'වියදම';

  @override
  String get txTypeIncome => 'ආදායම';

  @override
  String get txTypeTransfer => 'මාරු කිරීම';

  @override
  String get txTypeReimbursement => 'ප්‍රතිපූරණය';

  @override
  String get txTypeLoanGiven => 'ණයට දුන් මුදල්';

  @override
  String get txTypeLoanReceived => 'ණයට ගත් මුදල්';

  @override
  String get txTypeLoanRepaymentReceived => 'ලැබුණු ණය ආපසු ගෙවීම';

  @override
  String get txTypeLoanRepaymentPaid => 'ගෙවූ ණය වාරිකය';

  @override
  String get txTypeAdjustmentIn => 'ශේෂ නිවැරදි කිරීම (+)';

  @override
  String get txTypeAdjustmentOut => 'ශේෂ නිවැරදි කිරීම (−)';

  @override
  String get txTypeReimbursementHelp =>
      'වෙනත් අයෙකු වෙනුවෙන් ඔබ ගෙවූ දෙයක් සඳහා ඔබට ආපසු ලැබුණු මුදල්. එය ආදායමක් ලෙස ගණන් නොගැනේ.';

  @override
  String get txTransferHelp =>
      'ඔබේම ගිණුම් අතර මුදල් මාරු කිරීම ආදායමක් හෝ වියදමක් නොවේ.';

  @override
  String get txAddExpense => 'වියදමක් එක් කරන්න';

  @override
  String get txAddIncome => 'ආදායමක් එක් කරන්න';

  @override
  String get txAddTransfer => 'ගිණුම් අතර මාරු කිරීම';

  @override
  String get txAddReimbursement => 'ප්‍රතිපූරණයක් එක් කරන්න';

  @override
  String get txEdit => 'ගනුදෙනුව සංස්කරණය';

  @override
  String get txDetails => 'ගනුදෙනුව';

  @override
  String get txPaidFrom => 'ගෙවූ ගිණුම';

  @override
  String get txReceivedInto => 'ලැබුණු ගිණුම';

  @override
  String get txFromAccount => 'ගිණුමෙන්';

  @override
  String get txToAccount => 'ගිණුමට';

  @override
  String get txDescriptionHint => 'එය කුමක් සඳහාද?';

  @override
  String get txNoteHint => 'අමතර විස්තර (අත්‍යවශ්‍ය නැත)';

  @override
  String get txReceipt => 'රිසිට්පත් ඡායාරූපය';

  @override
  String get txAddReceipt => 'රිසිට්පත් ඡායාරූපය එක් කරන්න';

  @override
  String get txTakePhoto => 'ඡායාරූපයක් ගන්න';

  @override
  String get txChooseFromGallery => 'ගැලරියෙන් තෝරන්න';

  @override
  String get txRemoveReceipt => 'ඡායාරූපය ඉවත් කරන්න';

  @override
  String get txSelectAccount => 'ගිණුම තෝරන්න';

  @override
  String get txSelectCategory => 'වර්ගය තෝරන්න';

  @override
  String get txErrorSameAccount => 'වෙනස් ගිණුම් දෙකක් තෝරන්න';

  @override
  String get txErrorCurrencyMismatch =>
      'ගිණුම් දෙකම එකම මුදල් ඒකකය භාවිත කළ යුතුය';

  @override
  String get txErrorNoAccount => 'පළමුව ගිණුමක් සාදන්න';

  @override
  String get txErrorCategoryRequired => 'වර්ගයක් තෝරන්න';

  @override
  String get txDeleteTitle => 'මෙම ගනුදෙනුව මකන්නද?';

  @override
  String get txDeleteLinkedWarning =>
      'මෙම ගනුදෙනුව බිල්පතකට, සාප්පු ලැයිස්තුවකට, ඉතිරිකිරීම් ඉලක්කයකට හෝ ණයකට සම්බන්ධයි. සම්බන්ධය ඉවත් කර ශේෂය නැවත ගණනය කෙරේ.';

  @override
  String get txDuplicated => 'පිටපතක් සාදන ලදී — පරීක්ෂා කර සුරකින්න';

  @override
  String get txSearchHint => 'විස්තරය, සටහන හෝ මුදල සොයන්න';

  @override
  String get txNoResults => 'ගැළපෙන ගනුදෙනු නැත';

  @override
  String get txEmpty => 'තවම ගනුදෙනු නැත';

  @override
  String get txFilterType => 'වර්ගය';

  @override
  String get txFilterDates => 'දින';

  @override
  String get txFilterAnyDate => 'ඕනෑම දිනයක්';

  @override
  String get txSourceRecurring => 'පුනරාවර්තන';

  @override
  String get txSourceBill => 'බිල්පත් ගෙවීම';

  @override
  String get txSourceShopping => 'සාප්පු ලැයිස්තුව';

  @override
  String get txSourceSavings => 'ඉතිරිකිරීම් ඉලක්කය';

  @override
  String get txSourceLoan => 'ණය';

  @override
  String get txRepeatSection => 'මෙය පුනරාවර්තන ගනුදෙනුවක් කරන්න';

  @override
  String get txRepeatHelp =>
      'DAWASA එය එක් එක් දිනයේ ස්වයංක්‍රීයව එක් කරයි. ඔබට ඕනෑම එකක් සංස්කරණය හෝ මකා දැමිය හැක.';

  @override
  String get txOpeningBalance => 'ආරම්භක ශේෂය';

  @override
  String get txSplitNote =>
      'මාරු කිරීම්, ණය සහ ප්‍රතිපූරණ ආදායම හෝ වියදම ලෙස ගණන් නොගැනේ.';

  @override
  String get txMoreTypes => 'තවත් වර්ග';

  @override
  String get recurringTitle => 'පුනරාවර්තන ගනුදෙනු';

  @override
  String get recurringEmpty =>
      'පුනරාවර්තන ගනුදෙනු නැත. වියදමක් හෝ ආදායමක් එක් කරන විට \"නැවත නැවත\" සක්‍රිය කරන්න.';

  @override
  String recurringNext(String date) {
    return 'ඊළඟ: $date';
  }

  @override
  String get recurringEnded => 'අවසන්';

  @override
  String get recurringPause => 'නවත්වන්න';

  @override
  String get recurringResume => 'නැවත අරඹන්න';

  @override
  String get recurringStop => 'නැවත කිරීම නවත්වන්න';

  @override
  String get recurringStopBody =>
      'අනාගත ගනුදෙනු තවදුරටත් එක් නොකෙරේ. දැනටමත් සටහන් කළ ගනුදෙනු රඳවා ගැනේ.';

  @override
  String recurringGenerated(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'පුනරාවර්තන ගනුදෙනු $countක් එක් කරන ලදී',
      one: 'පුනරාවර්තන ගනුදෙනු 1ක් එක් කරන ලදී',
    );
    return '$_temp0';
  }

  @override
  String get catFood => 'ආහාර';

  @override
  String get catTransport => 'ප්‍රවාහනය';

  @override
  String get catShopping => 'සාප්පු යාම';

  @override
  String get catBills => 'බිල්පත්';

  @override
  String get catHealthcare => 'සෞඛ්‍ය සේවා';

  @override
  String get catEducation => 'අධ්‍යාපනය';

  @override
  String get catEntertainment => 'විනෝදාස්වාදය';

  @override
  String get catFamily => 'පවුල';

  @override
  String get catFuel => 'ඉන්ධන';

  @override
  String get catRent => 'කුලිය';

  @override
  String get catInterestFees => 'පොලී සහ ගාස්තු';

  @override
  String get catOther => 'වෙනත්';

  @override
  String get catSalary => 'වැටුප';

  @override
  String get catBusiness => 'ව්‍යාපාරය';

  @override
  String get catFreelancing => 'නිදහස් සේවා';

  @override
  String get catInterest => 'පොලිය';

  @override
  String get catGifts => 'තෑගි';

  @override
  String get categoriesTitle => 'වර්ග';

  @override
  String get categoriesExpense => 'වියදම් වර්ග';

  @override
  String get categoriesIncome => 'ආදායම් මාර්ග';

  @override
  String get categoryAdd => 'නව වර්ගයක්';

  @override
  String get categoryAddIncome => 'නව ආදායම් මාර්ගයක්';

  @override
  String get categoryEdit => 'වර්ගය සංස්කරණය';

  @override
  String get categoryName => 'වර්ගයේ නම';

  @override
  String get categoryIcon => 'නිරූපකය';

  @override
  String get categoryColor => 'වර්ණය';

  @override
  String get categoryArchiveHelp =>
      'සංරක්ෂිත වර්ග නව ඇතුළත් කිරීම් වලින් සැඟවෙන නමුත් පැරණි ගනුදෙනුවල රඳවා ගැනේ.';

  @override
  String get categoryDuplicateName => 'මෙම නමින් වර්ගයක් දැනටමත් ඇත';

  @override
  String get categoryUncategorized => 'වර්ගීකරණය නොකළ';

  @override
  String get accountsTitle => 'ගිණුම්';

  @override
  String get accountAdd => 'ගිණුමක් එක් කරන්න';

  @override
  String get accountEdit => 'ගිණුම සංස්කරණය';

  @override
  String get accountName => 'ගිණුමේ නම';

  @override
  String get accountType => 'ගිණුම් වර්ගය';

  @override
  String get accountTypeCash => 'අතැති මුදල්';

  @override
  String get accountTypeBank => 'බැංකු ගිණුම';

  @override
  String get accountTypeEWallet => 'ඊ-පසුම්බිය';

  @override
  String get accountTypeSavings => 'ඉතිරිකිරීමේ ගිණුම';

  @override
  String get accountTypeOther => 'වෙනත්';

  @override
  String get accountDefaultCash => 'අතැති මුදල්';

  @override
  String get accountDefaultBank => 'බැංකුව';

  @override
  String get accountDefaultWallet => 'පසුම්බිය';

  @override
  String get accountOpeningBalance => 'ආරම්භක ශේෂය';

  @override
  String get accountOpeningBalanceHelp =>
      'DAWASA භාවිතය ආරම්භ කිරීමට පෙර මෙම ගිණුමේ තිබූ මුදල්';

  @override
  String get accountIncludeInTotal => 'පවතින ශේෂයට ඇතුළත් කරන්න';

  @override
  String get accountBalance => 'ශේෂය';

  @override
  String accountTotalBalance(String currency) {
    return '$currency මුළු ශේෂය';
  }

  @override
  String get accountCorrectBalance => 'ශේෂය නිවැරදි කරන්න';

  @override
  String get accountCorrectBalanceBody =>
      'මෙම ගිණුමේ සැබෑ ශේෂය ඇතුළත් කරන්න. DAWASA වෙනස ශේෂ නිවැරදි කිරීමක් ලෙස සටහන් කරයි — එය ආදායම හෝ වියදම ලෙස ගණන් නොගැනේ.';

  @override
  String get accountActualBalance => 'සැබෑ ශේෂය';

  @override
  String accountCorrectionPreview(String amount) {
    return '$amount ක නිවැරදි කිරීමක් සටහන් කෙරේ';
  }

  @override
  String get accountCorrectionNone => 'ශේෂය දැනටමත් නිවැරදියි';

  @override
  String get accountDeleteBlocked =>
      'මෙම ගිණුමේ ගනුදෙනු ඇත. ඔබේ ඉතිහාසය රඳවා ගැනීමට ඒ වෙනුවට එය සංරක්ෂණය කරන්න.';

  @override
  String get accountEmpty => 'තවම ගිණුම් නැත';

  @override
  String get accountArchivedSection => 'සංරක්ෂිත ගිණුම්';

  @override
  String get accountHistory => 'ගිණුම් ඉතිහාසය';

  @override
  String get accountOtherCurrencies =>
      'වෙනත් මුදල් ඒකකවල ගිණුම් මෙම එකතුවට එක් නොකෙරේ.';

  @override
  String get accountCurrencyLocked =>
      'ගනුදෙනු සටහන් කළ පසු මුදල් ඒකකය වෙනස් කළ නොහැක.';

  @override
  String get plannerTitle => 'සැලසුම්';

  @override
  String get tabTasks => 'කාර්යයන්';

  @override
  String get tabShopping => 'සාප්පු';

  @override
  String get tabHabits => 'පුරුදු';

  @override
  String get tabEvents => 'දින';

  @override
  String get budgetsTitle => 'අයවැය';

  @override
  String get budgetAdd => 'නව අයවැයක්';

  @override
  String get budgetEdit => 'අයවැය සංස්කරණය';

  @override
  String get budgetName => 'අයවැයේ නම';

  @override
  String get budgetAmount => 'අයවැය මුදල';

  @override
  String get budgetPeriod => 'කාලය';

  @override
  String get budgetPeriodDaily => 'දිනපතා';

  @override
  String get budgetPeriodWeekly => 'සතිපතා';

  @override
  String get budgetPeriodMonthly => 'මාසික';

  @override
  String get budgetPeriodCustom => 'අභිරුචි දින';

  @override
  String get budgetScope => 'අදාළ වන්නේ';

  @override
  String get budgetScopeAll => 'සියලු වියදම්';

  @override
  String get budgetScopeCategories => 'තෝරාගත් වර්ග';

  @override
  String budgetWarnAt(int percent) {
    return '$percent% භාවිත කළ විට මට අනතුරු අඟවන්න';
  }

  @override
  String get budgetNotify => 'අයවැය දැනුම්දීම්';

  @override
  String get budgetSpent => 'වියදම් කළ';

  @override
  String get budgetLeft => 'ඉතිරි';

  @override
  String budgetOverBy(String amount) {
    return '$amount කින් ඉක්මවා ඇත';
  }

  @override
  String budgetDaysLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'තව දින $countයි',
      one: 'තව දින 1යි',
      zero: 'අවසාන දිනය',
    );
    return '$_temp0';
  }

  @override
  String budgetPerDay(String amount) {
    return 'දිනකට ආසන්න වශයෙන් $amount';
  }

  @override
  String get budgetEmpty => 'තවම අයවැය නැත. අයවැයක් ඔබේ වියදම් පාලනයට උදවු වේ.';

  @override
  String get budgetNotCounted =>
      'මාරු කිරීම්, ඉතිරිකිරීම් චලනයන් සහ ණය මුදල් වියදම් ලෙස ගණන් නොගැනේ.';

  @override
  String get budgetEnded => 'අවසන්';

  @override
  String budgetNotStarted(String date) {
    return '$date ආරම්භ වේ';
  }

  @override
  String get budgetDeleteTitle => 'මෙම අයවැය මකන්නද?';

  @override
  String get budgetDeleteBody => 'ඔබේ ගනුදෙනුවලට බලපෑමක් නැත.';

  @override
  String get budgetChooseCategories => 'අවම වශයෙන් එක් වර්ගයක් තෝරන්න';

  @override
  String get budgetPerformance => 'අයවැය කාර්ය සාධනය';

  @override
  String get tasksTitle => 'කාර්යයන්';

  @override
  String get taskAdd => 'නව කාර්යයක්';

  @override
  String get taskEdit => 'කාර්යය සංස්කරණය';

  @override
  String get taskTitle => 'මාතෘකාව';

  @override
  String get taskTitleHint => 'ඔබ කළ යුත්තේ කුමක්ද?';

  @override
  String get taskDescription => 'විස්තර';

  @override
  String get taskDueDate => 'නියමිත දිනය';

  @override
  String get taskDueTime => 'වේලාව';

  @override
  String get taskPriority => 'ප්‍රමුඛතාව';

  @override
  String get taskPriorityLow => 'අඩු';

  @override
  String get taskPriorityMedium => 'මධ්‍යම';

  @override
  String get taskPriorityHigh => 'ඉහළ';

  @override
  String get taskReminder => 'සිහිකැඳවීම';

  @override
  String get taskReminderNone => 'සිහිකැඳවීමක් නැත';

  @override
  String get taskReminderAtTime => 'නියමිත වේලාවට';

  @override
  String taskReminderMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'විනාඩි $countකට පෙර',
      one: 'විනාඩි 1කට පෙර',
    );
    return '$_temp0';
  }

  @override
  String taskReminderHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'පැය $countකට පෙර',
      one: 'පැය 1කට පෙර',
    );
    return '$_temp0';
  }

  @override
  String taskReminderDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'දින $countකට පෙර',
      one: 'දින 1කට පෙර',
    );
    return '$_temp0';
  }

  @override
  String get taskReminderNeedsDate =>
      'සිහිකැඳවීමක් එක් කිරීමට නියමිත දිනයක් සකසන්න';

  @override
  String get taskViewToday => 'අද';

  @override
  String get taskViewTomorrow => 'හෙට';

  @override
  String get taskViewUpcoming => 'ඉදිරියට';

  @override
  String get taskViewCompleted => 'සම්පූර්ණ';

  @override
  String get taskViewAll => 'සියල්ල';

  @override
  String get taskOverdue => 'කල් ඉකුත්';

  @override
  String get taskNoDate => 'නියමිත දිනයක් නැත';

  @override
  String get taskEmptyToday =>
      'අදට කිසිවක් සැලසුම් කර නැත. ඔබේ දවස භුක්ති විඳින්න!';

  @override
  String get taskEmpty => 'මෙහි කාර්ය නැත';

  @override
  String get taskCompleted => 'කාර්යය සම්පූර්ණයි';

  @override
  String taskNextCreated(String date) {
    return 'ඊළඟ පුනරාවර්තනය $date සඳහා සැලසුම් කළා';
  }

  @override
  String get taskMarkDone => 'සම්පූර්ණ ලෙස සලකුණු කරන්න';

  @override
  String get taskMarkNotDone => 'අසම්පූර්ණ ලෙස සලකුණු කරන්න';

  @override
  String get taskSortDue => 'නියමිත දිනය අනුව';

  @override
  String get taskSortPriority => 'ප්‍රමුඛතාව අනුව';

  @override
  String get taskDeleteTitle => 'මෙම කාර්යය මකන්නද?';

  @override
  String get taskClearCompleted => 'සම්පූර්ණ කළ කාර්ය මකන්න';

  @override
  String taskCountToday(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'කාර්ය $countයි',
      one: 'කාර්ය 1යි',
      zero: 'කාර්ය නැත',
    );
    return '$_temp0';
  }

  @override
  String get billsTitle => 'බිල්පත් සහ ගෙවීම්';

  @override
  String get billAdd => 'නව බිල්පතක්';

  @override
  String get billEdit => 'බිල්පත සංස්කරණය';

  @override
  String get billName => 'බිල්පතේ නම';

  @override
  String get billNameHint => 'උදා: ලංවිම විදුලිය';

  @override
  String get billCategory => 'වර්ගය';

  @override
  String get billCatElectricity => 'විදුලිය';

  @override
  String get billCatWater => 'ජලය';

  @override
  String get billCatInternet => 'අන්තර්ජාලය';

  @override
  String get billCatMobile => 'ජංගම දුරකථනය';

  @override
  String get billCatRent => 'කුලිය';

  @override
  String get billCatInsurance => 'රක්ෂණය';

  @override
  String get billCatLoan => 'ණය වාරිකය';

  @override
  String get billCatOther => 'වෙනත්';

  @override
  String get billAmount => 'සාමාන්‍ය මුදල';

  @override
  String get billDueDate => 'ඊළඟ නියමිත දිනය';

  @override
  String get billRepeat => 'නැවත නැවත';

  @override
  String get billOneTime => 'එක් වරක් ගෙවීම';

  @override
  String get billRemind => 'මට මතක් කරන්න';

  @override
  String billRemindDaysBefore(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'දින $countකට පෙර',
      one: 'දින 1කට පෙර',
      zero: 'නියමිත දිනයේ',
    );
    return '$_temp0';
  }

  @override
  String get billPaymentAccount => 'සාමාන්‍යයෙන් ගෙවන ගිණුම';

  @override
  String get billPaid => 'ගෙවා ඇත';

  @override
  String get billUnpaid => 'නොගෙවූ';

  @override
  String get billDueToday => 'අද නියමිතයි';

  @override
  String billDueIn(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'දින $countකින් නියමිතයි',
      one: 'හෙට නියමිතයි',
    );
    return '$_temp0';
  }

  @override
  String billOverdueBy(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'දින $countක් ප්‍රමාදයි',
      one: 'දින 1ක් ප්‍රමාදයි',
    );
    return '$_temp0';
  }

  @override
  String get billMarkPaid => 'ගෙවූ ලෙස සලකුණු කරන්න';

  @override
  String get billPayTitle => 'ගෙවීම සටහන් කරන්න';

  @override
  String get billPaidAmount => 'ගෙවූ මුදල';

  @override
  String get billPaidOn => 'ගෙවූ දිනය';

  @override
  String get billRecordExpense => 'වියදමක් ලෙස සටහන් කරන්න';

  @override
  String get billRecordExpenseHelp =>
      '\"බිල්පත්\" වර්ගයේ වියදමක් එක් කර ගිණුම් ශේෂය අඩු කරයි.';

  @override
  String get billPossibleDuplicate => 'ඔබ දැනටමත් සමාන වියදමක් සටහන් කර ඇත';

  @override
  String get billPossibleDuplicateBody =>
      'අනුපිටපතක් සෑදීම වෙනුවට එම වියදම මෙම බිල්පතට සම්බන්ධ කරන්නද?';

  @override
  String get billLinkExisting => 'පවතින වියදම සම්බන්ධ කරන්න';

  @override
  String get billCreateNew => 'නව වියදමක් සාදන්න';

  @override
  String get billDontRecord => 'ගෙවූ ලෙස පමණක් සලකුණු කරන්න';

  @override
  String get billPaymentSaved => 'ගෙවීම සටහන් කරන ලදී';

  @override
  String get billAlreadyPaid => 'මෙම නියමිත දිනය දැනටමත් ගෙවූ ලෙස සලකුණු කර ඇත';

  @override
  String get billHistory => 'ගෙවීම් ඉතිහාසය';

  @override
  String get billNoHistory => 'තවම ගෙවීම් නැත';

  @override
  String get billEmpty =>
      'තවම බිල්පත් නැත. සිහිකැඳවීම් ලබා ගැනීමට විදුලිය, ජලය, දුරකථනය සහ අනෙකුත් නිතිපතා ගෙවීම් එක් කරන්න.';

  @override
  String get billUndoPayment => 'ගෙවීම අහෝසි කරන්න';

  @override
  String get billUndoPaymentBody =>
      'ගෙවීමේ වාර්තාව ඉවත් කර බිල්පත නැවත නොගෙවූ තත්ත්වයට පත් වේ. සම්බන්ධිත වියදම ඔබ මකා නොදැමුවහොත් රඳවා ගැනේ.';

  @override
  String get billExpenseLinked => 'වියදම සටහන් කර ඇත';

  @override
  String get billUpcoming => 'ඉදිරි';

  @override
  String get billInactive => 'අවසන්';

  @override
  String get billStop => 'මෙම බිල්පත නවත්වන්න';

  @override
  String get billResume => 'මෙම බිල්පත නැවත ආරම්භ කරන්න';

  @override
  String get shoppingTitle => 'සාප්පු ලැයිස්තු';

  @override
  String get shoppingNewList => 'නව ලැයිස්තුවක්';

  @override
  String get shoppingListName => 'ලැයිස්තුවේ නම';

  @override
  String get shoppingListNameHint => 'උදා: සතිපතා බඩු';

  @override
  String get shoppingAddItem => 'අයිතමයක් එක් කරන්න';

  @override
  String get shoppingEditItem => 'අයිතමය සංස්කරණය';

  @override
  String get shoppingItemName => 'අයිතමය';

  @override
  String get shoppingQuantity => 'ප්‍රමාණය';

  @override
  String get shoppingUnit => 'ඒකකය';

  @override
  String get shoppingEstimated => 'ඇස්තමේන්තු මිල';

  @override
  String get shoppingActual => 'සැබෑ මිල';

  @override
  String get shoppingPriceHelp => 'එක් ඒකකයකට නොව, මෙම පේළියේ මුළු මිල';

  @override
  String get shoppingEstimatedTotal => 'ඇස්තමේන්තු එකතුව';

  @override
  String get shoppingActualTotal => 'සැබෑ එකතුව';

  @override
  String get shoppingEstimateNote =>
      'ඇස්තමේන්තු මඟ පෙන්වීමක් පමණි. ඒවා කිසිවිටෙක ඔබේ ශේෂයන් වෙනස් නොකරයි.';

  @override
  String get shoppingPurchased => 'මිලදී ගත්';

  @override
  String get shoppingToBuy => 'මිලදී ගැනීමට';

  @override
  String get shoppingEmptyLists =>
      'සාප්පු ලැයිස්තු නැත. සාප්පුවට යාමට පෙර එකක් සාදන්න.';

  @override
  String get shoppingEmptyItems => 'මෙම ලැයිස්තුව හිස්';

  @override
  String get shoppingRecordExpense => 'මිලදී ගැනීම් වියදමක් ලෙස සටහන් කරන්න';

  @override
  String shoppingRecordExpenseBody(int count, String amount) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'මිලදී ගත් අයිතම $countක්',
      one: 'මිලදී ගත් අයිතම 1ක්',
    );
    return '$_temp0 තවම සටහන් කර නැත · $amount';
  }

  @override
  String get shoppingMissingPrices =>
      'පළමුව මිලදී ගත් සෑම අයිතමයකම සැබෑ මිල ඇතුළත් කරන්න';

  @override
  String get shoppingRecorded =>
      'වියදම සටහන් කරන ලදී. මෙම අයිතම නැවත ගණන් නොගැනේ.';

  @override
  String get shoppingAllRecorded => 'සියලු මිලදී ගැනීම් සටහන් කර ඇත';

  @override
  String get shoppingCompleteList => 'ලැයිස්තුව සම්පූර්ණ ලෙස සලකුණු කරන්න';

  @override
  String get shoppingReopenList => 'ලැයිස්තුව නැවත විවෘත කරන්න';

  @override
  String get shoppingListDone => 'අවසන්';

  @override
  String get shoppingDeleteList => 'ලැයිස්තුව මකන්න';

  @override
  String get shoppingDeleteListBody =>
      'මෙම ලැයිස්තුවෙන් දැනටමත් සටහන් කළ වියදම් රඳවා ගැනේ.';

  @override
  String get shoppingItemRecorded => 'සටහන් කර ඇත';

  @override
  String shoppingProgress(int done, int total) {
    return '$total න් $doneක් මිලදී ගෙන ඇත';
  }

  @override
  String get unitPcs => 'කෑලි';

  @override
  String get unitKg => 'කි.ග්‍රෑ.';

  @override
  String get unitG => 'ග්‍රෑ.';

  @override
  String get unitL => 'ලී.';

  @override
  String get unitMl => 'මි.ලී.';

  @override
  String get unitPack => 'පැකට්';

  @override
  String get unitBottle => 'බෝතල්';

  @override
  String get unitDozen => 'දුසිම්';

  @override
  String get homeSeeTasks => 'කාර්ය බලන්න';

  @override
  String get homeSeeBills => 'බිල්පත් බලන්න';

  @override
  String notifTaskTitle(String title) {
    return 'කාර්යය: $title';
  }

  @override
  String notifTaskBodyDue(String when) {
    return 'නියමිත වන්නේ $when';
  }

  @override
  String notifBillTitle(String name) {
    return 'බිල්පත් නියමිතයි: $name';
  }

  @override
  String notifBillBody(String amount, String when) {
    return '$amount $when ගෙවිය යුතුයි';
  }

  @override
  String notifBudgetWarnTitle(String name) {
    return 'අයවැය බොහෝ දුරට භාවිත කර ඇත: $name';
  }

  @override
  String notifBudgetWarnBody(int percent, String amount) {
    return 'ඔබ $amount න් $percent% භාවිත කර ඇත';
  }

  @override
  String notifBudgetOverTitle(String name) {
    return 'අයවැය ඉක්මවා ඇත: $name';
  }

  @override
  String notifBudgetOverBody(String spent, String amount) {
    return '$amount න් $spent වියදම් කර ඇත';
  }

  @override
  String get notifDailyTitle => 'DAWASA සමඟ ඔබේ දවස සැලසුම් කරන්න';

  @override
  String get notifDailyBody => 'අද කාර්ය සමාලෝචනය කර ඔබේ වියදම් සටහන් කරන්න.';

  @override
  String get notifWhenToday => 'අද';

  @override
  String get notifWhenTomorrow => 'හෙට';

  @override
  String notifWhenOn(String date) {
    return '$date දින';
  }

  @override
  String notifWhenAt(String time) {
    return '$time ට';
  }

  @override
  String get billLoanNote =>
      'ණය වාරිකවලින් වැඩි කොටස ණය මුදල වන අතර එය වියදමක් නොවේ. ඔබ ගෙවිය යුතු මුදල නිවැරදිව අඩු වීමට ණය කොටසේ ආපසු ගෙවීම සටහන් කරන්න.';
}

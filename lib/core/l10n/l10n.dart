import 'package:flutter/widgets.dart';

import '../../l10n/generated/app_localizations.dart';
import '../database/enums.dart';

export '../../l10n/generated/app_localizations.dart';

/// Supported UI languages.
const List<Locale> kSupportedLocales = [Locale('en'), Locale('si')];

extension L10nContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}

/// Localized labels for persisted enums and built-in keys.
extension L10nLabels on AppLocalizations {
  String weekdayName(int isoWeekday) => switch (isoWeekday) {
    1 => weekdayMon,
    2 => weekdayTue,
    3 => weekdayWed,
    4 => weekdayThu,
    5 => weekdayFri,
    6 => weekdaySat,
    _ => weekdaySun,
  };

  String accountTypeLabel(AccountType type) => switch (type) {
    AccountType.cash => accountTypeCash,
    AccountType.bank => accountTypeBank,
    AccountType.eWallet => accountTypeEWallet,
    AccountType.savings => accountTypeSavings,
    AccountType.other => accountTypeOther,
  };

  String transactionTypeLabel(TransactionType type) => switch (type) {
    TransactionType.expense => txTypeExpense,
    TransactionType.income => txTypeIncome,
    TransactionType.transfer => txTypeTransfer,
    TransactionType.reimbursement => txTypeReimbursement,
    TransactionType.loanGiven => txTypeLoanGiven,
    TransactionType.loanReceived => txTypeLoanReceived,
    TransactionType.loanRepaymentReceived => txTypeLoanRepaymentReceived,
    TransactionType.loanRepaymentPaid => txTypeLoanRepaymentPaid,
    TransactionType.adjustmentIn => txTypeAdjustmentIn,
    TransactionType.adjustmentOut => txTypeAdjustmentOut,
  };

  String transactionSourceLabel(TransactionSource source) => switch (source) {
    TransactionSource.manual => '',
    TransactionSource.recurring => txSourceRecurring,
    TransactionSource.bill => txSourceBill,
    TransactionSource.shopping => txSourceShopping,
    TransactionSource.savings => txSourceSavings,
    TransactionSource.loan => txSourceLoan,
  };

  /// Label of a built-in category key.
  String systemCategoryLabel(String key) => switch (key) {
    'food' => catFood,
    'transport' => catTransport,
    'shopping' => catShopping,
    'bills' => catBills,
    'healthcare' => catHealthcare,
    'education' => catEducation,
    'entertainment' => catEntertainment,
    'family' => catFamily,
    'fuel' => catFuel,
    'rent' => catRent,
    'interestFees' => catInterestFees,
    'salary' => catSalary,
    'business' => catBusiness,
    'freelancing' => catFreelancing,
    'interest' => catInterest,
    'gifts' => catGifts,
    _ => catOther,
  };
}

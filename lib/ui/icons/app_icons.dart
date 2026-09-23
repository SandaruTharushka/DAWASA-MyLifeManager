import 'package:flutter/material.dart';

import '../../core/database/enums.dart';

/// Stable icon keys stored in the database mapped to Material icons.
///
/// Storing keys (not code points) keeps icon tree-shaking working and lets us
/// change the visual icon without a data migration.
abstract final class AppIcons {
  static const Map<String, IconData> byKey = {
    'category': Icons.category_rounded,
    'restaurant': Icons.restaurant_rounded,
    'bus': Icons.directions_bus_rounded,
    'shopping': Icons.shopping_bag_rounded,
    'receipt': Icons.receipt_long_rounded,
    'health': Icons.local_hospital_rounded,
    'school': Icons.school_rounded,
    'movie': Icons.movie_rounded,
    'family': Icons.family_restroom_rounded,
    'fuel': Icons.local_gas_station_rounded,
    'home': Icons.home_rounded,
    'percent': Icons.percent_rounded,
    'work': Icons.work_rounded,
    'store': Icons.storefront_rounded,
    'laptop': Icons.laptop_mac_rounded,
    'gift': Icons.card_giftcard_rounded,
    'phone': Icons.smartphone_rounded,
    'wifi': Icons.wifi_rounded,
    'bolt': Icons.bolt_rounded,
    'water': Icons.water_drop_rounded,
    'shield': Icons.shield_rounded,
    'pets': Icons.pets_rounded,
    'sports': Icons.sports_soccer_rounded,
    'travel': Icons.flight_rounded,
    'coffee': Icons.local_cafe_rounded,
    'grocery': Icons.local_grocery_store_rounded,
    'car': Icons.directions_car_rounded,
    'bike': Icons.two_wheeler_rounded,
    'clothes': Icons.checkroom_rounded,
    'beauty': Icons.spa_rounded,
    'charity': Icons.volunteer_activism_rounded,
    'temple': Icons.temple_buddhist_rounded,
    'baby': Icons.child_friendly_rounded,
    'tools': Icons.build_rounded,
    'savings': Icons.savings_rounded,
    'wallet': Icons.account_balance_wallet_rounded,
    'bank': Icons.account_balance_rounded,
    'cash': Icons.payments_rounded,
    'card': Icons.credit_card_rounded,
    'star': Icons.star_rounded,
  };

  /// Icons offered when creating a custom category.
  static const List<String> categoryChoices = [
    'category',
    'restaurant',
    'grocery',
    'coffee',
    'bus',
    'car',
    'bike',
    'fuel',
    'shopping',
    'clothes',
    'receipt',
    'bolt',
    'water',
    'wifi',
    'phone',
    'home',
    'health',
    'beauty',
    'school',
    'movie',
    'sports',
    'travel',
    'family',
    'baby',
    'pets',
    'gift',
    'charity',
    'temple',
    'tools',
    'work',
    'store',
    'laptop',
    'percent',
    'savings',
    'star',
  ];

  static const List<int> colorChoices = [
    0xFF16A34A,
    0xFF0D9488,
    0xFF0EA5E9,
    0xFF2563EB,
    0xFF6366F1,
    0xFF8B5CF6,
    0xFFA855F7,
    0xFFEC4899,
    0xFFEF4444,
    0xFFF97316,
    0xFFEAB308,
    0xFF65A30D,
    0xFF78716C,
    0xFF64748B,
  ];

  static IconData forKey(String? key) => byKey[key] ?? Icons.category_rounded;

  static IconData forAccountType(AccountType type) => switch (type) {
    AccountType.cash => Icons.payments_rounded,
    AccountType.bank => Icons.account_balance_rounded,
    AccountType.eWallet => Icons.account_balance_wallet_rounded,
    AccountType.savings => Icons.savings_rounded,
    AccountType.other => Icons.wallet_rounded,
  };

  static IconData forTransactionType(TransactionType type) => switch (type) {
    TransactionType.expense => Icons.arrow_upward_rounded,
    TransactionType.income => Icons.arrow_downward_rounded,
    TransactionType.transfer => Icons.swap_horiz_rounded,
    TransactionType.reimbursement => Icons.replay_rounded,
    TransactionType.loanGiven => Icons.north_east_rounded,
    TransactionType.loanReceived => Icons.south_west_rounded,
    TransactionType.loanRepaymentReceived => Icons.south_west_rounded,
    TransactionType.loanRepaymentPaid => Icons.north_east_rounded,
    TransactionType.adjustmentIn => Icons.tune_rounded,
    TransactionType.adjustmentOut => Icons.tune_rounded,
  };

  static IconData forBillCategory(BillCategory c) => switch (c) {
    BillCategory.electricity => Icons.bolt_rounded,
    BillCategory.water => Icons.water_drop_rounded,
    BillCategory.internet => Icons.wifi_rounded,
    BillCategory.mobile => Icons.smartphone_rounded,
    BillCategory.rent => Icons.home_rounded,
    BillCategory.insurance => Icons.shield_rounded,
    BillCategory.loan => Icons.account_balance_rounded,
    BillCategory.other => Icons.receipt_long_rounded,
  };

  static IconData forEventType(EventType t) => switch (t) {
    EventType.birthday => Icons.cake_rounded,
    EventType.anniversary => Icons.favorite_rounded,
    EventType.appointment => Icons.event_available_rounded,
    EventType.exam => Icons.edit_note_rounded,
    EventType.other => Icons.event_rounded,
  };
}

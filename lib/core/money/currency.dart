/// Currency definitions.
///
/// DAWASA stores every monetary amount as an integer number of *minor units*
/// (e.g. cents). A [Currency] tells us how many decimal digits the minor unit
/// represents and how to display the amount.
class Currency {
  const Currency({
    required this.code,
    required this.symbol,
    required this.decimalDigits,
    required this.nameEn,
    required this.nameSi,
  });

  /// ISO 4217 code, e.g. `LKR`.
  final String code;

  /// Display symbol, e.g. `Rs`.
  final String symbol;

  /// Number of decimal digits of the minor unit (2 for LKR).
  final int decimalDigits;

  final String nameEn;
  final String nameSi;

  /// Number of minor units in one major unit (100 for 2 decimal digits).
  int get minorPerMajor {
    var result = 1;
    for (var i = 0; i < decimalDigits; i++) {
      result *= 10;
    }
    return result;
  }

  @override
  bool operator ==(Object other) => other is Currency && other.code == code;

  @override
  int get hashCode => code.hashCode;

  @override
  String toString() => code;
}

/// Registry of supported currencies. LKR is the default; the list is
/// intentionally extensible for future international support.
class Currencies {
  Currencies._();

  static const lkr = Currency(
    code: 'LKR',
    symbol: 'Rs',
    decimalDigits: 2,
    nameEn: 'Sri Lankan rupee',
    nameSi: 'ශ්‍රී ලංකා රුපියල',
  );

  static const usd = Currency(
    code: 'USD',
    symbol: r'$',
    decimalDigits: 2,
    nameEn: 'US dollar',
    nameSi: 'ඇමරිකානු ඩොලර්',
  );

  static const eur = Currency(
    code: 'EUR',
    symbol: '€',
    decimalDigits: 2,
    nameEn: 'Euro',
    nameSi: 'යුරෝ',
  );

  static const gbp = Currency(
    code: 'GBP',
    symbol: '£',
    decimalDigits: 2,
    nameEn: 'British pound',
    nameSi: 'බ්‍රිතාන්‍ය පවුම',
  );

  static const inr = Currency(
    code: 'INR',
    symbol: '₹',
    decimalDigits: 2,
    nameEn: 'Indian rupee',
    nameSi: 'ඉන්දියානු රුපියල',
  );

  static const aed = Currency(
    code: 'AED',
    symbol: 'AED',
    decimalDigits: 2,
    nameEn: 'UAE dirham',
    nameSi: 'එ.අ.එ. ඩිර්හැම්',
  );

  static const jpy = Currency(
    code: 'JPY',
    symbol: '¥',
    decimalDigits: 0,
    nameEn: 'Japanese yen',
    nameSi: 'ජපන් යෙන්',
  );

  static const defaultCurrency = lkr;

  static const List<Currency> all = [lkr, usd, eur, gbp, inr, aed, jpy];

  static Currency byCode(String? code) {
    if (code == null) return defaultCurrency;
    for (final c in all) {
      if (c.code == code) return c;
    }
    return defaultCurrency;
  }
}

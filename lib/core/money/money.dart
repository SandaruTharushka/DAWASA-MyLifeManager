import 'currency.dart';

/// Largest amount (in minor units) accepted from user input:
/// 999,999,999,999.99 for a 2-digit currency. Keeps all sums far away from
/// the 64-bit integer limit even for very large histories.
const int kMaxMinorAmount = 99999999999999;

/// Error raised when a user supplied amount cannot be parsed.
class MoneyFormatException implements Exception {
  const MoneyFormatException(this.reason);

  final MoneyParseError reason;

  @override
  String toString() => 'MoneyFormatException($reason)';
}

enum MoneyParseError { empty, invalid, tooManyDecimals, negative, tooLarge }

/// Exact decimal parsing and formatting for integer minor units.
///
/// Binary floating point is never used: "0.1 + 0.2" style rounding errors are
/// impossible because every value is an `int` number of minor units.
class Money {
  Money._();

  /// Parses user input such as `1,250.50`, `1250.5`, `Rs 1 250` into minor
  /// units using [decimalDigits] fractional digits.
  ///
  /// Grouping separators (`,`, spaces, `'`) are ignored. Only `.` is accepted
  /// as a decimal separator, which matches both Sinhala and English usage in
  /// Sri Lanka.
  static int parse(
    String input, {
    int decimalDigits = 2,
    bool allowNegative = false,
    bool allowZero = true,
  }) {
    var text = input.trim();
    // Strip common currency markers.
    for (final marker in const ['LKR', 'Rs.', 'Rs', 'රු.', 'රු']) {
      if (text.startsWith(marker)) {
        text = text.substring(marker.length).trim();
      }
    }
    text = text.replaceAll(RegExp(r"[,\s' ]"), '');
    if (text.isEmpty) throw const MoneyFormatException(MoneyParseError.empty);

    var negative = false;
    if (text.startsWith('-')) {
      negative = true;
      text = text.substring(1);
    } else if (text.startsWith('+')) {
      text = text.substring(1);
    }
    if (negative && !allowNegative) {
      throw const MoneyFormatException(MoneyParseError.negative);
    }

    final match = RegExp(r'^(\d*)(?:\.(\d*))?$').firstMatch(text);
    if (match == null) throw const MoneyFormatException(MoneyParseError.invalid);
    final wholePart = match.group(1) ?? '';
    var fracPart = match.group(2) ?? '';
    if (wholePart.isEmpty && fracPart.isEmpty) {
      throw const MoneyFormatException(MoneyParseError.invalid);
    }
    if (fracPart.length > decimalDigits) {
      // Allow trailing zeros beyond precision ("10.500" -> 10.50).
      final extra = fracPart.substring(decimalDigits);
      if (extra.replaceAll('0', '').isNotEmpty) {
        throw const MoneyFormatException(MoneyParseError.tooManyDecimals);
      }
      fracPart = fracPart.substring(0, decimalDigits);
    }
    fracPart = fracPart.padRight(decimalDigits, '0');

    final wholeDigits = wholePart.replaceFirst(RegExp(r'^0+(?=\d)'), '');
    if (wholeDigits.length > 15) {
      throw const MoneyFormatException(MoneyParseError.tooLarge);
    }
    final whole = wholeDigits.isEmpty ? 0 : int.parse(wholeDigits);
    final frac = fracPart.isEmpty ? 0 : int.parse(fracPart);
    var factor = 1;
    for (var i = 0; i < decimalDigits; i++) {
      factor *= 10;
    }
    final value = whole * factor + frac;
    if (value > kMaxMinorAmount) {
      throw const MoneyFormatException(MoneyParseError.tooLarge);
    }
    if (!allowZero && value == 0) {
      throw const MoneyFormatException(MoneyParseError.invalid);
    }
    return negative ? -value : value;
  }

  /// Like [parse] but returns `null` instead of throwing.
  static int? tryParse(
    String input, {
    int decimalDigits = 2,
    bool allowNegative = false,
  }) {
    try {
      return parse(
        input,
        decimalDigits: decimalDigits,
        allowNegative: allowNegative,
      );
    } on MoneyFormatException {
      return null;
    }
  }

  /// Formats [minor] units as a plain decimal string with grouping, e.g.
  /// `125050` -> `1,250.50`.
  static String formatPlain(
    int minor, {
    int decimalDigits = 2,
    bool grouping = true,
    bool trimZeroFraction = false,
  }) {
    final negative = minor < 0;
    // Work on the absolute value; int.abs() of min int is not an issue here
    // because amounts are bounded by kMaxMinorAmount sums.
    final absValue = minor.abs();
    var factor = 1;
    for (var i = 0; i < decimalDigits; i++) {
      factor *= 10;
    }
    final whole = absValue ~/ factor;
    final frac = absValue % factor;
    final wholeText = grouping ? _group(whole.toString()) : whole.toString();
    final buffer = StringBuffer();
    if (negative) buffer.write('-');
    buffer.write(wholeText);
    if (decimalDigits > 0 && !(trimZeroFraction && frac == 0)) {
      buffer
        ..write('.')
        ..write(frac.toString().padLeft(decimalDigits, '0'));
    }
    return buffer.toString();
  }

  /// Formats [minor] with the currency symbol, e.g. `Rs 1,250.50`.
  static String format(
    int minor,
    Currency currency, {
    bool showSign = false,
    bool compact = false,
  }) {
    final negative = minor < 0;
    String number;
    if (compact && minor.abs() >= 100000 * currency.minorPerMajor) {
      number = _compact(minor.abs(), currency);
    } else {
      number = formatPlain(
        minor.abs(),
        decimalDigits: currency.decimalDigits,
      );
    }
    final sign = negative ? '-' : (showSign && minor > 0 ? '+' : '');
    return '$sign${currency.symbol} $number';
  }

  /// Formats an amount for text fields (no grouping, no symbol).
  static String formatForInput(int minor, {int decimalDigits = 2}) {
    return formatPlain(
      minor,
      decimalDigits: decimalDigits,
      grouping: false,
      trimZeroFraction: true,
    );
  }

  static String _compact(int absMinor, Currency currency) {
    final major = absMinor ~/ currency.minorPerMajor;
    // Integer based compact formatting with one decimal: 1.2M, 350.5K.
    if (major >= 1000000) {
      final tenths = (major * 10) ~/ 1000000;
      return '${tenths ~/ 10}.${tenths % 10}M';
    }
    final tenths = (major * 10) ~/ 1000;
    return '${tenths ~/ 10}.${tenths % 10}K';
  }

  static String _group(String digits) {
    final buffer = StringBuffer();
    final len = digits.length;
    for (var i = 0; i < len; i++) {
      buffer.write(digits[i]);
      final remaining = len - i - 1;
      if (remaining > 0 && remaining % 3 == 0) buffer.write(',');
    }
    return buffer.toString();
  }

  /// Percentage (0..n) of [part] relative to [whole] with integer arithmetic,
  /// rounded half up. Returns 0 when [whole] is not positive.
  static int percent(int part, int whole) {
    if (whole <= 0) return 0;
    return ((part * 100) + (whole ~/ 2)) ~/ whole;
  }

  /// Multiplies a minor unit price by a quantity expressed in thousandths
  /// (e.g. 1.5 kg -> 1500) using integer arithmetic, rounding half up.
  static int multiplyByMilli(int minor, int quantityMilli) {
    final product = minor * quantityMilli;
    return (product + 500) ~/ 1000;
  }
}

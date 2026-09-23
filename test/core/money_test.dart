import 'package:dawasa/core/money/currency.dart';
import 'package:dawasa/core/money/money.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Money.parse', () {
    test('parses plain and grouped amounts into minor units', () {
      expect(Money.parse('1250'), 125000);
      expect(Money.parse('1,250.50'), 125050);
      expect(Money.parse('1 250.5'), 125050);
      expect(Money.parse('0.01'), 1);
      expect(Money.parse('.5'), 50);
      expect(Money.parse('Rs 99.99'), 9999);
      expect(Money.parse('රු. 10'), 1000);
    });

    test('avoids floating point rounding (0.1 + 0.2 style errors)', () {
      final a = Money.parse('0.10');
      final b = Money.parse('0.20');
      expect(a + b, Money.parse('0.30'));
      // 1.005 is not representable exactly as a double; integer parsing is.
      expect(Money.parse('1.00'), 100);
      expect(Money.parse('19.99') * 3, 5997);
    });

    test(
      'accepts trailing zeros beyond precision but rejects extra digits',
      () {
        expect(Money.parse('10.500'), 1050);
        expect(
          () => Money.parse('10.555'),
          throwsA(
            isA<MoneyFormatException>().having(
              (e) => e.reason,
              'reason',
              MoneyParseError.tooManyDecimals,
            ),
          ),
        );
      },
    );

    test('rejects invalid, negative and oversized input', () {
      expect(() => Money.parse(''), throwsA(isA<MoneyFormatException>()));
      expect(() => Money.parse('abc'), throwsA(isA<MoneyFormatException>()));
      expect(() => Money.parse('1.2.3'), throwsA(isA<MoneyFormatException>()));
      expect(() => Money.parse('-5'), throwsA(isA<MoneyFormatException>()));
      expect(
        () => Money.parse('10000000000000'),
        throwsA(isA<MoneyFormatException>()),
      );
      expect(Money.parse('-5', allowNegative: true), -500);
    });

    test('supports zero-decimal currencies', () {
      expect(Money.parse('1500', decimalDigits: 0), 1500);
      expect(
        () => Money.parse('15.5', decimalDigits: 0),
        throwsA(isA<MoneyFormatException>()),
      );
    });
  });

  group('Money.format', () {
    test('formats with grouping and currency symbol', () {
      expect(Money.formatPlain(125050), '1,250.50');
      expect(Money.formatPlain(-99), '-0.99');
      expect(Money.formatPlain(100000000), '1,000,000.00');
      expect(Money.format(125050, Currencies.lkr), 'Rs 1,250.50');
      expect(Money.format(-500, Currencies.lkr), '-Rs 5.00');
      expect(Money.format(500, Currencies.lkr, showSign: true), '+Rs 5.00');
      expect(Money.format(1500, Currencies.jpy), '¥ 1,500');
    });

    test('compact format for large values', () {
      expect(Money.format(150000000, Currencies.lkr, compact: true), 'Rs 1.5M');
      expect(
        Money.format(35050000, Currencies.lkr, compact: true),
        'Rs 350.5K',
      );
    });

    test('input format round-trips', () {
      for (final v in [0, 1, 50, 100, 125050, 99999999]) {
        expect(Money.parse(Money.formatForInput(v)), v);
      }
    });
  });

  test('percent and quantity helpers use integer arithmetic', () {
    expect(Money.percent(50, 200), 25);
    expect(Money.percent(1, 3), 33);
    expect(Money.percent(2, 3), 67);
    expect(Money.percent(5, 0), 0);
    expect(Money.multiplyByMilli(25000, 1500), 37500);
    expect(Money.multiplyByMilli(333, 3333), 1110);
  });
}

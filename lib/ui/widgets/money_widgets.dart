import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/l10n.dart';
import '../../core/money/currency.dart';
import '../../core/money/money.dart';
import '../../core/providers.dart';
import '../theme/app_colors.dart';

/// Displays an amount in the user's currency. When [sensitive] is true the
/// value is masked while "hide balances" is active.
class MoneyText extends ConsumerWidget {
  const MoneyText(
    this.minor, {
    super.key,
    this.currency,
    this.style,
    this.color,
    this.showSign = false,
    this.sensitive = true,
    this.compact = false,
    this.textAlign,
  });

  final int minor;
  final Currency? currency;
  final TextStyle? style;
  final Color? color;
  final bool showSign;
  final bool sensitive;
  final bool compact;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hidden = sensitive && ref.watch(balancesHiddenProvider);
    final Currency cur = currency ?? ref.watch(currencyProvider);
    final text = hidden
        ? '${cur.symbol} ••••••'
        : Money.format(minor, cur, showSign: showSign, compact: compact);
    return Semantics(
      label: hidden ? context.l10n.hiddenAmount : null,
      excludeSemantics: hidden,
      child: Text(
        text,
        style: (style ?? context.textTheme.bodyLarge)?.copyWith(
          color: color,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
        textAlign: textAlign,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

/// Text field for entering money. Parses with integer arithmetic only.
class MoneyField extends StatelessWidget {
  const MoneyField({
    super.key,
    required this.controller,
    required this.currency,
    this.label,
    this.helperText,
    this.required = true,
    this.allowZero = false,
    this.allowNegative = false,
    this.autofocus = false,
    this.onChanged,
    this.textInputAction,
    this.large = false,
  });

  final TextEditingController controller;
  final Currency currency;
  final String? label;
  final String? helperText;
  final bool required;
  final bool allowZero;
  final bool allowNegative;
  final bool autofocus;
  final ValueChanged<String>? onChanged;
  final TextInputAction? textInputAction;
  final bool large;

  /// Validates [text]; returns an error message or null.
  static String? validate(
    AppLocalizations l10n,
    String? text, {
    required Currency currency,
    bool required = true,
    bool allowZero = false,
    bool allowNegative = false,
  }) {
    if (text == null || text.trim().isEmpty) {
      return required ? l10n.validationRequired : null;
    }
    try {
      final value = Money.parse(
        text,
        decimalDigits: currency.decimalDigits,
        allowNegative: allowNegative,
      );
      if (!allowZero && value == 0) return l10n.validationAmountPositive;
      return null;
    } on MoneyFormatException catch (e) {
      return switch (e.reason) {
        MoneyParseError.tooLarge => l10n.validationAmountTooLarge,
        MoneyParseError.tooManyDecimals => l10n.validationTooManyDecimals,
        MoneyParseError.negative => l10n.validationAmountPositive,
        _ => l10n.validationAmountInvalid,
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return TextFormField(
      controller: controller,
      autofocus: autofocus,
      keyboardType: TextInputType.numberWithOptions(
        decimal: currency.decimalDigits > 0,
        signed: allowNegative,
      ),
      textInputAction: textInputAction,
      inputFormatters: [
        FilteringTextInputFormatter.allow(
          RegExp(allowNegative ? r'[0-9.,\-]' : r'[0-9.,]'),
        ),
        LengthLimitingTextInputFormatter(20),
      ],
      style: large
          ? context.textTheme.headlineSmall?.copyWith(
              fontFeatures: const [FontFeature.tabularFigures()],
            )
          : null,
      decoration: InputDecoration(
        labelText: label ?? l10n.commonAmount,
        helperText: helperText,
        helperMaxLines: 3,
        prefixText: '${currency.symbol} ',
      ),
      onChanged: onChanged,
      validator: (text) => validate(
        l10n,
        text,
        currency: currency,
        required: required,
        allowZero: allowZero,
        allowNegative: allowNegative,
      ),
    );
  }
}

/// Parses a [MoneyField] value (after validation) into minor units.
int? parseMoneyField(
  String text,
  Currency currency, {
  bool allowNegative = false,
}) {
  if (text.trim().isEmpty) return null;
  return Money.tryParse(
    text,
    decimalDigits: currency.decimalDigits,
    allowNegative: allowNegative,
  );
}

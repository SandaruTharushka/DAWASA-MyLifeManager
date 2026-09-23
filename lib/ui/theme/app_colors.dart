import 'package:flutter/material.dart';

/// Brand palette of DAWASA.
abstract final class AppPalette {
  static const green = Color(0xFF16A34A);
  static const darkGreen = Color(0xFF15803D);
  static const lightGreen = Color(0xFFDCFCE7);
  static const background = Color(0xFFF8FAFC);
  static const card = Color(0xFFFFFFFF);
  static const text = Color(0xFF0F172A);
  static const textMuted = Color(0xFF64748B);
  static const border = Color(0xFFE2E8F0);

  static const darkBackground = Color(0xFF0B1220);
  static const darkCard = Color(0xFF131C2E);
  static const darkText = Color(0xFFE2E8F0);
  static const darkTextMuted = Color(0xFF94A3B8);
  static const darkBorder = Color(0xFF1E293B);

  static const expense = Color(0xFFDC2626);
  static const income = Color(0xFF16A34A);
  static const transfer = Color(0xFF2563EB);
  static const warning = Color(0xFFD97706);
  static const neutral = Color(0xFF64748B);
}

/// Semantic colours exposed through the theme so that widgets never
/// hard-code "red for expenses" etc.
@immutable
class AppSemanticColors extends ThemeExtension<AppSemanticColors> {
  const AppSemanticColors({
    required this.income,
    required this.incomeContainer,
    required this.expense,
    required this.expenseContainer,
    required this.transfer,
    required this.transferContainer,
    required this.warning,
    required this.warningContainer,
    required this.success,
    required this.successContainer,
    required this.neutral,
    required this.mutedText,
    required this.cardBorder,
  });

  static const light = AppSemanticColors(
    income: Color(0xFF15803D),
    incomeContainer: Color(0xFFDCFCE7),
    expense: Color(0xFFDC2626),
    expenseContainer: Color(0xFFFEE2E2),
    transfer: Color(0xFF2563EB),
    transferContainer: Color(0xFFDBEAFE),
    warning: Color(0xFFB45309),
    warningContainer: Color(0xFFFEF3C7),
    success: Color(0xFF15803D),
    successContainer: Color(0xFFDCFCE7),
    neutral: Color(0xFF475569),
    mutedText: AppPalette.textMuted,
    cardBorder: AppPalette.border,
  );

  static const dark = AppSemanticColors(
    income: Color(0xFF4ADE80),
    incomeContainer: Color(0xFF14532D),
    expense: Color(0xFFF87171),
    expenseContainer: Color(0xFF7F1D1D),
    transfer: Color(0xFF60A5FA),
    transferContainer: Color(0xFF1E3A8A),
    warning: Color(0xFFFBBF24),
    warningContainer: Color(0xFF78350F),
    success: Color(0xFF4ADE80),
    successContainer: Color(0xFF14532D),
    neutral: Color(0xFF94A3B8),
    mutedText: AppPalette.darkTextMuted,
    cardBorder: AppPalette.darkBorder,
  );

  final Color income;
  final Color incomeContainer;
  final Color expense;
  final Color expenseContainer;
  final Color transfer;
  final Color transferContainer;
  final Color warning;
  final Color warningContainer;
  final Color success;
  final Color successContainer;
  final Color neutral;
  final Color mutedText;
  final Color cardBorder;

  @override
  AppSemanticColors copyWith({
    Color? income,
    Color? incomeContainer,
    Color? expense,
    Color? expenseContainer,
    Color? transfer,
    Color? transferContainer,
    Color? warning,
    Color? warningContainer,
    Color? success,
    Color? successContainer,
    Color? neutral,
    Color? mutedText,
    Color? cardBorder,
  }) {
    return AppSemanticColors(
      income: income ?? this.income,
      incomeContainer: incomeContainer ?? this.incomeContainer,
      expense: expense ?? this.expense,
      expenseContainer: expenseContainer ?? this.expenseContainer,
      transfer: transfer ?? this.transfer,
      transferContainer: transferContainer ?? this.transferContainer,
      warning: warning ?? this.warning,
      warningContainer: warningContainer ?? this.warningContainer,
      success: success ?? this.success,
      successContainer: successContainer ?? this.successContainer,
      neutral: neutral ?? this.neutral,
      mutedText: mutedText ?? this.mutedText,
      cardBorder: cardBorder ?? this.cardBorder,
    );
  }

  @override
  AppSemanticColors lerp(AppSemanticColors? other, double t) {
    if (other == null) return this;
    return AppSemanticColors(
      income: Color.lerp(income, other.income, t)!,
      incomeContainer: Color.lerp(incomeContainer, other.incomeContainer, t)!,
      expense: Color.lerp(expense, other.expense, t)!,
      expenseContainer: Color.lerp(
        expenseContainer,
        other.expenseContainer,
        t,
      )!,
      transfer: Color.lerp(transfer, other.transfer, t)!,
      transferContainer: Color.lerp(
        transferContainer,
        other.transferContainer,
        t,
      )!,
      warning: Color.lerp(warning, other.warning, t)!,
      warningContainer: Color.lerp(
        warningContainer,
        other.warningContainer,
        t,
      )!,
      success: Color.lerp(success, other.success, t)!,
      successContainer: Color.lerp(
        successContainer,
        other.successContainer,
        t,
      )!,
      neutral: Color.lerp(neutral, other.neutral, t)!,
      mutedText: Color.lerp(mutedText, other.mutedText, t)!,
      cardBorder: Color.lerp(cardBorder, other.cardBorder, t)!,
    );
  }
}

extension AppThemeX on BuildContext {
  AppSemanticColors get semantic =>
      Theme.of(this).extension<AppSemanticColors>() ?? AppSemanticColors.light;
  ColorScheme get colors => Theme.of(this).colorScheme;
  TextTheme get textTheme => Theme.of(this).textTheme;
}

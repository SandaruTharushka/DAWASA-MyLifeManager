import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/routes.dart';
import '../../core/l10n/l10n.dart';
import '../../core/money/currency.dart';
import '../../core/notifications/notification_providers.dart';
import '../../core/providers.dart';
import '../../ui/theme/app_colors.dart';
import '../../ui/theme/app_theme.dart';
import '../../ui/widgets/brand.dart';
import '../../ui/widgets/common.dart';
import '../../ui/widgets/form_widgets.dart';
import '../../ui/widgets/money_widgets.dart';
import '../accounts/presentation/account_providers.dart';
import 'onboarding_service.dart';

final onboardingServiceProvider = Provider<OnboardingService>(
  (ref) => OnboardingService(
    accounts: ref.watch(accountRepositoryProvider),
    settingsRepository: ref.watch(userSettingsRepositoryProvider),
  ),
);

final _hasAccountsProvider = FutureProvider.autoDispose<bool>(
  (ref) => ref.watch(onboardingServiceProvider).hasAccounts(),
);

enum _Step { welcome, language, currency, balances, budget, reminders }

/// First-launch guide: welcome, language, currency, opening balances,
/// daily budget and optional reminder permission.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pageController = PageController();
  final _balancesForm = GlobalKey<FormState>();
  final _budgetForm = GlobalKey<FormState>();
  final _cash = TextEditingController();
  final _bank = TextEditingController();
  final _wallet = TextEditingController();
  final _budget = TextEditingController();
  int _index = 0;
  late String _currencyCode = ref.read(userSettingsProvider).currencyCode;
  bool? _remindersGranted;

  List<_Step> _steps(bool hasAccounts) => [
    _Step.welcome,
    _Step.language,
    _Step.currency,
    if (!hasAccounts) _Step.balances,
    _Step.budget,
    _Step.reminders,
  ];

  @override
  void dispose() {
    _pageController.dispose();
    _cash.dispose();
    _bank.dispose();
    _wallet.dispose();
    _budget.dispose();
    super.dispose();
  }

  Currency get _currency => Currencies.byCode(_currencyCode);

  Future<void> _next(List<_Step> steps) async {
    final step = steps[_index];
    if (step == _Step.balances &&
        !(_balancesForm.currentState?.validate() ?? true)) {
      return;
    }
    if (step == _Step.budget &&
        !(_budgetForm.currentState?.validate() ?? true)) {
      return;
    }
    if (_index == steps.length - 1) {
      await _finish();
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() => _index++);
    await _pageController.animateToPage(
      _index,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _back() async {
    if (_index == 0) return;
    setState(() => _index--);
    await _pageController.animateToPage(
      _index,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _finish() async {
    final l10n = context.l10n;
    final language = ref.read(localeNameProvider);
    final result = OnboardingResult(
      languageCode: language,
      currencyCode: _currencyCode,
      cashMinor: parseMoneyField(_cash.text, _currency),
      bankMinor: parseMoneyField(_bank.text, _currency),
      walletMinor: parseMoneyField(_wallet.text, _currency),
      dailyBudgetMinor: parseMoneyField(_budget.text, _currency),
      cashName: l10n.accountDefaultCash,
      bankName: l10n.accountDefaultBank,
      walletName: l10n.accountDefaultWallet,
    );
    final outcome = await ref
        .read(onboardingServiceProvider)
        .complete(
          result,
          ref.read(userSettingsProvider),
          ref.read(todayProvider),
        );
    await ref
        .read(userSettingsProvider.notifier)
        .update((_) => outcome.settings);
    await ref.read(preferencesProvider.notifier).update(outcome.prefs);
  }

  Future<void> _requestReminders() async {
    final granted = await ref
        .read(notificationGatewayProvider)
        .requestPermission();
    await ref
        .read(preferencesProvider.notifier)
        .update((p) => p.copyWith(notificationsEnabled: granted));
    if (mounted) setState(() => _remindersGranted = granted);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final hasAccounts = ref.watch(_hasAccountsProvider).value;
    if (hasAccounts == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final steps = _steps(hasAccounts);
    final isLast = _index == steps.length - 1;
    final optionalStep =
        steps[_index] == _Step.balances ||
        steps[_index] == _Step.budget ||
        steps[_index] == _Step.reminders;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(Gap.sm, Gap.sm, Gap.lg, 0),
              child: Row(
                children: [
                  IconButton(
                    tooltip: l10n.actionBack,
                    onPressed: _index == 0 ? null : _back,
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
                  Expanded(
                    child: Semantics(
                      label: l10n.onbStepOf(_index + 1, steps.length),
                      child: ExcludeSemantics(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: (_index + 1) / steps.length,
                            minHeight: 6,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  for (final step in steps)
                    switch (step) {
                      _Step.welcome => const _WelcomePage(),
                      _Step.language => const _LanguagePage(),
                      _Step.currency => _CurrencyPage(
                        selected: _currencyCode,
                        onSelected: (c) => setState(() => _currencyCode = c),
                      ),
                      _Step.balances => _BalancesPage(
                        formKey: _balancesForm,
                        currency: _currency,
                        cash: _cash,
                        bank: _bank,
                        wallet: _wallet,
                      ),
                      _Step.budget => _BudgetPage(
                        formKey: _budgetForm,
                        currency: _currency,
                        controller: _budget,
                      ),
                      _Step.reminders => _RemindersPage(
                        granted: _remindersGranted,
                        onRequest: _requestReminders,
                      ),
                    },
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(Gap.xl, 0, Gap.xl, Gap.lg),
              child: Column(
                children: [
                  SubmitButton(
                    label: isLast
                        ? l10n.onbFinish
                        : _index == 0
                        ? l10n.actionGetStarted
                        : l10n.actionContinue,
                    onSubmit: () => _next(steps),
                  ),
                  if (optionalStep && !isLast)
                    TextButton(
                      onPressed: () {
                        if (steps[_index] == _Step.balances) {
                          _cash.clear();
                          _bank.clear();
                          _wallet.clear();
                        } else if (steps[_index] == _Step.budget) {
                          _budget.clear();
                        }
                        _next(steps);
                      },
                      child: Text(l10n.actionSkip),
                    )
                  else if (_index == 0)
                    TextButton.icon(
                      icon: const Icon(Icons.settings_backup_restore_rounded),
                      label: Text(l10n.onbRestoreBackup),
                      onPressed: () => context.push(Routes.restore),
                    )
                  else
                    const SizedBox(height: 48),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepScaffold extends StatelessWidget {
  const _StepScaffold({
    required this.title,
    required this.body,
    required this.children,
    this.icon,
  });

  final String title;
  final String body;
  final IconData? icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(Gap.xl, Gap.xl, Gap.xl, Gap.xl),
      children: [
        if (icon != null) ...[
          Align(
            alignment: Alignment.centerLeft,
            child: IconBadge(
              icon: icon!,
              color: context.colors.primary,
              size: 56,
            ),
          ),
          const SizedBox(height: Gap.lg),
        ],
        Semantics(
          header: true,
          child: Text(title, style: context.textTheme.headlineSmall),
        ),
        const SizedBox(height: Gap.sm),
        Text(
          body,
          style: context.textTheme.bodyLarge?.copyWith(
            color: context.colors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: Gap.xl),
        ...children,
      ],
    );
  }
}

class _WelcomePage extends StatelessWidget {
  const _WelcomePage();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    Widget point(IconData icon, String text) => Padding(
      padding: const EdgeInsets.only(bottom: Gap.md),
      child: Row(
        children: [
          IconBadge(icon: icon, color: context.colors.primary, size: 40),
          const SizedBox(width: Gap.md),
          Expanded(child: Text(text, style: context.textTheme.bodyLarge)),
        ],
      ),
    );
    return ListView(
      padding: const EdgeInsets.all(Gap.xl),
      children: [
        const SizedBox(height: Gap.lg),
        const Center(child: DawasaLogo(size: 96)),
        const SizedBox(height: Gap.xl),
        Text(
          l10n.onbWelcomeTitle,
          style: context.textTheme.headlineMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: Gap.sm),
        Text(
          l10n.appTagline,
          style: context.textTheme.titleMedium?.copyWith(
            color: context.colors.primary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: Gap.md),
        Text(
          l10n.onbWelcomeBody,
          style: context.textTheme.bodyLarge?.copyWith(
            color: context.colors.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: Gap.xl),
        point(Icons.volunteer_activism_rounded, l10n.onbPointFree),
        point(Icons.cloud_off_rounded, l10n.onbPointOffline),
        point(Icons.lock_rounded, l10n.onbPointPrivate),
        point(Icons.person_off_rounded, l10n.onbPointNoLogin),
      ],
    );
  }
}

class _LanguagePage extends ConsumerWidget {
  const _LanguagePage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final selected = ref.watch(localeNameProvider);
    Future<void> select(String code) => ref
        .read(preferencesProvider.notifier)
        .update((p) => p.copyWith(languageCode: code));
    return _StepScaffold(
      icon: Icons.translate_rounded,
      title: l10n.onbLanguageTitle,
      body: l10n.onbLanguageBody,
      children: [
        ChoiceTile(
          title: 'සිංහල',
          subtitle: 'Sinhala',
          selected: selected == 'si',
          onTap: () => select('si'),
        ),
        ChoiceTile(
          title: 'English',
          subtitle: 'ඉංග්‍රීසි',
          selected: selected == 'en',
          onTap: () => select('en'),
        ),
      ],
    );
  }
}

class _CurrencyPage extends ConsumerWidget {
  const _CurrencyPage({required this.selected, required this.onSelected});

  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final isSinhala = ref.watch(localeNameProvider) == 'si';
    return _StepScaffold(
      icon: Icons.payments_rounded,
      title: l10n.onbCurrencyTitle,
      body: l10n.onbCurrencyBody,
      children: [
        for (final c in Currencies.all)
          ChoiceTile(
            title: '${c.code} · ${c.symbol}',
            subtitle: isSinhala ? c.nameSi : c.nameEn,
            selected: selected == c.code,
            onTap: () => onSelected(c.code),
          ),
      ],
    );
  }
}

class _BalancesPage extends StatelessWidget {
  const _BalancesPage({
    required this.formKey,
    required this.currency,
    required this.cash,
    required this.bank,
    required this.wallet,
  });

  final GlobalKey<FormState> formKey;
  final Currency currency;
  final TextEditingController cash;
  final TextEditingController bank;
  final TextEditingController wallet;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Form(
      key: formKey,
      child: _StepScaffold(
        icon: Icons.account_balance_wallet_rounded,
        title: l10n.onbBalancesTitle,
        body: l10n.onbBalancesBody,
        children: [
          MoneyField(
            controller: cash,
            currency: currency,
            label: l10n.onbCashBalance,
            required: false,
            allowZero: true,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: Gap.md),
          MoneyField(
            controller: bank,
            currency: currency,
            label: l10n.onbBankBalance,
            required: false,
            allowZero: true,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: Gap.md),
          MoneyField(
            controller: wallet,
            currency: currency,
            label: l10n.onbWalletBalance,
            required: false,
            allowZero: true,
            textInputAction: TextInputAction.done,
          ),
        ],
      ),
    );
  }
}

class _BudgetPage extends StatelessWidget {
  const _BudgetPage({
    required this.formKey,
    required this.currency,
    required this.controller,
  });

  final GlobalKey<FormState> formKey;
  final Currency currency;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Form(
      key: formKey,
      child: _StepScaffold(
        icon: Icons.savings_rounded,
        title: l10n.onbBudgetTitle,
        body: l10n.onbBudgetBody,
        children: [
          MoneyField(
            controller: controller,
            currency: currency,
            label: l10n.onbBudgetLabel,
            required: false,
            large: true,
          ),
        ],
      ),
    );
  }
}

class _RemindersPage extends StatelessWidget {
  const _RemindersPage({required this.granted, required this.onRequest});

  final bool? granted;
  final Future<void> Function() onRequest;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return _StepScaffold(
      icon: Icons.notifications_active_rounded,
      title: l10n.onbRemindersTitle,
      body: l10n.onbRemindersBody,
      children: [
        if (granted == null)
          SubmitButton(
            label: l10n.onbEnableReminders,
            icon: Icons.notifications_rounded,
            tonal: true,
            onSubmit: onRequest,
          )
        else
          AppCard(
            color: granted!
                ? context.semantic.successContainer
                : context.semantic.warningContainer,
            child: Row(
              children: [
                Icon(
                  granted!
                      ? Icons.check_circle_rounded
                      : Icons.info_outline_rounded,
                  color: granted!
                      ? context.semantic.success
                      : context.semantic.warning,
                ),
                const SizedBox(width: Gap.md),
                Expanded(
                  child: Text(
                    granted!
                        ? l10n.onbRemindersEnabled
                        : l10n.onbRemindersDenied,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

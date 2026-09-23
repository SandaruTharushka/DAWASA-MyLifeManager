import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/routes.dart';
import '../../core/config/app_config.dart';
import '../../core/l10n/l10n.dart';
import '../../core/money/currency.dart';
import '../../core/money/money.dart';
import '../../core/platform/app_info.dart';
import '../../core/providers.dart';
import '../../ui/format/formatters.dart';
import '../../ui/theme/app_colors.dart';
import '../../ui/theme/app_theme.dart';
import '../../ui/widgets/brand.dart';
import '../../ui/widgets/common.dart';
import '../../ui/widgets/form_widgets.dart';
import '../home/home_sections.dart';
import 'settings_sections.dart';
import 'widgets/settings_widgets.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: const PageBody(
        children: [
          _GeneralSection(),
          ...extraSettingsSections,
          _AboutSection(),
        ],
      ),
    );
  }
}

class _GeneralSection extends ConsumerWidget {
  const _GeneralSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final prefs = ref.watch(preferencesProvider);
    final settings = ref.watch(userSettingsProvider);
    final formatter = ref.watch(dateFormatterProvider);
    final today = ref.watch(todayProvider);
    final prefsCtrl = ref.read(preferencesProvider.notifier);
    final settingsCtrl = ref.read(userSettingsProvider.notifier);
    final isSinhala = ref.watch(localeNameProvider) == 'si';
    final currency = settings.currency;

    String themeLabel(ThemeMode m) => switch (m) {
      ThemeMode.system => l10n.settingsThemeSystem,
      ThemeMode.light => l10n.settingsThemeLight,
      ThemeMode.dark => l10n.settingsThemeDark,
    };

    return SettingsSection(
      title: l10n.settingsGeneral,
      children: [
        SettingsTile(
          icon: Icons.translate_rounded,
          title: l10n.settingsLanguage,
          subtitle: isSinhala ? 'සිංහල' : 'English',
          onTap: () async {
            final code = await showOptionsSheet<String>(
              context,
              title: l10n.settingsLanguage,
              selected: ref.read(localeNameProvider),
              options: const [('si', 'සිංහල'), ('en', 'English')],
            );
            if (code != null) {
              await prefsCtrl.update((p) => p.copyWith(languageCode: code));
            }
          },
        ),
        SettingsTile(
          icon: Icons.payments_outlined,
          title: l10n.settingsCurrency,
          subtitle:
              '${currency.code} · ${isSinhala ? currency.nameSi : currency.nameEn}',
          onTap: () async {
            final code = await showOptionsSheet<String>(
              context,
              title: l10n.settingsCurrency,
              selected: currency.code,
              options: [
                for (final c in Currencies.all)
                  (c.code, '${c.code} · ${isSinhala ? c.nameSi : c.nameEn}'),
              ],
            );
            if (code == null || code == currency.code) return;
            if (!context.mounted) return;
            final ok = await confirmDialog(
              context,
              title: l10n.settingsCurrency,
              message: l10n.settingsCurrencyChangeNote,
            );
            if (ok) {
              await settingsCtrl.update((s) => s.copyWith(currencyCode: code));
            }
          },
        ),
        SettingsTile(
          icon: Icons.dark_mode_outlined,
          title: l10n.settingsTheme,
          subtitle: themeLabel(prefs.themeMode),
          onTap: () async {
            final mode = await showOptionsSheet<ThemeMode>(
              context,
              title: l10n.settingsTheme,
              selected: prefs.themeMode,
              options: [for (final m in ThemeMode.values) (m, themeLabel(m))],
            );
            if (mode != null) {
              await prefsCtrl.update((p) => p.copyWith(themeMode: mode));
            }
          },
        ),
        SettingsTile(
          icon: Icons.calendar_month_outlined,
          title: l10n.settingsDateFormat,
          subtitle: formatter.date(today),
          onTap: () async {
            final format = await showOptionsSheet<DateDisplayFormat>(
              context,
              title: l10n.settingsDateFormat,
              selected: settings.dateFormat,
              options: [
                for (final f in DateDisplayFormat.values)
                  (
                    f,
                    AppDateFormatter(
                      localeName: formatter.localeName,
                      format: f,
                    ).date(today),
                  ),
              ],
            );
            if (format != null) {
              await settingsCtrl.update((s) => s.copyWith(dateFormat: format));
            }
          },
        ),
        SettingsTile(
          icon: Icons.view_week_outlined,
          title: l10n.settingsFirstDayOfWeek,
          subtitle: l10n.weekdayName(settings.firstDayOfWeek),
          onTap: () async {
            final day = await showOptionsSheet<int>(
              context,
              title: l10n.settingsFirstDayOfWeek,
              selected: settings.firstDayOfWeek,
              options: [
                for (final d in const [1, 7, 6]) (d, l10n.weekdayName(d)),
              ],
            );
            if (day != null) {
              await settingsCtrl.update((s) => s.copyWith(firstDayOfWeek: day));
            }
          },
        ),
        SettingsTile(
          icon: Icons.badge_outlined,
          title: l10n.settingsYourName,
          subtitle: settings.userName ?? l10n.settingsYourNameHint,
          onTap: () => _editName(context, ref),
        ),
        SettingsTile(
          icon: Icons.savings_outlined,
          title: l10n.settingsDailyBudget,
          subtitle: settings.dailyBudgetMinor == null
              ? l10n.commonNotSet
              : Money.format(settings.dailyBudgetMinor!, currency),
          onTap: () => editDailyBudget(context, ref),
        ),
        SettingsTile(
          icon: Icons.category_outlined,
          title: l10n.settingsCategories,
          onTap: () => context.push(Routes.categories),
        ),
      ],
    );
  }

  Future<void> _editName(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final controller = TextEditingController(
      text: ref.read(userSettingsProvider).userName ?? '',
    );
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.settingsYourName),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 30,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(helperText: l10n.settingsYourNameHint),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.actionCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: Text(l10n.actionSave),
          ),
        ],
      ),
    );
    controller.dispose();
    if (name == null) return;
    final trimmed = name.trim();
    await ref
        .read(userSettingsProvider.notifier)
        .update(
          (s) => s.copyWith(
            userName: trimmed.isEmpty ? null : trimmed,
            clearUserName: trimmed.isEmpty,
          ),
        );
  }
}

class _AboutSection extends ConsumerWidget {
  const _AboutSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final version = ref.watch(appVersionProvider).value;
    final s = context.semantic;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: l10n.settingsAbout),
        AppCard(
          child: Column(
            children: [
              Row(
                children: [
                  const DawasaLogo(size: 56),
                  const SizedBox(width: Gap.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l10n.appName, style: context.textTheme.titleLarge),
                        Text(
                          l10n.appTagline,
                          style: context.textTheme.bodySmall?.copyWith(
                            color: context.colors.onSurfaceVariant,
                          ),
                        ),
                        if (version != null)
                          Text(
                            l10n.aboutVersion(
                              version.versionName,
                              '${version.versionCode}',
                            ),
                            style: context.textTheme.bodySmall,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Gap.md),
              Wrap(
                spacing: Gap.sm,
                runSpacing: Gap.sm,
                children: [
                  for (final label in [
                    l10n.aboutFree,
                    l10n.aboutNoAds,
                    l10n.aboutNoSubscription,
                  ])
                    StatusChip(
                      label: label,
                      icon: Icons.check_rounded,
                      color: s.success,
                      background: s.successContainer,
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: Gap.md),
        AppCard(
          padding: const EdgeInsets.symmetric(vertical: Gap.xs),
          child: Column(
            children: [
              SettingsTile(
                icon: Icons.person_outline_rounded,
                title: l10n.aboutDeveloper,
                subtitle: AppConfig.developerName,
              ),
              if (AppConfig.developerWebsite.isNotEmpty)
                SettingsTile(
                  icon: Icons.language_rounded,
                  title: l10n.aboutWebsite,
                  subtitle: AppConfig.developerWebsite,
                ),
              if (AppConfig.developerEmail.isNotEmpty)
                SettingsTile(
                  icon: Icons.mail_outline_rounded,
                  title: l10n.aboutContact,
                  subtitle: AppConfig.developerEmail,
                ),
              SettingsTile(
                icon: Icons.privacy_tip_outlined,
                title: l10n.settingsPrivacyPolicy,
                onTap: () => context.push(Routes.privacy),
              ),
              SettingsTile(
                icon: Icons.slideshow_outlined,
                title: l10n.settingsReplayOnboarding,
                onTap: () => ref
                    .read(preferencesProvider.notifier)
                    .update((p) => p.copyWith(onboardingComplete: false)),
              ),
              SettingsTile(
                icon: Icons.description_outlined,
                title: l10n.settingsLicenses,
                onTap: () => showLicensePage(
                  context: context,
                  applicationName: l10n.appName,
                  applicationVersion: version?.versionName,
                  applicationLegalese: '© ${AppConfig.developerName}',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.privacyTitle)),
      body: PageBody(
        children: [
          AppCard(
            child: Text(l10n.privacyBody, style: context.textTheme.bodyLarge),
          ),
          const SizedBox(height: Gap.md),
          AppCard(
            color: context.semantic.warningContainer,
            child: Text(l10n.settingsUninstallWarning),
          ),
        ],
      ),
    );
  }
}

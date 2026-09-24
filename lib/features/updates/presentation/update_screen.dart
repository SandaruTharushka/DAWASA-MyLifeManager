import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/platform/app_info.dart';
import '../../../core/providers.dart';
import '../../../ui/theme/app_colors.dart';
import '../../../ui/theme/app_theme.dart';
import '../../../ui/widgets/common.dart';
import '../../../ui/widgets/form_widgets.dart';
import '../../backup/presentation/backup_screen.dart' show formatBytes;
import '../../settings/widgets/settings_widgets.dart';
import '../application/update_controller.dart';
import '../data/update_client.dart';
import '../domain/update_manifest.dart';

String updateFailureMessage(AppLocalizations l10n, UpdateFailure failure) =>
    switch (failure) {
      UpdateFailure.offline => l10n.updateOffline,
      UpdateFailure.server => l10n.updateServerUnavailable,
      UpdateFailure.invalidManifest => l10n.updateInvalidManifest,
      UpdateFailure.checksum => l10n.updateChecksumMismatch,
      UpdateFailure.packageMismatch => l10n.updatePackageMismatch,
      UpdateFailure.storage => l10n.updateStorageFailed,
      UpdateFailure.install => l10n.updateInstallFailed,
    };

/// Shown at the top of the home screen when a newer version is known.
class UpdateBanner extends ConsumerWidget {
  const UpdateBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(updateControllerProvider);
    if (state is! UpdateWithRelease) return const SizedBox.shrink();
    final l10n = context.l10n;
    final s = context.semantic;
    final required = state.required;
    return Padding(
      padding: const EdgeInsets.only(top: Gap.md),
      child: AppCard(
        color: required ? s.warningContainer : context.colors.primaryContainer,
        onTap: () => context.push(Routes.updates),
        child: Row(
          children: [
            Icon(
              required
                  ? Icons.warning_amber_rounded
                  : Icons.system_update_rounded,
              color: required ? s.warning : context.colors.primary,
            ),
            const SizedBox(width: Gap.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    required
                        ? l10n.updateRequired
                        : l10n.updateNewVersionBanner,
                    style: context.textTheme.titleSmall,
                  ),
                  Text(
                    l10n.updateAvailable(state.release.versionName),
                    style: context.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded),
          ],
        ),
      ),
    );
  }
}

class UpdatesSettingsSection extends ConsumerWidget {
  const UpdatesSettingsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(updateControllerProvider);
    if (state is UpdateDisabled) return const SizedBox.shrink();
    final l10n = context.l10n;
    final version = ref.watch(appVersionProvider).value;
    final prefs = ref.watch(preferencesProvider);
    final ctrl = ref.read(preferencesProvider.notifier);
    return SettingsSection(
      title: l10n.settingsUpdates,
      children: [
        SettingsTile(
          icon: Icons.system_update_outlined,
          title: l10n.updateTitle,
          subtitle: state is UpdateWithRelease
              ? l10n.updateAvailable(state.release.versionName)
              : version == null
              ? null
              : l10n.updateInstalledVersion(version.versionName),
          onTap: () => context.push(Routes.updates),
        ),
        SettingsSwitch(
          icon: Icons.update_rounded,
          title: l10n.settingsAutoCheckUpdates,
          subtitle: l10n.settingsAutoCheckUpdatesDesc,
          value: prefs.autoCheckUpdates,
          onChanged: (on) =>
              ctrl.update((p) => p.copyWith(autoCheckUpdates: on)),
        ),
        SettingsSwitch(
          icon: Icons.wifi_rounded,
          title: l10n.settingsWifiOnly,
          value: prefs.wifiOnlyUpdates,
          onChanged: (on) =>
              ctrl.update((p) => p.copyWith(wifiOnlyUpdates: on)),
        ),
      ],
    );
  }
}

class UpdateScreen extends ConsumerStatefulWidget {
  const UpdateScreen({super.key});

  @override
  ConsumerState<UpdateScreen> createState() => _UpdateScreenState();
}

class _UpdateScreenState extends ConsumerState<UpdateScreen> {
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(
      onResume: () => ref.read(updateControllerProvider.notifier).onResumed(),
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = ref.watch(updateControllerProvider);
    final version = ref.watch(appVersionProvider).value;
    final prefs = ref.watch(preferencesProvider);
    final formatter = ref.watch(dateFormatterProvider);
    final lastCheck = prefs.lastUpdateCheck;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.updateTitle)),
      body: PageBody(
        children: [
          AppCard(
            child: Row(
              children: [
                IconBadge(
                  icon: Icons.verified_user_outlined,
                  color: context.colors.primary,
                ),
                const SizedBox(width: Gap.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.settingsCurrentVersion,
                        style: context.textTheme.bodySmall,
                      ),
                      Text(
                        version == null
                            ? '…'
                            : '${version.versionName} (${version.versionCode})',
                        style: context.textTheme.titleMedium,
                      ),
                      Text(
                        lastCheck == null
                            ? l10n.updateNeverChecked
                            : l10n.updateLastChecked(
                                formatter.dateTime(lastCheck.toLocal()),
                              ),
                        style: context.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: Gap.md),
          _StatusCard(state: state),
          if (state is! UpdateDisabled) ...[
            const SizedBox(height: Gap.lg),
            const UpdateServerTile(),
          ],
          const SizedBox(height: Gap.md),
          Text(
            l10n.updatePrivacyNote,
            style: context.textTheme.bodySmall?.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusCard extends ConsumerWidget {
  const _StatusCard({required this.state});

  final UpdateState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final ctrl = ref.read(updateControllerProvider.notifier);
    final s = context.semantic;
    final language = ref.watch(localeNameProvider);

    Widget message(IconData icon, Color color, String text) => Row(
      children: [
        Icon(icon, color: color),
        const SizedBox(width: Gap.md),
        Expanded(child: Text(text, style: context.textTheme.titleSmall)),
      ],
    );

    Widget progress(String text, {double? value}) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(text, style: context.textTheme.titleSmall),
        const SizedBox(height: Gap.sm),
        LinearProgressIndicator(value: value),
      ],
    );

    final checkButton = SubmitButton(
      icon: Icons.refresh_rounded,
      label: l10n.settingsCheckUpdates,
      tonal: true,
      onSubmit: ctrl.check,
    );

    final children = <Widget>[
      switch (state) {
        UpdateDisabled() => message(
          Icons.storefront_outlined,
          context.colors.primary,
          l10n.updateDisabledStore,
        ),
        UpdateNotConfigured() => message(
          Icons.link_off_rounded,
          context.colors.onSurfaceVariant,
          l10n.updateNotConfiguredBody,
        ),
        UpdateIdle() => checkButton,
        UpdateChecking() => progress(l10n.updateChecking),
        UpdateOffline() => message(
          Icons.cloud_off_rounded,
          context.colors.onSurfaceVariant,
          l10n.updateOffline,
        ),
        UpdateUpToDate() => message(
          Icons.check_circle_rounded,
          s.success,
          l10n.updateUpToDate,
        ),
        UpdateFailed(:final failure) => message(
          Icons.error_outline_rounded,
          context.colors.error,
          updateFailureMessage(l10n, failure),
        ),
        UpdateWithRelease() => _ReleaseDetails(
          release: (state as UpdateWithRelease).release,
          required: (state as UpdateWithRelease).required,
          language: language,
        ),
      },
    ];

    switch (state) {
      case UpdateOffline() || UpdateUpToDate():
        children.addAll([const SizedBox(height: Gap.md), checkButton]);
      case UpdateFailed(:final release):
        children.addAll([
          const SizedBox(height: Gap.md),
          SubmitButton(
            icon: Icons.refresh_rounded,
            label: l10n.actionRetry,
            onSubmit: release == null ? ctrl.check : ctrl.download,
          ),
        ]);
      case UpdateAvailable():
        children.addAll([
          const SizedBox(height: Gap.md),
          SubmitButton(
            key: const ValueKey('update-now'),
            icon: Icons.download_rounded,
            label: l10n.updateNow,
            onSubmit: ctrl.download,
          ),
        ]);
      case UpdateWifiRequired():
        children.addAll([
          const SizedBox(height: Gap.md),
          Text(l10n.updateWifiOnlyBlocked),
          const SizedBox(height: Gap.sm),
          SubmitButton(
            icon: Icons.signal_cellular_alt_rounded,
            label: l10n.updateDownloadAnyway,
            onSubmit: () => ctrl.download(allowMobileData: true),
          ),
        ]);
      case UpdateDownloading(
        :final received,
        :final total,
        :final fraction,
        :final percent,
      ):
        children.addAll([
          const SizedBox(height: Gap.md),
          progress(l10n.updateDownloading(percent), value: fraction),
          const SizedBox(height: Gap.xs),
          Text(
            l10n.updateProgressBytes(formatBytes(received), formatBytes(total)),
            style: context.textTheme.bodySmall,
          ),
          const SizedBox(height: Gap.sm),
          OutlinedButton.icon(
            icon: const Icon(Icons.close_rounded),
            label: Text(l10n.updateCancelDownload),
            onPressed: ctrl.cancelDownload,
          ),
        ]);
      case UpdateDownloadCancelled():
        children.addAll([
          const SizedBox(height: Gap.md),
          Text(l10n.updateDownloadPaused),
          const SizedBox(height: Gap.sm),
          SubmitButton(
            icon: Icons.play_arrow_rounded,
            label: l10n.updateResume,
            onSubmit: ctrl.download,
          ),
        ]);
      case UpdateVerifying():
        children.addAll([
          const SizedBox(height: Gap.md),
          progress(l10n.updateVerifying),
        ]);
      case UpdateReady(:final installCancelled):
        children.addAll([
          const SizedBox(height: Gap.md),
          message(Icons.verified_rounded, s.success, l10n.updateReady),
          const SizedBox(height: Gap.xs),
          Text(l10n.updateVerifiedNote, style: context.textTheme.bodySmall),
          if (installCancelled) ...[
            const SizedBox(height: Gap.xs),
            Text(
              l10n.updateInstallCancelled,
              style: TextStyle(color: s.warning),
            ),
          ],
          const SizedBox(height: Gap.md),
          SubmitButton(
            key: const ValueKey('update-install'),
            icon: Icons.install_mobile_rounded,
            label: l10n.updateInstall,
            onSubmit: ctrl.install,
          ),
          const SizedBox(height: Gap.xs),
          Text(l10n.updateInstallHint, style: context.textTheme.bodySmall),
        ]);
      case UpdateNeedsPermission():
        children.addAll([
          const SizedBox(height: Gap.md),
          Text(l10n.updatePermissionTitle, style: context.textTheme.titleSmall),
          const SizedBox(height: Gap.xs),
          Text(l10n.updatePermissionBody),
          const SizedBox(height: Gap.md),
          SubmitButton(
            icon: Icons.settings_outlined,
            label: l10n.actionOpenSettings,
            onSubmit: ctrl.openInstallPermissionSettings,
          ),
        ]);
      case UpdateInstalling():
        children.addAll([
          const SizedBox(height: Gap.md),
          progress(l10n.updateInstalling),
        ]);
      case UpdateDisabled() ||
          UpdateNotConfigured() ||
          UpdateIdle() ||
          UpdateChecking():
        break;
    }

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }
}

class _ReleaseDetails extends StatelessWidget {
  const _ReleaseDetails({
    required this.release,
    required this.required,
    required this.language,
  });

  final UpdateRelease release;
  final bool required;
  final String language;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final notes = release.notesFor(language);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.new_releases_outlined, color: context.colors.primary),
            const SizedBox(width: Gap.md),
            Expanded(
              child: Text(
                l10n.updateAvailable(release.versionName),
                style: context.textTheme.titleMedium,
              ),
            ),
          ],
        ),
        if (required) ...[
          const SizedBox(height: Gap.sm),
          Text(
            l10n.updateRequired,
            style: TextStyle(color: context.semantic.warning),
          ),
        ],
        const SizedBox(height: Gap.sm),
        Text(
          l10n.updateSize(formatBytes(release.sizeBytes)),
          style: context.textTheme.bodySmall,
        ),
        if (notes != null) ...[
          const SizedBox(height: Gap.md),
          Text(l10n.updateWhatsNew, style: context.textTheme.titleSmall),
          const SizedBox(height: Gap.xs),
          Text(notes),
        ],
        const SizedBox(height: Gap.sm),
        Text(
          l10n.updateDataSafe,
          style: context.textTheme.bodySmall?.copyWith(
            color: context.semantic.success,
          ),
        ),
      ],
    );
  }
}

/// Lets the user enter their own update folder address (HTTPS only).
class UpdateServerTile extends ConsumerWidget {
  const UpdateServerTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final custom = ref.watch(
      preferencesProvider.select((p) => p.customUpdateUrl),
    );
    final defaultUrl = ref.watch(updateConfigProvider).defaultBaseUrl;
    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: Gap.xs),
      child: SettingsTile(
        icon: Icons.dns_outlined,
        title: l10n.settingsUpdateServer,
        subtitle:
            custom ?? (defaultUrl.isEmpty ? l10n.commonNotSet : defaultUrl),
        onTap: () => _edit(context, ref, custom ?? defaultUrl),
      ),
    );
  }

  Future<void> _edit(
    BuildContext context,
    WidgetRef ref,
    String current,
  ) async {
    final l10n = context.l10n;
    final result = await showDialog<(String?,)>(
      context: context,
      builder: (context) => _ServerDialog(initial: current),
    );
    if (result == null) return;
    final (url,) = result;
    await ref
        .read(preferencesProvider.notifier)
        .update(
          (p) => url == null
              ? p.copyWith(clearCustomUpdateUrl: true)
              : p.copyWith(customUpdateUrl: url),
        );
    if (context.mounted) showAppSnackBar(context, l10n.commonSaved);
  }
}

class _ServerDialog extends ConsumerStatefulWidget {
  const _ServerDialog({required this.initial});

  final String initial;

  @override
  ConsumerState<_ServerDialog> createState() => _ServerDialogState();
}

class _ServerDialogState extends ConsumerState<_ServerDialog> {
  late final _controller = TextEditingController(text: widget.initial);
  final _form = GlobalKey<FormState>();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final manifestName = ref.watch(updateConfigProvider).manifestName;
    return AlertDialog(
      title: Text(l10n.settingsUpdateServer),
      content: Form(
        key: _form,
        child: TextFormField(
          key: const ValueKey('update-server-url'),
          controller: _controller,
          keyboardType: TextInputType.url,
          autocorrect: false,
          decoration: InputDecoration(
            hintText: 'https://',
            helperText: l10n.settingsUpdateServerHint,
            helperMaxLines: 2,
          ),
          validator: (v) => manifestUriFor(v ?? '', manifestName) == null
              ? l10n.settingsUpdateServerInvalid
              : null,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop((null,)),
          child: Text(l10n.settingsUpdateServerReset),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.actionCancel),
        ),
        FilledButton(
          onPressed: () {
            if (!(_form.currentState?.validate() ?? false)) return;
            Navigator.of(context).pop((_controller.text.trim(),));
          },
          child: Text(l10n.actionSave),
        ),
      ],
    );
  }
}

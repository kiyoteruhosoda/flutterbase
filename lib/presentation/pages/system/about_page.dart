import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutterbase/domain/entities/app_info.dart';
import 'package:flutterbase/domain/errors/app_error.dart';
import 'package:flutterbase/presentation/l10n/app_localizations.dart';
import 'package:flutterbase/presentation/providers/app_info_providers.dart';
import 'package:flutterbase/presentation/providers/debug_providers.dart';
import 'package:flutterbase/presentation/theme/theme.dart';
import 'package:flutterbase/presentation/widgets/ui/widgets.dart';
import 'package:flutterbase/shared/app_config.dart';

/// About / version information page.
class AboutPage extends ConsumerStatefulWidget {
  const AboutPage({super.key});

  @override
  ConsumerState<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends ConsumerState<AboutPage> {
  static const int _debugUnlockTapCount = 7;

  /// Local to the screen — nothing outside it cares how far a user has got
  /// through the unlock gesture, so it stays out of Riverpod.
  int _versionTapCount = 0;

  Future<void> _onVersionTapped() async {
    if (ref.read(debugModeProvider)) {
      _versionTapCount = 0;
      return;
    }
    _versionTapCount++;
    if (_versionTapCount < _debugUnlockTapCount) return;
    _versionTapCount = 0;
    await ref.read(debugModeProvider.notifier).setEnabled(true);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context).aboutDebugUnlocked)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppMainHeader(title: l10n.aboutTitle),
      body: switch (ref.watch(appInfoProvider)) {
        AsyncLoading<AppInfo>() => const AppLoadingView(),
        AsyncError<AppInfo>(:final error) => AppErrorView(
          message: error is AppError ? error.message : l10n.commonError,
          onRetry: () => ref.invalidate(appInfoProvider),
        ),
        AsyncData<AppInfo>(value: final info) => _buildContent(
          context,
          colorScheme,
          info,
        ),
      },
    );
  }

  Widget _buildContent(
    BuildContext context,
    ColorScheme colorScheme,
    AppInfo info,
  ) {
    final l10n = AppLocalizations.of(context);
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.pageMargin),
      children: [
        const SizedBox(height: AppSpacing.xl),
        Center(
          child: Container(
            width: AppSpacing.aboutIconContainer,
            height: AppSpacing.aboutIconContainer,
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: AppRadius.xlBorder,
            ),
            child: Icon(
              Icons.web_asset,
              size: AppSpacing.aboutIconSize,
              color: colorScheme.primary,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        Center(
          child: Text(
            AppConfig.appName,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Center(
          child: Text(
            AppConfig.appDescription,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: AppSpacing.xxl),
        AppCard(
          child: Column(
            children: [
              _VersionInfoRow(
                label: l10n.aboutVersion,
                value: info.version,
                onTap: _onVersionTapped,
              ),
              const Divider(height: AppSpacing.xl),
              _InfoRow(label: l10n.aboutBuildNumber, value: info.buildNumber),
              const Divider(height: AppSpacing.xl),
              _InfoRow(label: l10n.aboutGitCommit, value: info.gitCommit),
              const Divider(height: AppSpacing.xl),
              _InfoRow(
                label: l10n.aboutFlutterVersion,
                value: info.flutterVersion,
              ),
              const Divider(height: AppSpacing.xl),
              _InfoRow(label: l10n.aboutDartVersion, value: info.dartVersion),
              const Divider(height: AppSpacing.xl),
              _InfoRow(
                label: l10n.aboutPlatform,
                value: l10n.aboutPlatformValue,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        Text(value, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }
}

/// Version row with a secret 7-tap gesture that re-enables debug mode.
class _VersionInfoRow extends StatelessWidget {
  const _VersionInfoRow({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: _InfoRow(label: label, value: value),
    );
  }
}

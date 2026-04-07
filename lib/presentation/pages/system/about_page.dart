import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutterbase/presentation/widgets/ui/widgets.dart';
import 'package:flutterbase/shared/build_info.dart';
import 'package:flutterbase/shared/l10n/app_strings.dart';
import 'package:flutterbase/shared/theme/theme.dart';

/// About / version information page.
class AboutPage extends StatefulWidget {
  const AboutPage({super.key});

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  PackageInfo? _packageInfo;

  @override
  void initState() {
    super.initState();
    PackageInfo.fromPlatform().then((info) {
      if (mounted) setState(() => _packageInfo = info);
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final version = _packageInfo?.version ?? BuildInfo.version;
    final buildNum = BuildInfo.buildNumber;

    return Scaffold(
      appBar: AppMainHeader(title: AppStrings.aboutTitle),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.pageMargin),
        children: [
          const SizedBox(height: AppSpacing.xl),
          Center(
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: AppRadius.xlBorder,
              ),
              child: Icon(
                Icons.web_asset,
                size: 40,
                color: colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Center(
            child: Text(
              AppStrings.appName,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Center(
            child: Text(
              AppStrings.appDescription,
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
                _InfoRow(label: AppStrings.aboutVersion, value: version),
                const Divider(height: AppSpacing.xl),
                _InfoRow(label: AppStrings.aboutBuildNumber, value: buildNum),
                const Divider(height: AppSpacing.xl),
                _InfoRow(
                  label: AppStrings.aboutGitCommit,
                  value: BuildInfo.gitCommit,
                ),
                const Divider(height: AppSpacing.xl),
                _InfoRow(
                  label: AppStrings.aboutFlutterVersion,
                  value: BuildInfo.flutterVersion,
                ),
                const Divider(height: AppSpacing.xl),
                _InfoRow(
                  label: AppStrings.aboutDartVersion,
                  value: BuildInfo.dartVersion,
                ),
                const Divider(height: AppSpacing.xl),
                _InfoRow(
                  label: AppStrings.aboutDesignSystem,
                  value: AppStrings.aboutDesignSystemValue,
                ),
                const Divider(height: AppSpacing.xl),
                _InfoRow(
                  label: AppStrings.aboutPlatform,
                  value: AppStrings.aboutPlatformValue,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.aboutDesignSystemSectionTitle,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  AppStrings.aboutDesignSystemBody,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.lg),
                TextButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.open_in_new, size: 16),
                  label: const Text(AppStrings.aboutDesignSystemLink),
                ),
              ],
            ),
          ),
        ],
      ),
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

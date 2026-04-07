import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutterbase/presentation/widgets/ui/widgets.dart';
import 'package:flutterbase/shared/build_info.dart';
import 'package:flutterbase/shared/l10n/app_strings.dart';
import 'package:flutterbase/shared/logging/app_logger.dart';
import 'package:flutterbase/shared/theme/theme.dart';

/// Debug information page — shows build metadata and diagnostic actions.
class DebugPage extends StatefulWidget {
  const DebugPage({super.key});

  @override
  State<DebugPage> createState() => _DebugPageState();
}

class _DebugPageState extends State<DebugPage> {
  Map<String, String>? _debugInfo;

  @override
  void initState() {
    super.initState();
    _loadDebugInfo();
  }

  Future<void> _loadDebugInfo() async {
    final packageInfo = await PackageInfo.fromPlatform();
    if (!mounted) return;
    setState(() {
      _debugInfo = {
        AppStrings.debugAppName: AppStrings.appName,
        AppStrings.debugVersion:
            packageInfo.version.isNotEmpty
                ? packageInfo.version
                : BuildInfo.version,
        AppStrings.debugBuildNumber: BuildInfo.buildNumber,
        AppStrings.debugGitCommit: BuildInfo.gitCommitFull,
        AppStrings.debugFlutterVersion: BuildInfo.flutterVersion,
        AppStrings.debugDartVersion: BuildInfo.dartVersion,
        AppStrings.debugPlatform: AppStrings.aboutPlatformValue,
        AppStrings.debugDesignSystem: AppStrings.aboutDesignSystemValue,
        AppStrings.debugBuildDate: BuildInfo.buildDate,
        AppStrings.debugIsDebugBuild: BuildInfo.isDebug.toString(),
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppMainHeader(
        title: AppStrings.debugTitle,
        actions: [
          IconButton(
            icon: const Icon(Icons.copy),
            onPressed: _copyAllToClipboard,
            tooltip: AppStrings.debugCopyAll,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.pageMargin),
        children: [
          // Warning banner
          Container(
            padding: const EdgeInsets.all(AppSpacing.componentPadding),
            decoration: BoxDecoration(
              color: AppColors.statusWarningBg,
              borderRadius: AppRadius.lgBorder,
              border: Border.all(color: AppColors.statusWarning),
            ),
            child: Row(
              children: [
                Icon(Icons.warning_amber, color: AppColors.statusWarning),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    AppStrings.debugWarning,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.statusWarning,
                        ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // App info card
          AppSectionHeader(title: AppStrings.debugAppInfoSection),
          const SizedBox(height: AppSpacing.sm),
          if (_debugInfo == null)
            const AppLoadingView()
          else
            AppCard(
              child: Column(
                children: () {
                  final entries = _debugInfo!.entries.toList();
                  return List.generate(entries.length, (i) {
                    return Column(
                      children: [
                        if (i > 0) const Divider(height: AppSpacing.xl),
                        _DebugInfoRow(
                          label: entries[i].key,
                          value: entries[i].value,
                        ),
                      ],
                    );
                  });
                }(),
              ),
            ),
          const SizedBox(height: AppSpacing.lg),

          // Theme info card
          AppSectionHeader(title: AppStrings.debugThemeSection),
          const SizedBox(height: AppSpacing.sm),
          AppCard(
            child: Column(
              children: [
                _DebugInfoRow(
                  label: AppStrings.debugThemeMode,
                  value: Theme.of(context).brightness == Brightness.dark
                      ? AppStrings.debugThemeModeDark
                      : AppStrings.debugThemeModeLight,
                ),
                const Divider(height: AppSpacing.xl),
                _DebugInfoRow(
                  label: AppStrings.debugPrimaryColor,
                  value: colorScheme.primary.toHexString(),
                  valueWidget: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: colorScheme.primary,
                          borderRadius: AppRadius.smBorder,
                          border: Border.all(color: colorScheme.outline),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        colorScheme.primary.toHexString(),
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                const Divider(height: AppSpacing.xl),
                _DebugInfoRow(
                  label: AppStrings.debugSurfaceColor,
                  value: colorScheme.surface.toHexString(),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Actions card
          AppSectionHeader(title: AppStrings.debugActionsSection),
          const SizedBox(height: AppSpacing.sm),
          AppListCard(
            title: AppStrings.debugClearLogs,
            leading: const Icon(Icons.clear_all),
            onTap: () {
              AppLogger.instance.clearBuffer();
              _showSnackBar(AppStrings.debugClearLogsSuccess);
            },
          ),
          const SizedBox(height: AppSpacing.sm),
          AppListCard(
            title: AppStrings.debugClearCache,
            leading: const Icon(Icons.cleaning_services_outlined),
            onTap: () => _showSnackBar(AppStrings.debugClearCacheSuccess),
          ),
          const SizedBox(height: AppSpacing.sm),
          AppListCard(
            title: AppStrings.debugTestCrash,
            leading: Icon(Icons.warning, color: AppColors.statusError),
            onTap: _showCrashConfirmDialog,
          ),
        ],
      ),
    );
  }

  void _copyAllToClipboard() {
    if (_debugInfo == null) return;
    final buffer = StringBuffer();
    _debugInfo!.forEach((key, value) => buffer.writeln('$key: $value'));
    Clipboard.setData(ClipboardData(text: buffer.toString()));
    _showSnackBar(AppStrings.debugCopiedToClipboard);
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _showCrashConfirmDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(AppStrings.debugTestCrashTitle),
        content: const Text(AppStrings.debugTestCrashBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(AppStrings.debugCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(AppStrings.debugCrash),
          ),
        ],
      ),
    );
    if (confirmed == true) throw Exception('Test crash');
  }
}

class _DebugInfoRow extends StatelessWidget {
  const _DebugInfoRow({
    required this.label,
    required this.value,
    this.valueWidget,
  });

  final String label;
  final String value;
  final Widget? valueWidget;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 140,
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: valueWidget ??
              SelectableText(
                value,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
        ),
      ],
    );
  }
}

extension ColorExtension on Color {
  /// Returns the color as an uppercase hex string (e.g. "#1A2B3C").
  String toHexString() {
    // ignore: deprecated_member_use
    final v = value; // ARGB32 int — works across all Flutter versions
    final r = ((v >> 16) & 0xFF).toRadixString(16).padLeft(2, '0');
    final g = ((v >> 8) & 0xFF).toRadixString(16).padLeft(2, '0');
    final b = (v & 0xFF).toRadixString(16).padLeft(2, '0');
    return '#${r.toUpperCase()}${g.toUpperCase()}${b.toUpperCase()}';
  }
}

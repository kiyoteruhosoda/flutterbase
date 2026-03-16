import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../presentation/viewmodels/debug_info_viewmodel.dart';
import '../../../presentation/widgets/ui/app_card.dart';
import '../../../presentation/widgets/ui/app_status_badge.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_text_styles.dart';

/// デバッグ情報表示ページ
///
/// 開発・デバッグ用の各種情報を表示します。
/// リリースビルドでも表示可能ですが、本番環境では非公開にすることを推奨します。
class DebugInfoPage extends ConsumerWidget {
  const DebugInfoPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(debugInfoViewModelProvider(context));

    return Scaffold(
      appBar: AppBar(
        title: const Text('デバッグ情報'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: '更新',
            onPressed: () =>
                ref.read(debugInfoViewModelProvider(context).notifier).refresh(),
          ),
        ],
      ),
      body: switch (state) {
        DebugInfoLoading() => const Center(child: CircularProgressIndicator()),
        DebugInfoError(:final message) => Center(
            child: _ErrorState(
              message: message,
              onRetry: () => ref
                  .read(debugInfoViewModelProvider(context).notifier)
                  .refresh(),
            ),
          ),
        DebugInfoLoaded(:final info) => _DebugInfoContent(info: info),
      },
    );
  }
}

class _DebugInfoContent extends StatelessWidget {
  const _DebugInfoContent({required this.info});

  final DebugInfo info;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.pageHorizontalPadding,
        vertical: AppSpacing.pageVerticalPadding,
      ),
      children: [
        // Build mode badge
        Row(
          children: [
            AppStatusBadge(
              label: info.buildMode,
              type: info.isDebugMode
                  ? AppStatusType.warning
                  : info.isProfileMode
                      ? AppStatusType.info
                      : AppStatusType.success,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),

        // App info
        _DebugSection(
          title: 'アプリ情報',
          icon: Icons.apps,
          children: [
            _DebugRow(label: 'バージョン', value: info.appVersion),
            _DebugRow(label: 'ビルド番号', value: info.buildNumber),
            _DebugRow(label: 'パッケージ名', value: info.packageName),
          ],
        ),
        const SizedBox(height: AppSpacing.md),

        // Runtime info
        _DebugSection(
          title: 'ランタイム',
          icon: Icons.developer_mode,
          children: [
            _DebugRow(label: 'プラットフォーム', value: info.platform),
            _DebugRow(label: 'OS', value: info.os),
            _DebugRow(label: 'OSバージョン', value: info.osVersion),
            _DebugRow(label: 'Dart', value: info.dartVersion),
          ],
        ),
        const SizedBox(height: AppSpacing.md),

        // Display info
        _DebugSection(
          title: 'ディスプレイ',
          icon: Icons.monitor,
          children: [
            _DebugRow(label: '画面サイズ', value: info.screenSize),
            _DebugRow(label: 'デバイスピクセル比', value: info.devicePixelRatio),
            _DebugRow(label: 'テキストスケール', value: info.textScaleFactor),
            _DebugRow(label: 'ロケール', value: info.locale),
          ],
        ),
        const SizedBox(height: AppSpacing.md),

        // Build flags
        _DebugSection(
          title: 'ビルドフラグ',
          icon: Icons.flag_outlined,
          children: [
            _DebugBoolRow(label: 'kDebugMode', value: info.isDebugMode),
            _DebugBoolRow(label: 'kProfileMode', value: info.isProfileMode),
            _DebugBoolRow(label: 'kReleaseMode', value: info.isReleaseMode),
          ],
        ),
        const SizedBox(height: AppSpacing.xxxl),
      ],
    );
  }
}

class _DebugSection extends StatelessWidget {
  const _DebugSection({
    required this.title,
    required this.icon,
    required this.children,
  });

  final String title;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: scheme.primary),
            const SizedBox(width: AppSpacing.xxs),
            Text(
              title,
              style: AppTextStyles.dnsSmBold.copyWith(color: scheme.primary),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        AppCard(
          padding: const EdgeInsets.all(0),
          child: Column(
            children: children
                .asMap()
                .entries
                .map(
                  (e) => Column(
                    children: [
                      e.value,
                      if (e.key < children.length - 1)
                        Divider(color: scheme.outline, height: 1),
                    ],
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }
}

class _DebugRow extends StatelessWidget {
  const _DebugRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return InkWell(
      onLongPress: () {
        Clipboard.setData(ClipboardData(text: value));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('「$value」をコピーしました')),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 120,
              child: Text(
                label,
                style: AppTextStyles.dnsSmNormal.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
            Expanded(
              child: Text(
                value,
                style: AppTextStyles.monoMd.copyWith(
                  color: scheme.onSurface,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DebugBoolRow extends StatelessWidget {
  const _DebugBoolRow({required this.label, required this.value});

  final String label;
  final bool value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.monoMd.copyWith(color: scheme.onSurface),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xs,
              vertical: 2,
            ),
            decoration: BoxDecoration(
              color: value
                  ? scheme.primaryContainer
                  : scheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              value ? 'true' : 'false',
              style: AppTextStyles.monoMd.copyWith(
                color: value
                    ? scheme.onPrimaryContainer
                    : scheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, size: 48, color: scheme.error),
          const SizedBox(height: AppSpacing.md),
          Text(
            '情報の取得に失敗しました',
            style: AppTextStyles.stdSmBold.copyWith(color: scheme.onSurface),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            message,
            style: AppTextStyles.dnsSmNormal.copyWith(
              color: scheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xl),
          TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('再試行'),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../presentation/viewmodels/version_info_viewmodel.dart';
import '../../../presentation/widgets/ui/app_card.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_text_styles.dart';

/// バージョン情報ページ
///
/// アプリのバージョン・ビルド情報を表示します。
class VersionInfoPage extends ConsumerWidget {
  const VersionInfoPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(versionInfoViewModelProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('バージョン情報'),
      ),
      body: switch (state) {
        VersionInfoLoading() => const Center(
            child: CircularProgressIndicator(),
          ),
        VersionInfoError(:final message) => Center(
            child: _ErrorState(
              message: message,
              onRetry: () =>
                  ref.read(versionInfoViewModelProvider.notifier).refresh(),
            ),
          ),
        VersionInfoLoaded(:final info) => _VersionInfoContent(info: info),
      },
    );
  }
}

class _VersionInfoContent extends StatelessWidget {
  const _VersionInfoContent({required this.info});

  final VersionInfo info;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.pageHorizontalPadding,
        vertical: AppSpacing.pageVerticalPadding,
      ),
      children: [
        // App icon + name
        Center(
          child: Column(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(
                  Icons.apps_rounded,
                  size: 48,
                  color: scheme.primary,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                info.appName,
                style: AppTextStyles.stdMdBold.copyWith(
                  color: scheme.onSurface,
                ),
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                'バージョン ${info.fullVersion}',
                style: AppTextStyles.dnsLgNormal.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),

        // Version details
        AppCard(
          child: Column(
            children: [
              _InfoRow(label: 'アプリ名', value: info.appName),
              const Divider(),
              _InfoRow(label: 'パッケージ名', value: info.packageName),
              const Divider(),
              _InfoRow(label: 'バージョン', value: info.version),
              const Divider(),
              _InfoRow(label: 'ビルド番号', value: info.buildNumber),
              if (info.buildSignature.isNotEmpty) ...[
                const Divider(),
                _InfoRow(label: 'ビルド署名', value: info.buildSignature),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),

        // Design system info
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'デザインシステム',
                style: AppTextStyles.dnsSmBold.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              _InfoRow(label: 'システム名', value: 'デジタル庁デザインシステム'),
              const Divider(),
              _InfoRow(label: 'バージョン', value: 'v2.10.3'),
              const Divider(),
              _InfoRow(label: '発行元', value: 'デジタル庁'),
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
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
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
              style: AppTextStyles.dnsSmNormal.copyWith(
                color: scheme.onSurface,
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

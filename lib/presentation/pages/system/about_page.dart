import 'package:flutter/material.dart';
import 'package:flutterbase/presentation/widgets/ui/widgets.dart';
import 'package:flutterbase/shared/theme/theme.dart';

/// バージョン情報ページ
class AboutPage extends StatelessWidget {
  const AboutPage({
    super.key,
    this.appName = 'FlutterBase',
    this.version = '1.0.0',
    this.buildNumber = '1',
    this.description = 'デジタル庁デザインシステム準拠ベースアプリ',
  });

  final String appName;
  final String version;
  final String buildNumber;
  final String description;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppMainHeader(title: 'バージョン情報'),
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
            child: Text(appName, style: AppTextStyles.headlineSmall),
          ),
          const SizedBox(height: AppSpacing.sm),
          Center(
            child: Text(
              description,
              style: AppTextStyles.bodyMedium.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
          AppCard(
            child: Column(
              children: [
                _InfoRow(label: 'バージョン', value: version),
                const Divider(height: AppSpacing.xl),
                _InfoRow(label: 'ビルド番号', value: buildNumber),
                const Divider(height: AppSpacing.xl),
                _InfoRow(label: 'デザインシステム', value: 'DADS v2.10.3'),
                const Divider(height: AppSpacing.xl),
                _InfoRow(label: '対象プラットフォーム', value: 'Android / iOS'),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('デザインシステム', style: AppTextStyles.titleSmall),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'このアプリはデジタル庁が提供する\nデザインシステム（DADS）に準拠して構築されています。',
                  style: AppTextStyles.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.lg),
                TextButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.open_in_new, size: 16),
                  label: const Text('デザインシステム公式サイト'),
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
          style: AppTextStyles.bodyMedium.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        Text(value, style: AppTextStyles.bodyMedium),
      ],
    );
  }
}

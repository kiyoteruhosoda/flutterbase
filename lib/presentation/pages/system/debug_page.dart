import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutterbase/presentation/widgets/ui/widgets.dart';
import 'package:flutterbase/shared/theme/theme.dart';

/// デバッグ用情報表示ページ
class DebugPage extends StatefulWidget {
  const DebugPage({super.key});

  @override
  State<DebugPage> createState() => _DebugPageState();
}

class _DebugPageState extends State<DebugPage> {
  final Map<String, String> _debugInfo = {
    'アプリ名': 'FlutterBase',
    'バージョン': '1.0.0',
    'ビルド番号': '1',
    'Flutterバージョン': '3.x',
    'Dartバージョン': '3.x',
    '対象プラットフォーム': 'Android / iOS',
    'デザインシステム': 'DADS v2.10.3',
    'ビルド日時': DateTime.now().toIso8601String(),
    'デバッグビルド': 'true',
  };

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppMainHeader(
        title: 'デバッグ情報',
        actions: [
          IconButton(
            icon: const Icon(Icons.copy),
            onPressed: _copyAllToClipboard,
            tooltip: 'すべてコピー',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.pageMargin),
        children: [
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
                    'このページはデバッグ目的専用です。リリースビルドでは表示しないでください。',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.statusWarning,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppSectionHeader(title: 'アプリ情報'),
          const SizedBox(height: AppSpacing.sm),
          AppCard(
            child: Column(
              children: () {
                final entries = _debugInfo.entries.toList();
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
          AppSectionHeader(title: 'テーマ情報'),
          const SizedBox(height: AppSpacing.sm),
          AppCard(
            child: Column(
              children: [
                _DebugInfoRow(
                  label: 'テーマモード',
                  value: Theme.of(context).brightness == Brightness.dark
                      ? 'ダークモード'
                      : 'ライトモード',
                ),
                const Divider(height: AppSpacing.xl),
                _DebugInfoRow(
                  label: 'プライマリカラー',
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
                          border: Border.all(
                            color: colorScheme.outline,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        colorScheme.primary.toHexString(),
                        style: AppTextStyles.bodyMedium,
                      ),
                    ],
                  ),
                ),
                const Divider(height: AppSpacing.xl),
                _DebugInfoRow(
                  label: 'サーフェスカラー',
                  value: colorScheme.surface.toHexString(),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppSectionHeader(title: 'デバッグアクション'),
          const SizedBox(height: AppSpacing.sm),
          AppListCard(
            title: 'ログをクリア',
            leading: const Icon(Icons.clear_all),
            onTap: () => _showSnackBar('ログをクリアしました'),
          ),
          const SizedBox(height: AppSpacing.sm),
          AppListCard(
            title: 'キャッシュをクリア',
            leading: const Icon(Icons.cleaning_services_outlined),
            onTap: () => _showSnackBar('キャッシュをクリアしました'),
          ),
          const SizedBox(height: AppSpacing.sm),
          AppListCard(
            title: 'テストクラッシュ',
            leading: Icon(Icons.warning, color: AppColors.statusError),
            onTap: () => _showCrashConfirmDialog(),
          ),
        ],
      ),
    );
  }

  void _copyAllToClipboard() {
    final buffer = StringBuffer();
    _debugInfo.forEach((key, value) => buffer.writeln('$key: $value'));
    Clipboard.setData(ClipboardData(text: buffer.toString()));
    _showSnackBar('クリップボードにコピーしました');
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _showCrashConfirmDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('テストクラッシュ'),
        content: const Text('テスト用にアプリをクラッシュさせますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('クラッシュ'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      throw Exception('テスト用クラッシュ');
    }
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
            style: AppTextStyles.bodyMedium.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: valueWidget ??
              Text(
                value,
                style: AppTextStyles.bodyMedium,
              ),
        ),
      ],
    );
  }
}

extension ColorExtension on Color {
  String toHexString() {
    final r = (red * 255).round().toRadixString(16).padLeft(2, '0');
    final g = (green * 255).round().toRadixString(16).padLeft(2, '0');
    final b = (blue * 255).round().toRadixString(16).padLeft(2, '0');
    return '#${r.toUpperCase()}${g.toUpperCase()}${b.toUpperCase()}';
  }
}

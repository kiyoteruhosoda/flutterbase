import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/bootstrap/app_router.dart';
import '../../../presentation/widgets/layout/app_drawer.dart';
import '../../../presentation/widgets/layout/app_footer.dart';
import '../../../presentation/widgets/layout/app_header.dart';
import '../../../presentation/widgets/ui/app_card.dart';
import '../../../presentation/widgets/ui/app_status_badge.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_text_styles.dart';

/// メインページ
///
/// アプリのホーム画面。ヘッダー・コンテンツ・フッター・ドロワーを含みます。
class MainPage extends ConsumerWidget {
  const MainPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppHeader(
        title: 'ホーム',
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            tooltip: '通知',
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.account_circle_outlined),
            tooltip: 'アカウント',
            onPressed: () {},
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: const _MainContent(),
      bottomNavigationBar: AppFooter(
        items: [
          AppFooterItem(
            label: 'ホーム',
            icon: Icons.home_outlined,
            onTap: () {},
            isSelected: true,
          ),
          AppFooterItem(
            label: '検索',
            icon: Icons.search,
            onTap: () {},
          ),
          AppFooterItem(
            label: '設定',
            icon: Icons.settings_outlined,
            onTap: () => context.go(AppRoutes.versionInfo),
          ),
        ],
      ),
    );
  }
}

class _MainContent extends StatelessWidget {
  const _MainContent();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.pageHorizontalPadding,
        vertical: AppSpacing.pageVerticalPadding,
      ),
      children: [
        _WelcomeBanner(),
        const SizedBox(height: AppSpacing.xl),
        _SectionTitle(title: 'デザインシステム概要'),
        const SizedBox(height: AppSpacing.md),
        _DesignSystemCards(),
        const SizedBox(height: AppSpacing.xl),
        _SectionTitle(title: 'ステータスバッジ'),
        const SizedBox(height: AppSpacing.md),
        _StatusBadgeShowcase(),
        const SizedBox(height: AppSpacing.xl),
        _SectionTitle(title: 'カラーパレット'),
        const SizedBox(height: AppSpacing.md),
        _ColorPaletteShowcase(),
        const SizedBox(height: AppSpacing.xxxl),
      ],
    );
  }
}

class _WelcomeBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.flag_circle_outlined,
                  color: scheme.primary,
                  size: 28,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Flutterbase',
                      style: AppTextStyles.stdSmBold.copyWith(
                        color: scheme.onSurface,
                      ),
                    ),
                    Text(
                      'デジタル庁デザインシステム実装',
                      style: AppTextStyles.dnsSmNormal.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'このアプリはデジタル庁デザインシステム (DADS) v2.10.3 に準拠した Flutter 実装のベースアプリです。'
            'カラートークン・タイポグラフィ・スペーシング・コンポーネントを標準実装しています。',
            style: AppTextStyles.stdBaseNormal.copyWith(
              color: scheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: AppTextStyles.stdSmBold.copyWith(
        color: Theme.of(context).colorScheme.onSurface,
      ),
    );
  }
}

class _DesignSystemCards extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const items = [
      (Icons.palette_outlined, 'カラー', 'Sumi・Umi・Midori・Ki・Suo スケール'),
      (Icons.text_fields, 'タイポグラフィ', 'Noto Sans JP / Display・Standard・Dense'),
      (Icons.space_bar, 'スペーシング', '8px ベースユニット / 4px グリッド'),
      (Icons.rounded_corner, '角丸', '2・4・8・12・16・24px スケール'),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: AppSpacing.sm,
      mainAxisSpacing: AppSpacing.sm,
      childAspectRatio: 1.4,
      children: items
          .map((item) => _DesignSystemCard(
                icon: item.$1,
                title: item.$2,
                subtitle: item.$3,
              ))
          .toList(),
    );
  }
}

class _DesignSystemCard extends StatelessWidget {
  const _DesignSystemCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: scheme.primary, size: 24),
          const SizedBox(height: AppSpacing.xs),
          Text(
            title,
            style: AppTextStyles.dnsSmBold.copyWith(
              color: scheme.onSurface,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: AppTextStyles.dnsSmNormal.copyWith(
              color: scheme.onSurfaceVariant,
              fontSize: 11,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _StatusBadgeShowcase extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      children: const [
        AppStatusBadge(label: '完了', type: AppStatusType.success),
        AppStatusBadge(label: '警告', type: AppStatusType.warning),
        AppStatusBadge(label: 'エラー', type: AppStatusType.error),
        AppStatusBadge(label: '情報', type: AppStatusType.info),
        AppStatusBadge(label: '通常', type: AppStatusType.neutral),
      ],
    );
  }
}

class _ColorPaletteShowcase extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final swatches = [
      ('Primary', scheme.primary),
      ('On Primary', scheme.onPrimary),
      ('Primary Container', scheme.primaryContainer),
      ('Secondary', scheme.secondary),
      ('Error', scheme.error),
      ('Surface', scheme.surface),
      ('Surface Variant', scheme.surfaceContainerHighest),
      ('Outline', scheme.outline),
    ];

    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      children: swatches
          .map(
            (s) => Column(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: s.$2,
                    border: Border.all(color: scheme.outline),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 2),
                SizedBox(
                  width: 56,
                  child: Text(
                    s.$1,
                    style: AppTextStyles.dnsSmNormal.copyWith(fontSize: 9),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          )
          .toList(),
    );
  }
}

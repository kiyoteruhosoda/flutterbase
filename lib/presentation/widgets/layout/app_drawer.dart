import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/bootstrap/app_router.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_text_styles.dart';

/// ドロワーメニュー
///
/// デジタル庁デザインシステム準拠のグローバルナビゲーションドロワー。
class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isLight = scheme.brightness == Brightness.light;

    return Drawer(
      child: Column(
        children: [
          // Header
          _DrawerHeader(scheme: scheme, isLight: isLight),

          // Navigation items
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _DrawerSection(
                  title: 'メインメニュー',
                  children: [
                    _DrawerItem(
                      icon: Icons.home_outlined,
                      selectedIcon: Icons.home,
                      label: 'ホーム',
                      routePath: AppRoutes.main,
                    ),
                  ],
                ),
                const Divider(),
                _DrawerSection(
                  title: 'システム',
                  children: [
                    _DrawerItem(
                      icon: Icons.info_outlined,
                      selectedIcon: Icons.info,
                      label: 'バージョン情報',
                      routePath: AppRoutes.versionInfo,
                    ),
                    _DrawerItem(
                      icon: Icons.article_outlined,
                      selectedIcon: Icons.article,
                      label: 'ライセンス情報',
                      routePath: AppRoutes.licenses,
                    ),
                    _DrawerItem(
                      icon: Icons.bug_report_outlined,
                      selectedIcon: Icons.bug_report,
                      label: 'デバッグ情報',
                      routePath: AppRoutes.debugInfo,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Footer
          _DrawerFooter(scheme: scheme),
        ],
      ),
    );
  }
}

class _DrawerHeader extends StatelessWidget {
  const _DrawerHeader({required this.scheme, required this.isLight});

  final ColorScheme scheme;
  final bool isLight;

  @override
  Widget build(BuildContext context) {
    return DrawerHeader(
      decoration: BoxDecoration(color: scheme.primary),
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: scheme.onPrimary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.apps,
              color: scheme.primary,
              size: 32,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Flutterbase',
            style: AppTextStyles.stdSmBold.copyWith(
              color: scheme.onPrimary,
            ),
          ),
          Text(
            'デジタル庁デザインシステム',
            style: AppTextStyles.dnsSmNormal.copyWith(
              color: scheme.onPrimary.withAlpha(180),
            ),
          ),
        ],
      ),
    );
  }
}

class _DrawerSection extends StatelessWidget {
  const _DrawerSection({
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.xxs,
          ),
          child: Text(
            title,
            style: AppTextStyles.dnsSmBold.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        ...children,
      ],
    );
  }
}

class _DrawerItem extends StatelessWidget {
  const _DrawerItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.routePath,
    this.badge,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final String routePath;
  final int? badge;

  @override
  Widget build(BuildContext context) {
    final currentPath = GoRouterState.of(context).uri.path;
    final isSelected = currentPath == routePath;
    final scheme = Theme.of(context).colorScheme;

    return ListTile(
      leading: Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(
            isSelected ? selectedIcon : icon,
            color: isSelected ? scheme.primary : scheme.onSurfaceVariant,
          ),
          if (badge != null && badge! > 0)
            Positioned(
              top: -4,
              right: -8,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: scheme.error,
                  shape: BoxShape.circle,
                ),
                constraints: const BoxConstraints(
                  minWidth: 16,
                  minHeight: 16,
                ),
                child: Text(
                  '$badge',
                  style: AppTextStyles.dnsSmBold.copyWith(
                    color: scheme.onError,
                    fontSize: 10,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
      title: Text(
        label,
        style: AppTextStyles.stdBaseNormal.copyWith(
          color: isSelected ? scheme.primary : scheme.onSurface,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
        ),
      ),
      selected: isSelected,
      selectedTileColor: scheme.primaryContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.xs),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: 0,
      ),
      onTap: () {
        Navigator.of(context).pop(); // Close drawer
        if (!isSelected) {
          context.go(routePath);
        }
      },
    );
  }
}

class _DrawerFooter extends StatelessWidget {
  const _DrawerFooter({required this.scheme});

  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    final isLight = scheme.brightness == Brightness.light;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: isLight ? AppColors.borderDefaultLight : AppColors.borderDefaultDark,
            width: 1,
          ),
        ),
      ),
      child: Text(
        '© デジタル庁デザインシステム v2.10.3',
        style: AppTextStyles.dnsSmNormal.copyWith(
          color: scheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

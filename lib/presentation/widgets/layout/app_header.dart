import 'package:flutter/material.dart';

import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_text_styles.dart';

/// メインヘッダー (AppBar)
///
/// デジタル庁デザインシステム準拠のグローバルヘッダー。
class AppHeader extends StatelessWidget implements PreferredSizeWidget {
  const AppHeader({
    super.key,
    required this.title,
    this.actions,
    this.leading,
    this.showMenuButton = true,
    this.onMenuPressed,
  });

  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool showMenuButton;
  final VoidCallback? onMenuPressed;

  @override
  Size get preferredSize => const Size.fromHeight(AppSpacing.headerHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title, style: AppTextStyles.olnLgBold),
      leading: leading ??
          (showMenuButton
              ? IconButton(
                  icon: const Icon(Icons.menu),
                  tooltip: 'メニューを開く',
                  onPressed:
                      onMenuPressed ?? () => Scaffold.of(context).openDrawer(),
                )
              : null),
      actions: actions,
    );
  }
}

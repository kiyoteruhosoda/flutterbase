import 'package:flutter/material.dart';
import 'package:flutterbase/shared/theme/theme.dart';

/// デジタル庁デザインシステム準拠 カード
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.semanticLabel,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      child: Card(
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.lgBorder,
          child: Padding(
            padding: padding ??
                const EdgeInsets.all(AppSpacing.componentPadding),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// リスト形式のカードアイテム
class AppListCard extends StatelessWidget {
  const AppListCard({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      onTap: onTap,
      child: ListTile(
        title: Text(title, style: AppTextStyles.titleSmall),
        subtitle:
            subtitle != null ? Text(subtitle!, style: AppTextStyles.bodySmall) : null,
        leading: leading,
        trailing: trailing ?? (onTap != null ? const Icon(Icons.chevron_right) : null),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.componentPadding,
          vertical: AppSpacing.sm,
        ),
      ),
    );
  }
}

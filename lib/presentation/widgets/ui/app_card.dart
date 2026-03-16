import 'package:flutter/material.dart';

import '../../../shared/theme/app_radius.dart';
import '../../../shared/theme/app_spacing.dart';

/// カードコンポーネント
///
/// デジタル庁デザインシステム Card に準拠。
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding,
    this.margin,
    this.semanticLabel,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Semantics(
      label: semanticLabel,
      container: semanticLabel != null,
      child: Container(
        margin: margin,
        decoration: BoxDecoration(
          color: scheme.surface,
          border: Border.all(color: scheme.outline, width: 1),
          borderRadius: AppRadius.mdAll,
        ),
        child: onTap != null
            ? InkWell(
                onTap: onTap,
                borderRadius: AppRadius.mdAll,
                child: Padding(
                  padding: padding ??
                      const EdgeInsets.all(AppSpacing.md),
                  child: child,
                ),
              )
            : Padding(
                padding: padding ??
                    const EdgeInsets.all(AppSpacing.md),
                child: child,
              ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutterbase/shared/theme/theme.dart';

/// デジタル庁デザインシステム準拠 メインフッター
class AppMainFooter extends StatelessWidget {
  const AppMainFooter({
    super.key,
    this.appName,
    this.version,
    this.links,
  });

  final String? appName;
  final String? version;
  final List<AppFooterLink>? links;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      color: colorScheme.surfaceContainerHighest,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.pageMargin,
            vertical: AppSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (links != null && links!.isNotEmpty) ...[
                Wrap(
                  spacing: AppSpacing.lg,
                  runSpacing: AppSpacing.sm,
                  children: links!
                      .map(
                        (link) => InkWell(
                          onTap: link.onTap,
                          child: Text(
                            link.label,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: colorScheme.primary,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: AppSpacing.sm),
                const Divider(),
                const SizedBox(height: AppSpacing.sm),
              ],
              if (appName != null)
                Text(
                  appName!,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              if (version != null)
                Text(
                  version!,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class AppFooterLink {
  const AppFooterLink({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;
}

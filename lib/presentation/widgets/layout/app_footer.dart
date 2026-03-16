import 'package:flutter/material.dart';

import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_text_styles.dart';

/// メインフッター
///
/// アプリ下部に表示される固定フッターバー。
class AppFooter extends StatelessWidget {
  const AppFooter({
    super.key,
    this.items,
  });

  final List<AppFooterItem>? items;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      height: AppSpacing.footerHeight,
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(
          top: BorderSide(color: scheme.outline, width: 1),
        ),
      ),
      child: items != null && items!.isNotEmpty
          ? Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: items!
                  .map((item) => _FooterTab(item: item))
                  .toList(),
            )
          : Center(
              child: Text(
                '© デジタル庁',
                style: AppTextStyles.dnsSmNormal.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
    );
  }
}

class AppFooterItem {
  const AppFooterItem({
    required this.label,
    required this.icon,
    required this.onTap,
    this.isSelected = false,
    this.badge,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool isSelected;
  final int? badge;
}

class _FooterTab extends StatelessWidget {
  const _FooterTab({required this.item});

  final AppFooterItem item;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color =
        item.isSelected ? scheme.primary : scheme.onSurfaceVariant;

    return Expanded(
      child: InkWell(
        onTap: item.onTap,
        child: SizedBox(
          height: AppSpacing.footerHeight,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(item.icon, size: 24, color: color),
                  if (item.badge != null && item.badge! > 0)
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
                          '${item.badge}',
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
              const SizedBox(height: 2),
              Text(
                item.label,
                style: AppTextStyles.dnsSmNormal.copyWith(
                  color: color,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

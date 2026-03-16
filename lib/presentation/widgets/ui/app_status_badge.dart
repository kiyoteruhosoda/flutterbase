import 'package:flutter/material.dart';

import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_radius.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_text_styles.dart';

enum AppStatusType { success, warning, error, info, neutral }

/// ステータスバッジ
///
/// 成功・警告・エラー・情報・通常の5種類のステータスを表示します。
class AppStatusBadge extends StatelessWidget {
  const AppStatusBadge({
    super.key,
    required this.label,
    required this.type,
  });

  final String label;
  final AppStatusType type;

  @override
  Widget build(BuildContext context) {
    final isLight =
        Theme.of(context).colorScheme.brightness == Brightness.light;

    final (bgColor, textColor, iconData) = switch (type) {
      AppStatusType.success => (
          isLight ? AppColors.successBgLight : AppColors.successBgDark,
          isLight ? AppColors.successTextLight : AppColors.successTextDark,
          Icons.check_circle_outline,
        ),
      AppStatusType.warning => (
          isLight ? AppColors.warningBgLight : AppColors.warningBgDark,
          isLight ? AppColors.warningTextLight : AppColors.warningTextDark,
          Icons.warning_amber_outlined,
        ),
      AppStatusType.error => (
          isLight ? AppColors.errorBgLight : AppColors.errorBgDark,
          isLight ? AppColors.errorTextLight : AppColors.errorTextDark,
          Icons.error_outline,
        ),
      AppStatusType.info => (
          isLight ? AppColors.umi50 : AppColors.umi700,
          isLight ? AppColors.umi600 : AppColors.umi300,
          Icons.info_outline,
        ),
      AppStatusType.neutral => (
          isLight ? AppColors.sumi100 : AppColors.sumi800,
          isLight ? AppColors.sumi700 : AppColors.sumi300,
          Icons.circle_outlined,
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: AppRadius.smAll,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(iconData, size: 14, color: textColor),
          const SizedBox(width: AppSpacing.xxs),
          Text(
            label,
            style: AppTextStyles.dnsSmBold.copyWith(color: textColor),
          ),
        ],
      ),
    );
  }
}

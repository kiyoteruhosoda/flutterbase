import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';
import 'app_radius.dart';
import 'app_spacing.dart';
import 'app_text_styles.dart';

/// デジタル庁デザインシステム テーマ定義
abstract final class AppTheme {
  static ThemeData get light => _buildTheme(AppColors.lightScheme);
  static ThemeData get dark => _buildTheme(AppColors.darkScheme);

  static ThemeData _buildTheme(ColorScheme scheme) {
    final isLight = scheme.brightness == Brightness.light;

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      fontFamily: 'NotoSansJP',

      // App Bar
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        elevation: AppSpacing.appBarElevation,
        scrolledUnderElevation: 1,
        centerTitle: false,
        titleTextStyle: AppTextStyles.olnLgBold.copyWith(
          color: scheme.onPrimary,
        ),
        systemOverlayStyle: isLight
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
        iconTheme: IconThemeData(color: scheme.onPrimary, size: 24),
        actionsIconTheme: IconThemeData(color: scheme.onPrimary, size: 24),
      ),

      // Scaffold
      scaffoldBackgroundColor: scheme.surface,

      // Navigation Drawer
      drawerTheme: DrawerThemeData(
        backgroundColor: scheme.surface,
        elevation: 16,
        width: 304,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(AppRadius.xl),
            bottomRight: Radius.circular(AppRadius.xl),
          ),
        ),
      ),

      // Bottom Navigation Bar
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: scheme.surface,
        selectedItemColor: scheme.primary,
        unselectedItemColor: scheme.onSurfaceVariant,
        elevation: 8,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: AppTextStyles.dnsSmBold,
        unselectedLabelStyle: AppTextStyles.dnsSmNormal,
      ),

      // Navigation Bar (Material 3)
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surface,
        indicatorColor: scheme.primaryContainer,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: scheme.onPrimaryContainer, size: 24);
          }
          return IconThemeData(color: scheme.onSurfaceVariant, size: 24);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppTextStyles.dnsSmBold.copyWith(color: scheme.primary);
          }
          return AppTextStyles.dnsSmNormal.copyWith(
            color: scheme.onSurfaceVariant,
          );
        }),
        elevation: 3,
      ),

      // Cards
      cardTheme: CardTheme(
        color: scheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.mdAll,
          side: BorderSide(color: scheme.outline, width: 1),
        ),
        margin: const EdgeInsets.all(0),
      ),

      // Elevated Button (Primary)
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          disabledBackgroundColor: scheme.outline,
          disabledForegroundColor: scheme.onSurfaceVariant,
          elevation: 0,
          shadowColor: Colors.transparent,
          minimumSize: const Size(double.infinity, AppSpacing.minTapTarget),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.smAll),
          textStyle: AppTextStyles.olnMdBold,
        ),
      ),

      // Outlined Button (Secondary)
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.primary,
          disabledForegroundColor: scheme.onSurfaceVariant,
          minimumSize: const Size(double.infinity, AppSpacing.minTapTarget),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.smAll),
          side: BorderSide(color: scheme.primary, width: 1),
          textStyle: AppTextStyles.olnMdBold,
        ),
      ),

      // Text Button
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: scheme.primary,
          disabledForegroundColor: scheme.onSurfaceVariant,
          minimumSize: const Size(0, AppSpacing.minTapTarget),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs,
          ),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.smAll),
          textStyle: AppTextStyles.olnMdNormal,
        ),
      ),

      // Input Decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        border: OutlineInputBorder(
          borderRadius: AppRadius.smAll,
          borderSide: BorderSide(color: scheme.outline, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.smAll,
          borderSide: BorderSide(color: scheme.outline, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.smAll,
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppRadius.smAll,
          borderSide: BorderSide(color: scheme.error, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppRadius.smAll,
          borderSide: BorderSide(color: scheme.error, width: 2),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.smAll,
          borderSide: BorderSide(color: scheme.outline, width: 1),
        ),
        hintStyle: AppTextStyles.stdBaseNormal.copyWith(
          color: scheme.onSurfaceVariant,
        ),
        labelStyle: AppTextStyles.stdBaseNormal.copyWith(
          color: scheme.onSurfaceVariant,
        ),
        errorStyle: AppTextStyles.dnsSmNormal.copyWith(color: scheme.error),
      ),

      // List Tile
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: 0,
        ),
        minVerticalPadding: AppSpacing.xs,
        minLeadingWidth: 0,
        iconColor: scheme.onSurfaceVariant,
        titleTextStyle: AppTextStyles.stdBaseNormal.copyWith(
          color: scheme.onSurface,
        ),
        subtitleTextStyle: AppTextStyles.dnsSmNormal.copyWith(
          color: scheme.onSurfaceVariant,
        ),
      ),

      // Divider
      dividerTheme: DividerThemeData(
        color: scheme.outline,
        thickness: 1,
        space: 0,
      ),

      // Chip
      chipTheme: ChipThemeData(
        backgroundColor: scheme.surfaceContainerHighest,
        selectedColor: scheme.primaryContainer,
        disabledColor: scheme.surfaceContainerHighest,
        labelStyle: AppTextStyles.dnsSmNormal,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xxs,
        ),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.fullAll),
        side: BorderSide(color: scheme.outline, width: 1),
      ),

      // Snack Bar
      snackBarTheme: SnackBarThemeData(
        backgroundColor: scheme.inverseSurface,
        contentTextStyle: AppTextStyles.stdBaseNormal.copyWith(
          color: scheme.onInverseSurface,
        ),
        actionTextColor: scheme.inversePrimary,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.smAll),
        behavior: SnackBarBehavior.floating,
      ),

      // Dialog
      dialogTheme: DialogTheme(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.xlAll),
        titleTextStyle: AppTextStyles.stdMdBold.copyWith(
          color: scheme.onSurface,
        ),
        contentTextStyle: AppTextStyles.stdBaseNormal.copyWith(
          color: scheme.onSurface,
        ),
      ),

      // Switch
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return scheme.onPrimary;
          return scheme.onSurfaceVariant;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return scheme.primary;
          return scheme.outline;
        }),
      ),

      // Progress Indicator
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        circularTrackColor: scheme.surfaceContainerHighest,
        linearTrackColor: scheme.surfaceContainerHighest,
      ),

      // Icon
      iconTheme: IconThemeData(color: scheme.onSurface, size: 24),

      // Text
      textTheme: TextTheme(
        displayLarge: AppTextStyles.dspLgBold,
        displayMedium: AppTextStyles.dspMdBold,
        displaySmall: AppTextStyles.dspSmBold,
        headlineLarge: AppTextStyles.stdXxlBold,
        headlineMedium: AppTextStyles.stdXlBold,
        headlineSmall: AppTextStyles.stdLgBold,
        titleLarge: AppTextStyles.stdMdBold,
        titleMedium: AppTextStyles.stdSmBold,
        titleSmall: AppTextStyles.stdBaseBold,
        bodyLarge: AppTextStyles.stdBaseNormal,
        bodyMedium: AppTextStyles.dnsLgNormal,
        bodySmall: AppTextStyles.dnsSmNormal,
        labelLarge: AppTextStyles.olnMdBold,
        labelMedium: AppTextStyles.olnSmBold,
        labelSmall: AppTextStyles.dnsSmBold,
      ).apply(
        bodyColor: scheme.onSurface,
        displayColor: scheme.onSurface,
      ),
    );
  }
}

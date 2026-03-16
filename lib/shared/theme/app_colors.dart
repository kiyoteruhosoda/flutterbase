import 'package:flutter/material.dart';

/// デジタル庁デザインシステム カラートークン
/// https://design.digital.go.jp/dads/foundations/color/
abstract final class AppColors {
  // ---------------------------------------------------------------------------
  // Reference Tokens - Sumi (墨) Scale
  // ---------------------------------------------------------------------------
  static const Color sumiWhite = Color(0xFFFFFFFF);
  static const Color sumi50 = Color(0xFFF8F8F8);
  static const Color sumi100 = Color(0xFFF1F1F3);
  static const Color sumi200 = Color(0xFFD9D9D9);
  static const Color sumi300 = Color(0xFFCBCBCB);
  static const Color sumi400 = Color(0xFFB0B0B0);
  static const Color sumi500 = Color(0xFF949494);
  static const Color sumi600 = Color(0xFF767676);
  static const Color sumi700 = Color(0xFF595959);
  static const Color sumi800 = Color(0xFF414143);
  static const Color sumi900 = Color(0xFF1A1A1C);
  static const Color sumiBlack = Color(0xFF000000);

  // ---------------------------------------------------------------------------
  // Reference Tokens - Umi (海) Scale (Blue)
  // ---------------------------------------------------------------------------
  static const Color umi50 = Color(0xFFF0F4FA);
  static const Color umi100 = Color(0xFFD8E2EE);
  static const Color umi200 = Color(0xFFB3C3DC);
  static const Color umi300 = Color(0xFF849EC1);
  static const Color umi400 = Color(0xFF4068D5);
  static const Color umi500 = Color(0xFF003AD2);
  static const Color umi600 = Color(0xFF0017C1);
  static const Color umi700 = Color(0xFF001C9C);

  // ---------------------------------------------------------------------------
  // Reference Tokens - Midori (緑) Scale (Green)
  // ---------------------------------------------------------------------------
  static const Color midori50 = Color(0xFFEBF5ED);
  static const Color midori100 = Color(0xFFCDE9D3);
  static const Color midori200 = Color(0xFF9DD3AA);
  static const Color midori300 = Color(0xFF5BB974);
  static const Color midori400 = Color(0xFF23A046);
  static const Color midori500 = Color(0xFF1B7A37);
  static const Color midori600 = Color(0xFF005825);

  // ---------------------------------------------------------------------------
  // Reference Tokens - Ki (黄) Scale (Amber/Warning)
  // ---------------------------------------------------------------------------
  static const Color ki50 = Color(0xFFFFF6E5);
  static const Color ki100 = Color(0xFFFFEDC7);
  static const Color ki200 = Color(0xFFFFD891);
  static const Color ki300 = Color(0xFFFFBC54);
  static const Color ki400 = Color(0xFFFF9500);
  static const Color ki500 = Color(0xFFC87000);
  static const Color ki600 = Color(0xFF87521F);

  // ---------------------------------------------------------------------------
  // Reference Tokens - Suo (蘇芳) Scale (Red)
  // ---------------------------------------------------------------------------
  static const Color suo50 = Color(0xFFFDF2F2);
  static const Color suo100 = Color(0xFFFADAD8);
  static const Color suo200 = Color(0xFFF6A8A3);
  static const Color suo300 = Color(0xFFF4736A);
  static const Color suo400 = Color(0xFFE83B3B);
  static const Color suo500 = Color(0xFFC80000);
  static const Color suo600 = Color(0xFF780000);

  // ---------------------------------------------------------------------------
  // Semantic Tokens - Light Mode
  // ---------------------------------------------------------------------------
  static const ColorScheme lightScheme = ColorScheme(
    brightness: Brightness.light,
    primary: umi600,
    onPrimary: sumiWhite,
    primaryContainer: umi50,
    onPrimaryContainer: umi700,
    secondary: sumi700,
    onSecondary: sumiWhite,
    secondaryContainer: sumi100,
    onSecondaryContainer: sumi900,
    tertiary: midori500,
    onTertiary: sumiWhite,
    tertiaryContainer: midori50,
    onTertiaryContainer: midori600,
    error: suo500,
    onError: sumiWhite,
    errorContainer: suo50,
    onErrorContainer: suo600,
    surface: sumiWhite,
    onSurface: sumi900,
    surfaceContainerHighest: sumi100,
    onSurfaceVariant: sumi700,
    outline: sumi200,
    outlineVariant: sumi300,
    shadow: sumiBlack,
    scrim: sumiBlack,
    inverseSurface: sumi900,
    onInverseSurface: sumi100,
    inversePrimary: umi300,
  );

  // ---------------------------------------------------------------------------
  // Semantic Tokens - Dark Mode
  // ---------------------------------------------------------------------------
  static const ColorScheme darkScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: umi400,
    onPrimary: sumiWhite,
    primaryContainer: umi700,
    onPrimaryContainer: umi100,
    secondary: sumi400,
    onSecondary: sumi900,
    secondaryContainer: sumi800,
    onSecondaryContainer: sumi100,
    tertiary: midori300,
    onTertiary: midori600,
    tertiaryContainer: midori600,
    onTertiaryContainer: midori50,
    error: suo300,
    onError: suo600,
    errorContainer: suo600,
    onErrorContainer: suo50,
    surface: sumi900,
    onSurface: sumi100,
    surfaceContainerHighest: sumi800,
    onSurfaceVariant: sumi400,
    outline: sumi700,
    outlineVariant: sumi600,
    shadow: sumiBlack,
    scrim: sumiBlack,
    inverseSurface: sumi100,
    onInverseSurface: sumi900,
    inversePrimary: umi600,
  );

  // ---------------------------------------------------------------------------
  // Semantic Color Aliases (Light)
  // ---------------------------------------------------------------------------
  static const Color textPrimaryLight = sumi900;
  static const Color textSecondaryLight = sumi700;
  static const Color textDisabledLight = sumi500;
  static const Color textLinkLight = umi600;
  static const Color textLinkVisitedLight = Color(0xFF5C2B9D);

  static const Color bgPageLight = sumiWhite;
  static const Color bgSurfaceLight = sumi100;
  static const Color bgBrandLight = umi600;
  static const Color bgBrandHoverLight = umi700;

  static const Color borderDefaultLight = sumi200;
  static const Color borderStrongLight = sumi700;

  static const Color successTextLight = midori600;
  static const Color successBgLight = midori50;
  static const Color warningTextLight = ki600;
  static const Color warningBgLight = ki50;
  static const Color errorTextLight = suo600;
  static const Color errorBgLight = suo50;

  // ---------------------------------------------------------------------------
  // Semantic Color Aliases (Dark)
  // ---------------------------------------------------------------------------
  static const Color textPrimaryDark = sumi100;
  static const Color textSecondaryDark = sumi400;
  static const Color textDisabledDark = sumi600;
  static const Color textLinkDark = umi300;
  static const Color textLinkVisitedDark = Color(0xFFB294E8);

  static const Color bgPageDark = sumi900;
  static const Color bgSurfaceDark = sumi800;
  static const Color bgBrandDark = umi400;
  static const Color bgBrandHoverDark = umi300;

  static const Color borderDefaultDark = sumi700;
  static const Color borderStrongDark = sumi400;

  static const Color successTextDark = midori300;
  static const Color successBgDark = midori600;
  static const Color warningTextDark = ki300;
  static const Color warningBgDark = ki600;
  static const Color errorTextDark = suo300;
  static const Color errorBgDark = suo600;
}

/// デジタル庁デザインシステム スペーシングトークン
/// https://design.digital.go.jp/dads/foundations/spacing/
/// Base unit: 8px
abstract final class AppSpacing {
  /// 4px — micro gap (sub-element spacing)
  static const double xxs = 4.0;

  /// 8px — base unit
  static const double xs = 8.0;

  /// 12px — compact gap
  static const double sm = 12.0;

  /// 16px — standard gap
  static const double md = 16.0;

  /// 24px — section gap (3x base)
  static const double lg = 24.0;

  /// 32px — content group gap
  static const double xl = 32.0;

  /// 40px — large section gap
  static const double xxl = 40.0;

  /// 48px — page section gap
  static const double xxxl = 48.0;

  /// 64px — major section gap (8x base)
  static const double huge = 64.0;

  /// 80px — hero spacing
  static const double hero = 80.0;

  /// Minimum tap target (48dp)
  static const double minTapTarget = 48.0;

  /// Standard header height
  static const double headerHeight = 56.0;

  /// Standard footer height
  static const double footerHeight = 56.0;

  /// Standard app bar elevation
  static const double appBarElevation = 0.0;

  /// Page horizontal padding
  static const double pageHorizontalPadding = 16.0;

  /// Page vertical padding
  static const double pageVerticalPadding = 24.0;
}

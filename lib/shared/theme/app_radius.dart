import 'package:flutter/material.dart';

/// デジタル庁デザインシステム 角丸トークン
/// https://design.digital.go.jp/dads/foundations/corner-shapes/
abstract final class AppRadius {
  /// 0px — no rounding (rectangular)
  static const double none = 0.0;

  /// 2px — subtle rounding
  static const double xs = 2.0;

  /// 4px — small rounding (badges, chips)
  static const double sm = 4.0;

  /// 8px — standard rounding (cards, inputs)
  static const double md = 8.0;

  /// 12px — medium rounding
  static const double lg = 12.0;

  /// 16px — large rounding (modals, sheets)
  static const double xl = 16.0;

  /// 24px — extra large rounding
  static const double xxl = 24.0;

  /// Full pill shape
  static const double full = 9999.0;

  // BorderRadius convenience helpers
  static BorderRadius get noneAll => BorderRadius.circular(none);
  static BorderRadius get xsAll => BorderRadius.circular(xs);
  static BorderRadius get smAll => BorderRadius.circular(sm);
  static BorderRadius get mdAll => BorderRadius.circular(md);
  static BorderRadius get lgAll => BorderRadius.circular(lg);
  static BorderRadius get xlAll => BorderRadius.circular(xl);
  static BorderRadius get xxlAll => BorderRadius.circular(xxl);
  static BorderRadius get fullAll => BorderRadius.circular(full);
}

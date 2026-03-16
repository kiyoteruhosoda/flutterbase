import 'package:flutter/material.dart';

/// デジタル庁デザインシステム タイポグラフィトークン
/// https://design.digital.go.jp/dads/foundations/typography/
/// Font: Noto Sans JP
/// Weights: Regular (400), Medium (500), Bold (700)
abstract final class AppTextStyles {
  static const String _fontFamily = 'NotoSansJP';

  // ---------------------------------------------------------------------------
  // Display (Dsp) — High-impact headlines 48–64px, 140% leading
  // ---------------------------------------------------------------------------

  static const TextStyle dspLgBold = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 64,
    fontWeight: FontWeight.w700,
    height: 1.4,
    letterSpacing: 0,
  );

  static const TextStyle dspMdBold = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 56,
    fontWeight: FontWeight.w700,
    height: 1.4,
    letterSpacing: 0,
  );

  static const TextStyle dspSmBold = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 48,
    fontWeight: FontWeight.w700,
    height: 1.4,
    letterSpacing: 0,
  );

  // ---------------------------------------------------------------------------
  // Standard (Std) — Document structure 16–45px
  // ---------------------------------------------------------------------------

  static const TextStyle stdXxlBold = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 45,
    fontWeight: FontWeight.w700,
    height: 1.4,
    letterSpacing: 0,
  );

  static const TextStyle stdXlBold = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 36,
    fontWeight: FontWeight.w700,
    height: 1.4,
    letterSpacing: 0,
  );

  static const TextStyle stdLgBold = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 28,
    fontWeight: FontWeight.w700,
    height: 1.4,
    letterSpacing: 0,
  );

  static const TextStyle stdMdBold = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 24,
    fontWeight: FontWeight.w700,
    height: 1.5,
    letterSpacing: 0,
  );

  static const TextStyle stdMdNormal = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 24,
    fontWeight: FontWeight.w400,
    height: 1.5,
    letterSpacing: 0,
  );

  static const TextStyle stdSmBold = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 20,
    fontWeight: FontWeight.w700,
    height: 1.5,
    letterSpacing: 0,
  );

  static const TextStyle stdSmNormal = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 20,
    fontWeight: FontWeight.w400,
    height: 1.5,
    letterSpacing: 0,
  );

  static const TextStyle stdBaseBold = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w700,
    height: 1.75,
    letterSpacing: 0.02,
  );

  static const TextStyle stdBaseNormal = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.75,
    letterSpacing: 0.02,
  );

  // ---------------------------------------------------------------------------
  // Dense (Dns) — Data-dense layouts 14–17px
  // ---------------------------------------------------------------------------

  static const TextStyle dnsLgBold = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 17,
    fontWeight: FontWeight.w700,
    height: 1.3,
    letterSpacing: 0.02,
  );

  static const TextStyle dnsLgNormal = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 17,
    fontWeight: FontWeight.w400,
    height: 1.3,
    letterSpacing: 0.02,
  );

  static const TextStyle dnsMdBold = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 15,
    fontWeight: FontWeight.w700,
    height: 1.3,
    letterSpacing: 0.02,
  );

  static const TextStyle dnsMdNormal = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 15,
    fontWeight: FontWeight.w400,
    height: 1.3,
    letterSpacing: 0.02,
  );

  static const TextStyle dnsSmBold = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w700,
    height: 1.3,
    letterSpacing: 0.02,
  );

  static const TextStyle dnsSmNormal = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.3,
    letterSpacing: 0.02,
  );

  // ---------------------------------------------------------------------------
  // Oneline (Oln) — UI elements, 100% line height
  // ---------------------------------------------------------------------------

  static const TextStyle olnLgBold = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 20,
    fontWeight: FontWeight.w700,
    height: 1.0,
    letterSpacing: 0,
  );

  static const TextStyle olnLgNormal = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 20,
    fontWeight: FontWeight.w400,
    height: 1.0,
    letterSpacing: 0,
  );

  static const TextStyle olnMdBold = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w700,
    height: 1.0,
    letterSpacing: 0,
  );

  static const TextStyle olnMdNormal = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.0,
    letterSpacing: 0,
  );

  static const TextStyle olnSmBold = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w700,
    height: 1.0,
    letterSpacing: 0,
  );

  static const TextStyle olnSmNormal = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.0,
    letterSpacing: 0,
  );

  // ---------------------------------------------------------------------------
  // Mono — Code content
  // ---------------------------------------------------------------------------

  static const TextStyle monoMd = TextStyle(
    fontFamily: 'NotoSansMono',
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.6,
    letterSpacing: 0,
  );
}

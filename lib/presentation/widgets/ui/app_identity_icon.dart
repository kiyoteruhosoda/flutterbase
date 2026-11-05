import 'package:flutter/material.dart';
import 'package:flutterbase/presentation/theme/theme.dart';

/// The app's own icon — the same picture as on the home screen — for the
/// screens that introduce the app (About, Licenses).
///
/// Drawn from `assets/icon/app_icon.png`, the source `flutter_launcher_icons`
/// makes the launcher icon from. An app made from this template replaces that
/// file with its own icon and these screens follow without further changes
/// (docs/adr/0017-about-screens-show-the-launcher-icon.md).
class AppIdentityIcon extends StatelessWidget {
  const AppIdentityIcon({super.key, this.size = AppSpacing.aboutIconContainer});

  /// The launcher icon's source, as declared under `flutter_launcher_icons:`
  /// in pubspec.yaml.
  static const String asset = 'assets/icon/app_icon.png';

  /// The width and height of the icon.
  final double size;

  @override
  Widget build(BuildContext context) {
    final outline = Theme.of(context).colorScheme.outlineVariant;
    // Rounded like a launcher icon; the hairline keeps a white icon from
    // dissolving into a white page.
    return DecoratedBox(
      position: DecorationPosition.foreground,
      decoration: BoxDecoration(
        borderRadius: AppRadius.xxlBorder,
        border: Border.all(color: outline, width: 0.5),
      ),
      child: ClipRRect(
        borderRadius: AppRadius.xxlBorder,
        child: Image.asset(
          asset,
          width: size,
          height: size,
          fit: BoxFit.cover,
          filterQuality: FilterQuality.medium,
          // The app's name is written right next to it.
          excludeFromSemantics: true,
        ),
      ),
    );
  }
}

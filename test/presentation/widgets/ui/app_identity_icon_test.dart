import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutterbase/presentation/widgets/ui/app_identity_icon.dart';

void main() {
  test('draws the same picture the launcher icon is made from', () {
    // If the two drift apart, About and Licenses show a different picture
    // from the home screen.
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final imagePath = RegExp(
      r'''^flutter_launcher_icons:[\s\S]*?^\s+image_path:\s*["']?([^"'\s]+)''',
      multiLine: true,
    ).firstMatch(pubspec)?.group(1);
    expect(imagePath, AppIdentityIcon.asset);
    expect(File(AppIdentityIcon.asset).existsSync(), isTrue);
  });

  testWidgets('shows the asset at the requested size, hidden from readers', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: Center(child: AppIdentityIcon(size: 48))),
    );
    final image = tester.widget<Image>(find.byType(Image));
    expect((image.image as AssetImage).assetName, AppIdentityIcon.asset);
    expect(image.width, 48);
    expect(image.height, 48);
    expect(image.excludeFromSemantics, isTrue);
  });
}

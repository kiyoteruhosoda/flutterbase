import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutterbase/presentation/viewmodels/theme_viewmodel.dart';

void main() {
  group('ThemeViewModel', () {
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
    });

    test('defaults to light mode when no preference is saved', () {
      final vm = ThemeViewModel(prefs);
      expect(vm.themeMode, equals(ThemeMode.light));
    });

    test('persists and restores light mode', () async {
      final vm = ThemeViewModel(prefs);
      await vm.setThemeMode(ThemeMode.light);

      final vm2 = ThemeViewModel(prefs);
      expect(vm2.themeMode, equals(ThemeMode.light));
    });

    test('persists and restores dark mode', () async {
      final vm = ThemeViewModel(prefs);
      await vm.setThemeMode(ThemeMode.dark);

      final vm2 = ThemeViewModel(prefs);
      expect(vm2.themeMode, equals(ThemeMode.dark));
    });

    test('persists and restores system mode', () async {
      final vm = ThemeViewModel(prefs);
      await vm.setThemeMode(ThemeMode.system);

      final vm2 = ThemeViewModel(prefs);
      expect(vm2.themeMode, equals(ThemeMode.system));
    });

    test('notifies listeners when theme changes', () async {
      final vm = ThemeViewModel(prefs);
      var notified = false;
      vm.addListener(() => notified = true);

      await vm.setThemeMode(ThemeMode.dark);

      expect(notified, isTrue);
    });

    test('does not notify when the same theme is set again', () async {
      final vm = ThemeViewModel(prefs);
      await vm.setThemeMode(ThemeMode.light); // already light

      var notified = false;
      vm.addListener(() => notified = true);
      await vm.setThemeMode(ThemeMode.light); // same — no notification

      expect(notified, isFalse);
    });

    test('can cycle through all three modes', () async {
      final vm = ThemeViewModel(prefs);

      await vm.setThemeMode(ThemeMode.dark);
      expect(vm.themeMode, equals(ThemeMode.dark));

      await vm.setThemeMode(ThemeMode.system);
      expect(vm.themeMode, equals(ThemeMode.system));

      await vm.setThemeMode(ThemeMode.light);
      expect(vm.themeMode, equals(ThemeMode.light));
    });
  });
}

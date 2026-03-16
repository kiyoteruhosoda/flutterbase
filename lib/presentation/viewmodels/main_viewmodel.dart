import 'package:flutter/material.dart';

/// メイン画面のUI状態
enum MainPageTab { home, search, settings }

/// メイン画面ViewModel
class MainViewModel extends ChangeNotifier {
  MainPageTab _selectedTab = MainPageTab.home;
  bool _isDrawerOpen = false;

  MainPageTab get selectedTab => _selectedTab;
  bool get isDrawerOpen => _isDrawerOpen;

  void selectTab(MainPageTab tab) {
    if (_selectedTab == tab) return;
    _selectedTab = tab;
    notifyListeners();
  }

  void openDrawer() {
    _isDrawerOpen = true;
    notifyListeners();
  }

  void closeDrawer() {
    _isDrawerOpen = false;
    notifyListeners();
  }
}

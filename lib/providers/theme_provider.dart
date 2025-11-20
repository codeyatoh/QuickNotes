import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'user_settings_provider.dart';

class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode = false;
  bool _isInitialized = false;
  UserSettingsProvider? _userSettingsProvider;

  bool get isDarkMode => _isDarkMode;

  /// Initialize theme provider with optional UserSettingsProvider for Firestore sync
  Future<void> init({UserSettingsProvider? userSettingsProvider}) async {
    if (_isInitialized) return;
    
    _userSettingsProvider = userSettingsProvider;
    
    // Load from Firestore if available, otherwise from SharedPreferences
    if (_userSettingsProvider != null) {
      _isDarkMode = _userSettingsProvider!.isDarkMode;
    } else {
      final prefs = await SharedPreferences.getInstance();
      _isDarkMode = prefs.getBool('darkMode') ?? false;
    }
    
    _isInitialized = true;
    notifyListeners();
  }

  /// Toggle theme and sync to Firestore
  Future<void> toggleTheme() async {
    final newValue = !_isDarkMode;
    await setTheme(newValue);
  }

  /// Set theme and sync to Firestore
  Future<void> setTheme(bool isDark) async {
    _isDarkMode = isDark;
    
    // Sync to Firestore if UserSettingsProvider is available
    if (_userSettingsProvider != null) {
      final theme = isDark ? 'dark' : 'light';
      await _userSettingsProvider!.updateTheme(theme);
    } else {
      // Fallback to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('darkMode', _isDarkMode);
    }
    
    notifyListeners();
  }

  /// Update from UserSettingsProvider (called when Firestore updates)
  void updateFromUserSettings(UserSettingsProvider userSettings) {
    if (_isDarkMode != userSettings.isDarkMode) {
      _isDarkMode = userSettings.isDarkMode;
      notifyListeners();
    }
  }
}


import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PreferencesProvider with ChangeNotifier {
  static const String _themeKey = 'theme_mode';
  static const String _unitKey = 'speed_unit';
  static const String _notificationsKey = 'notifications_enabled';
  static const String _autoTestKey = 'auto_test_enabled';
  static const String _autoTestIntervalKey = 'auto_test_interval';

  ThemeMode _themeMode = ThemeMode.dark;
  String _speedUnit = 'Mbps';
  bool _notificationsEnabled = true;
  bool _autoTestEnabled = false;
  int _autoTestInterval = 60; // en minutes

  // Getters
  ThemeMode get themeMode => _themeMode;
  String get speedUnit => _speedUnit;
  bool get notificationsEnabled => _notificationsEnabled;
  bool get autoTestEnabled => _autoTestEnabled;
  int get autoTestInterval => _autoTestInterval;

  String get themeDisplayName {
    switch (_themeMode) {
      case ThemeMode.light:
        return 'Clair';
      case ThemeMode.dark:
        return 'Sombre';
      case ThemeMode.system:
        return 'Système';
    }
  }

  // Initialisation des préférences
  Future<void> loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();

    final themeIndex = prefs.getInt(_themeKey) ?? 1; // 1 = dark par défaut
    _themeMode = ThemeMode.values[themeIndex];

    _speedUnit = prefs.getString(_unitKey) ?? 'Mbps';
    _notificationsEnabled = prefs.getBool(_notificationsKey) ?? true;
    _autoTestEnabled = prefs.getBool(_autoTestKey) ?? false;
    _autoTestInterval = prefs.getInt(_autoTestIntervalKey) ?? 60;

    notifyListeners();
  }

  // Setters avec sauvegarde
  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeKey, mode.index);
    notifyListeners();
  }

  Future<void> setSpeedUnit(String unit) async {
    _speedUnit = unit;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_unitKey, unit);
    notifyListeners();
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    _notificationsEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notificationsKey, enabled);
    notifyListeners();
  }

  Future<void> setAutoTestEnabled(bool enabled) async {
    _autoTestEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_autoTestKey, enabled);
    notifyListeners();
  }

  Future<void> setAutoTestInterval(int interval) async {
    _autoTestInterval = interval;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_autoTestIntervalKey, interval);
    notifyListeners();
  }

  // Conversion d'unité
  double convertSpeed(double value, String fromUnit, String toUnit) {
    if (fromUnit == toUnit) return value;

    // Convertir vers Mbps d'abord
    double mbps = value;
    switch (fromUnit) {
      case 'Kbps':
        mbps = value / 1000;
        break;
      case 'Gbps':
        mbps = value * 1000;
        break;
    }

    // Convertir vers l'unité cible
    switch (toUnit) {
      case 'Kbps':
        return mbps * 1000;
      case 'Gbps':
        return mbps / 1000;
      default:
        return mbps;
    }
  }
}
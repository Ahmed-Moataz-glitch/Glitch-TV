import 'package:flutter/material.dart';

abstract class SettingsLocalDataSource {
  Future<ThemeMode> getThemeMode();
  Future<void> saveThemeMode(ThemeMode themeMode);

  Future<Locale> getLanguage();
  Future<void> saveLanguage(String languageCode);
}

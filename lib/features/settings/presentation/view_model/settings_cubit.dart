import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:glitch_tv/features/settings/domain/repo/data_source/settings_local_data_source.dart';
import 'package:glitch_tv/features/settings/presentation/view_model/settings_state.dart';

class SettingsCubit extends Cubit<SettingsState> {
  final SettingsLocalDataSource _localDataSource;

  SettingsCubit({required SettingsLocalDataSource localDataSource})
      : _localDataSource = localDataSource,
        super(const SettingsState());

  Future<void> loadSettings() async {
    final themeMode = await _localDataSource.getThemeMode();
    final locale = await _localDataSource.getLanguage();
    emit(state.copyWith(
      themeMode: themeMode,
      locale: locale,
    ));
  }

  Future<void> setThemeMode(ThemeMode themeMode) async {
    emit(state.copyWith(themeMode: themeMode));
    await _localDataSource.saveThemeMode(themeMode);
  }

  Future<void> setLanguage(String languageCode) async {
    final newLocale = Locale(languageCode);
    emit(state.copyWith(locale: newLocale));
    await _localDataSource.saveLanguage(languageCode);
  }
}

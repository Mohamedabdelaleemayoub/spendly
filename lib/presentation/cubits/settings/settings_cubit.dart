import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'settings_state.dart';

class SettingsCubit extends Cubit<SettingsState> {
  SettingsCubit({required this.prefs})
      : super(
          SettingsState(
            locale: _loadLocale(prefs),
            themeMode: _loadThemeMode(prefs),
          ),
        );

  final SharedPreferences prefs;

  @override
  void emit(SettingsState state) {
    if (!isClosed) {
      super.emit(state);
    }
  }

  static const String _keyLanguage = 'spendly_language_code';
  static const String _keyThemeMode = 'spendly_theme_mode';

  static Locale _loadLocale(SharedPreferences prefs) {
    final code = prefs.getString(_keyLanguage) ?? 'ar';
    return Locale(code);
  }

  static ThemeMode _loadThemeMode(SharedPreferences prefs) {
    final modeStr = prefs.getString(_keyThemeMode) ?? 'light';
    switch (modeStr) {
      case 'dark':
        return ThemeMode.dark;
      case 'system':
        return ThemeMode.system;
      case 'light':
      default:
        return ThemeMode.light;
    }
  }

  Future<void> setLocale(Locale locale) async {
    if (state.locale == locale) return;
    await prefs.setString(_keyLanguage, locale.languageCode);
    emit(state.copyWith(locale: locale));
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (state.themeMode == mode) return;
    String modeStr = 'light';
    if (mode == ThemeMode.dark) modeStr = 'dark';
    if (mode == ThemeMode.system) modeStr = 'system';

    await prefs.setString(_keyThemeMode, modeStr);
    emit(state.copyWith(themeMode: mode));
  }

  Future<void> toggleLanguage() async {
    final newLocale = state.isArabic ? const Locale('en') : const Locale('ar');
    await setLocale(newLocale);
  }
}

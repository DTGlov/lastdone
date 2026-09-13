import 'dart:async';

import 'package:flutter/material.dart';

import '../features/profile/domain/profile_settings.dart';

class AppPreferencesController extends ChangeNotifier {
  AppPreferencesController(this.store) {
    unawaited(_load());
  }
  final ProfileSettingsStore store;
  String? displayNameValue;
  AppThemePreference theme = AppThemePreference.system;
  String currency = 'GHS';
  bool ready = false;

  ThemeMode get themeMode => switch (theme) {
    AppThemePreference.system => ThemeMode.system,
    AppThemePreference.light => ThemeMode.light,
    AppThemePreference.dark => ThemeMode.dark,
  };

  String get greetingName =>
      displayNameValue == null || displayNameValue!.trim().isEmpty
      ? ''
      : ', ${displayNameValue!.trim()}';

  Future<void> _load() async {
    displayNameValue = await store.displayName();
    theme = await store.themePreference();
    currency = await store.defaultCurrency();
    ready = true;
    notifyListeners();
  }

  Future<void> saveName(String value) async {
    final trimmed = value.trim();
    final nextName = trimmed.isEmpty ? null : trimmed;
    await store.saveDisplayName(nextName);
    displayNameValue = nextName;
    notifyListeners();
  }

  Future<void> saveTheme(AppThemePreference value) async {
    theme = value;
    await store.saveThemePreference(value);
    notifyListeners();
  }

  Future<void> saveCurrency(String value) async {
    currency = value;
    await store.saveDefaultCurrency(value);
    notifyListeners();
  }
}

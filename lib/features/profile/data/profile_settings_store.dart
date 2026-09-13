import 'package:shared_preferences/shared_preferences.dart';

import '../domain/profile_settings.dart';

class SharedPreferencesProfileSettingsStore implements ProfileSettingsStore {
  SharedPreferencesProfileSettingsStore(this.preferences);
  final SharedPreferences preferences;
  static const _nameKey = 'profile.display_name';
  static const _themeKey = 'profile.theme';
  static const _currencyKey = 'profile.default_currency';

  @override
  Future<String?> displayName() async => preferences.getString(_nameKey);

  @override
  Future<void> saveDisplayName(String? value) async {
    if (value == null || value.trim().isEmpty) {
      await preferences.remove(_nameKey);
    } else {
      await preferences.setString(_nameKey, value.trim());
    }
  }

  @override
  Future<AppThemePreference> themePreference() async {
    final value = preferences.getString(_themeKey);
    return AppThemePreference.values.firstWhere(
      (item) => item.name == value,
      orElse: () => AppThemePreference.system,
    );
  }

  @override
  Future<void> saveThemePreference(AppThemePreference value) async {
    await preferences.setString(_themeKey, value.name);
  }

  @override
  Future<String> defaultCurrency() async =>
      preferences.getString(_currencyKey) ?? 'GHS';

  @override
  Future<void> saveDefaultCurrency(String value) async {
    await preferences.setString(_currencyKey, value);
  }
}

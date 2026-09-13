enum AppThemePreference { system, light, dark }

abstract interface class ProfileSettingsStore {
  Future<String?> displayName();
  Future<void> saveDisplayName(String? value);
  Future<AppThemePreference> themePreference();
  Future<void> saveThemePreference(AppThemePreference value);
  Future<String> defaultCurrency();
  Future<void> saveDefaultCurrency(String value);
}

class ProfileStatistics {
  const ProfileStatistics({
    required this.activeTrackerCount,
    required this.monthCompletionCount,
    required this.totalCompletionCount,
    required this.activeSubscriptionCount,
    required this.monthlySubscriptionTotals,
  });
  final int activeTrackerCount;
  final int monthCompletionCount;
  final int totalCompletionCount;
  final int activeSubscriptionCount;
  final Map<String, int> monthlySubscriptionTotals;
}

abstract interface class ProfileStatisticsRepository {
  Future<ProfileStatistics> getStatistics(DateTime now);
  Stream<ProfileStatistics> watchStatistics(DateTime now);
}

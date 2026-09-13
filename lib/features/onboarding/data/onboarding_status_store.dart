import 'package:shared_preferences/shared_preferences.dart';

abstract interface class OnboardingStatusStore {
  Future<bool> isComplete();
  Future<void> markComplete();
  Future<void> setReminderIntent(bool wantsReminders);
}

class SharedPreferencesOnboardingStatusStore implements OnboardingStatusStore {
  SharedPreferencesOnboardingStatusStore(this.preferences);
  final SharedPreferences preferences;
  static const _completeKey = 'onboarding.completed';
  static const _reminderKey = 'onboarding.reminderIntent';

  @override
  Future<bool> isComplete() async => preferences.getBool(_completeKey) ?? false;

  @override
  Future<void> markComplete() async {
    await preferences.setBool(_completeKey, true);
  }

  @override
  Future<void> setReminderIntent(bool wantsReminders) async {
    await preferences.setBool(_reminderKey, wantsReminders);
  }
}

class MemoryOnboardingStatusStore implements OnboardingStatusStore {
  bool complete = false;
  bool? reminderIntent;

  @override
  Future<bool> isComplete() async => complete;
  @override
  Future<void> markComplete() async => complete = true;
  @override
  Future<void> setReminderIntent(bool wantsReminders) async =>
      reminderIntent = wantsReminders;
}

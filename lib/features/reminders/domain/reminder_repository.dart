import 'reminder.dart';

abstract interface class ReminderRepository {
  Stream<List<ReminderPreference>> watchPreferences();
  Future<List<ReminderPreference>> listPreferences();
  Future<ReminderPreference?> getPreference(ReminderTarget target);
  Future<ReminderPreference> savePreference(ReminderDraft draft, DateTime now);
  Future<int> countEnabled(ReminderTargetType type);
}

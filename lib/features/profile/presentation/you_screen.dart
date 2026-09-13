import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_preferences_controller.dart';
import '../../../core/design_system/app_icons.dart';
import '../../../core/design_system/design_tokens.dart';
import '../../../core/design_system/everdun_dialog.dart';
import '../../../core/widgets/dun_view.dart';
import '../../reminders/data/notification_gateway.dart';
import '../../reminders/domain/reminder.dart';
import '../../reminders/domain/reminder_repository.dart';
import '../domain/profile_settings.dart';
import '../../subscriptions/domain/subscription.dart';
import 'profile_view_model.dart';

class YouScreen extends StatelessWidget {
  const YouScreen({super.key});

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
    create: (_) => ProfileViewModel(
      clock: context.read(),
      statisticsRepository: context.read<ProfileStatisticsRepository?>(),
      reminderRepository: context.read<ReminderRepository>(),
      gateway: context.read<NotificationGateway>(),
    ),
    child: const _YouContent(),
  );
}

class _YouContent extends StatelessWidget {
  const _YouContent();

  @override
  Widget build(BuildContext context) {
    final preferences = context.watch<AppPreferencesController>();
    final model = context.watch<ProfileViewModel>();
    final stats = model.statistics;
    return SafeArea(
      top: true,
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
          120,
        ),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'You',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      preferences.displayNameValue == null
                          ? 'Your calm corner in EverDun.'
                          : 'A little space for ${preferences.displayNameValue}.',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ],
                ),
              ),
              const SizedBox(
                width: 84,
                height: 70,
                child: DunMascot(decorative: true),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          const _SectionLabel('Identity'),
          Card(
            child: ListTile(
              leading: const Icon(AppIcons.profile),
              title: Text(preferences.displayNameValue ?? 'Add your name'),
              subtitle: const Text('Used locally for a warmer greeting'),
              trailing: const Icon(AppIcons.edit),
              onTap: () => _editName(context, preferences),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          const _SectionLabel('Your activity'),
          if (stats == null)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.md),
                child: LinearProgressIndicator(),
              ),
            )
          else
            _StatsCard(stats: stats),
          const SizedBox(height: AppSpacing.lg),
          const _SectionLabel('Preferences'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.brightness_6_outlined),
                  title: const Text('Theme'),
                  trailing: DropdownButton<AppThemePreference>(
                    value: preferences.theme,
                    underline: const SizedBox.shrink(),
                    items: AppThemePreference.values
                        .map(
                          (value) => DropdownMenuItem(
                            value: value,
                            child: Text(_themeLabel(value)),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) preferences.saveTheme(value);
                    },
                  ),
                ),
                ListTile(
                  leading: const Icon(AppIcons.subscriptions),
                  title: const Text('Default subscription currency'),
                  trailing: DropdownButton<String>(
                    value: preferences.currency,
                    underline: const SizedBox.shrink(),
                    items:
                        const [
                              'GHS',
                              'USD',
                              'GBP',
                              'EUR',
                              'CAD',
                              'NGN',
                              'ZAR',
                              'KES',
                            ]
                            .map(
                              (value) => DropdownMenuItem(
                                value: value,
                                child: Text(value),
                              ),
                            )
                            .toList(),
                    onChanged: (value) {
                      if (value != null) preferences.saveCurrency(value);
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          const _SectionLabel('Manage your list'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.archive_outlined),
                  title: const Text('Archived trackers'),
                  subtitle: const Text(
                    'Restore trackers and keep their history',
                  ),
                  trailing: const Icon(AppIcons.next),
                  onTap: () => context.push('/archived-trackers'),
                ),
                ListTile(
                  leading: const Icon(Icons.cancel_outlined),
                  title: const Text('Cancelled subscriptions'),
                  subtitle: const Text('Restore saved subscription details'),
                  trailing: const Icon(AppIcons.next),
                  onTap: () => context.push('/cancelled-subscriptions'),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          const _SectionLabel('Reminders'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.notifications_none),
                  title: const Text('Reminder settings'),
                  subtitle: Text(
                    '${model.trackerReminders} tracker · ${model.subscriptionReminders} subscription reminders',
                  ),
                  trailing: const Icon(AppIcons.next),
                  onTap: () => context.push('/reminders'),
                ),
                if (model.permission == NotificationPermissionStatus.denied)
                  ListTile(
                    leading: const Icon(Icons.info_outline),
                    title: const Text('Permission needed'),
                    onTap: model.openNotificationSettings,
                  ),
                if (model.permission == NotificationPermissionStatus.authorized)
                  ListTile(
                    leading: const Icon(Icons.notifications_active_outlined),
                    title: const Text('Send test notification'),
                    onTap: model.sendTestNotification,
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          const _SectionLabel('About and privacy'),
          Card(
            child: Column(
              children: [
                const ListTile(
                  leading: Icon(Icons.lock_outline),
                  title: Text('Local-first privacy'),
                  subtitle: Text(
                    'Your trackers, subscriptions, and settings stay on this device.',
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: const Text('About EverDun'),
                  subtitle: const Text('Warm tools for everyday rhythms.'),
                  onTap: () => _about(context),
                ),
                ListTile(
                  leading: const Icon(Icons.menu_book_outlined),
                  title: const Text('Open-source licenses'),
                  onTap: () => showLicensePage(
                    context: context,
                    applicationName: 'EverDun',
                  ),
                ),
              ],
            ),
          ),
          if (model.errorMessage != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              model.errorMessage!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
        ],
      ),
    );
  }

  static Future<void> _editName(
    BuildContext context,
    AppPreferencesController preferences,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _NameEditorSheet(preferences: preferences),
    );
  }

  static Future<void> _about(BuildContext context) async {
    final info = await PackageInfo.fromPlatform();
    if (!context.mounted) return;
    showAboutDialog(
      context: context,
      applicationName: 'EverDun',
      applicationVersion: '${info.version} (${info.buildNumber})',
      applicationLegalese: 'Offline-first tools for everyday rhythms.',
    );
  }

  static String _themeLabel(AppThemePreference value) => switch (value) {
    AppThemePreference.system => 'System',
    AppThemePreference.light => 'Light',
    AppThemePreference.dark => 'Dark',
  };
}

class _NameEditorSheet extends StatefulWidget {
  const _NameEditorSheet({required this.preferences});
  final AppPreferencesController preferences;

  @override
  State<_NameEditorSheet> createState() => _NameEditorSheetState();
}

class _NameEditorSheetState extends State<_NameEditorSheet> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.preferences.displayNameValue ?? '',
  );
  bool _saving = false;
  String? _error;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(
      AppSpacing.lg,
      AppSpacing.sm,
      AppSpacing.lg,
      MediaQuery.viewInsetsOf(context).bottom + AppSpacing.lg,
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'What should Dun call you?',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: AppSpacing.md),
        TextField(
          controller: _controller,
          maxLength: 40,
          autofocus: true,
          decoration: InputDecoration(
            labelText: 'Display name',
            errorText: _error,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save name'),
        ),
      ],
    ),
  );

  Future<void> _save() async {
    final value = _controller.text.trim();
    if (value.length > 40) {
      setState(() => _error = 'Keep your name to 40 characters or fewer.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.preferences.saveName(value);
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = 'We could not save your name yet. Please try again.';
      });
      await showEverDunDialog<void>(
        context: context,
        title: 'Name not saved',
        message: 'Your name is still here. Please try saving it again.',
        variant: EverDunDialogVariant.error,
        primaryLabel: 'Keep editing',
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class _StatsCard extends StatelessWidget {
  const _StatsCard({required this.stats});
  final ProfileStatistics stats;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        children: [
          _StatRow('Active trackers', '${stats.activeTrackerCount}'),
          _StatRow('Handled this month', '${stats.monthCompletionCount}'),
          _StatRow('All-time completions', '${stats.totalCompletionCount}'),
          _StatRow('Active subscriptions', '${stats.activeSubscriptionCount}'),
          ...stats.monthlySubscriptionTotals.entries.map(
            (entry) => _StatRow(
              'Estimated monthly · ${entry.key}',
              formatMinorAmount(entry.value, entry.key),
            ),
          ),
        ],
      ),
    ),
  );
}

class _StatRow extends StatelessWidget {
  const _StatRow(this.label, this.value);
  final String label, value;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      children: [
        Expanded(child: Text(label)),
        Text(value, style: Theme.of(context).textTheme.titleMedium),
      ],
    ),
  );
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);
  final String label;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
    child: Text(label, style: Theme.of(context).textTheme.titleMedium),
  );
}

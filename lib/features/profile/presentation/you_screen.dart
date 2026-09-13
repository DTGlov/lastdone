import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_preferences_controller.dart';
import '../../../core/design_system/app_icons.dart';
import '../../../core/design_system/design_tokens.dart';
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
    return ListView(
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
                        ? 'Your calm corner in LastDone.'
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
                title: const Text('About LastDone'),
                subtitle: const Text('Warm tools for everyday rhythms.'),
                onTap: () => _about(context),
              ),
              ListTile(
                leading: const Icon(Icons.menu_book_outlined),
                title: const Text('Open-source licenses'),
                onTap: () => showLicensePage(
                  context: context,
                  applicationName: 'LastDone',
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
    );
  }

  static Future<void> _editName(
    BuildContext context,
    AppPreferencesController preferences,
  ) async {
    final controller = TextEditingController(
      text: preferences.displayNameValue ?? '',
    );
    final value = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.sm,
          AppSpacing.lg,
          MediaQuery.viewInsetsOf(context).bottom + AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'What should Dun call you?',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: controller,
              maxLength: 40,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Display name'),
            ),
            const SizedBox(height: AppSpacing.sm),
            FilledButton(
              onPressed: () => Navigator.pop(context, controller.text),
              child: const Text('Save name'),
            ),
          ],
        ),
      ),
    );
    controller.dispose();
    if (value != null) await preferences.saveName(value);
  }

  static Future<void> _about(BuildContext context) async {
    final info = await PackageInfo.fromPlatform();
    if (!context.mounted) return;
    showAboutDialog(
      context: context,
      applicationName: 'LastDone',
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

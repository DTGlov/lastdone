import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/design_system/design_tokens.dart';
import '../../../core/widgets/dun_view.dart';
import '../data/notification_gateway.dart';
import '../domain/reminder.dart';
import '../domain/reminder_repository.dart';
import 'reminders_settings_view_model.dart';

class RemindersSettingsScreen extends StatelessWidget {
  const RemindersSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
    create: (_) => RemindersSettingsViewModel(
      repository: context.read<ReminderRepository>(),
      gateway: context.read<NotificationGateway>(),
    ),
    child: const _RemindersContent(),
  );
}

class _RemindersContent extends StatelessWidget {
  const _RemindersContent();

  @override
  Widget build(BuildContext context) {
    final model = context.watch<RemindersSettingsViewModel>();
    final permission = switch (model.permission) {
      NotificationPermissionStatus.authorized => 'Allowed',
      NotificationPermissionStatus.denied => 'Permission needed',
      NotificationPermissionStatus.notDetermined => 'Not set up yet',
      NotificationPermissionStatus.unavailable => 'Unavailable on this device',
    };
    return Scaffold(
      appBar: AppBar(title: const Text('Reminders')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          const SizedBox(height: AppSpacing.sm),
          const Center(
            child: SizedBox(
              width: 100,
              height: 82,
              child: DunMascot(decorative: true),
            ),
          ),
          Text(
            'A gentle nudge, when it helps.',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: AppSpacing.sm),
          const Text(
            'Reminders stay local to this device. EverDun never sends your tracker or subscription details to a server.',
          ),
          const SizedBox(height: AppSpacing.lg),
          Card(
            child: Column(
              children: [
                ListTile(
                  title: const Text('Notification permission'),
                  subtitle: Text(permission),
                ),
                ListTile(
                  title: const Text('Tracker reminders'),
                  trailing: Text('${model.trackerCount} enabled'),
                ),
                ListTile(
                  title: const Text('Subscription reminders'),
                  trailing: Text('${model.subscriptionCount} enabled'),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          OutlinedButton.icon(
            onPressed: model.openSettings,
            icon: const Icon(Icons.settings_outlined),
            label: const Text('Open notification settings'),
          ),
          const SizedBox(height: AppSpacing.sm),
          FilledButton.icon(
            onPressed:
                model.permission == NotificationPermissionStatus.authorized &&
                    !model.sendingTest
                ? model.sendTest
                : null,
            icon: const Icon(Icons.notifications_outlined),
            label: Text(
              model.sendingTest ? 'Sending…' : 'Send test notification',
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
}

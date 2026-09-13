import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/design_system/design_tokens.dart';
import '../../../core/design_system/lastdone_dialog.dart';
import '../../../core/time/app_clock.dart';
import '../../../core/widgets/app_feedback.dart';
import '../../reminders/data/notification_gateway.dart';
import '../../reminders/domain/reminder.dart';
import '../../reminders/domain/reminder_repository.dart';
import '../domain/subscription.dart';
import '../domain/subscription_repository.dart';
import 'subscription_editor_sheet.dart';

class SubscriptionDetailsScreen extends StatefulWidget {
  const SubscriptionDetailsScreen({required this.subscriptionId, super.key});
  final String subscriptionId;
  @override
  State<SubscriptionDetailsScreen> createState() =>
      _SubscriptionDetailsScreenState();
}

class _SubscriptionDetailsScreenState extends State<SubscriptionDetailsScreen> {
  late Future<Subscription?> _subscription;
  bool _changingState = false;
  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() => _subscription = context
      .read<SubscriptionRepository>()
      .getSubscription(widget.subscriptionId);

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Details')),
    body: FutureBuilder<Subscription?>(
      future: _subscription,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        final value = snapshot.data;
        if (value == null) {
          return const Center(
            child: Text('This subscription is no longer available.'),
          );
        }
        return ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            Text(value.name, style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: AppSpacing.sm),
            Text('${value.category.label} · ${value.frequency.label}'),
            const SizedBox(height: AppSpacing.lg),
            Card(
              child: ListTile(
                title: Text(
                  formatMinorAmount(value.amountMinor, value.currency),
                ),
                subtitle: Text('Next charge: ${_date(value.nextChargeDate)}'),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              value.active ? 'Active' : 'Inactive',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton.icon(
              onPressed: () async {
                await showSubscriptionEditor(
                  context: context,
                  repository: context.read<SubscriptionRepository>(),
                  clock: context.read<AppClock>(),
                  subscription: value,
                  reminderRepository: context.read(),
                );
                if (mounted) setState(_load);
              },
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Edit subscription'),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Manage subscription',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.xs),
            OutlinedButton.icon(
              onPressed: _changingState
                  ? null
                  : () => value.active ? _cancel(value) : _restore(value),
              icon: Icon(value.active ? Icons.cancel_outlined : Icons.restore),
              label: Text(
                value.active ? 'Cancel subscription' : 'Restore subscription',
              ),
            ),
            Text(
              value.active
                  ? 'Stop upcoming charges and reminders while keeping its details.'
                  : 'Bring it back to active subscriptions with its saved details.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        );
      },
    ),
  );

  Future<void> _cancel(Subscription subscription) async {
    if (_changingState || !mounted) return;
    final confirmed = await showLastDoneDialog<bool>(
      context: context,
      title: 'Cancel subscription?',
      message: 'Its reminders and active totals will stop, but the saved details remain available to restore later.',
      variant: LastDoneDialogVariant.confirmation,
      icon: Icons.cancel_outlined,
      primaryLabel: 'Cancel subscription',
      primaryResult: true,
      secondaryLabel: 'Keep subscription',
      secondaryResult: false,
    );
    if (confirmed != true || !mounted) return;
    setState(() => _changingState = true);
    try {
      final repo = context.read<SubscriptionRepository>();
      if (repo case final SubscriptionCancellationRepository cancellation) {
        await cancellation.cancelSubscription(
          subscription.id,
          context.read<AppClock>().now,
        );
        try {
          final preference = await context
              .read<ReminderRepository>()
              .getPreference(
                ReminderTarget(
                  ReminderTargetType.subscription,
                  subscription.id,
                ),
              );
          if (preference != null) {
            await context.read<NotificationGateway>().cancel(
              preference.notificationId,
            );
          }
        } catch (_) {
          if (mounted) {
            await showLastDoneDialog<void>(
              context: context,
              title: 'Subscription cancelled',
              message: 'Your saved data is safe, but its reminder could not be cancelled yet.',
              variant: LastDoneDialogVariant.warning,
              primaryLabel: 'Continue',
            );
          }
        }
        if (mounted) {
          context.pop(true);
          showAppFeedback(
            'Subscription cancelled. Its saved details remain safe.',
          );
        }
      }
    } catch (_) {
      if (mounted) {
        await showLastDoneDialog<void>(
          context: context,
          title: 'Could not cancel subscription',
          message: 'Your subscription is still active. Please try again.',
          variant: LastDoneDialogVariant.error,
          primaryLabel: 'Okay',
        );
      }
    } finally {
      if (mounted) setState(() => _changingState = false);
    }
  }

  Future<void> _restore(Subscription subscription) async {
    if (_changingState || !mounted) return;
    setState(() => _changingState = true);
    try {
      final repo = context.read<SubscriptionRepository>();
      if (repo case final SubscriptionCancellationRepository cancellation) {
        await cancellation.restoreSubscription(
          subscription.id,
          context.read<AppClock>().now,
        );
        if (mounted) {
          context.pop(true);
          showAppFeedback('Subscription restored.');
        }
      }
    } catch (_) {
      if (mounted) {
        await showLastDoneDialog<void>(
          context: context,
          title: 'Could not restore subscription',
          message: 'It is still cancelled. Please try again.',
          variant: LastDoneDialogVariant.error,
          primaryLabel: 'Okay',
        );
      }
    } finally {
      if (mounted) setState(() => _changingState = false);
    }
  }

  static String _date(DateTime value) =>
      '${value.day}/${value.month}/${value.year}';
}

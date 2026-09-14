import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/design_system/design_tokens.dart';
import '../../../core/design_system/everdun_dialog.dart';
import '../../../core/time/app_clock.dart';
import '../domain/subscription.dart';
import '../domain/subscription_repository.dart';
import 'subscription_editor_sheet.dart';

class CancelledSubscriptionsScreen extends StatelessWidget {
  const CancelledSubscriptionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repository = context.read<SubscriptionRepository>();
    if (repository is! SubscriptionCancellationRepository) {
      return const Scaffold(
        body: Center(child: Text('Subscription storage is unavailable.')),
      );
    }
    final cancellationRepository =
        repository as SubscriptionCancellationRepository;
    return Scaffold(
      appBar: AppBar(title: const Text('Cancelled subscriptions')),
      body: SafeArea(
        child: StreamBuilder<List<Subscription>>(
          stream: cancellationRepository.watchCancelledSubscriptions(),
          builder: (context, snapshot) {
            if (snapshot.hasError)
              return const Center(
                child: Text('We could not load cancelled subscriptions.'),
              );
            if (!snapshot.hasData)
              return const Center(child: CircularProgressIndicator());
            final subscriptions = snapshot.data!;
            if (subscriptions.isEmpty)
              return const Center(
                child: Text('No cancelled subscriptions yet.'),
              );
            return ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.lg),
              itemCount: subscriptions.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.xs),
              itemBuilder: (context, index) => _CancelledTile(
                subscription: subscriptions[index],
                onRestore: () => _restore(
                  context,
                  cancellationRepository,
                  subscriptions[index],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  static Future<void> _restore(
    BuildContext context,
    SubscriptionCancellationRepository repository,
    Subscription subscription,
  ) async {
    try {
      await repository.restoreSubscription(
        subscription.id,
        context.read<AppClock>().now,
      );
      if (!context.mounted) return;
      await showEverDunDialog<void>(
        context: context,
        title: 'Subscription restored',
        message: 'It is back in your active subscriptions with its saved details intact.',
        variant: EverDunDialogVariant.success,
        primaryLabel: 'Done',
      );
    } catch (_) {
      if (!context.mounted) return;
      await showEverDunDialog<void>(
        context: context,
        title: 'Could not restore subscription',
        message: 'Your subscription is still cancelled. Please try again.',
        variant: EverDunDialogVariant.error,
        primaryLabel: 'Okay',
      );
    }
  }
}

class _CancelledTile extends StatelessWidget {
  const _CancelledTile({required this.subscription, required this.onRestore});
  final Subscription subscription;
  final VoidCallback onRestore;
  @override
  Widget build(BuildContext context) => Material(
    color: Theme.of(context).colorScheme.surface,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadii.control),
      side: BorderSide(color: Theme.of(context).dividerColor),
    ),
    clipBehavior: Clip.antiAlias,
    child: ListTile(
      tileColor: Colors.transparent,
      leading: SubscriptionLogo(
        name: subscription.name,
        category: subscription.category,
        catalogServiceId: subscription.catalogServiceId,
        logoKey: subscription.logoKey,
        small: true,
      ),
      title: Text(subscription.name),
      subtitle: Text(
        '${formatMinorAmount(subscription.amountMinor, subscription.currency)} · ${subscription.frequency.label}',
      ),
      trailing: TextButton(onPressed: onRestore, child: const Text('Restore')),
    ),
  );
}

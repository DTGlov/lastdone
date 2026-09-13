import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/design_system/design_tokens.dart';
import '../../../core/time/app_clock.dart';
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
          ],
        );
      },
    ),
  );

  static String _date(DateTime value) =>
      '${value.day}/${value.month}/${value.year}';
}

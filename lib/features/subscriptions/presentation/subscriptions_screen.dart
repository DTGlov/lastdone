import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/design_system/design_tokens.dart';
import '../../../core/time/app_clock.dart';
import '../../../core/widgets/dun_view.dart';
import '../domain/subscription.dart';
import '../domain/subscription_repository.dart';
import '../../reminders/domain/reminder_repository.dart';
import 'subscription_editor_sheet.dart';
import 'subscriptions_view_model.dart';

class SubscriptionsScreen extends StatelessWidget {
  const SubscriptionsScreen({super.key});
  @override
  Widget build(BuildContext context) => SafeArea(
    child: Consumer<SubscriptionsViewModel>(
      builder: (context, model, _) => RefreshIndicator(
        onRefresh: model.retry,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            96,
          ),
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Subs',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
                const SizedBox(
                  width: 96,
                  height: 78,
                  child: DunMascot(state: DunMascotState.subscriptions),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Keep recurring costs calm and visible.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: AppSpacing.lg),
            AnimatedSwitcher(
              duration: _motion(context),
              child: switch (model.state) {
                SubscriptionsLoadState.loading => const Center(
                  key: ValueKey('loading'),
                  child: CircularProgressIndicator(),
                ),
                SubscriptionsLoadState.error => _ErrorState(
                  model: model,
                  key: const ValueKey('error'),
                ),
                SubscriptionsLoadState.empty => const _EmptyState(
                  key: ValueKey('empty'),
                ),
                SubscriptionsLoadState.content => _Content(
                  model: model,
                  key: const ValueKey('content'),
                ),
              },
            ),
          ],
        ),
      ),
    ),
  );
}

class _Content extends StatelessWidget {
  const _Content({required this.model, super.key});
  final SubscriptionsViewModel model;
  @override
  Widget build(BuildContext context) {
    final totals = model.monthlyTotals;
    final upcoming = model.upcoming.take(3).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer
                .withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(AppRadii.card),
            border: Border.all(color: Theme.of(context).dividerColor),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Estimated monthly spend',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.sm),
                if (totals.isEmpty)
                  const Text('Nothing active right now.')
                else
                  Wrap(
                    spacing: AppSpacing.md,
                    runSpacing: AppSpacing.xs,
                    children: totals.entries
                        .map(
                          (entry) => Text(
                            formatMinorAmount(entry.value, entry.key),
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        )
                        .toList(),
                  ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Estimates by currency; no conversions.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
        if (upcoming.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.lg),
          _Header(title: 'Coming up', detail: 'Next charges'),
          ...upcoming.map(
            (subscription) => _SubscriptionTile(
              subscription: subscription,
              date: model.nextCharge(subscription),
              currentDate: model.currentDate,
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        _Header(
          title: 'All subscriptions',
          detail: '${model.activeSubscriptions.length} active',
        ),
        ...model.activeSubscriptions.map(
          (subscription) => _SubscriptionTile(
            subscription: subscription,
            date: model.nextCharge(subscription),
            currentDate: model.currentDate,
          ),
        ),
        if (model.inactiveSubscriptions.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.lg),
          _Header(title: 'Inactive', detail: 'Not included in estimates'),
          ...model.inactiveSubscriptions.map(
            (subscription) => _SubscriptionTile(
              subscription: subscription,
              date: model.nextCharge(subscription),
              currentDate: model.currentDate,
              inactive: true,
            ),
          ),
        ],
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.title, required this.detail});
  final String title, detail;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
    child: Row(
      children: [
        Expanded(
          child: Text(title, style: Theme.of(context).textTheme.titleLarge),
        ),
        Text(detail, style: Theme.of(context).textTheme.bodySmall),
      ],
    ),
  );
}

class _SubscriptionTile extends StatelessWidget {
  const _SubscriptionTile({
    required this.subscription,
    required this.date,
    required this.currentDate,
    this.inactive = false,
  });
  final Subscription subscription;
  final DateTime date, currentDate;
  final bool inactive;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.xs),
    child: Material(
      color: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.control),
        side: BorderSide(color: Theme.of(context).dividerColor),
      ),
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        tileColor: Colors.transparent,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: 2,
        ),
        leading: SubscriptionLogo(
          name: subscription.name,
          category: subscription.category,
          catalogServiceId: subscription.catalogServiceId,
          logoKey: subscription.logoKey,
        ),
        title: Text(subscription.name),
        subtitle: Text(
          '${formatMinorAmount(subscription.amountMinor, subscription.currency)} · ${subscription.frequency.label}\n${inactive ? 'Inactive' : _chargeLanguage(date, currentDate)}',
        ),
        isThreeLine: false,
        trailing: const Icon(
          Icons.chevron_right,
          semanticLabel: 'Edit subscription',
        ),
        onTap: () => _edit(context),
      ),
    ),
  );

  Future<void> _edit(BuildContext context) async {
    final result = await showSubscriptionEditor(
      context: context,
      repository: context.read<SubscriptionRepository>(),
      clock: context.read<AppClock>(),
      subscription: subscription,
      reminderRepository: context.read<ReminderRepository>(),
    );
    if (result == true && context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Subscription updated.')));
    }
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({super.key});
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        children: [
          const SizedBox(
            width: 120,
            height: 96,
            child: DunMascot(state: DunMascotState.subscriptions),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Nothing recurring yet.',
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.sm),
          const Text(
            'Keep subscriptions together so future charges feel less surprising.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.lg),
          FilledButton(
            onPressed: () => _create(context),
            child: const Text('Add subscription'),
          ),
        ],
      ),
    ),
  );

  Future<void> _create(BuildContext context) async {
    final result = await showSubscriptionEditor(
      context: context,
      repository: context.read<SubscriptionRepository>(),
      clock: context.read<AppClock>(),
      reminderRepository: context.read<ReminderRepository>(),
    );
    if (result == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Added to your monthly picture.')),
      );
    }
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.model, super.key});
  final SubscriptionsViewModel model;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        children: [
          Text(model.errorMessage ?? 'We could not load your subscriptions.'),
          const SizedBox(height: AppSpacing.md),
          OutlinedButton(
            onPressed: model.retry,
            child: const Text('Try again'),
          ),
        ],
      ),
    ),
  );
}

String _chargeLanguage(DateTime date, DateTime current) {
  final days = date.difference(current).inDays;
  if (days == 0) return 'Today';
  if (days == 1) return 'Tomorrow';
  if (days < 7) return 'In $days days';
  return '${date.month}/${date.day}/${date.year}';
}

Duration _motion(BuildContext context) =>
    MediaQuery.maybeOf(context)?.disableAnimations == true
    ? Duration.zero
    : AppMotion.standard;

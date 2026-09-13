import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/design_system/design_tokens.dart';
import '../../../core/widgets/dun_view.dart';
import '../../today/domain/today_overview.dart';
import '../../today/presentation/today_view_model.dart';
import '../domain/tracker.dart';

class TodayScreen extends StatelessWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Consumer<TodayViewModel>(
      builder: (context, model, _) => RefreshIndicator(
        onRefresh: model.retry,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            _TodayHeader(model: model),
            const SizedBox(height: AppSpacing.lg),
            _SummaryCard(model: model),
            const SizedBox(height: AppSpacing.lg),
            AnimatedSwitcher(
              duration: _motionDuration(context),
              switchInCurve: AppMotion.curve,
              child: switch (model.state) {
                TodayLoadState.loading => const _LoadingState(
                  key: ValueKey('loading'),
                ),
                TodayLoadState.error => _ErrorState(
                  model: model,
                  key: const ValueKey('error'),
                ),
                TodayLoadState.empty => const _EmptyState(
                  key: ValueKey('empty'),
                ),
                TodayLoadState.content => _ContentState(
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

Duration _motionDuration(BuildContext context) =>
    MediaQuery.maybeOf(context)?.disableAnimations == true
    ? Duration.zero
    : AppMotion.standard;

class _TodayHeader extends StatelessWidget {
  const _TodayHeader({required this.model});
  final TodayViewModel model;
  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              model.greeting,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text('Today', style: Theme.of(context).textTheme.displaySmall),
            const SizedBox(height: AppSpacing.xs),
            Text(
              model.formattedDate,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
      Padding(
        padding: const EdgeInsets.only(top: AppSpacing.sm),
        child: DunView(
          state: model.needsAttention ? DunState.focused : DunState.resting,
        ),
      ),
    ],
  );
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.model});
  final TodayViewModel model;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            model.needsAttention ? Icons.wb_sunny_outlined : Icons.auto_awesome,
            semanticLabel: model.needsAttention
                ? 'Needs attention'
                : 'Day summary',
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              model.summary,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
        ],
      ),
    ),
  );
}

class _ContentState extends StatelessWidget {
  const _ContentState({required this.model, super.key});
  final TodayViewModel model;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      if (model.sections.needsAttention.isNotEmpty) ...[
        const _SectionHeader(
          title: 'Needs attention',
          contextText: 'To look after',
        ),
        ...model.sections.needsAttention.map(
          (item) => _TrackerCard(item: item),
        ),
        const SizedBox(height: AppSpacing.md),
      ],
      if (model.sections.comingUp.isNotEmpty) ...[
        const _SectionHeader(
          title: 'Coming up',
          contextText: 'Next 7 days and beyond',
        ),
        ...model.sections.comingUp.map((item) => _TrackerCard(item: item)),
        const SizedBox(height: AppSpacing.md),
      ],
      if (model.sections.recentlyDone.isNotEmpty) ...[
        const _SectionHeader(
          title: 'Recently done',
          contextText: 'Handled lately',
        ),
        ...model.sections.recentlyDone.map((item) => _TrackerCard(item: item)),
      ],
    ],
  );
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.contextText});
  final String title, contextText;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
    child: Row(
      children: [
        Expanded(
          child: Text(title, style: Theme.of(context).textTheme.titleLarge),
        ),
        Text(contextText, style: Theme.of(context).textTheme.bodySmall),
      ],
    ),
  );
}

class _TrackerCard extends StatelessWidget {
  const _TrackerCard({required this.item});
  final TodayTracker item;
  @override
  Widget build(BuildContext context) {
    final category = _categoryFor(item.tracker);
    final status = _statusCopy(
      item,
      context.read<TodayViewModel>().currentDate,
    );
    return Semantics(
      button: true,
      container: true,
      label:
          '${item.tracker.title}. ${status.title}. ${item.tracker.repeatRule.label}',
      child: Card(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: InkWell(
          onTap: () => ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Details are coming next.')),
          ),
          borderRadius: BorderRadius.circular(AppRadii.card),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _CategoryIcon(category: category),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.tracker.title,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.tracker.repeatRule.label,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        status.title,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      if (status.context != null)
                        Text(
                          status.context!,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                    ],
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Icon(
                    Icons.chevron_right,
                    semanticLabel: 'Open details',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoryIcon extends StatelessWidget {
  const _CategoryIcon({required this.category});
  final _TrackerCategory category;
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<TrackerStatusThemeExtension>()!;
    final color = switch (category) {
      _TrackerCategory.home => colors.category,
      _TrackerCategory.vehicle => colors.dueSoon,
      _TrackerCategory.personalCare => colors.completed,
      _TrackerCategory.technology => colors.informational,
      _TrackerCategory.relationships => colors.overdue,
      _TrackerCategory.general => Theme.of(
        context,
      ).colorScheme.onSurface.withValues(alpha: 0.55),
    };
    final icon = switch (category) {
      _TrackerCategory.home => Icons.home_outlined,
      _TrackerCategory.vehicle => Icons.directions_car_outlined,
      _TrackerCategory.personalCare => Icons.spa_outlined,
      _TrackerCategory.technology => Icons.devices_outlined,
      _TrackerCategory.relationships => Icons.people_outline,
      _TrackerCategory.general => Icons.checklist_outlined,
    };
    return Semantics(
      label: category.label,
      child: CircleAvatar(
        backgroundColor: color,
        child: Icon(icon, color: Theme.of(context).colorScheme.onSurface),
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState({super.key});
  @override
  Widget build(BuildContext context) => Column(
    children: List.generate(
      3,
      (index) => Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: [
              const SizedBox(
                width: 48,
                height: 48,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.black12,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(height: 16, color: Colors.black12),
                    const SizedBox(height: AppSpacing.sm),
                    Container(width: 120, height: 12, color: Colors.black12),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({super.key});
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        children: [
          const DunView(),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Nothing to remember yet.',
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Add your first tracker when you’re ready.',
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.lg),
          FilledButton(
            onPressed: () => _showCreatePlaceholder(context),
            child: const Text('Add a tracker'),
          ),
        ],
      ),
    ),
  );
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.model, super.key});
  final TodayViewModel model;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        children: [
          const DunView(state: DunState.focused),
          const SizedBox(height: AppSpacing.lg),
          Text(
            model.errorMessage ?? 'We could not load your day.',
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.lg),
          OutlinedButton(
            onPressed: model.retry,
            child: const Text('Try again'),
          ),
        ],
      ),
    ),
  );
}

class _StatusCopy {
  const _StatusCopy(this.title, [this.context]);
  final String title;
  final String? context;
}

_StatusCopy _statusCopy(TodayTracker item, DateTime currentDate) {
  final completion = item.latestCompletion;
  final today = item.nextDueDate == null
      ? null
      : DateTime(
          item.nextDueDate!.year,
          item.nextDueDate!.month,
          item.nextDueDate!.day,
        );
  return switch (item.status) {
    TodayStatus.notStarted => const _StatusCopy(
      'Ready when you are',
      'Not logged yet',
    ),
    TodayStatus.overdue => _StatusCopy(
      '${currentDate.difference(today!).inDays} days late',
    ),
    TodayStatus.dueToday => const _StatusCopy('Due today'),
    TodayStatus.dueSoon || TodayStatus.upcoming => _StatusCopy(
      'In ${item.nextDueDate!.difference(currentDate).inDays} days',
    ),
    TodayStatus.recentlyDone => _StatusCopy(
      _doneCopy(completion!.completedAt, currentDate),
      'Last completed recently',
    ),
    TodayStatus.unscheduled => const _StatusCopy('Whenever you’re ready'),
  };
}

String _doneCopy(DateTime date, DateTime currentDate) {
  final days = currentDate
      .difference(DateTime(date.year, date.month, date.day))
      .inDays;
  if (days == 0) return 'Done today';
  if (days == 1) return 'Done yesterday';
  return 'Done $days days ago';
}

enum _TrackerCategory {
  home,
  vehicle,
  personalCare,
  technology,
  relationships,
  general,
}

extension on _TrackerCategory {
  String get label => switch (this) {
    _TrackerCategory.home => 'Home category',
    _TrackerCategory.vehicle => 'Vehicle category',
    _TrackerCategory.personalCare => 'Personal care category',
    _TrackerCategory.technology => 'Technology category',
    _TrackerCategory.relationships => 'Relationships category',
    _TrackerCategory.general => 'General category',
  };
}

_TrackerCategory _categoryFor(Tracker tracker) {
  final id = tracker.id.toLowerCase();
  if (id.startsWith('home-')) return _TrackerCategory.home;
  if (id.startsWith('vehicle-')) return _TrackerCategory.vehicle;
  if (id.startsWith('personal-care-')) return _TrackerCategory.personalCare;
  if (id.startsWith('technology-')) return _TrackerCategory.technology;
  if (id.startsWith('relationships-')) return _TrackerCategory.relationships;
  return _TrackerCategory.general;
}

void _showCreatePlaceholder(BuildContext context) => showModalBottomSheet<void>(
  context: context,
  showDragHandle: true,
  builder: (_) => const SafeArea(
    child: Padding(
      padding: EdgeInsets.all(AppSpacing.lg),
      child: Text('Create is coming soon.', key: Key('create-placeholder')),
    ),
  ),
);

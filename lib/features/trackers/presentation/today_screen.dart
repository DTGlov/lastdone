import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/design_system/design_tokens.dart';
import '../../../core/time/app_clock.dart';
import '../../../core/widgets/dun_view.dart';
import '../../today/domain/today_overview.dart';
import '../../today/presentation/today_view_model.dart';
import '../domain/tracker.dart';
import '../domain/tracker_repository.dart';
import 'tracker_editor_sheet.dart';

class TodayScreen extends StatelessWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Consumer<TodayViewModel>(
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
    final status = _statusCopy(
      item,
      context.read<TodayViewModel>().currentDate,
    );
    return Semantics(
      button: true,
      container: true,
      label:
          '${item.tracker.title}. ${status.title}. ${item.tracker.repeatRule.labelFor(item.tracker.repeatInterval)}',
      child: Card(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: InkWell(
          onTap: () => _editTracker(context, item.overview),
          borderRadius: BorderRadius.circular(AppRadii.card),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _CategoryIcon(tracker: item.tracker),
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
                        item.tracker.repeatRule.labelFor(
                          item.tracker.repeatInterval,
                        ),
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

Future<void> _editTracker(
  BuildContext context,
  TrackerOverview overview,
) async {
  final result = await showTrackerEditor(
    context: context,
    repository: context.read<TrackerRepository>(),
    clock: context.read<AppClock>(),
    overview: overview,
  );
  if (result == true && context.mounted) {
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Tracker updated.')));
  }
}

class _CategoryIcon extends StatelessWidget {
  const _CategoryIcon({required this.tracker});
  final Tracker tracker;
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<TrackerStatusThemeExtension>()!;
    final color = switch (tracker.color) {
      TrackerColor.lime => const Color(0xFFC8F55B),
      TrackerColor.plum => colors.category,
      TrackerColor.sky => colors.informational,
      TrackerColor.coral => colors.overdue,
      TrackerColor.gold => colors.dueSoon,
      TrackerColor.mint => colors.completed,
    };
    final icon = switch (tracker.iconKey) {
      TrackerIconKeys.home => Icons.home_outlined,
      TrackerIconKeys.vehicle => Icons.directions_car_outlined,
      TrackerIconKeys.personalCare => Icons.spa_outlined,
      TrackerIconKeys.technology => Icons.devices_outlined,
      TrackerIconKeys.relationships => Icons.people_outline,
      TrackerIconKeys.tools => Icons.build_outlined,
      TrackerIconKeys.leaf => Icons.eco_outlined,
      _ => Icons.checklist_outlined,
    };
    return Semantics(
      label: '${tracker.category.label} category, ${tracker.title} icon',
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
            onPressed: () => _createTrackerFromEmpty(context),
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

Future<void> _createTrackerFromEmpty(BuildContext context) async {
  final result = await showTrackerEditor(
    context: context,
    repository: context.read<TrackerRepository>(),
    clock: context.read<AppClock>(),
  );
  if (result == true && context.mounted) {
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Added to your rhythm.')));
  }
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/design_system/app_icons.dart';
import '../../../core/design_system/design_tokens.dart';
import '../../../core/widgets/dun_view.dart';
import '../../trackers/domain/tracker.dart';
import '../domain/timeline.dart';
import 'timeline_view_model.dart';

class TimelineScreen extends StatelessWidget {
  const TimelineScreen({super.key});

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Consumer<TimelineViewModel>(
      builder: (context, model, _) => NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification.metrics.extentAfter < 500) {
            model.loadMore();
          }
          return false;
        },
        child: RefreshIndicator(
          onRefresh: model.retry,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              112,
            ),
            children: [
              _Header(model: model),
              const SizedBox(height: AppSpacing.md),
              _MonthlySummary(model: model),
              const SizedBox(height: AppSpacing.md),
              _Filters(model: model),
              const SizedBox(height: AppSpacing.md),
              AnimatedSwitcher(
                duration: _motionDuration(context),
                child: switch (model.state) {
                  TimelineLoadState.loading => const _LoadingState(
                    key: ValueKey('loading'),
                  ),
                  TimelineLoadState.error => _ErrorState(
                    model: model,
                    key: const ValueKey('error'),
                  ),
                  TimelineLoadState.empty =>
                    model.hasFilters
                        ? _NoResultsState(
                            onClear: model.clearFilters,
                            key: const ValueKey('no-results'),
                          )
                        : const _EmptyState(key: ValueKey('empty')),
                  TimelineLoadState.content => _TimelineFeed(
                    model: model,
                    key: const ValueKey('content'),
                  ),
                },
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

Duration _motionDuration(BuildContext context) =>
    MediaQuery.maybeOf(context)?.disableAnimations == true
    ? Duration.zero
    : AppMotion.standard;

class _Header extends StatelessWidget {
  const _Header({required this.model});
  final TimelineViewModel model;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Timeline', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Everything you’ve handled.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
      const SizedBox(width: 72, height: 58, child: DunMascot(decorative: true)),
    ],
  );
}

class _MonthlySummary extends StatelessWidget {
  const _MonthlySummary({required this.model});
  final TimelineViewModel model;

  @override
  Widget build(BuildContext context) {
    final count = model.monthlyCount;
    final copy = count == 0
        ? 'Nothing handled this month yet.'
        : '$count ${count == 1 ? 'thing' : 'things'} handled in ${model.monthName}';
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer
            .withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(AppRadii.control),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          children: [
            Icon(AppIcons.complete, size: 20),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(copy, style: Theme.of(context).textTheme.titleMedium),
            ),
          ],
        ),
      ),
    );
  }
}

class _Filters extends StatelessWidget {
  const _Filters({required this.model});
  final TimelineViewModel model;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      TextField(
        onChanged: model.setSearchQuery,
        decoration: InputDecoration(
          labelText: 'Search completed trackers',
          prefixIcon: const Icon(AppIcons.search),
          suffixIcon: model.searchQuery.isEmpty
              ? null
              : IconButton(
                  tooltip: 'Clear search',
                  onPressed: () => model.setSearchQuery(''),
                  icon: const Icon(Icons.close),
                ),
        ),
      ),
      const SizedBox(height: AppSpacing.sm),
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            FilterChip(
              label: const Text('All'),
              selected: model.selectedCategory == null,
              onSelected: (_) => model.setCategory(null),
            ),
            ...model.availableCategories.map(
              (category) => Padding(
                padding: const EdgeInsets.only(left: AppSpacing.xs),
                child: FilterChip(
                  label: Text(_categoryLabel(category)),
                  selected: model.selectedCategory == category,
                  onSelected: (_) => model.setCategory(category),
                ),
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

class _TimelineFeed extends StatelessWidget {
  const _TimelineFeed({required this.model, super.key});
  final TimelineViewModel model;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      ...model.groups.map(
        (group) => _TimelineGroup(group: group, currentDate: model.currentDate),
      ),
      if (model.paginationError != null)
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(model.paginationError!),
            TextButton(onPressed: model.loadMore, child: const Text('Retry')),
          ],
        )
      else if (model.isLoadingMore)
        const Padding(
          padding: EdgeInsets.all(AppSpacing.md),
          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ),
    ],
  );
}

class _TimelineGroup extends StatelessWidget {
  const _TimelineGroup({required this.group, required this.currentDate});
  final TimelineGroup group;
  final DateTime currentDate;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.xs),
        child: Text(
          _groupLabel(context, group.date, currentDate),
          style: Theme.of(context).textTheme.titleLarge,
        ),
      ),
      ...group.entries.map(
        (entry) =>
            _TimelineEntryRow(key: ValueKey(entry.completionId), entry: entry),
      ),
      const SizedBox(height: AppSpacing.md),
    ],
  );
}

class _TimelineEntryRow extends StatelessWidget {
  const _TimelineEntryRow({required this.entry, super.key});
  final TimelineEntry entry;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    container: true,
    label:
        '${entry.title}, completed ${_timeLabel(context, entry.completedAt)}${entry.cadence == null ? '' : ', ${entry.cadence}'}',
    child: Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 24,
            child: Column(
              children: [
                const SizedBox(height: 18),
                Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Theme.of(context).colorScheme.surface,
                      width: 2,
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    width: 1,
                    color: Theme.of(context).dividerColor,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Material(
              color: Theme.of(context).colorScheme.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadii.control),
                side: BorderSide(color: Theme.of(context).dividerColor),
              ),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => context.push('/trackers/${entry.trackerId}'),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  child: Row(
                    children: [
                      _TimelineIcon(entry: entry),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              entry.title,
                              style: Theme.of(context).textTheme.titleMedium,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              '${_timeLabel(context, entry.completedAt)}${entry.cadence == null ? '' : ' · ${entry.cadence}'}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      const Icon(AppIcons.next, size: 20),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _TimelineIcon extends StatelessWidget {
  const _TimelineIcon({required this.entry});
  final TimelineEntry entry;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: _trackerColor(context, entry.color).withValues(alpha: 0.22),
      borderRadius: BorderRadius.circular(AppRadii.control),
      border: Border.all(color: _trackerColor(context, entry.color)),
    ),
    child: SizedBox(
      width: 40,
      height: 40,
      child: Icon(_trackerIcon(entry.iconKey), size: 20),
    ),
  );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({super.key});
  @override
  Widget build(BuildContext context) => Column(
    children: [
      const SizedBox(width: 150, height: 125, child: DunMascot()),
      const SizedBox(height: AppSpacing.md),
      Text(
        'Your trail starts here',
        style: Theme.of(context).textTheme.titleLarge,
      ),
      const SizedBox(height: AppSpacing.xs),
      const Text(
        'Complete a tracker and it’ll show up in your Timeline.',
        textAlign: TextAlign.center,
      ),
    ],
  );
}

class _NoResultsState extends StatelessWidget {
  const _NoResultsState({required this.onClear, super.key});
  final VoidCallback onClear;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(
        'Nothing matches that.',
        style: Theme.of(context).textTheme.titleMedium,
      ),
      TextButton(
        onPressed: onClear,
        child: const Text('Clear search and filters'),
      ),
    ],
  );
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.model, super.key});
  final TimelineViewModel model;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      const SizedBox(width: 100, height: 84, child: DunMascot()),
      const Text('We could not load your Timeline.'),
      TextButton(onPressed: model.retry, child: const Text('Try again')),
    ],
  );
}

class _LoadingState extends StatelessWidget {
  const _LoadingState({super.key});
  @override
  Widget build(BuildContext context) => Column(
    children: List.generate(
      3,
      (_) => Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.xs),
        child: Container(
          height: 68,
          decoration: BoxDecoration(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(AppRadii.control),
          ),
        ),
      ),
    ),
  );
}

String _timeLabel(BuildContext context, DateTime value) =>
    MaterialLocalizations.of(context)
        .formatTimeOfDay(TimeOfDay.fromDateTime(value.toLocal()));

String _groupLabel(BuildContext context, DateTime date, DateTime today) {
  final yesterday = today.subtract(const Duration(days: 1));
  if (_sameDate(date, today)) return 'Today';
  if (_sameDate(date, yesterday)) return 'Yesterday';
  final difference = today.difference(date).inDays;
  if (difference < 7) {
    return MaterialLocalizations.of(context).formatMediumDate(date);
  }
  return MaterialLocalizations.of(context).formatFullDate(date);
}

bool _sameDate(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

String _categoryLabel(TrackerCategory category) => switch (category) {
  TrackerCategory.home => 'Home',
  TrackerCategory.vehicle => 'Vehicle',
  TrackerCategory.personalCare => 'Personal care',
  TrackerCategory.technology => 'Technology',
  TrackerCategory.relationships => 'Relationships',
  TrackerCategory.custom => 'Custom',
};

IconData _trackerIcon(String key) => switch (key) {
  TrackerIconKeys.home => Icons.home_outlined,
  TrackerIconKeys.vehicle => Icons.directions_car_outlined,
  TrackerIconKeys.personalCare => Icons.spa_outlined,
  TrackerIconKeys.technology => Icons.devices_outlined,
  TrackerIconKeys.relationships => Icons.people_outline,
  TrackerIconKeys.tools => Icons.build_outlined,
  TrackerIconKeys.leaf => Icons.eco_outlined,
  _ => Icons.checklist_outlined,
};

Color _trackerColor(BuildContext context, TrackerColor color) {
  final colors = Theme.of(context).extension<TrackerStatusThemeExtension>()!;
  return switch (color) {
    TrackerColor.lime => Theme.of(context).colorScheme.primaryContainer,
    TrackerColor.plum => colors.category,
    TrackerColor.sky => colors.informational,
    TrackerColor.coral => colors.overdue,
    TrackerColor.gold => colors.dueSoon,
    TrackerColor.mint => colors.completed,
  };
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../core/design_system/app_icons.dart';
import '../../../core/design_system/everdun_calendar.dart';
import '../../../core/design_system/design_tokens.dart';
import '../../../core/widgets/dun_view.dart';
import '../../trackers/domain/tracker.dart';
import '../../subscriptions/domain/subscription.dart';
import '../domain/planner.dart';
import '../domain/timeline.dart';
import 'planner_view_model.dart';
import 'timeline_view_model.dart';

class TimelineScreen extends StatefulWidget {
  const TimelineScreen({super.key});

  @override
  State<TimelineScreen> createState() => _TimelineScreenState();
}

class _TimelineScreenState extends State<TimelineScreen> {
  bool _planner = false;

  @override
  Widget build(BuildContext context) => SafeArea(
    child: _planner
        ? Consumer<PlannerViewModel>(
            builder: (context, model, _) => _PlannerContent(
              model: model,
              onHistory: () => setState(() => _planner = false),
            ),
          )
        : Consumer<TimelineViewModel>(
            builder: (context, model, _) =>
                NotificationListener<ScrollNotification>(
                  onNotification: (notification) {
                    if (notification.metrics.extentAfter < 500) {
                      model.scheduleLoadMore();
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
                        _ModeSwitch(
                          planner: false,
                          onChanged: () => setState(() => _planner = true),
                        ),
                        _Header(model: model),
                        const SizedBox(height: AppSpacing.md),
                        _MonthlySummary(model: model),
                        const SizedBox(height: AppSpacing.md),
                        _Filters(model: model),
                        const SizedBox(height: AppSpacing.md),
                        switch (model.state) {
                          TimelineLoadState.loading => const _LoadingState(),
                          TimelineLoadState.error => _ErrorState(model: model),
                          TimelineLoadState.empty =>
                            model.hasFilters
                                ? _NoResultsState(onClear: model.clearFilters)
                                : const _EmptyState(),
                          TimelineLoadState.content => _TimelineFeed(
                            model: model,
                          ),
                        },
                      ],
                    ),
                  ),
                ),
          ),
  );
}

class _ModeSwitch extends StatelessWidget {
  const _ModeSwitch({required this.planner, required this.onChanged});
  final bool planner;
  final VoidCallback onChanged;
  @override
  Widget build(BuildContext context) => SegmentedButton<bool>(
    segments: const [
      ButtonSegment(
        value: false,
        label: Text('History'),
        icon: Icon(AppIcons.timeline),
      ),
      ButtonSegment(
        value: true,
        label: Text('Planner'),
        icon: Icon(AppIcons.today),
      ),
    ],
    selected: {planner},
    onSelectionChanged: (value) {
      if (value.isNotEmpty && value.first != planner) onChanged();
    },
    showSelectedIcon: false,
  );
}

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
              onSelected: (_) => model.setFilter(TimelineCategoryFilter.all),
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
  const _TimelineFeed({required this.model});
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
  const _EmptyState();
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
        'Complete a tracker and it’ll show up here. Current and upcoming trackers are on Today.',
        textAlign: TextAlign.center,
      ),
    ],
  );
}

class _NoResultsState extends StatelessWidget {
  const _NoResultsState({required this.onClear});
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
  const _ErrorState({required this.model});
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
  const _LoadingState();
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

class _PlannerContent extends StatelessWidget {
  const _PlannerContent({required this.model, required this.onHistory});
  final PlannerViewModel model;
  final VoidCallback onHistory;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final items = model.selectedItems;
    return RefreshIndicator(
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
          _ModeSwitch(planner: true, onChanged: onHistory),
          const SizedBox(height: AppSpacing.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Planner', style: theme.textTheme.headlineSmall),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'A clear view of what is coming up.',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              const SizedBox(
                width: 84,
                height: 64,
                child: DunMascot(decorative: true),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _PlannerSummary(model: model),
          const SizedBox(height: AppSpacing.md),
          if (model.state == PlannerLoadState.loading)
            const _LoadingState()
          else if (model.state == PlannerLoadState.error)
            Column(
              children: [
                const Text('We could not load your Planner.'),
                TextButton(
                  onPressed: model.retry,
                  child: const Text('Try again'),
                ),
              ],
            )
          else ...[
            EverDunMonthCalendar<PlannerItem>(
              firstDay: DateTime(model.today.year, model.today.month),
              lastDay: DateTime(model.today.year, model.today.month + 12, 0),
              focusedDay: model.focusedMonth,
              selectedDayPredicate: (day) => _sameDate(day, model.selectedDate),
              onDaySelected: (selected, _) => model.selectDay(selected),
              onPageChanged: model.changeMonth,
              eventLoader: (day) => model.itemsFor(day),
              headerStyle: HeaderStyle(
                titleTextStyle: theme.textTheme.titleMedium!,
                formatButtonVisible: false,
                leftChevronIcon: const Icon(AppIcons.previous),
                rightChevronIcon: const Icon(AppIcons.next),
              ),
              daysOfWeekStyle: DaysOfWeekStyle(
                weekdayStyle: theme.textTheme.labelSmall!,
                weekendStyle: theme.textTheme.labelSmall!,
              ),
              calendarStyle: CalendarStyle(
                outsideDaysVisible: false,
                defaultTextStyle: theme.textTheme.bodyMedium!,
                weekendTextStyle: theme.textTheme.bodyMedium!,
                todayDecoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: theme.colorScheme.primary),
                ),
                selectedDecoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.colorScheme.primary,
                ),
                selectedTextStyle: theme.textTheme.bodyMedium!.copyWith(
                  color: theme.colorScheme.onPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              calendarBuilders: CalendarBuilders<PlannerItem>(
                markerBuilder: (context, day, events) {
                  if (events.isEmpty) return null;
                  final hasDue = events.any(
                    (item) => item.type == PlannerItemType.trackerDue,
                  );
                  final hasCharge = events.any(
                    (item) => item.type == PlannerItemType.subscriptionCharge,
                  );
                  final handled = events.any(
                    (item) => item.status == PlannerItemStatus.handled,
                  );
                  final colour = handled
                      ? theme
                            .extension<TrackerStatusThemeExtension>()!
                            .completed
                      : hasDue
                      ? theme.extension<TrackerStatusThemeExtension>()!.dueSoon
                      : theme.colorScheme.secondary;
                  return Semantics(
                    label: '${events.length} Planner items',
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (hasDue) _marker(colour),
                        if (hasCharge)
                          _marker(
                            theme
                                .extension<TrackerStatusThemeExtension>()!
                                .category,
                          ),
                        if (handled)
                          _marker(
                            theme
                                .extension<TrackerStatusThemeExtension>()!
                                .completed,
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              _dayHeading(context, model.selectedDate),
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.xs),
            if (items.isEmpty)
              const Text('The lodge is calm. Nothing is planned for this day.')
            else
              ...items.map((item) => _PlannerRow(item: item)),
          ],
        ],
      ),
    );
  }

  Widget _marker(Color color) => Container(
    width: 5,
    height: 5,
    margin: const EdgeInsets.symmetric(horizontal: 1),
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );
}

class _PlannerSummary extends StatelessWidget {
  const _PlannerSummary({required this.model});
  final PlannerViewModel model;
  @override
  Widget build(BuildContext context) {
    final summary = model.monthSummary;
    final currencies = summary.subscriptionTotals.entries
        .map((entry) => formatMinorAmount(entry.value, entry.key))
        .join(' · ');
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer
            .withValues(alpha: .35),
        borderRadius: BorderRadius.circular(AppRadii.control),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Text(
          '${summary.dueCount} ${summary.dueCount == 1 ? 'thing' : 'things'} due · ${summary.handledCount} handled${currencies.isEmpty ? '' : ' · $currencies expected'}',
        ),
      ),
    );
  }
}

class _PlannerRow extends StatelessWidget {
  const _PlannerRow({required this.item});
  final PlannerItem item;
  @override
  Widget build(BuildContext context) {
    final isCharge = item.type == PlannerItemType.subscriptionCharge;
    final detail = isCharge
        ? '${formatMinorAmount(item.amountMinor!, item.currency!)} · Charge expected'
        : item.status == PlannerItemStatus.overdue
        ? 'Overdue'
        : item.status == PlannerItemStatus.handled
        ? 'Handled${item.completedAt == null ? '' : ' · ${_timeLabel(context, item.completedAt!)}'}'
        : 'Due';
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xs),
      child: Material(
        color: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.control),
          side: BorderSide(color: Theme.of(context).dividerColor),
        ),
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          tileColor: Colors.transparent,
          onTap: () => context.push(item.navigationTarget),
          leading: Icon(
            isCharge
                ? Icons.receipt_long_outlined
                : _trackerIcon(item.iconKey ?? ''),
          ),
          title: Text(item.title, maxLines: 2, overflow: TextOverflow.ellipsis),
          subtitle: Text(detail),
          trailing: const Icon(AppIcons.next),
        ),
      ),
    );
  }
}

String _dayHeading(BuildContext context, DateTime date) =>
    MaterialLocalizations.of(context).formatFullDate(date);

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

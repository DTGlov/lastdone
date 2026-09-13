import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/design_system/design_tokens.dart';
import '../../../core/time/app_clock.dart';
import '../../../core/widgets/dun_view.dart';
import '../../today/domain/today_overview.dart';
import '../domain/tracker.dart';
import '../domain/tracker_repository.dart';
import 'tracker_editor_sheet.dart';
import 'tracker_detail_view_model.dart';

class TrackerDetailScreen extends StatefulWidget {
  const TrackerDetailScreen({required this.trackerId, super.key});
  final String trackerId;

  @override
  State<TrackerDetailScreen> createState() => _TrackerDetailScreenState();
}

class _TrackerDetailScreenState extends State<TrackerDetailScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _celebrationController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 720),
  );
  bool _celebrating = false;

  @override
  Widget build(BuildContext context) {
    final model = context.watch<TrackerDetailViewModel>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tracker details'),
        actions: [
          if (model.details != null)
            IconButton(
              tooltip: 'Edit tracker',
              onPressed: () => _edit(context, model),
              icon: const Icon(Icons.edit_outlined),
            ),
        ],
      ),
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: _detailMotion(context),
          child: switch (model.state) {
            TrackerDetailLoadState.loading => const _DetailLoading(
              key: ValueKey('loading'),
            ),
            TrackerDetailLoadState.error => _DetailError(
              model: model,
              key: const ValueKey('error'),
            ),
            TrackerDetailLoadState.missing => const _MissingTracker(
              key: ValueKey('missing'),
            ),
            TrackerDetailLoadState.content => _DetailContent(
              model: model,
              celebrating: _celebrating,
              onComplete: () => _complete(model),
              key: const ValueKey('content'),
            ),
          },
        ),
      ),
    );
  }

  Future<void> _complete(TrackerDetailViewModel model) async {
    final completion = await model.completeToday();
    if (!mounted || completion == null || model.completedToday == false) {
      return;
    }
    HapticFeedback.mediumImpact();
    final reducedMotion =
        MediaQuery.maybeOf(context)?.disableAnimations == true;
    if (reducedMotion) {
      context.pop(completion);
      return;
    }
    setState(() => _celebrating = true);
    await _celebrationController.forward(from: 0);
    if (mounted) context.pop(completion);
  }

  Future<void> _edit(BuildContext context, TrackerDetailViewModel model) async {
    final details = model.details;
    if (details == null) return;
    await showTrackerEditor(
      context: context,
      repository: context.read<TrackerRepository>(),
      clock: context.read<AppClock>(),
      overview: TrackerOverview(
        tracker: details.tracker,
        latestCompletion: details.latestCompletion,
      ),
    );
  }

  @override
  void dispose() {
    _celebrationController.dispose();
    super.dispose();
  }
}

class _DetailContent extends StatelessWidget {
  const _DetailContent({
    required this.model,
    required this.celebrating,
    required this.onComplete,
    super.key,
  });
  final TrackerDetailViewModel model;
  final bool celebrating;
  final VoidCallback onComplete;

  @override
  Widget build(BuildContext context) {
    final details = model.details!;
    final item = model.classifiedTracker!;
    final tracker = details.tracker;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.xl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _TrackerHero(tracker: tracker, status: item.status),
          const SizedBox(height: AppSpacing.lg),
          AnimatedSwitcher(
            duration: _detailMotion(context),
            child: celebrating
                ? const _CelebrationMessage(key: ValueKey('celebration'))
                : _StatusPanel(
                    item: item,
                    currentDate: model.currentDate,
                    completedToday: model.completedToday,
                    key: const ValueKey('status'),
                  ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Stack(
            alignment: Alignment.center,
            children: [
              FilledButton.icon(
                onPressed:
                    model.isCompleting || model.completedToday || celebrating
                    ? null
                    : onComplete,
                icon: Icon(
                  model.completedToday
                      ? Icons.check_circle_outline
                      : Icons.done,
                ),
                label: Text(model.completedToday ? 'Done today' : 'Done today'),
              ),
              if (celebrating)
                IgnorePointer(
                  child: SizedBox(
                    height: 96,
                    child: _CelebrationBurst(
                      animation: context
                          .findAncestorStateOfType<_TrackerDetailScreenState>()!
                          ._celebrationController,
                    ),
                  ),
                ),
            ],
          ),
          if (model.errorMessage != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              model.errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          const SizedBox(height: AppSpacing.xl),
          Text('Recent history', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSpacing.sm),
          if (details.completions.isEmpty)
            const _EmptyHistory()
          else
            ...details.completions.map(
              (completion) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.check_circle_outline),
                title: Text(_dateLabel(completion.completedAt)),
                subtitle: Text(
                  _relativeDate(completion.completedAt, model.currentDate),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _TrackerHero extends StatelessWidget {
  const _TrackerHero({required this.tracker, required this.status});
  final Tracker tracker;
  final TodayStatus status;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _TrackerIcon(tracker: tracker),
      const SizedBox(width: AppSpacing.md),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              tracker.title,
              style: Theme.of(context).textTheme.displaySmall,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '${tracker.category.label} · ${tracker.repeatRule.labelFor(tracker.repeatInterval)}',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              _statusTitle(status),
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      ),
    ],
  );
}

class _StatusPanel extends StatelessWidget {
  const _StatusPanel({
    required this.item,
    required this.currentDate,
    required this.completedToday,
    super.key,
  });
  final TodayTracker item;
  final DateTime currentDate;
  final bool completedToday;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: [
          Icon(completedToday ? Icons.celebration_outlined : Icons.schedule),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              completedToday
                  ? 'Freshly handled.'
                  : _statusCopy(item, currentDate),
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
        ],
      ),
    ),
  );
}

class _CelebrationMessage extends StatelessWidget {
  const _CelebrationMessage({super.key});
  @override
  Widget build(BuildContext context) => Card(
    color: Theme.of(context).colorScheme.primaryContainer,
    child: const Padding(
      padding: EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: [
          DunView(state: DunState.celebrating),
          Expanded(child: Text('Freshly handled.')),
        ],
      ),
    ),
  );
}

class _CelebrationBurst extends StatelessWidget {
  const _CelebrationBurst({required this.animation});
  final Animation<double> animation;
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: animation,
    builder: (_, _) => CustomPaint(
      painter: _BurstPainter(
        animation.value,
        Theme.of(context).colorScheme.primary,
      ),
    ),
  );
}

class _BurstPainter extends CustomPainter {
  const _BurstPainter(this.progress, this.color);
  final double progress;
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()..color = color;
    for (var index = 0; index < 8; index++) {
      final angle = index * math.pi / 4;
      final distance = 12 + progress * 42;
      final point =
          center + Offset(math.cos(angle), math.sin(angle)) * distance;
      canvas.drawCircle(point, 3 * (1 - progress), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _BurstPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Text(
        'Nothing logged yet. This can be your first one.',
        style: Theme.of(context).textTheme.bodyLarge,
      ),
    ),
  );
}

class _DetailLoading extends StatelessWidget {
  const _DetailLoading({super.key});
  @override
  Widget build(BuildContext context) => const Center(
    child: CircularProgressIndicator(semanticsLabel: 'Loading tracker'),
  );
}

class _DetailError extends StatelessWidget {
  const _DetailError({required this.model, super.key});
  final TrackerDetailViewModel model;
  @override
  Widget build(BuildContext context) => _DetailMessage(
    title: model.errorMessage ?? 'We could not load this tracker.',
    action: OutlinedButton(
      onPressed: model.retry,
      child: const Text('Try again'),
    ),
  );
}

class _MissingTracker extends StatelessWidget {
  const _MissingTracker({super.key});
  @override
  Widget build(BuildContext context) =>
      const _DetailMessage(title: 'That tracker is no longer here.');
}

class _DetailMessage extends StatelessWidget {
  const _DetailMessage({required this.title, this.action});
  final String title;
  final Widget? action;
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const DunView(state: DunState.focused),
          const SizedBox(height: AppSpacing.lg),
          Text(title, textAlign: TextAlign.center),
          if (action != null) ...[
            const SizedBox(height: AppSpacing.lg),
            action!,
          ],
        ],
      ),
    ),
  );
}

class _TrackerIcon extends StatelessWidget {
  const _TrackerIcon({required this.tracker});
  final Tracker tracker;
  @override
  Widget build(BuildContext context) => CircleAvatar(
    radius: 32,
    backgroundColor: _trackerColor(context, tracker.color),
    child: Icon(
      _iconFor(tracker.iconKey),
      semanticLabel: '${tracker.category.label} icon',
    ),
  );
}

String _statusTitle(TodayStatus status) => switch (status) {
  TodayStatus.notStarted => 'Ready when you are',
  TodayStatus.overdue => 'Overdue',
  TodayStatus.dueToday => 'Due today',
  TodayStatus.dueSoon => 'Due soon',
  TodayStatus.upcoming => 'Upcoming',
  TodayStatus.recentlyDone => 'Recently done',
  TodayStatus.unscheduled => 'Whenever you’re ready',
};

String _statusCopy(TodayTracker item, DateTime currentDate) {
  if (item.status == TodayStatus.notStarted) return 'Ready when you are';
  if (item.status == TodayStatus.unscheduled) {
    final completion = item.latestCompletion;
    if (completion == null) return 'Whenever you’re ready';
    return '${currentDate.difference(_dateOnly(completion.completedAt)).inDays} days since last done';
  }
  if (item.status == TodayStatus.overdue) {
    return '${currentDate.difference(item.nextDueDate!).inDays} days overdue';
  }
  if (item.status == TodayStatus.dueToday) return 'Due today';
  if (item.status == TodayStatus.recentlyDone) {
    return 'Done ${_relativeDate(item.latestCompletion!.completedAt, currentDate).toLowerCase()}';
  }
  return 'Due in ${item.nextDueDate!.difference(currentDate).inDays} days';
}

String _relativeDate(DateTime date, DateTime currentDate) {
  final days = currentDate.difference(_dateOnly(date)).inDays;
  if (days == 0) return 'Today';
  if (days == 1) return 'Yesterday';
  return '$days days ago';
}

String _dateLabel(DateTime date) => '${date.month}/${date.day}/${date.year}';
DateTime _dateOnly(DateTime value) {
  final local = value.toLocal();
  return DateTime(local.year, local.month, local.day);
}

IconData _iconFor(String key) => switch (key) {
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
    TrackerColor.lime => const Color(0xFFC8F55B),
    TrackerColor.plum => colors.category,
    TrackerColor.sky => colors.informational,
    TrackerColor.coral => colors.overdue,
    TrackerColor.gold => colors.dueSoon,
    TrackerColor.mint => colors.completed,
  };
}

Duration _detailMotion(BuildContext context) =>
    MediaQuery.maybeOf(context)?.disableAnimations == true
    ? Duration.zero
    : AppMotion.standard;

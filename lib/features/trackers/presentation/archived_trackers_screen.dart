import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/design_system/design_tokens.dart';
import '../../../core/design_system/lastdone_dialog.dart';
import '../../../core/time/app_clock.dart';
import '../domain/tracker.dart';
import '../domain/tracker_repository.dart';
import 'tracker_editor_sheet.dart' show TrackerCategoryLabel;

class ArchivedTrackersScreen extends StatelessWidget {
  const ArchivedTrackersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repository = context.read<TrackerRepository>();
    if (repository is! TrackerArchiveRepository) {
      return const Scaffold(
        body: Center(child: Text('Archive storage is unavailable.')),
      );
    }
    final archiveRepository = repository as TrackerArchiveRepository;
    return Scaffold(
      appBar: AppBar(title: const Text('Archived trackers')),
      body: SafeArea(
        child: StreamBuilder<List<Tracker>>(
          stream: archiveRepository.watchArchivedTrackers(),
          builder: (context, snapshot) {
            if (snapshot.hasError) return _ErrorState(onRetry: () {});
            if (!snapshot.hasData)
              return const Center(child: CircularProgressIndicator());
            final trackers = snapshot.data!;
            if (trackers.isEmpty) {
              return const Center(child: Text('No archived trackers yet.'));
            }
            return ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.lg),
              itemCount: trackers.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.xs),
              itemBuilder: (context, index) => _ArchivedTrackerTile(
                tracker: trackers[index],
                onRestore: () =>
                    _restore(context, archiveRepository, trackers[index]),
              ),
            );
          },
        ),
      ),
    );
  }

  static Future<void> _restore(
    BuildContext context,
    TrackerArchiveRepository repository,
    Tracker tracker,
  ) async {
    try {
      await repository.restoreTracker(tracker.id, context.read<AppClock>().now);
      if (!context.mounted) return;
      await showLastDoneDialog<void>(
        context: context,
        title: 'Tracker restored',
        message: 'It is back in Today with its completion history intact.',
        variant: LastDoneDialogVariant.success,
        primaryLabel: 'Done',
      );
    } catch (_) {
      if (!context.mounted) return;
      await showLastDoneDialog<void>(
        context: context,
        title: 'Could not restore tracker',
        message: 'Your tracker is still archived. Please try again.',
        variant: LastDoneDialogVariant.error,
        primaryLabel: 'Okay',
      );
    }
  }
}

class _ArchivedTrackerTile extends StatelessWidget {
  const _ArchivedTrackerTile({required this.tracker, required this.onRestore});
  final Tracker tracker;
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
      leading: Icon(_trackerIcon(tracker.iconKey)),
      title: Text(tracker.title),
      subtitle: Text(
        '${tracker.category.label} · ${tracker.repeatRule.labelFor(tracker.repeatInterval)}',
      ),
      trailing: TextButton(onPressed: onRestore, child: const Text('Restore')),
    ),
  );
}

IconData _trackerIcon(String key) => switch (key) {
  TrackerIconKeys.home => Icons.home_outlined,
  TrackerIconKeys.vehicle => Icons.directions_car_outlined,
  TrackerIconKeys.personalCare => Icons.spa_outlined,
  TrackerIconKeys.technology => Icons.devices_outlined,
  TrackerIconKeys.relationships => Icons.people_outline,
  TrackerIconKeys.water => Icons.water_drop_outlined,
  TrackerIconKeys.tools => Icons.build_outlined,
  TrackerIconKeys.leaf => Icons.eco_outlined,
  _ => Icons.checklist_outlined,
};

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('We could not load archived trackers.'),
        TextButton(onPressed: onRetry, child: const Text('Try again')),
      ],
    ),
  );
}

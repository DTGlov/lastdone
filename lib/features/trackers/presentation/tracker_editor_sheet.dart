import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/design_system/design_tokens.dart';
import '../../../core/design_system/everdun_dialog.dart';
import '../../../core/design_system/everdun_calendar.dart';
import '../../../core/time/app_clock.dart';
import '../domain/tracker.dart';
import '../domain/tracker_icon.dart';
import '../domain/tracker_repository.dart';
import '../../reminders/domain/reminder.dart';
import '../../reminders/domain/reminder_repository.dart';
import '../../reminders/data/notification_gateway.dart';
import 'tracker_editor_view_model.dart';

Future<bool?> showTrackerEditor({
  required BuildContext context,
  required TrackerRepository repository,
  required AppClock clock,
  TrackerOverview? overview,
  ReminderRepository? reminderRepository,
}) => showModalBottomSheet<bool>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  showDragHandle: true,
  builder: (_) => ChangeNotifierProvider(
    create: (_) => overview == null
        ? TrackerEditorViewModel.create(
            repository: repository,
            clock: clock,
            reminderRepository: reminderRepository,
          )
        : TrackerEditorViewModel.edit(
            repository: repository,
            clock: clock,
            overview: overview,
            reminderRepository: reminderRepository,
          ),
    child: const TrackerEditorSheet(),
  ),
);

class TrackerEditorSheet extends StatefulWidget {
  const TrackerEditorSheet({super.key});
  @override
  State<TrackerEditorSheet> createState() => _TrackerEditorSheetState();
}

class _TrackerEditorSheetState extends State<TrackerEditorSheet> {
  bool _discarding = false;

  @override
  Widget build(BuildContext context) {
    final model = context.watch<TrackerEditorViewModel>();
    return PopScope(
      canPop: _discarding || (!model.isDirty && !model.isSaving),
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && !_discarding && model.isDirty) _confirmDiscard(model);
      },
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.82,
        minChildSize: 0.55,
        maxChildSize: 0.96,
        builder: (context, scrollController) => CustomScrollView(
          controller: scrollController,
          slivers: [
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                MediaQuery.viewInsetsOf(context).bottom + AppSpacing.lg,
              ),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  Text(
                    model.title,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    model.supportingCopy,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _NameField(model: model),
                  const SizedBox(height: AppSpacing.md),
                  _CategoryField(model: model),
                  const SizedBox(height: AppSpacing.md),
                  _IconField(model: model),
                  const SizedBox(height: AppSpacing.md),
                  _ColorField(model: model),
                  const SizedBox(height: AppSpacing.md),
                  _CompletionField(model: model),
                  const SizedBox(height: AppSpacing.md),
                  _ScheduleField(model: model),
                  if (model.isCreate &&
                      model.repeatUnit != RepeatUnit.none) ...[
                    const SizedBox(height: AppSpacing.md),
                    _FirstDueDateField(model: model),
                  ],
                  if (model.reminderRepository != null &&
                      model.repeatUnit != RepeatUnit.none) ...[
                    const SizedBox(height: AppSpacing.md),
                    _ReminderField(model: model),
                  ],
                  if (model.errorMessage != null) ...[
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      model.errorMessage!,
                      key: const Key('tracker-editor-error'),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.md),
                  FilledButton(
                    onPressed: model.isSaving ? null : () => _save(model),
                    child: model.isSaving
                        ? const SizedBox.square(
                            dimension: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(model.isCreate ? 'Add tracker' : 'Save changes'),
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save(TrackerEditorViewModel model) async {
    if (model.reminderEnabled && model.repeatUnit != RepeatUnit.none) {
      await _offerReminderPermission();
    }
    final saved = await model.save();
    if (!saved && mounted && model.errorMessage != null) {
      await showEverDunDialog<void>(
        context: context,
        title: 'Tracker not saved',
        message: model.errorMessage!,
        variant: EverDunDialogVariant.error,
        primaryLabel: 'Keep editing',
      );
    }
    if (saved && mounted) context.pop(true);
  }

  Future<void> _offerReminderPermission() async {
    try {
      final gateway = context.read<NotificationGateway>();
      final status = await gateway.permissionStatus();
      if (status == NotificationPermissionStatus.authorized || !mounted) return;
      final allow = await showEverDunDialog<bool>(
        context: context,
        title: 'A gentle reminder?',
        message: 'EverDun can nudge you locally before this tracker is due. Nothing is sent to a server.',
        primaryLabel: 'Allow reminders',
        primaryResult: true,
        secondaryLabel: 'Not now',
        secondaryResult: false,
      );
      if (allow == true) await gateway.requestPermission();
    } catch (_) {
      if (mounted) {
        await showEverDunDialog<void>(
          context: context,
          title: 'Reminder setup is unavailable',
          message: 'The tracker can still be saved, but its local reminder could not be configured. You can try again later from Reminders.',
          variant: EverDunDialogVariant.warning,
          primaryLabel: 'Continue',
        );
      }
    }
  }

  Future<void> _confirmDiscard(TrackerEditorViewModel model) async {
    final discard = await showEverDunDialog<bool>(
      context: context,
      title: 'Leave without saving?',
      message: 'Your changes are still fresh. Would you like to keep editing?',
      variant: EverDunDialogVariant.confirmation,
      primaryLabel: 'Leave',
      primaryResult: true,
      secondaryLabel: 'Keep editing',
      secondaryResult: false,
    );
    if (discard == true && mounted) {
      setState(() => _discarding = true);
      Navigator.pop(context);
    }
  }
}

class _NameField extends StatelessWidget {
  const _NameField({required this.model});
  final TrackerEditorViewModel model;
  @override
  Widget build(BuildContext context) => TextField(
    controller: model.nameController,
    maxLength: 60,
    textInputAction: TextInputAction.next,
    decoration: InputDecoration(
      labelText: 'Name',
      hintText: 'e.g. Clean the fridge',
      errorText: model.nameError,
    ),
  );
}

class _CategoryField extends StatelessWidget {
  const _CategoryField({required this.model});
  final TrackerEditorViewModel model;
  @override
  Widget build(BuildContext context) =>
      DropdownButtonFormField<TrackerCategory>(
        initialValue: model.category,
        decoration: const InputDecoration(labelText: 'Category'),
        items: TrackerCategory.values
            .map(
              (value) =>
                  DropdownMenuItem(value: value, child: Text(value.label)),
            )
            .toList(),
        onChanged: (value) {
          if (value != null) model.setCategory(value);
        },
      );
}

class _IconField extends StatelessWidget {
  const _IconField({required this.model});
  final TrackerEditorViewModel model;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('Icon', style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: AppSpacing.sm),
      SizedBox(
        height: 48,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: model.availableIconKeys.length,
          separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.xs),
          itemBuilder: (context, index) {
            final key = model.availableIconKeys[index];
            return _IconChoice(
              keyName: key,
              selected: model.iconKey == key,
              onTap: () => model.setIcon(key),
            );
          },
        ),
      ),
    ],
  );
}

class _IconChoice extends StatelessWidget {
  const _IconChoice({
    required this.keyName,
    required this.selected,
    required this.onTap,
  });
  final String keyName;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    label:
        '${TrackerIcons.resolve(keyName).label} icon${selected ? ', selected' : ''}',
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadii.control),
      child: AnimatedContainer(
        duration: _editorMotion(context),
        constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
        padding: const EdgeInsets.all(AppSpacing.xs),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadii.control),
          color: selected
              ? Theme.of(context).colorScheme.primaryContainer
              : Theme.of(context).colorScheme.surface,
          border: Border.all(
            color: selected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).dividerColor,
            width: selected ? 2 : 1,
          ),
        ),
        child: Text(
          TrackerIcons.resolve(keyName).emoji,
          style: const TextStyle(fontSize: 26),
          textAlign: TextAlign.center,
        ),
      ),
    ),
  );
}

class _ColorField extends StatelessWidget {
  const _ColorField({required this.model});
  final TrackerEditorViewModel model;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('Colour', style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: AppSpacing.sm),
      SizedBox(
        height: 44,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: TrackerColor.values.length,
          separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.xs),
          itemBuilder: (context, index) {
            final color = TrackerColor.values[index];
            return _ColorChoice(
              color: color,
              selected: model.color == color,
              onTap: () => model.setColor(color),
            );
          },
        ),
      ),
    ],
  );
}

class _ColorChoice extends StatelessWidget {
  const _ColorChoice({
    required this.color,
    required this.selected,
    required this.onTap,
  });
  final TrackerColor color;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    label: '${color.label} colour${selected ? ', selected' : ''}',
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadii.pill),
      child: AnimatedContainer(
        duration: _editorMotion(context),
        width: 44,
        height: 44,
        alignment: Alignment.center,
        child: AnimatedContainer(
          duration: _editorMotion(context),
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.value(context),
            border: Border.all(
              color: selected
                  ? Theme.of(context).colorScheme.onSurface
                  : Colors.transparent,
              width: selected ? 2 : 0,
            ),
          ),
          child: selected
              ? Icon(
                  Icons.check,
                  size: 16,
                  color: Theme.of(context).colorScheme.onSurface,
                  semanticLabel: 'Selected',
                )
              : null,
        ),
      ),
    ),
  );
}

class _CompletionField extends StatelessWidget {
  const _CompletionField({required this.model});
  final TrackerEditorViewModel model;
  @override
  Widget build(BuildContext context) {
    if (!model.isCreate) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Starting point',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            model.latestCompletionSummary,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          if (model.latestCompletion != null)
            TextButton.icon(
              onPressed: () => context.push('/trackers/${model.original!.id}'),
              icon: const Icon(Icons.open_in_new),
              label: const Text('View details and history'),
            ),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Starting point', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        SegmentedButton<InitialCompletionChoice>(
          segments: const [
            ButtonSegment(
              value: InitialCompletionChoice.notYet,
              label: Text('Not yet'),
            ),
            ButtonSegment(
              value: InitialCompletionChoice.today,
              label: Text('Today'),
            ),
            ButtonSegment(
              value: InitialCompletionChoice.date,
              label: Text('Earlier date'),
            ),
          ],
          selected: {model.initialCompletion},
          showSelectedIcon: true,
          onSelectionChanged: (value) {
            final choice = value.first;
            if (choice == InitialCompletionChoice.date) {
              _chooseDate(context);
            } else {
              model.setInitialCompletion(choice);
            }
          },
        ),
        if (model.initialCompletion == InitialCompletionChoice.date &&
            model.selectedDate != null)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => _chooseDate(context),
              icon: const Icon(Icons.calendar_today_outlined, size: 18),
              label: Text(_dateLabel(model.selectedDate!)),
            ),
          ),
      ],
    );
  }

  Future<void> _chooseDate(BuildContext context) async {
    final model = this.model;
    final today = model.clock.now.toLocal();
    final todayDate = DateTime(today.year, today.month, today.day);
    final chosen = await showEverDunCalendar(
      context: context,
      firstDay: DateTime(2000),
      lastDay: todayDate,
      initialDay: model.selectedDate ?? todayDate,
      title: 'Earlier date',
      supportingText:
          'Choose a past date or today. This remains factual history.',
      enabledDayPredicate: (day) => !day.isAfter(todayDate),
    );
    if (chosen != null) model.setDate(chosen);
  }
}

class _ScheduleField extends StatelessWidget {
  const _ScheduleField({required this.model});
  final TrackerEditorViewModel model;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('Schedule', style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: AppSpacing.sm),
      SegmentedButton<bool>(
        segments: const [
          ButtonSegment(value: false, label: Text('No schedule')),
          ButtonSegment(value: true, label: Text('Repeats')),
        ],
        selected: {model.repeatUnit != RepeatUnit.none},
        showSelectedIcon: true,
        onSelectionChanged: (value) {
          if (value.first) {
            model.setRepeatUnit(
              model.repeatUnit == RepeatUnit.none
                  ? RepeatUnit.days
                  : model.repeatUnit,
            );
          } else {
            model.setRepeatUnit(RepeatUnit.none);
          }
        },
      ),
      AnimatedSize(
        duration: _editorMotion(context),
        curve: Curves.easeOut,
        child: model.repeatUnit == RepeatUnit.none
            ? Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xs),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Log it whenever it happens.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              )
            : Padding(
                padding: const EdgeInsets.only(top: AppSpacing.sm),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: model.intervalController,
                            keyboardType: TextInputType.number,
                            onChanged: model.setRepeatInterval,
                            decoration: InputDecoration(
                              labelText: 'Every',
                              errorText: model.intervalError,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: DropdownButtonFormField<RepeatUnit>(
                            initialValue: model.repeatUnit,
                            decoration: const InputDecoration(
                              labelText: 'Unit',
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: RepeatUnit.days,
                                child: Text('day'),
                              ),
                              DropdownMenuItem(
                                value: RepeatUnit.weeks,
                                child: Text('week'),
                              ),
                              DropdownMenuItem(
                                value: RepeatUnit.months,
                                child: Text('month'),
                              ),
                              DropdownMenuItem(
                                value: RepeatUnit.years,
                                child: Text('year'),
                              ),
                            ],
                            onChanged: (unit) {
                              if (unit != null) model.setRepeatUnit(unit);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        model.cadencePreview,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
      ),
    ],
  );
}

class _FirstDueDateField extends StatelessWidget {
  const _FirstDueDateField({required this.model});
  final TrackerEditorViewModel model;

  @override
  Widget build(BuildContext context) => InputDecorator(
    decoration: const InputDecoration(
      labelText: 'First due date (optional)',
      helperText: 'For a tracker you have not completed yet.',
    ),
    child: Row(
      children: [
        Expanded(
          child: Text(
            model.firstDueDate == null
                ? 'Starts when you are ready'
                : _dateLabel(model.firstDueDate!),
          ),
        ),
        TextButton(
          onPressed: () => _chooseDate(context),
          child: Text(model.firstDueDate == null ? 'Choose' : 'Change'),
        ),
        if (model.firstDueDate != null)
          IconButton(
            tooltip: 'Clear first due date',
            onPressed: () => model.setFirstDueDate(null),
            icon: const Icon(Icons.clear),
          ),
      ],
    ),
  );

  Future<void> _chooseDate(BuildContext context) async {
    final today = model.clock.now.toLocal();
    final todayDate = DateTime(today.year, today.month, today.day);
    final chosen = await showEverDunCalendar(
      context: context,
      firstDay: todayDate,
      lastDay: DateTime(todayDate.year + 20),
      initialDay: model.firstDueDate ?? todayDate,
      title: 'First due date',
      supportingText:
          'This schedules the first occurrence without creating a completion.',
    );
    if (chosen != null) model.setFirstDueDate(chosen);
  }
}

class _ReminderField extends StatelessWidget {
  const _ReminderField({required this.model});
  final TrackerEditorViewModel model;

  @override
  Widget build(BuildContext context) {
    final scheduled = model.repeatUnit != RepeatUnit.none;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          title: const Text('Gentle reminder'),
          subtitle: Text(
            scheduled
                ? 'A local nudge before this is due.'
                : 'Add a schedule before enabling reminders.',
          ),
          value: model.reminderEnabled && scheduled,
          onChanged: scheduled ? model.setReminderEnabled : null,
        ),
        if (model.reminderEnabled && scheduled) ...[
          DropdownButtonFormField<ReminderLeadTime>(
            initialValue: model.reminderLeadTime,
            decoration: const InputDecoration(labelText: 'Remind me'),
            items: ReminderLeadTime.values
                .map(
                  (value) =>
                      DropdownMenuItem(value: value, child: Text(value.label)),
                )
                .toList(),
            onChanged: (value) {
              if (value != null) model.setReminderLeadTime(value);
            },
          ),
          const SizedBox(height: AppSpacing.sm),
          OutlinedButton.icon(
            onPressed: () => _chooseTime(context),
            icon: const Icon(Icons.schedule_outlined),
            label: Text(
              'At ${TimeOfDay(hour: model.reminderHour, minute: model.reminderMinute).format(context)}',
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _chooseTime(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: model.reminderHour,
        minute: model.reminderMinute,
      ),
    );
    if (picked != null) model.setReminderTime(picked.hour, picked.minute);
  }
}

extension TrackerCategoryLabel on TrackerCategory {
  String get label => switch (this) {
    TrackerCategory.home => 'Home',
    TrackerCategory.vehicle => 'Vehicle',
    TrackerCategory.personalCare => 'Personal care',
    TrackerCategory.technology => 'Technology',
    TrackerCategory.relationships => 'Relationships',
    TrackerCategory.custom => 'Custom',
  };
}

extension TrackerColorLabel on TrackerColor {
  String get label => switch (this) {
    TrackerColor.lime => 'Lime',
    TrackerColor.plum => 'Plum',
    TrackerColor.sky => 'Sky',
    TrackerColor.coral => 'Coral',
    TrackerColor.gold => 'Gold',
    TrackerColor.mint => 'Mint',
  };

  Color value(BuildContext context) => switch (this) {
    TrackerColor.lime => Theme.of(context).colorScheme.primaryContainer,
    TrackerColor.plum => Theme.of(
      context,
    ).extension<TrackerStatusThemeExtension>()!.category,
    TrackerColor.sky => Theme.of(
      context,
    ).extension<TrackerStatusThemeExtension>()!.informational,
    TrackerColor.coral => Theme.of(
      context,
    ).extension<TrackerStatusThemeExtension>()!.overdue,
    TrackerColor.gold => Theme.of(
      context,
    ).extension<TrackerStatusThemeExtension>()!.dueSoon,
    TrackerColor.mint => Theme.of(
      context,
    ).extension<TrackerStatusThemeExtension>()!.completed,
  };
}

String _dateLabel(DateTime date) => '${date.month}/${date.day}/${date.year}';
Duration _editorMotion(BuildContext context) =>
    MediaQuery.maybeOf(context)?.disableAnimations == true
    ? Duration.zero
    : AppMotion.short;

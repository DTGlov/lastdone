import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/design_system/design_tokens.dart';
import '../../../core/time/app_clock.dart';
import '../domain/tracker.dart';
import '../domain/tracker_repository.dart';
import 'tracker_editor_view_model.dart';

Future<bool?> showTrackerEditor({
  required BuildContext context,
  required TrackerRepository repository,
  required AppClock clock,
  TrackerOverview? overview,
}) => showModalBottomSheet<bool>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  showDragHandle: true,
  builder: (_) => ChangeNotifierProvider(
    create: (_) => overview == null
        ? TrackerEditorViewModel.create(repository: repository, clock: clock)
        : TrackerEditorViewModel.edit(
            repository: repository,
            clock: clock,
            overview: overview,
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
                  const SizedBox(height: AppSpacing.lg),
                  _NameField(model: model),
                  const SizedBox(height: AppSpacing.md),
                  _CategoryField(model: model),
                  const SizedBox(height: AppSpacing.lg),
                  _IconField(model: model),
                  const SizedBox(height: AppSpacing.lg),
                  _ColorField(model: model),
                  const SizedBox(height: AppSpacing.lg),
                  _CompletionField(model: model),
                  const SizedBox(height: AppSpacing.lg),
                  _ScheduleField(model: model),
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
                  const SizedBox(height: AppSpacing.lg),
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
    if (await model.save() && mounted) context.pop(true);
  }

  Future<void> _confirmDiscard(TrackerEditorViewModel model) async {
    final discard = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave without saving?'),
        content: const Text(
          'Your changes are still fresh. Would you like to keep editing?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep editing'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Leave'),
          ),
        ],
      ),
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
      Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        children: model.availableIconKeys
            .map(
              (key) => _IconChoice(
                keyName: key,
                selected: model.iconKey == key,
                onTap: () => model.setIcon(key),
              ),
            )
            .toList(),
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
    label: '${_iconLabel(keyName)} icon${selected ? ', selected' : ''}',
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadii.control),
      child: AnimatedContainer(
        duration: _editorMotion(context),
        constraints: const BoxConstraints(minWidth: 52, minHeight: 52),
        padding: const EdgeInsets.all(AppSpacing.sm),
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
        child: Icon(_iconFor(keyName), semanticLabel: _iconLabel(keyName)),
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
      Wrap(
        spacing: AppSpacing.sm,
        children: TrackerColor.values
            .map(
              (color) => _ColorChoice(
                color: color,
                selected: model.color == color,
                onTap: () => model.setColor(color),
              ),
            )
            .toList(),
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
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.value(context),
          border: Border.all(
            color: selected
                ? Theme.of(context).colorScheme.onSurface
                : Colors.transparent,
            width: selected ? 3 : 0,
          ),
        ),
        child: selected
            ? const Icon(Icons.check, semanticLabel: 'Selected')
            : null,
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
      return InputDecorator(
        decoration: const InputDecoration(labelText: 'Last completed'),
        child: Text(
          model.latestCompletion == null
              ? 'Never completed'
              : 'Latest completion is kept as history',
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Last completed', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            _ChoiceButton(
              label: 'Never completed',
              selected:
                  model.initialCompletion == InitialCompletionChoice.never,
              onTap: () =>
                  model.setInitialCompletion(InitialCompletionChoice.never),
            ),
            _ChoiceButton(
              label: 'Today',
              selected:
                  model.initialCompletion == InitialCompletionChoice.today,
              onTap: () =>
                  model.setInitialCompletion(InitialCompletionChoice.today),
            ),
            _ChoiceButton(
              label: model.selectedDate == null
                  ? 'Choose a date'
                  : _dateLabel(model.selectedDate!),
              selected: model.initialCompletion == InitialCompletionChoice.date,
              onTap: () => _chooseDate(context),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _chooseDate(BuildContext context) async {
    final model = this.model;
    final today = model.clock.now.toLocal();
    final todayDate = DateTime(today.year, today.month, today.day);
    final chosen = await showDatePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: todayDate,
      initialDate: model.selectedDate ?? todayDate,
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
      Text('Repeat schedule', style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: AppSpacing.sm),
      Row(
        children: [
          Expanded(
            child: TextField(
              controller: model.intervalController,
              enabled: model.repeatUnit != RepeatUnit.none,
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
              decoration: const InputDecoration(labelText: 'Unit'),
              items: RepeatUnit.values
                  .map(
                    (unit) => DropdownMenuItem(
                      value: unit,
                      child: Text(unit.label(1)),
                    ),
                  )
                  .toList(),
              onChanged: (unit) {
                if (unit != null) model.setRepeatUnit(unit);
              },
            ),
          ),
        ],
      ),
      const SizedBox(height: AppSpacing.xs),
      Text(model.cadencePreview, style: Theme.of(context).textTheme.bodySmall),
    ],
  );
}

class _ChoiceButton extends StatelessWidget {
  const _ChoiceButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    label: '$label${selected ? ', selected' : ''}',
    child: OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(selected ? Icons.check : Icons.radio_button_unchecked),
      label: Text(label),
    ),
  );
}

IconData _iconFor(String key) => switch (key) {
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

String _iconLabel(String key) => switch (key) {
  TrackerIconKeys.home => 'Home',
  TrackerIconKeys.vehicle => 'Vehicle',
  TrackerIconKeys.personalCare => 'Personal care',
  TrackerIconKeys.technology => 'Technology',
  TrackerIconKeys.relationships => 'Relationships',
  TrackerIconKeys.water => 'Water',
  TrackerIconKeys.tools => 'Tools',
  TrackerIconKeys.leaf => 'Nature',
  _ => 'Checklist',
};

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

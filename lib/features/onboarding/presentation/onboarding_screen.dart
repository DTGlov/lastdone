import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/design_system/design_tokens.dart';
import '../../../core/widgets/dun_view.dart';
import '../../trackers/domain/tracker.dart';
import '../domain/onboarding_models.dart';
import 'onboarding_view_model.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: false,
    onPopInvokedWithResult: (_, _) =>
        context.read<OnboardingViewModel>().back(),
    child: Scaffold(
      body: SafeArea(
        child: Consumer<OnboardingViewModel>(
          builder: (context, model, _) => Column(
            children: [
              _ProgressHeader(model: model),
              Expanded(
                child: AnimatedSwitcher(
                  duration: _motionDuration(context),
                  switchInCurve: AppMotion.curve,
                  switchOutCurve: AppMotion.curve,
                  child: _StepBody(model: model, key: ValueKey(model.step)),
                ),
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

class _ProgressHeader extends StatelessWidget {
  const _ProgressHeader({required this.model});
  final OnboardingViewModel model;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(
      AppSpacing.lg,
      AppSpacing.md,
      AppSpacing.lg,
      0,
    ),
    child: Row(
      children: [
        if (model.step != OnboardingStep.welcome)
          IconButton(
            onPressed: model.back,
            tooltip: 'Back',
            icon: const Icon(Icons.arrow_back),
          )
        else
          const SizedBox(width: 48),
        Expanded(
          child: Semantics(
            label: 'Onboarding step ${model.step.index + 1} of 5',
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadii.pill),
              child: LinearProgressIndicator(
                minHeight: 8,
                value: (model.step.index + 1) / 5,
              ),
            ),
          ),
        ),
        const SizedBox(width: 48),
      ],
    ),
  );
}

class _StepBody extends StatelessWidget {
  const _StepBody({required this.model, super.key});
  final OnboardingViewModel model;
  @override
  Widget build(BuildContext context) => switch (model.step) {
    OnboardingStep.welcome => _WelcomeStep(model: model),
    OnboardingStep.areas => _AreasStep(model: model),
    OnboardingStep.starters => _StartersStep(model: model),
    OnboardingStep.reminders => _ReminderStep(model: model),
    OnboardingStep.completion => _CompletionStep(model: model),
  };
}

class _StepLayout extends StatelessWidget {
  const _StepLayout({required this.action, required this.children});
  final List<Widget> children;
  final Widget action;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: constraints.maxHeight - AppSpacing.xl,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ...children,
            const SizedBox(height: AppSpacing.xl),
            action,
          ],
        ),
      ),
    ),
  );
}

class _WelcomeStep extends StatelessWidget {
  const _WelcomeStep({required this.model});
  final OnboardingViewModel model;
  @override
  Widget build(BuildContext context) => _StepLayout(
    action: FilledButton(
      onPressed: model.begin,
      child: const Text('Let’s begin'),
    ),
    children: [
      const SizedBox(height: AppSpacing.xl),
      const Center(
        child: SizedBox(width: 160, height: 140, child: DunMascot()),
      ),
      const SizedBox(height: AppSpacing.xl),
      Text(
        'LastDone',
        style: Theme.of(context).textTheme.displaySmall,
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: AppSpacing.sm),
      Text(
        'Remember the things life doesn’t schedule.',
        style: Theme.of(context).textTheme.headlineSmall,
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: AppSpacing.md),
      Text(
        'A warm little place to keep recurring parts of everyday life from slipping through the cracks.',
        style: Theme.of(context).textTheme.bodyLarge,
        textAlign: TextAlign.center,
      ),
    ],
  );
}

class _AreasStep extends StatelessWidget {
  const _AreasStep({required this.model});
  final OnboardingViewModel model;
  @override
  Widget build(BuildContext context) => _StepLayout(
    action: FilledButton(
      onPressed: model.continueFromAreas,
      child: const Text('Continue'),
    ),
    children: [
      Text(
        'What deserves remembering?',
        style: Theme.of(context).textTheme.headlineMedium,
      ),
      const SizedBox(height: AppSpacing.sm),
      Text(
        'Choose the parts of life you would like a hand with.',
        style: Theme.of(context).textTheme.bodyLarge,
      ),
      const SizedBox(height: AppSpacing.lg),
      Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        children: LifeArea.values
            .map(
              (area) => _AreaCard(
                area: area,
                selected: model.selectedAreas.contains(area),
                onTap: () => model.toggleArea(area),
              ),
            )
            .toList(),
      ),
      if (model.errorMessage != null) ...[
        const SizedBox(height: AppSpacing.md),
        Text(
          model.errorMessage!,
          key: const Key('onboarding-error'),
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        ),
      ],
    ],
  );
}

class _AreaCard extends StatelessWidget {
  const _AreaCard({
    required this.area,
    required this.selected,
    required this.onTap,
  });
  final LifeArea area;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    checked: selected,
    label: '${area.label}${selected ? ', selected' : ''}',
    child: InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      borderRadius: BorderRadius.circular(AppRadii.card),
      child: AnimatedContainer(
        duration: _motionDuration(context),
        width:
            (MediaQuery.sizeOf(context).width -
                2 * AppSpacing.lg -
                AppSpacing.sm) /
            2,
        constraints: const BoxConstraints(minHeight: 72),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: selected
              ? Theme.of(context).colorScheme.primaryContainer
              : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(AppRadii.card),
          border: Border.all(
            color: selected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).dividerColor,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                area.label,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            Icon(
              selected ? Icons.check_circle : Icons.circle_outlined,
              semanticLabel: selected ? 'Selected' : 'Not selected',
            ),
          ],
        ),
      ),
    ),
  );
}

class _StartersStep extends StatelessWidget {
  const _StartersStep({required this.model});
  final OnboardingViewModel model;
  @override
  Widget build(BuildContext context) => _StepLayout(
    action: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilledButton(
          onPressed: model.canContinueStarters
              ? model.continueFromStarters
              : null,
          child: const Text('Continue'),
        ),
        TextButton(
          onPressed: () => model.continueFromStarters(withoutTrackers: true),
          child: const Text('Continue without trackers'),
        ),
      ],
    ),
    children: [
      Text(
        'A few good starts',
        style: Theme.of(context).textTheme.headlineMedium,
      ),
      const SizedBox(height: AppSpacing.sm),
      Text(
        'These are ready to go. You can leave them as they are, tweak a few details, or start empty.',
        style: Theme.of(context).textTheme.bodyLarge,
      ),
      const SizedBox(height: AppSpacing.lg),
      if (model.starters.isEmpty)
        Text(
          'Custom trackers can be created later from Today.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ...model.starters.map(
        (starter) => _StarterCard(model: model, starter: starter),
      ),
      if (model.errorMessage != null) ...[
        const SizedBox(height: AppSpacing.md),
        Text(
          model.errorMessage!,
          key: const Key('onboarding-error'),
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        ),
      ],
    ],
  );
}

class _StarterCard extends StatelessWidget {
  const _StarterCard({required this.model, required this.starter});
  final OnboardingViewModel model;
  final StarterTracker starter;
  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: AppSpacing.sm),
    child: InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        model.toggleStarter(starter.id);
      },
      borderRadius: BorderRadius.circular(AppRadii.card),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Checkbox(
              value: model.selectedStarterIds.contains(starter.id),
              onChanged: (_) => model.toggleStarter(starter.id),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    starter.effectiveTitle,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    starter.effectiveRepeatRule.label,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () => showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                showDragHandle: true,
                builder: (_) =>
                    _StarterEditorSheet(model: model, starter: starter),
              ),
              tooltip: 'Edit ${starter.effectiveTitle}',
              icon: const Icon(Icons.edit_outlined),
            ),
          ],
        ),
      ),
    ),
  );
}

class _StarterEditorSheet extends StatefulWidget {
  const _StarterEditorSheet({required this.model, required this.starter});
  final OnboardingViewModel model;
  final StarterTracker starter;
  @override
  State<_StarterEditorSheet> createState() => _StarterEditorSheetState();
}

class _StarterEditorSheetState extends State<_StarterEditorSheet> {
  late final TextEditingController _controller;
  late RepeatRule _rule;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.starter.effectiveTitle);
    _rule = widget.starter.effectiveRepeatRule;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(
      AppSpacing.lg,
      0,
      AppSpacing.lg,
      MediaQuery.viewInsetsOf(context).bottom + AppSpacing.lg,
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          controller: _controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Name'),
        ),
        const SizedBox(height: AppSpacing.md),
        DropdownButtonFormField<RepeatRule>(
          initialValue: _rule,
          decoration: const InputDecoration(labelText: 'Repeats'),
          items: RepeatRule.values
              .map(
                (value) =>
                    DropdownMenuItem(value: value, child: Text(value.label)),
              )
              .toList(),
          onChanged: (value) => setState(() => _rule = value ?? _rule),
        ),
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: () {
              final title = _controller.text.trim();
              if (title.isNotEmpty) {
                widget.model.editStarter(
                  widget.starter.id,
                  title: title,
                  repeatRule: _rule,
                );
              }
              Navigator.pop(context);
            },
            child: const Text('Save changes'),
          ),
        ),
      ],
    ),
  );
}

class _ReminderStep extends StatelessWidget {
  const _ReminderStep({required this.model});
  final OnboardingViewModel model;
  @override
  Widget build(BuildContext context) => _StepLayout(
    action: Row(
      children: [
        Expanded(
          child: FilledButton(
            onPressed: () => model.chooseReminderIntent(true),
            child: const Text('Sounds good'),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: OutlinedButton(
            onPressed: () => model.chooseReminderIntent(false),
            child: const Text('Not now'),
          ),
        ),
      ],
    ),
    children: [
      const SizedBox(height: AppSpacing.xl),
      const Center(
        child: SizedBox(width: 160, height: 140, child: DunMascot()),
      ),
      const SizedBox(height: AppSpacing.xl),
      Text(
        'A gentle nudge, right on time.',
        style: Theme.of(context).textTheme.headlineMedium,
      ),
      const SizedBox(height: AppSpacing.md),
      Text(
        'LastDone can remind you before something becomes overdue. You can decide about device notifications later, when reminders are ready.',
        style: Theme.of(context).textTheme.bodyLarge,
      ),
    ],
  );
}

class _CompletionStep extends StatelessWidget {
  const _CompletionStep({required this.model});
  final OnboardingViewModel model;
  @override
  Widget build(BuildContext context) => _StepLayout(
    action: _SubmitButton(model: model),
    children: [
      const SizedBox(height: AppSpacing.xl),
      const Center(
        child: SizedBox(
          width: 160,
          height: 140,
          child: DunMascot(state: DunMascotState.celebrating),
        ),
      ),
      const SizedBox(height: AppSpacing.xl),
      Text(
        'You’re all set.',
        style: Theme.of(context).textTheme.headlineMedium,
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: AppSpacing.md),
      Text(
        model.selectedTrackerCount == 0
            ? 'Your day is ready for the things you choose to add later.'
            : '${model.selectedTrackerCount} ${model.selectedTrackerCount == 1 ? 'tracker is' : 'trackers are'} ready for your day.',
        style: Theme.of(context).textTheme.bodyLarge,
        textAlign: TextAlign.center,
      ),
      if (model.errorMessage != null) ...[
        const SizedBox(height: AppSpacing.md),
        Text(
          model.errorMessage!,
          key: const Key('onboarding-error'),
          style: TextStyle(color: Theme.of(context).colorScheme.error),
          textAlign: TextAlign.center,
        ),
      ],
    ],
  );
}

class _SubmitButton extends StatelessWidget {
  const _SubmitButton({required this.model});
  final OnboardingViewModel model;
  @override
  Widget build(BuildContext context) => FilledButton(
    onPressed: model.isSubmitting
        ? null
        : () async {
            HapticFeedback.mediumImpact();
            if (await model.submit() && context.mounted) context.go('/today');
          },
    child: model.isSubmitting
        ? const SizedBox.square(
            dimension: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : const Text('See my day'),
  );
}

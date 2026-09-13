import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:simple_icons/simple_icons.dart';

import '../../../core/design_system/design_tokens.dart';
import '../../../core/design_system/app_icons.dart';
import '../../../core/time/app_clock.dart';
import '../domain/subscription.dart';
import '../domain/subscription_catalog.dart';
import '../domain/subscription_repository.dart';
import 'subscription_editor_view_model.dart';

Future<bool?> showSubscriptionEditor({
  required BuildContext context,
  required SubscriptionRepository repository,
  required AppClock clock,
  Subscription? subscription,
}) => showModalBottomSheet<bool>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  showDragHandle: true,
  builder: (_) => ChangeNotifierProvider(
    create: (_) => subscription == null
        ? SubscriptionEditorViewModel.create(
            repository: repository,
            clock: clock,
          )
        : SubscriptionEditorViewModel.edit(
            repository: repository,
            clock: clock,
            subscription: subscription,
          ),
    child: const SubscriptionEditorSheet(),
  ),
);

class SubscriptionEditorSheet extends StatefulWidget {
  const SubscriptionEditorSheet({super.key});
  @override
  State<SubscriptionEditorSheet> createState() =>
      _SubscriptionEditorSheetState();
}

class _SubscriptionEditorSheetState extends State<SubscriptionEditorSheet> {
  bool _discarding = false;

  @override
  Widget build(BuildContext context) {
    final model = context.watch<SubscriptionEditorViewModel>();
    return PopScope(
      canPop: _discarding || (!model.isDirty && !model.isSaving),
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && !_discarding && model.isDirty) _confirmDiscard(model);
      },
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.86,
        minChildSize: 0.55,
        maxChildSize: 0.98,
        builder: (_, controller) => CustomScrollView(
          controller: controller,
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
                    model.isCreate
                        ? 'Keep it on your radar'
                        : 'Edit subscription',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    model.isCreate
                        ? 'A calmer way to keep an eye on recurring costs.'
                        : 'Keep the details current and easy to understand.',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _CategoryField(model: model),
                  const SizedBox(height: AppSpacing.md),
                  _ServiceField(model: model),
                  const SizedBox(height: AppSpacing.md),
                  TextField(
                    controller: model.nameController,
                    maxLength: 60,
                    decoration: InputDecoration(
                      labelText: 'Name',
                      hintText: 'e.g. Netflix',
                      errorText: model.nameError,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextField(
                    controller: model.amountController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Amount',
                      hintText: '0.00',
                      errorText: model.amountError,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _CurrencyField(model: model),
                  const SizedBox(height: AppSpacing.md),
                  _DateField(model: model),
                  const SizedBox(height: AppSpacing.md),
                  _FrequencyField(model: model),
                  if (!model.isCreate) ...[
                    const SizedBox(height: AppSpacing.md),
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Active subscription'),
                      value: model.active,
                      onChanged: model.setActive,
                    ),
                  ],
                  if (model.errorMessage != null) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      model.errorMessage!,
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
                        : Text(
                            model.isCreate
                                ? 'Add subscription'
                                : 'Save changes',
                          ),
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save(SubscriptionEditorViewModel model) async {
    if (await model.save() && mounted) context.pop(true);
  }

  Future<void> _confirmDiscard(SubscriptionEditorViewModel model) async {
    final leave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave without saving?'),
        content: const Text('Your subscription details are still here.'),
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
    if (leave == true && mounted) {
      setState(() => _discarding = true);
      Navigator.pop(context);
    }
  }
}

class _CategoryField extends StatelessWidget {
  const _CategoryField({required this.model});
  final SubscriptionEditorViewModel model;
  @override
  Widget build(BuildContext context) => Wrap(
    spacing: AppSpacing.sm,
    runSpacing: AppSpacing.sm,
    children: SubscriptionCategory.values
        .map(
          (category) => ChoiceChip(
            label: Text(category.label),
            selected: model.category == category,
            onSelected: (_) => model.setCategory(category),
          ),
        )
        .toList(),
  );
}

class _ServiceField extends StatelessWidget {
  const _ServiceField({required this.model});
  final SubscriptionEditorViewModel model;
  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
    onPressed: () => _chooseService(context),
    icon: SubscriptionLogo(
      name: model.selectedService?.name ?? 'Custom',
      category: model.category,
      logoKey: model.selectedService?.logoKey,
      small: true,
    ),
    label: Text(
      model.selectedService?.name ?? 'Choose a popular service or custom',
    ),
  );

  Future<void> _chooseService(BuildContext context) async {
    final chosen = await showModalBottomSheet<SubscriptionCatalogEntry?>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _ServicePicker(
        category: model.category,
        selected: model.selectedService,
      ),
    );
    if (chosen != null) model.selectService(chosen);
  }
}

class _ServicePicker extends StatefulWidget {
  const _ServicePicker({required this.category, required this.selected});
  final SubscriptionCategory category;
  final SubscriptionCatalogEntry? selected;
  @override
  State<_ServicePicker> createState() => _ServicePickerState();
}

class _ServicePickerState extends State<_ServicePicker> {
  String query = '';
  @override
  Widget build(BuildContext context) {
    final entries = subscriptionCatalog.where((entry) {
      final matchesCategory = entry.category == widget.category;
      final term = query.toLowerCase();
      return matchesCategory &&
          (term.isEmpty ||
              entry.name.toLowerCase().contains(term) ||
              entry.aliases.any((alias) => alias.contains(term)));
    }).toList();
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Choose a service',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              autofocus: true,
              onChanged: (value) => setState(() => query = value),
              decoration: const InputDecoration(
                prefixIcon: Icon(AppIcons.search),
                labelText: 'Search services',
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  ...entries.map(
                    (entry) => ListTile(
                      leading: SubscriptionLogo(
                        name: entry.name,
                        category: entry.category,
                        catalogServiceId: entry.id,
                        logoKey: entry.logoKey,
                      ),
                      title: Text(entry.name),
                      trailing: widget.selected?.id == entry.id
                          ? const Icon(Icons.check)
                          : null,
                      onTap: () => Navigator.pop(context, entry),
                    ),
                  ),
                  ListTile(
                    leading: const SubscriptionLogo(
                      name: 'Custom',
                      category: SubscriptionCategory.custom,
                    ),
                    title: const Text('Custom subscription'),
                    subtitle: const Text('Something else you want to remember'),
                    onTap: () => Navigator.pop(
                      context,
                      const SubscriptionCatalogEntry(
                        id: 'custom',
                        name: 'Custom subscription',
                        category: SubscriptionCategory.custom,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CurrencyField extends StatelessWidget {
  const _CurrencyField({required this.model});
  final SubscriptionEditorViewModel model;
  @override
  Widget build(BuildContext context) => DropdownButtonFormField<String>(
    initialValue: model.currency,
    decoration: const InputDecoration(labelText: 'Currency'),
    items: supportedCurrencies
        .map((value) => DropdownMenuItem(value: value, child: Text(value)))
        .toList(),
    onChanged: (value) {
      if (value != null) model.setCurrency(value);
    },
  );
}

class _DateField extends StatelessWidget {
  const _DateField({required this.model});
  final SubscriptionEditorViewModel model;
  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
    onPressed: () => _chooseDate(context),
    icon: const Icon(Icons.calendar_today_outlined),
    label: Text('Next charge: ${_dateLabel(model.chargeDate)}'),
  );

  Future<void> _chooseDate(BuildContext context) async {
    final today = model.clock.now.toLocal();
    final date = DateTime(today.year, today.month, today.day);
    final chosen = await showDatePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialDate: model.chargeDate.isBefore(DateTime(2000))
          ? date
          : model.chargeDate,
    );
    if (chosen != null) model.setChargeDate(chosen);
  }
}

class _FrequencyField extends StatelessWidget {
  const _FrequencyField({required this.model});
  final SubscriptionEditorViewModel model;
  @override
  Widget build(BuildContext context) =>
      DropdownButtonFormField<BillingFrequency>(
        initialValue: model.frequency,
        decoration: const InputDecoration(labelText: 'Billing frequency'),
        items: BillingFrequency.values
            .map(
              (value) =>
                  DropdownMenuItem(value: value, child: Text(value.label)),
            )
            .toList(),
        onChanged: (value) {
          if (value != null) model.setFrequency(value);
        },
      );
}

class SubscriptionLogo extends StatelessWidget {
  const SubscriptionLogo({
    required this.name,
    required this.category,
    this.catalogServiceId,
    this.logoKey,
    this.small = false,
    super.key,
  });
  final String name;
  final SubscriptionCategory category;
  final String? catalogServiceId;
  final String? logoKey;
  final bool small;
  @override
  Widget build(BuildContext context) {
    final icon = subscriptionBrandIcon(catalogServiceId);
    final tileSize = small ? 36.0 : 42.0;
    return Semantics(
      label: '$name logo',
      image: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: _categoryColor(context, category).withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(AppRadii.control),
          border: Border.all(color: _categoryColor(context, category)),
        ),
        child: SizedBox(
          width: tileSize,
          height: tileSize,
          child: Center(
            child: icon == null
                ? Text(
                    name.isEmpty ? '?' : name.substring(0, 1).toUpperCase(),
                    style: Theme.of(context).textTheme.titleMedium,
                  )
                : Icon(
                    icon,
                    size: small ? 18 : 22,
                    color: _categoryColor(context, category),
                  ),
          ),
        ),
      ),
    );
  }
}

IconData? subscriptionBrandIcon(String? catalogServiceId) =>
    switch (catalogServiceId) {
      'netflix' => SimpleIcons.netflix,
      'apple-tv-plus' => SimpleIcons.appletv,
      'spotify' => SimpleIcons.spotify,
      'apple-music' => SimpleIcons.applemusic,
      'youtube-music' => SimpleIcons.youtubemusic,
      'tidal' => SimpleIcons.tidal,
      'chatgpt' => SimpleIcons.chatbot,
      'claude' => SimpleIcons.claude,
      'perplexity' => SimpleIcons.perplexity,
      'github-copilot' => SimpleIcons.githubcopilot,
      'playstation-plus' => SimpleIcons.playstation,
      'apple-arcade' => SimpleIcons.applearcade,
      'icloud-plus' => SimpleIcons.icloud,
      'dropbox' => SimpleIcons.dropbox,
      'notion' => SimpleIcons.notion,
      'medium' => SimpleIcons.medium,
      'substack' => SimpleIcons.substack,
      'audible' => SimpleIcons.audible,
      'strava' => SimpleIcons.strava,
      'fitbit-premium' => SimpleIcons.fitbit,
      _ => null,
    };

Color _categoryColor(BuildContext context, SubscriptionCategory category) {
  final colors = Theme.of(context).extension<TrackerStatusThemeExtension>()!;
  return switch (category) {
    SubscriptionCategory.streaming => colors.category,
    SubscriptionCategory.music => colors.completed,
    SubscriptionCategory.sports => colors.dueSoon,
    SubscriptionCategory.ai => colors.informational,
    SubscriptionCategory.gaming => colors.overdue,
    _ => Theme.of(context).colorScheme.primaryContainer,
  };
}

String _dateLabel(DateTime date) => '${date.month}/${date.day}/${date.year}';

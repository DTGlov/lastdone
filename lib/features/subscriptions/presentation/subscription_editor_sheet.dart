import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:simple_icons/simple_icons.dart';

import '../../../core/design_system/design_tokens.dart';
import '../../../core/design_system/everdun_dialog.dart';
import '../../../core/design_system/everdun_calendar.dart';
import '../../../core/design_system/app_icons.dart';
import '../../../core/time/app_clock.dart';
import '../../../app/app_preferences_controller.dart';
import '../domain/subscription.dart';
import '../domain/subscription_catalog.dart';
import '../domain/subscription_repository.dart';
import '../../reminders/domain/reminder.dart';
import '../../reminders/domain/reminder_repository.dart';
import '../../reminders/data/notification_gateway.dart';
import 'subscription_editor_view_model.dart';

Future<bool?> showSubscriptionEditor({
  required BuildContext context,
  required SubscriptionRepository repository,
  required AppClock clock,
  Subscription? subscription,
  ReminderRepository? reminderRepository,
}) => showModalBottomSheet<bool>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  showDragHandle: true,
  builder: (sheetContext) => ChangeNotifierProvider(
    create: (_) => subscription == null
        ? SubscriptionEditorViewModel.create(
            repository: repository,
            clock: clock,
            reminderRepository: reminderRepository,
            defaultCurrency: Provider.of<AppPreferencesController>(
              sheetContext,
              listen: false,
            ).currency,
          )
        : SubscriptionEditorViewModel.edit(
            repository: repository,
            clock: clock,
            subscription: subscription,
            reminderRepository: reminderRepository,
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
                  if (model.reminderRepository != null) ...[
                    const SizedBox(height: AppSpacing.md),
                    _ReminderField(model: model),
                  ],
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
    if (model.reminderEnabled && model.active) await _offerReminderPermission();
    final saved = await model.save();
    if (!saved && mounted && model.errorMessage != null) {
      await showEverDunDialog<void>(
        context: context,
        title: 'Subscription not saved',
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
        message: 'EverDun can give you a local heads-up before this subscription renews. Nothing is sent to a server.',
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
          message: 'The subscription can still be saved, but its local reminder could not be configured. You can try again later from Reminders.',
          variant: EverDunDialogVariant.warning,
          primaryLabel: 'Continue',
        );
      }
    }
  }

  Future<void> _confirmDiscard(SubscriptionEditorViewModel model) async {
    final leave = await showEverDunDialog<bool>(
      context: context,
      title: 'Leave without saving?',
      message: 'Your subscription details are still here.',
      variant: EverDunDialogVariant.confirmation,
      primaryLabel: 'Leave',
      primaryResult: true,
      secondaryLabel: 'Keep editing',
      secondaryResult: false,
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
      useSafeArea: true,
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
  late final TextEditingController _searchController;
  late final FocusNode _searchFocusNode;
  late final DraggableScrollableController _sheetController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _searchFocusNode = FocusNode()..addListener(_handleSearchFocus);
    _sheetController = DraggableScrollableController();
  }

  void _handleSearchFocus() {
    if (!_searchFocusNode.hasFocus) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_sheetController.isAttached) return;
      _sheetController.animateTo(
        0.92,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  void dispose() {
    _searchFocusNode
      ..removeListener(_handleSearchFocus)
      ..dispose();
    _searchController.dispose();
    _sheetController.dispose();
    super.dispose();
  }

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
    final media = MediaQuery.of(context);
    final bottomInset = media.viewInsets.bottom > 0
        ? media.viewInsets.bottom
        : media.padding.bottom;
    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SafeArea(
        top: true,
        bottom: false,
        child: DraggableScrollableSheet(
          controller: _sheetController,
          expand: false,
          initialChildSize: 0.72,
          minChildSize: 0.45,
          maxChildSize: 0.95,
          builder: (context, scrollController) => GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () => FocusScope.of(context).unfocus(),
            child: Material(
              color: Theme.of(context).colorScheme.surface,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.sm,
                  AppSpacing.lg,
                  0,
                ),
                child: Column(
                  children: [
                    Text(
                      'Choose a service',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      widget.category.label,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextField(
                      controller: _searchController,
                      focusNode: _searchFocusNode,
                      autofocus: true,
                      onChanged: (value) => setState(() => query = value),
                      decoration: const InputDecoration(
                        prefixIcon: Icon(AppIcons.search),
                        labelText: 'Search services',
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Expanded(
                      child: ListView(
                        controller: scrollController,
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        children: [
                          if (entries.isEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: AppSpacing.md,
                              ),
                              child: Text(
                                'No services match that search.',
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ),
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
                            subtitle: const Text(
                              'Something else you want to remember',
                            ),
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
            ),
          ),
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

class _ReminderField extends StatelessWidget {
  const _ReminderField({required this.model});
  final SubscriptionEditorViewModel model;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SwitchListTile.adaptive(
        contentPadding: EdgeInsets.zero,
        title: const Text('Gentle reminder'),
        subtitle: Text(
          model.active
              ? 'A local heads-up before the next charge.'
              : 'Reactivate this subscription before enabling delivery.',
        ),
        value: model.reminderEnabled && model.active,
        onChanged: model.active ? model.setReminderEnabled : null,
      ),
      if (model.reminderEnabled && model.active) ...[
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
    final chosen = await showEverDunCalendar(
      context: context,
      firstDay: DateTime(2000),
      lastDay: DateTime(2100),
      initialDay: model.chargeDate.isBefore(DateTime(2000))
          ? date
          : model.chargeDate,
      title: 'Next charge date',
      supportingText: 'Past dates are allowed; the next occurrence is calculated from your billing frequency.',
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
      'x-premium' => SimpleIcons.x,
      'snapchat-plus' => SimpleIcons.snapchat,
      'meta-verified' => SimpleIcons.meta,
      'discord-nitro' => SimpleIcons.discord,
      'telegram-premium' => SimpleIcons.telegram,
      'reddit-premium' => SimpleIcons.reddit,
      'patreon' => SimpleIcons.patreon,
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
    SubscriptionCategory.social => colors.category,
    _ => Theme.of(context).colorScheme.primaryContainer,
  };
}

String _dateLabel(DateTime date) => '${date.month}/${date.day}/${date.year}';

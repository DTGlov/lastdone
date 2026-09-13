import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/time/app_clock.dart';
import '../domain/subscription.dart';
import '../domain/subscription_catalog.dart';
import '../domain/subscription_repository.dart';
import '../../reminders/domain/reminder.dart';
import '../../reminders/domain/reminder_repository.dart';

enum SubscriptionEditorMode { create, edit }

class SubscriptionEditorViewModel extends ChangeNotifier {
  SubscriptionEditorViewModel.create({
    required this.repository,
    required this.clock,
    this.reminderRepository,
  }) : mode = SubscriptionEditorMode.create,
       original = null {
    _initialise();
  }

  SubscriptionEditorViewModel.edit({
    required this.repository,
    required this.clock,
    required Subscription subscription,
    this.reminderRepository,
  }) : mode = SubscriptionEditorMode.edit,
       original = subscription {
    _initialise(subscription);
  }

  final SubscriptionRepository repository;
  final AppClock clock;
  final SubscriptionEditorMode mode;
  final Subscription? original;
  final ReminderRepository? reminderRepository;
  late final TextEditingController nameController;
  late final TextEditingController amountController;
  late SubscriptionCategory category;
  SubscriptionCatalogEntry? selectedService;
  late String currency;
  late BillingFrequency frequency;
  late DateTime chargeDate;
  late bool active;
  String? nameError;
  String? amountError;
  String? errorMessage;
  bool isSaving = false;
  bool reminderEnabled = false;
  ReminderLeadTime reminderLeadTime = ReminderLeadTime.onDay;
  int reminderHour = 9;
  int reminderMinute = 0;
  late final String _initialName;
  late final String _initialAmount;
  late final SubscriptionCategory _initialCategory;
  late final String? _initialCatalogId;
  late final String _initialCurrency;
  late final BillingFrequency _initialFrequency;
  late final DateTime _initialChargeDate;
  late final bool _initialActive;

  bool get isCreate => mode == SubscriptionEditorMode.create;
  bool get isDirty =>
      nameController.text != _initialName ||
      amountController.text != _initialAmount ||
      category != _initialCategory ||
      selectedService?.id != _initialCatalogId ||
      currency != _initialCurrency ||
      frequency != _initialFrequency ||
      !_sameDate(chargeDate, _initialChargeDate) ||
      active != _initialActive;

  void _initialise([Subscription? subscription]) {
    final now = _dateOnly(clock.now);
    nameController = TextEditingController(text: subscription?.name ?? '');
    amountController = TextEditingController(
      text: subscription == null
          ? ''
          : _displayAmount(subscription.amountMinor),
    );
    category = subscription?.category ?? SubscriptionCategory.streaming;
    selectedService = subscription == null
        ? null
        : catalogForId(subscription.catalogServiceId);
    currency = subscription?.currency ?? 'GHS';
    frequency = subscription?.frequency ?? BillingFrequency.monthly;
    chargeDate = _dateOnly(subscription?.nextChargeDate ?? now);
    active = subscription?.active ?? true;
    _initialName = nameController.text;
    _initialAmount = amountController.text;
    _initialCategory = category;
    _initialCatalogId = selectedService?.id;
    _initialCurrency = currency;
    _initialFrequency = frequency;
    _initialChargeDate = chargeDate;
    _initialActive = active;
    nameController.addListener(notifyListeners);
    amountController.addListener(notifyListeners);
    unawaited(_loadReminder());
  }

  Future<void> _loadReminder() async {
    final value = await reminderRepository?.getPreference(
      ReminderTarget(ReminderTargetType.subscription, original?.id ?? ''),
    );
    if (value == null) return;
    reminderEnabled = value.enabled;
    reminderLeadTime = value.leadTime;
    reminderHour = value.localHour;
    reminderMinute = value.localMinute;
    notifyListeners();
  }

  void setCategory(SubscriptionCategory value) {
    category = value;
    selectedService = null;
    notifyListeners();
  }

  void selectService(SubscriptionCatalogEntry? value) {
    selectedService = value;
    if (value != null) {
      category = value.category;
      nameController.text = value.name;
    }
    notifyListeners();
  }

  void setCurrency(String value) {
    currency = value;
    notifyListeners();
  }

  void setFrequency(BillingFrequency value) {
    frequency = value;
    notifyListeners();
  }

  void setChargeDate(DateTime value) {
    chargeDate = _dateOnly(value);
    notifyListeners();
  }

  void setActive(bool value) {
    active = value;
    notifyListeners();
  }

  void setReminderEnabled(bool value) {
    reminderEnabled = value;
    notifyListeners();
  }

  void setReminderLeadTime(ReminderLeadTime value) {
    reminderLeadTime = value;
    notifyListeners();
  }

  void setReminderTime(int hour, int minute) {
    reminderHour = hour;
    reminderMinute = minute;
    notifyListeners();
  }

  Future<bool> save() async {
    if (isSaving || !_validate()) return false;
    isSaving = true;
    errorMessage = null;
    notifyListeners();
    try {
      final now = clock.now;
      final value = Subscription(
        id: original?.id ?? 'subscription-${now.microsecondsSinceEpoch}',
        catalogServiceId: selectedService?.id ?? original?.catalogServiceId,
        name: nameController.text.trim(),
        category: category,
        logoKey: selectedService?.logoKey ?? original?.logoKey,
        amountMinor: parseMinorAmount(amountController.text.trim())!,
        currency: currency,
        frequency: frequency,
        nextChargeDate: nextChargeOnOrAfter(chargeDate, frequency, now),
        active: active,
        createdAt: original?.createdAt ?? now,
        updatedAt: now,
      );
      if (isCreate) {
        await repository.createSubscription(value);
      } else {
        await repository.updateSubscription(value);
      }
      final reminderStore = reminderRepository;
      if (reminderStore != null) {
        await reminderStore.savePreference(
          ReminderDraft(
            target: ReminderTarget(ReminderTargetType.subscription, value.id),
            enabled: reminderEnabled && value.active,
            leadTime: reminderLeadTime,
            localHour: reminderHour,
            localMinute: reminderMinute,
          ),
          now,
        );
      }
      isSaving = false;
      notifyListeners();
      return true;
    } catch (_) {
      isSaving = false;
      errorMessage = 'We could not save that yet. Your changes are still here.';
      notifyListeners();
      return false;
    }
  }

  bool _validate() {
    nameError = null;
    amountError = null;
    errorMessage = null;
    if (nameController.text.trim().isEmpty) {
      nameError = 'Give this subscription a name.';
    }
    final amount = parseMinorAmount(amountController.text);
    if (amount == null) {
      amountError =
          'Enter an amount greater than zero, with up to two decimals.';
    }
    if (nameError != null || amountError != null) {
      notifyListeners();
      return false;
    }
    return true;
  }

  @override
  void dispose() {
    nameController.dispose();
    amountController.dispose();
    super.dispose();
  }

  static SubscriptionCatalogEntry? catalogForId(String? id) => id == null
      ? null
      : subscriptionCatalog.where((entry) => entry.id == id).firstOrNull;

  static String _displayAmount(int minor) =>
      '${minor ~/ 100}.${(minor % 100).toString().padLeft(2, '0')}';
  static DateTime _dateOnly(DateTime value) {
    final local = value.toLocal();
    return DateTime(local.year, local.month, local.day);
  }

  static bool _sameDate(DateTime a, DateTime b) {
    final first = _dateOnly(a);
    final second = _dateOnly(b);
    return first.year == second.year &&
        first.month == second.month &&
        first.day == second.day;
  }
}

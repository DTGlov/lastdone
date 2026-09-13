import 'package:flutter/material.dart';

import '../../../core/time/app_clock.dart';
import '../domain/tracker.dart';
import '../domain/tracker_repository.dart';

enum TrackerEditorMode { create, edit }

enum InitialCompletionChoice { never, today, date }

enum RepeatUnit { days, weeks, months, years, none }

class TrackerEditorViewModel extends ChangeNotifier {
  TrackerEditorViewModel.create({
    required TrackerRepository repository,
    required AppClock clock,
  }) : this._(
         repository: repository,
         clock: clock,
         mode: TrackerEditorMode.create,
       );

  TrackerEditorViewModel.edit({
    required TrackerRepository repository,
    required AppClock clock,
    required TrackerOverview overview,
  }) : this._(
         repository: repository,
         clock: clock,
         mode: TrackerEditorMode.edit,
         overview: overview,
       );

  TrackerEditorViewModel._({
    required this.repository,
    required this.clock,
    required this.mode,
    TrackerOverview? overview,
  }) : original = overview?.tracker,
       latestCompletion = overview?.latestCompletion {
    final tracker = overview?.tracker;
    nameController = TextEditingController(text: tracker?.title ?? '');
    intervalController = TextEditingController(
      text: '${_editorInterval(tracker)}',
    );
    category = tracker?.category ?? TrackerCategory.custom;
    iconKey = tracker?.iconKey ?? TrackerIconKeys.checklist;
    color = tracker?.color ?? TrackerColor.plum;
    final schedule = _editorSchedule(tracker);
    repeatUnit = schedule.$1;
    repeatInterval = schedule.$2;
    initialCompletion = InitialCompletionChoice.never;
    selectedDate = null;
    _initialName = nameController.text;
    _initialInterval = intervalController.text;
    _initialCategory = category;
    _initialIconKey = iconKey;
    _initialColor = color;
    _initialRepeatUnit = repeatUnit;
    _initialRepeatInterval = repeatInterval;
    nameController.addListener(notifyListeners);
    intervalController.addListener(notifyListeners);
  }

  final TrackerRepository repository;
  final AppClock clock;
  final TrackerEditorMode mode;
  final Tracker? original;
  final Completion? latestCompletion;
  late final TextEditingController nameController;
  late final TextEditingController intervalController;
  late TrackerCategory category;
  late String iconKey;
  late TrackerColor color;
  late RepeatUnit repeatUnit;
  late int repeatInterval;
  late InitialCompletionChoice initialCompletion;
  DateTime? selectedDate;
  String? nameError;
  String? intervalError;
  String? errorMessage;
  bool isSaving = false;
  late final String _initialName;
  late final String _initialInterval;
  late final TrackerCategory _initialCategory;
  late final String _initialIconKey;
  late final TrackerColor _initialColor;
  late final RepeatUnit _initialRepeatUnit;
  late final int _initialRepeatInterval;

  bool get isCreate => mode == TrackerEditorMode.create;
  bool get isDirty =>
      nameController.text != _initialName ||
      intervalController.text != _initialInterval ||
      category != _initialCategory ||
      iconKey != _initialIconKey ||
      color != _initialColor ||
      repeatUnit != _initialRepeatUnit ||
      repeatInterval != _initialRepeatInterval ||
      initialCompletion != InitialCompletionChoice.never ||
      selectedDate != null;
  String get title => isCreate ? 'Remember something' : 'Edit tracker';
  String get supportingCopy => isCreate
      ? 'What should future you keep track of?'
      : 'Keep it useful and easy to recognise.';
  String get cadencePreview => repeatUnit == RepeatUnit.none
      ? 'No fixed schedule'
      : 'Every $repeatInterval ${repeatUnit.label(repeatInterval)}';

  void setCategory(TrackerCategory value) {
    category = value;
    if (!availableIconKeys.contains(iconKey)) iconKey = availableIconKeys.first;
    notifyListeners();
  }

  void setIcon(String value) {
    iconKey = value;
    notifyListeners();
  }

  void setColor(TrackerColor value) {
    color = value;
    notifyListeners();
  }

  void setRepeatUnit(RepeatUnit value) {
    repeatUnit = value;
    if (value == RepeatUnit.none) intervalController.text = '1';
    notifyListeners();
  }

  void setRepeatInterval(String value) {
    repeatInterval = int.tryParse(value) ?? 0;
    notifyListeners();
  }

  void setInitialCompletion(InitialCompletionChoice value) {
    initialCompletion = value;
    if (value == InitialCompletionChoice.today) {
      selectedDate = _dateOnly(clock.now);
    }
    if (value != InitialCompletionChoice.date) {
      selectedDate = value == InitialCompletionChoice.today
          ? selectedDate
          : null;
    }
    notifyListeners();
  }

  void setDate(DateTime value) {
    selectedDate = _dateOnly(value);
    initialCompletion = InitialCompletionChoice.date;
    notifyListeners();
  }

  Future<bool> save() async {
    if (isSaving) return false;
    if (!_validate()) return false;
    final editorRepository = repository is TrackerEditorRepository
        ? repository as TrackerEditorRepository
        : null;
    if (editorRepository == null) {
      errorMessage =
          'Tracker editing is not available right now. Please try again.';
      notifyListeners();
      return false;
    }
    isSaving = true;
    errorMessage = null;
    notifyListeners();
    try {
      final now = clock.now;
      final tracker = Tracker(
        id: original?.id ?? 'tracker-${now.microsecondsSinceEpoch}',
        title: nameController.text.trim(),
        repeatRule: _repeatRule,
        repeatInterval: repeatUnit == RepeatUnit.none ? 1 : repeatInterval,
        category: category,
        iconKey: iconKey,
        color: color,
        createdAt: original?.createdAt ?? now,
        updatedAt: now,
      );
      if (isCreate) {
        final completion = initialCompletion == InitialCompletionChoice.never
            ? null
            : Completion(
                id: '${tracker.id}-initial',
                trackerId: tracker.id,
                completedAt: selectedDate ?? _dateOnly(now),
              );
        await editorRepository.createTracker(tracker, completion);
      } else {
        await editorRepository.updateTracker(tracker);
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

  @override
  void dispose() {
    nameController.dispose();
    intervalController.dispose();
    super.dispose();
  }

  List<String> get availableIconKeys => switch (category) {
    TrackerCategory.home => [
      TrackerIconKeys.home,
      TrackerIconKeys.tools,
      TrackerIconKeys.leaf,
      TrackerIconKeys.checklist,
    ],
    TrackerCategory.vehicle => [
      TrackerIconKeys.vehicle,
      TrackerIconKeys.tools,
      TrackerIconKeys.checklist,
    ],
    TrackerCategory.personalCare => [
      TrackerIconKeys.personalCare,
      TrackerIconKeys.leaf,
      TrackerIconKeys.checklist,
    ],
    TrackerCategory.technology => [
      TrackerIconKeys.technology,
      TrackerIconKeys.tools,
      TrackerIconKeys.checklist,
    ],
    TrackerCategory.relationships => [
      TrackerIconKeys.relationships,
      TrackerIconKeys.leaf,
      TrackerIconKeys.checklist,
    ],
    TrackerCategory.custom => [
      TrackerIconKeys.checklist,
      TrackerIconKeys.tools,
      TrackerIconKeys.leaf,
    ],
  };

  RepeatRule get _repeatRule => switch (repeatUnit) {
    RepeatUnit.days => RepeatRule.daily,
    RepeatUnit.weeks => RepeatRule.weekly,
    RepeatUnit.months => RepeatRule.monthly,
    RepeatUnit.years => RepeatRule.yearly,
    RepeatUnit.none => RepeatRule.unscheduled,
  };

  bool _validate() {
    nameError = null;
    intervalError = null;
    errorMessage = null;
    final name = nameController.text.trim();
    if (name.isEmpty) {
      nameError = 'Give this tracker a name so it is easy to spot.';
    }
    if (name.length > 60) {
      nameError = 'Keep the name to 60 characters or fewer.';
    }
    repeatInterval = int.tryParse(intervalController.text.trim()) ?? 0;
    if (repeatUnit != RepeatUnit.none && repeatInterval <= 0) {
      intervalError = 'Use a positive whole number.';
    }
    if (initialCompletion == InitialCompletionChoice.date &&
        selectedDate != null &&
        selectedDate!.isAfter(_dateOnly(clock.now))) {
      intervalError = 'That date cannot be in the future.';
    }
    if (nameError != null || intervalError != null) {
      notifyListeners();
      return false;
    }
    return true;
  }

  static int _editorInterval(Tracker? tracker) => tracker == null
      ? 1
      : switch (tracker.repeatRule) {
          RepeatRule.everyTwoWeeks => 2,
          RepeatRule.everyThreeWeeks => 3,
          RepeatRule.everyThreeMonths => 3,
          RepeatRule.everyFourMonths => 4,
          _ => tracker.repeatInterval,
        };

  static (RepeatUnit, int) _editorSchedule(Tracker? tracker) {
    if (tracker == null || tracker.repeatRule == RepeatRule.unscheduled) {
      return (RepeatUnit.none, 1);
    }
    final unit = switch (tracker.repeatRule) {
      RepeatRule.daily => RepeatUnit.days,
      RepeatRule.weekly ||
      RepeatRule.everyTwoWeeks ||
      RepeatRule.everyThreeWeeks => RepeatUnit.weeks,
      RepeatRule.monthly ||
      RepeatRule.everyThreeMonths ||
      RepeatRule.everyFourMonths => RepeatUnit.months,
      RepeatRule.yearly => RepeatUnit.years,
      RepeatRule.unscheduled => RepeatUnit.none,
    };
    return (unit, _editorInterval(tracker));
  }

  static DateTime _dateOnly(DateTime value) {
    final local = value.toLocal();
    return DateTime(local.year, local.month, local.day);
  }
}

extension RepeatUnitLabel on RepeatUnit {
  String label(int interval) => switch (this) {
    RepeatUnit.days => interval == 1 ? 'day' : 'days',
    RepeatUnit.weeks => interval == 1 ? 'week' : 'weeks',
    RepeatUnit.months => interval == 1 ? 'month' : 'months',
    RepeatUnit.years => interval == 1 ? 'year' : 'years',
    RepeatUnit.none => 'time',
  };
}

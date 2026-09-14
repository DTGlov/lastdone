import 'package:flutter/foundation.dart';

import '../../../core/time/app_clock.dart';
import '../../trackers/domain/tracker.dart';
import '../../trackers/domain/tracker_icon.dart';
import '../../trackers/domain/tracker_repository.dart';
import '../data/onboarding_status_store.dart';
import '../domain/onboarding_models.dart';

enum OnboardingStep { welcome, areas, starters, reminders, completion }

class OnboardingViewModel extends ChangeNotifier {
  OnboardingViewModel({
    required this.trackerRepository,
    required this.statusStore,
    required this.clock,
  });
  final TrackerRepository trackerRepository;
  final OnboardingStatusStore statusStore;
  final AppClock clock;

  OnboardingStep step = OnboardingStep.welcome;
  final Set<LifeArea> selectedAreas = <LifeArea>{};
  final Set<String> selectedStarterIds = <String>{};
  final Map<String, StarterTracker> _starters = <String, StarterTracker>{};
  final Set<LifeArea> _previousAreas = <LifeArea>{};
  bool? reminderIntent;
  bool isSubmitting = false;
  String? errorMessage;

  List<StarterTracker> get starters => _starters.values.toList();
  int get selectedTrackerCount => selectedStarterIds.length;
  bool get canContinueAreas => selectedAreas.isNotEmpty;
  bool get canContinueStarters => selectedStarterIds.isNotEmpty;
  bool get isLastStep => step == OnboardingStep.completion;

  void begin() => _setStep(OnboardingStep.areas);

  void toggleArea(LifeArea area) {
    if (!selectedAreas.add(area)) selectedAreas.remove(area);
    _refreshSuggestions();
    _previousAreas
      ..clear()
      ..addAll(selectedAreas);
    notifyListeners();
  }

  void continueFromAreas() {
    if (!canContinueAreas) {
      errorMessage =
          'Choose at least one area to get started — there is no wrong answer.';
      notifyListeners();
      return;
    }
    errorMessage = null;
    _setStep(OnboardingStep.starters);
  }

  void toggleStarter(String id) {
    if (!selectedStarterIds.add(id)) selectedStarterIds.remove(id);
    notifyListeners();
  }

  void editStarter(String id, {String? title, RepeatRule? repeatRule}) {
    final starter = _starters[id];
    if (starter == null) return;
    _starters[id] = starter.copyWith(
      editedTitle: title,
      editedRepeatRule: repeatRule,
    );
    notifyListeners();
  }

  void continueFromStarters({bool withoutTrackers = false}) {
    if (!withoutTrackers && !canContinueStarters) {
      errorMessage = 'Pick one starter, or choose “Continue without trackers”.';
      notifyListeners();
      return;
    }
    errorMessage = null;
    _setStep(OnboardingStep.reminders);
  }

  Future<void> chooseReminderIntent(bool wantsReminders) async {
    reminderIntent = wantsReminders;
    await statusStore.setReminderIntent(wantsReminders);
    _setStep(OnboardingStep.completion);
  }

  Future<bool> submit() async {
    if (isSubmitting) return false;
    isSubmitting = true;
    errorMessage = null;
    notifyListeners();
    try {
      final now = clock.now.toUtc();
      final trackers = starters
          .where((starter) => selectedStarterIds.contains(starter.id))
          .map(
            (starter) => Tracker(
              id: starter.id,
              title: starter.effectiveTitle,
              repeatRule: starter.effectiveRepeatRule,
              category: _trackerCategory(starter.area),
              iconKey: _trackerIcon(starter.area),
              color: _trackerColor(starter.area),
              createdAt: now,
              updatedAt: now,
            ),
          )
          .toList();
      await trackerRepository.insertStarterTrackers(trackers);
      await statusStore.markComplete();
      isSubmitting = false;
      notifyListeners();
      return true;
    } catch (_) {
      isSubmitting = false;
      errorMessage = 'That did not quite save. Let’s try again.';
      notifyListeners();
      return false;
    }
  }

  static TrackerCategory _trackerCategory(LifeArea area) => switch (area) {
    LifeArea.home => TrackerCategory.home,
    LifeArea.vehicle => TrackerCategory.vehicle,
    LifeArea.personalCare => TrackerCategory.personalCare,
    LifeArea.technology => TrackerCategory.technology,
    LifeArea.relationships => TrackerCategory.relationships,
    LifeArea.custom => TrackerCategory.custom,
  };

  static String _trackerIcon(LifeArea area) => switch (area) {
    LifeArea.home => TrackerIcons.storageKeyForLegacy(TrackerIconKeys.home),
    LifeArea.vehicle => TrackerIcons.storageKeyForLegacy(
      TrackerIconKeys.vehicle,
    ),
    LifeArea.personalCare => TrackerIcons.storageKeyForLegacy(
      TrackerIconKeys.personalCare,
    ),
    LifeArea.technology => TrackerIcons.storageKeyForLegacy(
      TrackerIconKeys.technology,
    ),
    LifeArea.relationships => TrackerIcons.storageKeyForLegacy(
      TrackerIconKeys.relationships,
    ),
    LifeArea.custom => TrackerIcons.storageKeyForLegacy(
      TrackerIconKeys.checklist,
    ),
  };

  static TrackerColor _trackerColor(LifeArea area) => switch (area) {
    LifeArea.home => TrackerColor.plum,
    LifeArea.vehicle => TrackerColor.gold,
    LifeArea.personalCare => TrackerColor.mint,
    LifeArea.technology => TrackerColor.sky,
    LifeArea.relationships => TrackerColor.coral,
    LifeArea.custom => TrackerColor.plum,
  };

  void back() {
    if (step == OnboardingStep.welcome || isSubmitting) return;
    final previous = switch (step) {
      OnboardingStep.areas => OnboardingStep.welcome,
      OnboardingStep.starters => OnboardingStep.areas,
      OnboardingStep.reminders => OnboardingStep.starters,
      OnboardingStep.completion => OnboardingStep.reminders,
      OnboardingStep.welcome => OnboardingStep.welcome,
    };
    _setStep(previous);
  }

  void _refreshSuggestions() {
    final fresh = suggestionsFor(selectedAreas);
    final previousStarters = Map<String, StarterTracker>.from(_starters);
    final oldSelections = selectedStarterIds.toSet();
    _starters
      ..clear()
      ..addEntries(
        fresh.map(
          (starter) =>
              MapEntry(starter.id, previousStarters[starter.id] ?? starter),
        ),
      );
    selectedStarterIds
      ..clear()
      ..addAll(
        fresh
            .map((starter) => starter.id)
            .where(
              (id) =>
                  oldSelections.contains(id) ||
                  !_previousAreas.contains(
                    fresh.firstWhere((starter) => starter.id == id).area,
                  ),
            ),
      );
  }

  void _setStep(OnboardingStep value) {
    step = value;
    notifyListeners();
  }
}

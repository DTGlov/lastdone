import 'package:flutter_test/flutter_test.dart';
import 'package:everdun/core/time/app_clock.dart';
import 'package:everdun/features/onboarding/data/onboarding_status_store.dart';
import 'package:everdun/features/onboarding/domain/onboarding_models.dart';
import 'package:everdun/features/onboarding/presentation/onboarding_view_model.dart';
import 'package:everdun/features/trackers/domain/tracker.dart';
import 'package:everdun/features/trackers/domain/tracker_repository.dart';

class _FakeTrackerRepository implements TrackerRepository {
  List<Tracker> saved = [];
  bool failNext = false;
  @override
  Future<List<Tracker>> listTrackers() async => saved;
  @override
  Future<void> insertStarterTrackers(List<Tracker> trackers) async {
    if (failNext) {
      failNext = false;
      throw StateError('database unavailable');
    }
    saved = [...saved, ...trackers];
  }
}

OnboardingViewModel _buildModel(
  _FakeTrackerRepository repository,
  MemoryOnboardingStatusStore store,
) => OnboardingViewModel(
  trackerRepository: repository,
  statusStore: store,
  clock: FixedAppClock(DateTime.utc(2026, 1, 2)),
);

void main() {
  group('OnboardingViewModel', () {
    late _FakeTrackerRepository repository;
    late MemoryOnboardingStatusStore store;
    late OnboardingViewModel model;

    setUp(() {
      repository = _FakeTrackerRepository();
      store = MemoryOnboardingStatusStore();
      model = _buildModel(repository, store);
    });

    test('starts at welcome with no selections', () {
      expect(model.step, OnboardingStep.welcome);
      expect(model.selectedAreas, isEmpty);
      expect(model.starters, isEmpty);
      expect(model.isSubmitting, isFalse);
    });

    test('selects and deselects life areas', () {
      model.toggleArea(LifeArea.home);
      expect(model.selectedAreas, {LifeArea.home});
      model.toggleArea(LifeArea.home);
      expect(model.selectedAreas, isEmpty);
    });

    test('validates that an area is selected before continuing', () {
      model.begin();
      model.continueFromAreas();
      expect(model.step, OnboardingStep.areas);
      expect(model.errorMessage, contains('at least one area'));
    });

    test('derives and defaults starters from selected areas', () {
      model.toggleArea(LifeArea.vehicle);
      model.toggleArea(LifeArea.relationships);
      expect(model.starters.map((starter) => starter.title), [
        'Service vehicle',
        'Check tyre pressure',
        'Call family',
      ]);
      expect(model.selectedTrackerCount, 3);
      expect(
        model.starters.first.effectiveRepeatRule,
        RepeatRule.everyFourMonths,
      );
    });

    test('selects, deselects, and edits a starter', () {
      model.toggleArea(LifeArea.home);
      final starter = model.starters.first;
      model.toggleStarter(starter.id);
      expect(model.selectedTrackerCount, 2);
      model.toggleStarter(starter.id);
      expect(model.selectedTrackerCount, 3);
      model.editStarter(
        starter.id,
        title: 'Fresh sheets',
        repeatRule: RepeatRule.monthly,
      );
      expect(model.starters.first.effectiveTitle, 'Fresh sheets');
      expect(model.starters.first.effectiveRepeatRule, RepeatRule.monthly);
    });

    test('stores reminder intent and advances to completion', () async {
      model.chooseReminderIntent(false);
      await Future<void>.delayed(Duration.zero);
      expect(store.reminderIntent, isFalse);
      expect(model.reminderIntent, isFalse);
      expect(model.step, OnboardingStep.completion);
    });

    test('prevents duplicate submission while saving', () async {
      model.toggleArea(LifeArea.home);
      final first = model.submit();
      final second = model.submit();
      expect(await second, isFalse);
      expect(await first, isTrue);
      expect(repository.saved, hasLength(3));
    });

    test('persists trackers before marking onboarding complete', () async {
      model.toggleArea(LifeArea.relationships);
      expect(await model.submit(), isTrue);
      expect(repository.saved.single.title, 'Call family');
      expect(store.complete, isTrue);
    });

    test('reports persistence failure and allows retry', () async {
      repository.failNext = true;
      model.toggleArea(LifeArea.home);
      expect(await model.submit(), isFalse);
      expect(model.errorMessage, contains('did not quite save'));
      expect(store.complete, isFalse);
      expect(await model.submit(), isTrue);
      expect(store.complete, isTrue);
    });
  });
}

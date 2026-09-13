import '../../trackers/domain/tracker.dart';

enum LifeArea { home, vehicle, personalCare, technology, relationships, custom }

extension LifeAreaLabel on LifeArea {
  String get label => switch (this) {
    LifeArea.home => 'Home',
    LifeArea.vehicle => 'Vehicle',
    LifeArea.personalCare => 'Personal care',
    LifeArea.technology => 'Technology',
    LifeArea.relationships => 'Relationships',
    LifeArea.custom => 'Custom',
  };
}

class StarterTracker {
  const StarterTracker({
    required this.id,
    required this.area,
    required this.title,
    required this.repeatRule,
    this.editedTitle,
    this.editedRepeatRule,
  });
  final String id;
  final LifeArea area;
  final String title;
  final RepeatRule repeatRule;
  final String? editedTitle;
  final RepeatRule? editedRepeatRule;

  String get effectiveTitle => editedTitle ?? title;
  RepeatRule get effectiveRepeatRule => editedRepeatRule ?? repeatRule;
  StarterTracker copyWith({
    String? editedTitle,
    RepeatRule? editedRepeatRule,
  }) => StarterTracker(
    id: id,
    area: area,
    title: title,
    repeatRule: repeatRule,
    editedTitle: editedTitle ?? this.editedTitle,
    editedRepeatRule: editedRepeatRule ?? this.editedRepeatRule,
  );
}

List<StarterTracker> suggestionsFor(Set<LifeArea> areas) => [
  const StarterTracker(
    id: 'home-bedsheets',
    area: LifeArea.home,
    title: 'Change bedsheets',
    repeatRule: RepeatRule.everyTwoWeeks,
  ),
  const StarterTracker(
    id: 'home-air-conditioner',
    area: LifeArea.home,
    title: 'Clean air conditioner',
    repeatRule: RepeatRule.everyThreeMonths,
  ),
  const StarterTracker(
    id: 'home-water-filter',
    area: LifeArea.home,
    title: 'Replace water filter',
    repeatRule: RepeatRule.everyThreeMonths,
  ),
  const StarterTracker(
    id: 'vehicle-service',
    area: LifeArea.vehicle,
    title: 'Service vehicle',
    repeatRule: RepeatRule.everyFourMonths,
  ),
  const StarterTracker(
    id: 'vehicle-tyre-pressure',
    area: LifeArea.vehicle,
    title: 'Check tyre pressure',
    repeatRule: RepeatRule.monthly,
  ),
  const StarterTracker(
    id: 'personal-care-haircut',
    area: LifeArea.personalCare,
    title: 'Get a haircut',
    repeatRule: RepeatRule.everyThreeWeeks,
  ),
  const StarterTracker(
    id: 'personal-care-toothbrush',
    area: LifeArea.personalCare,
    title: 'Replace toothbrush',
    repeatRule: RepeatRule.everyThreeMonths,
  ),
  const StarterTracker(
    id: 'technology-backup',
    area: LifeArea.technology,
    title: 'Back up computer',
    repeatRule: RepeatRule.monthly,
  ),
  const StarterTracker(
    id: 'technology-clean-devices',
    area: LifeArea.technology,
    title: 'Clean devices',
    repeatRule: RepeatRule.everyTwoWeeks,
  ),
  const StarterTracker(
    id: 'relationships-family-call',
    area: LifeArea.relationships,
    title: 'Call family',
    repeatRule: RepeatRule.weekly,
  ),
].where((suggestion) => areas.contains(suggestion.area)).toList();

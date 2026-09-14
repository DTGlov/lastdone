import 'tracker.dart';

/// A curated tracker icon that can be stored in the existing text column.
class TrackerIconOption {
  const TrackerIconOption({required this.emoji, required this.label});

  final String emoji;
  final String label;

  String get storageKey => 'emoji:$emoji';
}

/// Shared tracker-icon catalog and compatibility resolver.
class TrackerIcons {
  const TrackerIcons._();

  static const options = <TrackerIconOption>[
    TrackerIconOption(emoji: '✅', label: 'General task'),
    TrackerIconOption(emoji: '🔧', label: 'Maintenance'),
    TrackerIconOption(emoji: '🌿', label: 'Plants and outdoors'),
    TrackerIconOption(emoji: '🏠', label: 'Home'),
    TrackerIconOption(emoji: '🚗', label: 'Vehicle'),
    TrackerIconOption(emoji: '💊', label: 'Health and medication'),
    TrackerIconOption(emoji: '🏋🏾', label: 'Fitness'),
    TrackerIconOption(emoji: '🧹', label: 'Cleaning'),
    TrackerIconOption(emoji: '💧', label: 'Water and filters'),
    TrackerIconOption(emoji: '🐶', label: 'Pet'),
    TrackerIconOption(emoji: '💻', label: 'Technology'),
    TrackerIconOption(emoji: '📚', label: 'Learning'),
    TrackerIconOption(emoji: '✈️', label: 'Travel'),
    TrackerIconOption(emoji: '💇🏾', label: 'Personal care'),
  ];

  static TrackerIconOption resolve(String key) {
    if (key.startsWith('emoji:')) {
      final emoji = key.substring('emoji:'.length);
      for (final option in options) {
        if (option.emoji == emoji) return option;
      }
      if (emoji.isNotEmpty) {
        return TrackerIconOption(emoji: emoji, label: 'Tracker icon');
      }
    }
    return _legacy[key] ?? options.first;
  }

  static String storageKeyForLegacy(String key) => resolve(key).storageKey;

  static final _legacy = <String, TrackerIconOption>{
    TrackerIconKeys.checklist: options[0],
    TrackerIconKeys.tools: options[1],
    TrackerIconKeys.leaf: options[2],
    TrackerIconKeys.home: options[3],
    TrackerIconKeys.vehicle: options[4],
    TrackerIconKeys.personalCare: options[13],
    TrackerIconKeys.technology: options[10],
    TrackerIconKeys.water: options[8],
    TrackerIconKeys.relationships: options[6],
  };
}

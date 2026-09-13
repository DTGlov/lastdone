import 'subscription.dart';

class SubscriptionCatalogEntry {
  const SubscriptionCatalogEntry({
    required this.id,
    required this.name,
    required this.category,
    this.aliases = const [],
    this.logoKey,
  });
  final String id;
  final String name;
  final SubscriptionCategory category;
  final List<String> aliases;
  final String? logoKey;
}

const subscriptionCatalog = <SubscriptionCatalogEntry>[
  SubscriptionCatalogEntry(
    id: 'netflix',
    name: 'Netflix',
    category: SubscriptionCategory.streaming,
  ),
  SubscriptionCatalogEntry(
    id: 'apple-tv-plus',
    name: 'Apple TV+',
    category: SubscriptionCategory.streaming,
  ),
  SubscriptionCatalogEntry(
    id: 'prime-video',
    name: 'Prime Video',
    category: SubscriptionCategory.streaming,
  ),
  SubscriptionCatalogEntry(
    id: 'disney-plus',
    name: 'Disney+',
    category: SubscriptionCategory.streaming,
  ),
  SubscriptionCatalogEntry(
    id: 'hulu',
    name: 'Hulu',
    category: SubscriptionCategory.streaming,
  ),
  SubscriptionCatalogEntry(
    id: 'max',
    name: 'Max',
    category: SubscriptionCategory.streaming,
  ),
  SubscriptionCatalogEntry(
    id: 'paramount-plus',
    name: 'Paramount+',
    category: SubscriptionCategory.streaming,
  ),
  SubscriptionCatalogEntry(
    id: 'peacock',
    name: 'Peacock',
    category: SubscriptionCategory.streaming,
  ),
  SubscriptionCatalogEntry(
    id: 'crunchyroll',
    name: 'Crunchyroll',
    category: SubscriptionCategory.streaming,
  ),
  SubscriptionCatalogEntry(
    id: 'showmax',
    name: 'Showmax',
    category: SubscriptionCategory.streaming,
  ),
  SubscriptionCatalogEntry(
    id: 'spotify',
    name: 'Spotify',
    category: SubscriptionCategory.music,
  ),
  SubscriptionCatalogEntry(
    id: 'apple-music',
    name: 'Apple Music',
    category: SubscriptionCategory.music,
  ),
  SubscriptionCatalogEntry(
    id: 'youtube-music',
    name: 'YouTube Music',
    category: SubscriptionCategory.music,
  ),
  SubscriptionCatalogEntry(
    id: 'tidal',
    name: 'Tidal',
    category: SubscriptionCategory.music,
  ),
  SubscriptionCatalogEntry(
    id: 'audiomack',
    name: 'Audiomack',
    category: SubscriptionCategory.music,
  ),
  SubscriptionCatalogEntry(
    id: 'dazn',
    name: 'DAZN',
    category: SubscriptionCategory.sports,
  ),
  SubscriptionCatalogEntry(
    id: 'espn-plus',
    name: 'ESPN+',
    category: SubscriptionCategory.sports,
  ),
  SubscriptionCatalogEntry(
    id: 'nba-league-pass',
    name: 'NBA League Pass',
    category: SubscriptionCategory.sports,
  ),
  SubscriptionCatalogEntry(
    id: 'nfl-plus',
    name: 'NFL+',
    category: SubscriptionCategory.sports,
  ),
  SubscriptionCatalogEntry(
    id: 'f1-tv',
    name: 'F1 TV',
    category: SubscriptionCategory.sports,
  ),
  SubscriptionCatalogEntry(
    id: 'ufc-fight-pass',
    name: 'UFC Fight Pass',
    category: SubscriptionCategory.sports,
  ),
  SubscriptionCatalogEntry(
    id: 'chatgpt',
    name: 'ChatGPT',
    category: SubscriptionCategory.ai,
    aliases: ['openai'],
  ),
  SubscriptionCatalogEntry(
    id: 'claude',
    name: 'Claude',
    category: SubscriptionCategory.ai,
  ),
  SubscriptionCatalogEntry(
    id: 'gemini',
    name: 'Gemini',
    category: SubscriptionCategory.ai,
  ),
  SubscriptionCatalogEntry(
    id: 'perplexity',
    name: 'Perplexity',
    category: SubscriptionCategory.ai,
  ),
  SubscriptionCatalogEntry(
    id: 'github-copilot',
    name: 'GitHub Copilot',
    category: SubscriptionCategory.ai,
  ),
  SubscriptionCatalogEntry(
    id: 'midjourney',
    name: 'Midjourney',
    category: SubscriptionCategory.ai,
  ),
  SubscriptionCatalogEntry(
    id: 'playstation-plus',
    name: 'PlayStation Plus',
    category: SubscriptionCategory.gaming,
  ),
  SubscriptionCatalogEntry(
    id: 'xbox-game-pass',
    name: 'Xbox Game Pass',
    category: SubscriptionCategory.gaming,
  ),
  SubscriptionCatalogEntry(
    id: 'nintendo-switch-online',
    name: 'Nintendo Switch Online',
    category: SubscriptionCategory.gaming,
  ),
  SubscriptionCatalogEntry(
    id: 'ea-play',
    name: 'EA Play',
    category: SubscriptionCategory.gaming,
  ),
  SubscriptionCatalogEntry(
    id: 'nvidia-geforce-now',
    name: 'NVIDIA GeForce NOW',
    category: SubscriptionCategory.gaming,
  ),
  SubscriptionCatalogEntry(
    id: 'apple-arcade',
    name: 'Apple Arcade',
    category: SubscriptionCategory.gaming,
  ),
  SubscriptionCatalogEntry(
    id: 'icloud-plus',
    name: 'iCloud+',
    category: SubscriptionCategory.cloudAndProductivity,
  ),
  SubscriptionCatalogEntry(
    id: 'google-one',
    name: 'Google One',
    category: SubscriptionCategory.cloudAndProductivity,
  ),
  SubscriptionCatalogEntry(
    id: 'microsoft-365',
    name: 'Microsoft 365',
    category: SubscriptionCategory.cloudAndProductivity,
  ),
  SubscriptionCatalogEntry(
    id: 'dropbox',
    name: 'Dropbox',
    category: SubscriptionCategory.cloudAndProductivity,
  ),
  SubscriptionCatalogEntry(
    id: 'notion',
    name: 'Notion',
    category: SubscriptionCategory.cloudAndProductivity,
  ),
  SubscriptionCatalogEntry(
    id: 'canva',
    name: 'Canva',
    category: SubscriptionCategory.cloudAndProductivity,
  ),
  SubscriptionCatalogEntry(
    id: 'adobe-creative-cloud',
    name: 'Adobe Creative Cloud',
    category: SubscriptionCategory.cloudAndProductivity,
  ),
  SubscriptionCatalogEntry(
    id: 'medium',
    name: 'Medium',
    category: SubscriptionCategory.newsAndReading,
  ),
  SubscriptionCatalogEntry(
    id: 'substack',
    name: 'Substack',
    category: SubscriptionCategory.newsAndReading,
  ),
  SubscriptionCatalogEntry(
    id: 'kindle-unlimited',
    name: 'Kindle Unlimited',
    category: SubscriptionCategory.newsAndReading,
  ),
  SubscriptionCatalogEntry(
    id: 'audible',
    name: 'Audible',
    category: SubscriptionCategory.newsAndReading,
  ),
  SubscriptionCatalogEntry(
    id: 'apple-fitness-plus',
    name: 'Apple Fitness+',
    category: SubscriptionCategory.fitness,
  ),
  SubscriptionCatalogEntry(
    id: 'strava',
    name: 'Strava',
    category: SubscriptionCategory.fitness,
  ),
  SubscriptionCatalogEntry(
    id: 'fitbit-premium',
    name: 'Fitbit Premium',
    category: SubscriptionCategory.fitness,
  ),
  SubscriptionCatalogEntry(
    id: 'peloton',
    name: 'Peloton',
    category: SubscriptionCategory.fitness,
  ),
  SubscriptionCatalogEntry(
    id: 'x-premium',
    name: 'X Premium',
    category: SubscriptionCategory.social,
    aliases: ['twitter'],
  ),
  SubscriptionCatalogEntry(
    id: 'linkedin-premium',
    name: 'LinkedIn Premium',
    category: SubscriptionCategory.social,
  ),
  SubscriptionCatalogEntry(
    id: 'snapchat-plus',
    name: 'Snapchat+',
    category: SubscriptionCategory.social,
  ),
  SubscriptionCatalogEntry(
    id: 'meta-verified',
    name: 'Meta Verified',
    category: SubscriptionCategory.social,
  ),
  SubscriptionCatalogEntry(
    id: 'discord-nitro',
    name: 'Discord Nitro',
    category: SubscriptionCategory.social,
  ),
  SubscriptionCatalogEntry(
    id: 'telegram-premium',
    name: 'Telegram Premium',
    category: SubscriptionCategory.social,
  ),
  SubscriptionCatalogEntry(
    id: 'reddit-premium',
    name: 'Reddit Premium',
    category: SubscriptionCategory.social,
  ),
  SubscriptionCatalogEntry(
    id: 'patreon',
    name: 'Patreon',
    category: SubscriptionCategory.social,
  ),
];

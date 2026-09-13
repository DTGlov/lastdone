class Subscription {
  const Subscription({
    required this.id,
    required this.name,
    required this.category,
    required this.amountMinor,
    required this.currency,
    required this.frequency,
    required this.nextChargeDate,
    required this.active,
    required this.createdAt,
    required this.updatedAt,
    this.catalogServiceId,
    this.logoKey,
    this.note,
  });

  final String id;
  final String? catalogServiceId;
  final String name;
  final SubscriptionCategory category;
  final String? logoKey;
  final int amountMinor;
  final String currency;
  final BillingFrequency frequency;
  final DateTime nextChargeDate;
  final bool active;
  final String? note;
  final DateTime createdAt;
  final DateTime updatedAt;
}

enum SubscriptionCategory {
  streaming,
  music,
  sports,
  ai,
  gaming,
  cloudAndProductivity,
  newsAndReading,
  fitness,
  custom,
}

enum BillingFrequency { weekly, monthly, quarterly, everySixMonths, yearly }

extension SubscriptionCategoryLabel on SubscriptionCategory {
  String get label => switch (this) {
    SubscriptionCategory.streaming => 'Streaming',
    SubscriptionCategory.music => 'Music',
    SubscriptionCategory.sports => 'Sports',
    SubscriptionCategory.ai => 'AI',
    SubscriptionCategory.gaming => 'Gaming',
    SubscriptionCategory.cloudAndProductivity => 'Cloud & productivity',
    SubscriptionCategory.newsAndReading => 'News & reading',
    SubscriptionCategory.fitness => 'Fitness',
    SubscriptionCategory.custom => 'Custom',
  };
}

extension BillingFrequencyLabel on BillingFrequency {
  String get label => switch (this) {
    BillingFrequency.weekly => 'Weekly',
    BillingFrequency.monthly => 'Monthly',
    BillingFrequency.quarterly => 'Every 3 months',
    BillingFrequency.everySixMonths => 'Every 6 months',
    BillingFrequency.yearly => 'Yearly',
  };

  int get months => switch (this) {
    BillingFrequency.weekly => 0,
    BillingFrequency.monthly => 1,
    BillingFrequency.quarterly => 3,
    BillingFrequency.everySixMonths => 6,
    BillingFrequency.yearly => 12,
  };
}

DateTime nextChargeOnOrAfter(
  DateTime anchor,
  BillingFrequency frequency,
  DateTime today,
) {
  final anchorDate = _dateOnly(anchor);
  final todayDate = _dateOnly(today);
  if (!anchorDate.isBefore(todayDate)) return anchorDate;
  var candidate = anchorDate;
  while (candidate.isBefore(todayDate)) {
    candidate = _advance(candidate, frequency);
  }
  return candidate;
}

DateTime _advance(DateTime date, BillingFrequency frequency) =>
    switch (frequency) {
      BillingFrequency.weekly => date.add(const Duration(days: 7)),
      BillingFrequency.monthly => _addMonths(date, 1),
      BillingFrequency.quarterly => _addMonths(date, 3),
      BillingFrequency.everySixMonths => _addMonths(date, 6),
      BillingFrequency.yearly => _addMonths(date, 12),
    };

DateTime _addMonths(DateTime date, int months) {
  final monthIndex = date.month - 1 + months;
  final year = date.year + monthIndex ~/ 12;
  final month = monthIndex % 12 + 1;
  return DateTime(year, month, date.day.clamp(1, _daysInMonth(year, month)));
}

int _daysInMonth(int year, int month) => DateTime(year, month + 1, 0).day;

DateTime _dateOnly(DateTime value) {
  final local = value.toLocal();
  return DateTime(local.year, local.month, local.day);
}

int monthlyEstimateMinor(Subscription subscription) {
  final amount = subscription.amountMinor;
  return switch (subscription.frequency) {
    BillingFrequency.weekly => (amount * 52 + 6) ~/ 12,
    BillingFrequency.monthly => amount,
    BillingFrequency.quarterly => (amount + 1) ~/ 3,
    BillingFrequency.everySixMonths => (amount + 3) ~/ 6,
    BillingFrequency.yearly => (amount + 6) ~/ 12,
  };
}

const supportedCurrencies = <String>[
  'GHS',
  'USD',
  'GBP',
  'EUR',
  'CAD',
  'NGN',
  'ZAR',
  'KES',
];

const currencySymbols = <String, String>{
  'GHS': 'GH₵',
  'USD': '\$',
  'GBP': '£',
  'EUR': '€',
  'CAD': 'CA\$',
  'NGN': '₦',
  'ZAR': 'R',
  'KES': 'KSh',
};

String formatMinorAmount(int minor, String currency) {
  final symbol = currencySymbols[currency] ?? currency;
  final major = minor ~/ 100;
  final cents = (minor.abs() % 100).toString().padLeft(2, '0');
  return '$symbol$major.$cents';
}

int? parseMinorAmount(String value) {
  final normalized = value.trim().replaceAll(',', '');
  if (!RegExp(r'^\d+(\.\d{0,2})?$').hasMatch(normalized)) return null;
  final parts = normalized.split('.');
  final whole = int.tryParse(parts.first);
  if (whole == null) return null;
  final decimal = parts.length == 1 ? '00' : parts[1].padRight(2, '0');
  final result = whole * 100 + int.parse(decimal);
  return result > 0 && result <= 100000000 ? result : null;
}

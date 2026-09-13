String pluralizeCount(int count, String singular, [String? plural]) {
  final word = count == 1 ? singular : (plural ?? '${singular}s');
  return '$count $word';
}

String daysText(int count) => pluralizeCount(count, 'day');
String weeksText(int count) => pluralizeCount(count, 'week');
String monthsText(int count) => pluralizeCount(count, 'month');
String yearsText(int count) => pluralizeCount(count, 'year');

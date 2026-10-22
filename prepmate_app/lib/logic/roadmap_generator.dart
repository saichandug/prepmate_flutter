// Port of src/utils/roadmapGenerator.js. Returns a JSON-compatible map.
import 'dart:math';

const _baseTopics = [
  {'topic': 'Programming Fundamentals', 'priority': 'HIGH', 'minutes': 45},
  {'topic': 'Arrays', 'priority': 'HIGH', 'minutes': 45},
  {'topic': 'Strings', 'priority': 'HIGH', 'minutes': 40},
  {'topic': 'OOP', 'priority': 'MEDIUM', 'minutes': 45},
  {'topic': 'HashMap', 'priority': 'HIGH', 'minutes': 45},
  {'topic': 'SQL', 'priority': 'MEDIUM', 'minutes': 45},
  {'topic': 'Coding Practice', 'priority': 'HIGH', 'minutes': 60},
  {'topic': 'Company Questions', 'priority': 'HIGH', 'minutes': 50},
  {'topic': 'Mock Interview', 'priority': 'HIGH', 'minutes': 45},
  {'topic': 'Revision & Weak Topics', 'priority': 'MEDIUM', 'minutes': 45},
];

Map<String, dynamic> generateRoadmap({
  required String company,
  required String role,
  required String experience,
  required String interviewDate,
  required Object preparationHours,
  List<Map<String, dynamic>> skills = const [],
  DateTime? now,
}) {
  final detected = skills
      .where((s) => s['category'] != 'Soft Skills')
      .map(
        (s) => <String, dynamic>{
          'topic': s['name'],
          'priority': s['priority'],
          'minutes': 45,
        },
      )
      .toList();

  final unique = <Map<String, dynamic>>[];
  for (final item in [
    ...detected,
    ..._baseTopics.map((e) => Map<String, dynamic>.from(e)),
  ]) {
    final topic = item['topic'].toString().toLowerCase();
    if (!unique.any((e) => e['topic'].toString().toLowerCase() == topic))
      unique.add(item);
  }

  final parsed = double.tryParse(preparationHours.toString().trim()) ?? 0;
  final hours = parsed == 0 ? 1.0 : parsed;
  final interview = DateTime.tryParse('${interviewDate}T00:00:00');
  final current = now ?? DateTime.now();
  final days = interview == null
      ? 14
      : max(
          1,
          ((interview.millisecondsSinceEpoch - current.millisecondsSinceEpoch) /
                  86400000)
              .ceil(),
        );

  final count = max(4, min(unique.length, (hours * days / 3).round()));
  final selected = unique.take(count).toList();
  final weeks = max(1, (days / 7).ceil());
  final weekCount = min(weeks, 6);

  final weekList = <Map<String, dynamic>>[];
  for (var index = 0; index < weekCount; index++) {
    final inWeek = <Map<String, dynamic>>[];
    for (var i = 0; i < selected.length; i++) {
      if (i % weekCount == index) inWeek.add(selected[i]);
    }
    final items = <Map<String, dynamic>>[];
    for (var itemIndex = 0; itemIndex < inWeek.length; itemIndex++) {
      final item = inWeek[itemIndex];
      final slug = item['topic']
          .toString()
          .replaceAll(RegExp(r'[^a-z0-9]', caseSensitive: false), '-')
          .toLowerCase();
      items.add({
        'id': 'r-$index-$slug-$itemIndex',
        'topic': item['topic'],
        'priority': item['priority'],
        'minutes': item['minutes'],
        'status': 'not-started',
      });
    }
    weekList.add({
      'week': index + 1,
      'title': index == 0
          ? 'Foundation & Priority Skills'
          : index == weeks - 1
          ? 'Mock Interview & Revision'
          : 'Focused Preparation ${index + 1}',
      'items': items,
    });
  }

  return {
    'meta': {
      'company': company,
      'role': role,
      'experience': experience,
      'interviewDate': interviewDate,
      'preparationHours': preparationHours,
    },
    'weeks': weekList.where((w) => (w['items'] as List).isNotEmpty).toList(),
  };
}

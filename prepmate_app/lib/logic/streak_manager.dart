// Port of src/utils/streakManager.js. The streak is a JSON-compatible map.

String dateKey([DateTime? date]) =>
    (date ?? DateTime.now()).toUtc().toIso8601String().substring(0, 10);

String _yesterdayKey(DateTime now) =>
    dateKey(now.subtract(const Duration(days: 1)));

Map<String, dynamic> emptyStreak() => {
  'current': 0,
  'best': 0,
  'todayActivities': <String>[],
  'lastQualifiedDate': null,
  'activityDates': <String, dynamic>{},
};

Map<String, dynamic> recordActivity(
  Map<String, dynamic> streak,
  String type, {
  DateTime? now,
}) {
  final clock = now ?? DateTime.now();
  final today = dateKey(clock);

  final activityDates = <String, dynamic>{};
  final existing = streak['activityDates'];
  if (existing is Map) {
    existing.forEach(
      (k, v) => activityDates[k.toString()] = List<String>.from(v as List),
    );
  }
  final next = Map<String, dynamic>.from(streak)
    ..['activityDates'] = activityDates;

  final todayList = List<String>.from(activityDates[today] ?? const <String>[]);
  if (!todayList.contains(type)) todayList.add(type);
  activityDates[today] = todayList;
  next['todayActivities'] = List<String>.from(todayList);

  if (todayList.length >= 3 && next['lastQualifiedDate'] != today) {
    if (next['lastQualifiedDate'] == _yesterdayKey(clock)) {
      next['current'] = ((next['current'] as num?) ?? 0).toInt() + 1;
    } else {
      next['current'] = 1;
    }
    final best = ((next['best'] as num?) ?? 0).toInt();
    final current = (next['current'] as num).toInt();
    next['best'] = best > current ? best : current;
    next['lastQualifiedDate'] = today;
  }

  return next;
}

List<String> getTodayActivities(Map<String, dynamic> streak, {DateTime? now}) {
  final dates = streak['activityDates'];
  if (dates is Map) {
    final list = dates[dateKey(now)];
    if (list is List) return List<String>.from(list);
  }
  return const [];
}

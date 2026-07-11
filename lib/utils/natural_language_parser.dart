/// Very small rule-based natural language parser for the quick-add box.
/// Not a real NLP model - just handles the common English phrasings so
/// that typing something like "tomorrow at 3pm call the plumber" or
/// "in 20 minutes take out the trash" fills in a date/time automatically
/// and leaves the rest as the task title.
class ParsedQuickAdd {
  final String title;
  final DateTime? dateTime;

  const ParsedQuickAdd({required this.title, this.dateTime});
}

const _weekdays = {
  'monday': DateTime.monday,
  'tuesday': DateTime.tuesday,
  'wednesday': DateTime.wednesday,
  'thursday': DateTime.thursday,
  'friday': DateTime.friday,
  'saturday': DateTime.saturday,
  'sunday': DateTime.sunday,
};

ParsedQuickAdd parseQuickAdd(String input, {DateTime? now}) {
  final current = now ?? DateTime.now();
  var text = input.trim();
  DateTime? date;
  TimeOfDayLite? time;

  String strip(RegExp re) {
    final m = re.firstMatch(text);
    if (m == null) return text;
    return (text.substring(0, m.start) + text.substring(m.end)).trim();
  }

  // relative day words
  final tomorrowRe = RegExp(r'\btomorrow\b', caseSensitive: false);
  final todayRe = RegExp(r'\btoday\b', caseSensitive: false);
  final nextWeekdayRe = RegExp(
    r'\bnext (monday|tuesday|wednesday|thursday|friday|saturday|sunday)\b',
    caseSensitive: false,
  );
  final inDurationRe = RegExp(
    r'\bin (\d+)\s*(minute|minutes|min|hour|hours|hr|day|days)\b',
    caseSensitive: false,
  );
  final atTimeRe = RegExp(
    r'\bat (\d{1,2})(?::(\d{2}))?\s*(am|pm)?\b',
    caseSensitive: false,
  );

  final durationMatch = inDurationRe.firstMatch(text);
  if (durationMatch != null) {
    final amount = int.parse(durationMatch.group(1)!);
    final unit = durationMatch.group(2)!.toLowerCase();
    Duration delta;
    if (unit.startsWith('min')) {
      delta = Duration(minutes: amount);
    } else if (unit.startsWith('hour') || unit == 'hr') {
      delta = Duration(hours: amount);
    } else {
      delta = Duration(days: amount);
    }
    final target = current.add(delta);
    date = DateTime(target.year, target.month, target.day);
    time = TimeOfDayLite(target.hour, target.minute);
    text = strip(inDurationRe);
  } else if (tomorrowRe.hasMatch(text)) {
    final target = current.add(const Duration(days: 1));
    date = DateTime(target.year, target.month, target.day);
    text = strip(tomorrowRe);
  } else if (todayRe.hasMatch(text)) {
    date = DateTime(current.year, current.month, current.day);
    text = strip(todayRe);
  } else {
    final weekdayMatch = nextWeekdayRe.firstMatch(text);
    if (weekdayMatch != null) {
      final wantedName = weekdayMatch.group(1)!.toLowerCase();
      final wanted = _weekdays[wantedName]!;
      var delta = (wanted - current.weekday) % 7;
      if (delta <= 0) delta += 7;
      final target = current.add(Duration(days: delta));
      date = DateTime(target.year, target.month, target.day);
      text = strip(nextWeekdayRe);
    }
  }

  if (time == null) {
    final timeMatch = atTimeRe.firstMatch(text);
    if (timeMatch != null) {
      var hour = int.parse(timeMatch.group(1)!);
      final minute = int.tryParse(timeMatch.group(2) ?? '') ?? 0;
      final meridiem = timeMatch.group(3)?.toLowerCase();
      if (meridiem == 'pm' && hour < 12) hour += 12;
      if (meridiem == 'am' && hour == 12) hour = 0;
      time = TimeOfDayLite(hour, minute);
      text = strip(atTimeRe);
    }
  }

  DateTime? result;
  if (date != null || time != null) {
    final baseDate = date ?? DateTime(current.year, current.month, current.day);
    result = DateTime(
      baseDate.year,
      baseDate.month,
      baseDate.day,
      time?.hour ?? 9,
      time?.minute ?? 0,
    );
  }

  final cleaned = text.replaceAll(RegExp(r'\s+'), ' ').trim();
  return ParsedQuickAdd(
    title: cleaned.isEmpty ? input.trim() : cleaned,
    dateTime: result,
  );
}

/// Tiny stand-in for Flutter's TimeOfDay so this file has no Flutter
/// dependency and can be unit-tested in plain Dart.
class TimeOfDayLite {
  final int hour;
  final int minute;
  const TimeOfDayLite(this.hour, this.minute);
}

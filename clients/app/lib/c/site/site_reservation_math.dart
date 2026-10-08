/// Half-open reservation duration shared by the guest sheet and the web page.
///
/// `day` counts calendar dates. `hour` / `minute` / `second` floor elapsed time.
/// `month` is the calendar month index difference (a partial month is 0 only
/// while the month index is unchanged). `year` is a half-open anniversary.

bool reservationNeedsTime(String unit) {
  final u = unit.trim().toLowerCase();
  return u.isNotEmpty && u != 'day';
}

int reservationDurationCount({
  required DateTime start,
  required DateTime end,
  required String unit,
}) {
  if (!end.isAfter(start)) return 0;
  switch (unit.trim().toLowerCase()) {
    case '':
    case 'day':
      return _calendarDays(start, end);
    case 'hour':
      return _elapsedFloor(start, end, Duration.microsecondsPerHour);
    case 'minute':
      return _elapsedFloor(start, end, Duration.microsecondsPerMinute);
    case 'second':
      return _elapsedFloor(start, end, Duration.microsecondsPerSecond);
    case 'week':
      return _calendarDays(start, end) ~/ 7;
    case 'month':
      final months = (end.year * 12 + end.month) - (start.year * 12 + start.month);
      return months < 0 ? 0 : months;
    case 'year':
      var years = end.year - start.year;
      if (end.month < start.month || (end.month == start.month && end.day < start.day)) {
        years -= 1;
      }
      return years < 0 ? 0 : years;
    default:
      return 0;
  }
}

int reservationBillable({required int units, required int durationCount}) {
  if (units < 1 || durationCount < 1) return 0;
  return units * durationCount;
}

DateTime reservationEndFromDuration({
  required DateTime start,
  required String unit,
  required int count,
}) {
  if (count < 1) return start;
  switch (unit.trim().toLowerCase()) {
    case 'second':
      return start.add(Duration(seconds: count));
    case 'minute':
      return start.add(Duration(minutes: count));
    case 'hour':
      return start.add(Duration(hours: count));
    case 'week':
      return _addCalendar(start, days: count * 7);
    case 'month':
      return _addCalendar(start, months: count);
    case 'year':
      return _addCalendar(start, years: count);
    case '':
    case 'day':
      return _addCalendar(start, days: count);
    default:
      return start;
  }
}

int _calendarDays(DateTime start, DateTime end) {
  final s = DateTime.utc(start.year, start.month, start.day);
  final e = DateTime.utc(end.year, end.month, end.day);
  final days = e.difference(s).inDays;
  return days < 0 ? 0 : days;
}

int _elapsedFloor(DateTime start, DateTime end, int unitMicros) {
  final us = end.difference(start).inMicroseconds;
  if (us <= 0 || unitMicros < 1) return 0;
  return us ~/ unitMicros;
}

DateTime _addCalendar(
  DateTime start, {
  int years = 0,
  int months = 0,
  int days = 0,
}) {
  return DateTime(
    start.year + years,
    start.month + months,
    start.day + days,
    start.hour,
    start.minute,
    start.second,
    start.millisecond,
    start.microsecond,
  );
}

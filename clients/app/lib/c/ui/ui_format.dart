int uiAsInt(dynamic v) {
  if (v is num) return v.toInt();
  if (v is bool) return v ? 1 : 0;
  if (v is String) return int.tryParse(v) ?? 0;
  return 0;
}

String uiFmtGroupedInt(int n) {
  if (n == 0) return '0';
  final neg = n < 0;
  final s = (neg ? -n : n).toString();
  final out = StringBuffer();
  final lead = s.length % 3;
  if (lead > 0) {
    out.write(s.substring(0, lead));
    if (s.length > lead) out.write(',');
  }
  for (var i = lead; i < s.length; i += 3) {
    out.write(s.substring(i, i + 3));
    if (i + 3 < s.length) out.write(',');
  }
  return neg ? '-$out' : out.toString();
}

String _uiFmtClockSegment(int n) => n.toString().padLeft(2, '0');

/// Compact duration for usage/trace UI: `450ms`, `12.3s`, then `1:03`, `1:30:04`, `1d 4:30:25`.
String uiFmtDurationMs(int ms) {
  if (ms <= 0) return '';
  if (ms < 1000) return '${ms}ms';
  final secs = ms ~/ 1000;
  if (secs < 60) return _uiFmtUnit(ms / 1000, 's');
  final days = secs ~/ _secondsPerDay;
  final remDay = secs % _secondsPerDay;
  final hours = remDay ~/ _secondsPerHour;
  final remHour = remDay % _secondsPerHour;
  final minutes = remHour ~/ _secondsPerMinute;
  final seconds = remHour % _secondsPerMinute;
  final clock = hours > 0
      ? '$hours:${_uiFmtClockSegment(minutes)}:${_uiFmtClockSegment(seconds)}'
      : '$minutes:${_uiFmtClockSegment(seconds)}';
  if (days > 0) return '${days}d $clock';
  return clock;
}

enum UiDurationUnit { month, day, hour, minute, second }

/// Two largest time units (months+days, days+hours, hours+minutes, or minutes+seconds).
class UiDurationTwoMajor {
  const UiDurationTwoMajor(this.first, this.firstUnit, this.second, this.secondUnit);

  final int first;
  final UiDurationUnit firstUnit;
  final int second;
  final UiDurationUnit secondUnit;
}

const _secondsPerMinute = 60;
const _secondsPerHour = 3600;
const _secondsPerDay = 86400;
const _secondsPerMonth = 30 * _secondsPerDay;
const _secondsMonthsTier = 60 * _secondsPerDay;

/// Non-negative span; zero seconds yields minutes=0, seconds=0.
UiDurationTwoMajor uiDurationTwoMajorParts(Duration duration) {
  var secs = duration.inSeconds;
  if (secs < 0) secs = 0;

  if (secs >= _secondsMonthsTier) {
    final months = secs ~/ _secondsPerMonth;
    final days = (secs % _secondsPerMonth) ~/ _secondsPerDay;
    return UiDurationTwoMajor(months, UiDurationUnit.month, days, UiDurationUnit.day);
  }
  if (secs >= _secondsPerDay) {
    final days = secs ~/ _secondsPerDay;
    final hours = (secs % _secondsPerDay) ~/ _secondsPerHour;
    return UiDurationTwoMajor(days, UiDurationUnit.day, hours, UiDurationUnit.hour);
  }
  if (secs >= _secondsPerHour) {
    final hours = secs ~/ _secondsPerHour;
    final minutes = (secs % _secondsPerHour) ~/ _secondsPerMinute;
    return UiDurationTwoMajor(hours, UiDurationUnit.hour, minutes, UiDurationUnit.minute);
  }
  if (secs >= _secondsPerMinute) {
    final minutes = secs ~/ _secondsPerMinute;
    final seconds = secs % _secondsPerMinute;
    return UiDurationTwoMajor(minutes, UiDurationUnit.minute, seconds, UiDurationUnit.second);
  }
  return UiDurationTwoMajor(0, UiDurationUnit.minute, secs, UiDurationUnit.second);
}

String _uiFmtUnit(double v, String unit) {
  final t = v.toStringAsFixed(1);
  return t.endsWith('.0') ? '${v.round()}$unit' : '$t$unit';
}

String uiFmtUsd(double usd) {
  if (usd <= 0) return '';
  if (usd < 0.000001) return '\$${usd.toStringAsFixed(8)}';
  if (usd < 0.0001) return '\$${usd.toStringAsFixed(6)}';
  if (usd < 0.01) return '\$${usd.toStringAsFixed(4)}';
  return '\$${usd.toStringAsFixed(3)}';
}

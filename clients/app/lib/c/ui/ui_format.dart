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

String uiFmtDurationMs(int ms) {
  if (ms <= 0) return '';
  if (ms < 1000) return '${ms}ms';
  final sec = ms / 1000;
  if (sec < 60) return _uiFmtUnit(sec, 's');
  final min = sec / 60;
  if (min < 60) return _uiFmtUnit(min, 'm');
  return _uiFmtUnit(min / 60, 'h');
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

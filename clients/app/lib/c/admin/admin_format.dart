import 'package:fixnum/fixnum.dart';

String adminFmtBytes(Int64 bytes) {
  final n = bytes.toInt();
  if (n <= 0) return '0 B';
  const units = ['B', 'KB', 'MB', 'GB', 'TB'];
  var v = n.toDouble();
  var i = 0;
  while (v >= 1024 && i < units.length - 1) {
    v /= 1024;
    i++;
  }
  final t = v >= 10 || i == 0 ? v.toStringAsFixed(0) : v.toStringAsFixed(1);
  return '$t ${units[i]}';
}

String adminFmtBps(double bps) {
  if (bps <= 0) return '0 B/s';
  return '${adminFmtBytes(Int64(bps.round()))}/s';
}

double adminPct(Int64 used, Int64 total) {
  final t = total.toInt();
  if (t <= 0) return 0;
  return (used.toInt() / t).clamp(0, 1) * 100;
}

String adminFmtPct(double pct) => '${pct.toStringAsFixed(0)}%';

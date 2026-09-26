import 'dart:math' as math;

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

String adminFmtBytesPair(Int64 used, Int64 total) {
  final t = total.toInt();
  final u = used.toInt();
  if (t <= 0) return adminFmtBytes(used);
  const units = ['B', 'KB', 'MB', 'GB', 'TB'];
  var v = t.toDouble();
  var i = 0;
  while (v >= 1024 && i < units.length - 1) {
    v /= 1024;
    i++;
  }
  final div = math.pow(1024, i).toDouble();
  String fmt(double n) => n >= 10 || i == 0 ? n.toStringAsFixed(0) : n.toStringAsFixed(1);
  return '${fmt(u / div)}/${fmt(t / div)}${units[i]}';
}


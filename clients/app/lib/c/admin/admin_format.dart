import 'dart:math' as math;

import 'package:alienai_c35/c/pb/c35/stats.pb.dart';
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

String adminFmtCpuPair(double used, double limit) {
  String f(double n) => n >= 10 ? n.toStringAsFixed(0) : n.toStringAsFixed(1);
  if (limit <= 0) return f(used);
  return '${f(used)}/${f(limit)}';
}

const _adminFmtDash = '\u2014';

String adminFmtCpuTriple(double used, double request, double limit) {
  String f(double n) => n >= 10 ? n.toStringAsFixed(0) : n.toStringAsFixed(1);
  String seg(double n) => n > 0 ? f(n) : _adminFmtDash;
  return '${f(used)} / ${seg(request)} / ${seg(limit)}';
}

String adminFmtBytesTriple(Int64 used, Int64 request, Int64 limit) {
  final max = [used, request, limit].fold(Int64.ZERO, (a, b) => a > b ? a : b);
  if (max <= Int64.ZERO) return '0 / $_adminFmtDash / $_adminFmtDash';
  const units = ['B', 'KB', 'MB', 'GB', 'TB'];
  var v = max.toInt().toDouble();
  var i = 0;
  while (v >= 1024 && i < units.length - 1) {
    v /= 1024;
    i++;
  }
  final div = math.pow(1024, i).toDouble();
  String fmt(Int64 n) {
    if (n <= Int64.ZERO) return _adminFmtDash;
    final x = n.toInt() / div;
    return x >= 10 || i == 0 ? x.toStringAsFixed(0) : x.toStringAsFixed(1);
  }
  return '${fmt(used)} / ${fmt(request)} / ${fmt(limit)} ${units[i]}';
}

/// Request position on a limit-scaled bar (0–1), when both are set.
double? adminPodRequestMarkerFrac(double request, double limit) {
  if (limit <= 0 || request <= 0) return null;
  return (request / limit).clamp(0.0, 1.0);
}

String adminNodeNetLabel(NodeStat node) {
  final iface = node.netIface;
  if (iface.isNotEmpty) return iface;
  return 'Network';
}

String adminNodeDisplayTitle(NodeStat node) {
  final addr = node.displayAddress;
  if (addr.isNotEmpty) return addr;
  final name = node.nodeName;
  if (name.isNotEmpty) return name;
  return 'Node';
}

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
  return '${fmt(u / div)}/${fmt(t / div)} ${units[i]}';
}


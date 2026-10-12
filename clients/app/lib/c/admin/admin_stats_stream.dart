import 'dart:async';

import 'package:alienai_c35/c/admin/admin_api.dart';
import 'package:alienai_c35/c/admin/admin_format.dart';
import 'package:alienai_c35/c/pb/c35/stats.pb.dart';
import 'package:flutter/foundation.dart';

class _NetPeak {
  /// Bar full scale at this rate unless we observe sustained higher throughput.
  static const double _defaultScaleBps = 10 * 1024 * 1024; // 10 MB/s

  double _max = _defaultScaleBps;

  double get max => _max;

  void update(double inBps, double outBps) {
    final sample = inBps > outBps ? inBps : outBps;
    if (sample > _max * 0.92) {
      _max = (sample * 1.15).clamp(_defaultScaleBps, double.infinity).toDouble();
    }
  }
}

class AdminStatsStream extends ChangeNotifier {
  AdminStatsStream(this.api);

  final AdminApi api;
  StreamSubscription<StatsPush>? _sub;
  StreamSubscription<void>? _reconnectedSub;
  String? subscribeError;
  final _nodes = <String, NodeStat>{};
  final _pods = <String, PodStat>{};
  final _volumes = <String, VolumeStat>{};
  final _netPeaks = <String, _NetPeak>{};
  String? _selectedNodeName;

  List<NodeStat> get nodes {
    final list = _nodes.values.toList(growable: false);
    list.sort((a, b) => a.nodeName.compareTo(b.nodeName));
    return list;
  }

  List<VolumeStat> get volumes {
    final list = _volumes.values.toList(growable: false);
    list.sort((a, b) => adminPct(b.usedBytes, b.capacityBytes).compareTo(adminPct(a.usedBytes, a.capacityBytes)));
    return list;
  }

  NodeStat? get primaryNode => nodes.isEmpty ? null : nodes.first;

  NodeStat? get selectedNode {
    if (_selectedNodeName != null) return _nodes[_selectedNodeName];
    return nodes.isEmpty ? null : nodes.first;
  }

  void selectNode(String name) {
    _selectedNodeName = name;
    notifyListeners();
  }

  List<VolumeStat> volumesForNode(String nodeName) =>
      volumes.where((v) => v.nodeName.isEmpty || v.nodeName == nodeName).toList();

  double networkMaxBps(String nodeName) => _netPeaks[nodeName]?.max ?? _NetPeak._defaultScaleBps;

  static const int _podStaleMs = 12000;

  List<PodStat> podsForNode(String nodeName) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final list = _pods.values
        .where((p) => p.nodeName == nodeName && _podFresh(p, now))
        .toList(growable: false);
    list.sort((a, b) => '${a.namespace}/${a.podName}'.compareTo('${b.namespace}/${b.podName}'));
    return list;
  }

  /// Pods grouped by namespace, then workload (deployment).
  List<AdminPodNamespace> podNamespacesForNode(String nodeName, {String search = ''}) {
    final pods = podsForNode(nodeName).where((p) => adminPodMatchesSearch(p, search)).toList();
    final byNs = <String, List<AdminPodGroup>>{};
    for (final p in pods) {
      final wl = adminPodWorkloadName(p.podName);
      final groups = byNs.putIfAbsent(p.namespace, () => []);
      final idx = groups.indexWhere((g) => g.workload == wl);
      if (idx >= 0) {
        groups[idx].pods.add(p);
      } else {
        groups.add(AdminPodGroup(namespace: p.namespace, workload: wl, pods: [p]));
      }
    }
    for (final groups in byNs.values) {
      for (final g in groups) {
        g.pods.sort((a, b) => a.podName.compareTo(b.podName));
      }
      groups.sort((a, b) => a.workload.compareTo(b.workload));
    }
    final out = byNs.entries
        .map((e) => AdminPodNamespace(namespace: e.key, workloads: e.value))
        .toList();
    out.sort((a, b) => a.namespace.compareTo(b.namespace));
    return out;
  }

  bool _podFresh(PodStat p, int nowMs) {
    final ts = p.tsMs.toInt();
    if (ts <= 0) return true;
    return nowMs - ts <= _podStaleMs;
  }

  void _pruneStalePods() {
    final now = DateTime.now().millisecondsSinceEpoch;
    _pods.removeWhere((_, p) => !_podFresh(p, now));
  }

  double networkMaxBpsForPod(PodStat pod) {
    final key = _podNetKey(pod);
    return _netPeaks[key]?.max ?? _NetPeak._defaultScaleBps;
  }

  String? nodeNetIface(String nodeName) {
    final n = _nodes[nodeName];
    if (n == null || n.netIface.isEmpty) return null;
    return n.netIface;
  }

  static String _podKey(PodStat pod) => '${pod.nodeName}/${pod.namespace}/${pod.podName}';

  static String _podNetKey(PodStat pod) => 'pod:${pod.nodeName}/${pod.namespace}/${pod.podName}';

  List<DiskDeviceStat> storagesFor(NodeStat node) {
    if (node.devices.isNotEmpty) return node.devices;
    return node.mounts
        .map(
          (m) => DiskDeviceStat(
            device: m.label.isNotEmpty ? m.label : (m.mount == '/' ? 'sda' : m.mount.replaceAll('/', '')),
            mount: m.mount,
            label: m.label,
            isBoot: m.mount == '/',
            usedBytes: m.usedBytes,
            totalBytes: m.totalBytes,
            readBps: m.readBps,
            writeBps: m.writeBps,
          ),
        )
        .toList();
  }

  void applySnapshot(Iterable<StatsPush> pushes) {
    for (final push in pushes) {
      _onPush(push);
    }
  }

  Future<void> start() async {
    _reconnectedSub ??= api.chatConn.onReconnected.listen((_) => unawaited(_subscribe()));
    await _subscribe();
  }

  /// Live stats relay only (snapshot already applied via [rootConsoleInit]).
  Future<void> attachLive() async {
    _reconnectedSub ??= api.chatConn.onReconnected.listen((_) => unawaited(_subscribe()));
    await _sub?.cancel();
    _sub = api.chatConn.onStatsPush.listen(_onPush);
    subscribeError = null;
    notifyListeners();
  }

  Future<void> _subscribe() async {
    await _sub?.cancel();
    _sub = api.chatConn.onStatsPush.listen(_onPush);
    subscribeError = null;
    notifyListeners();
    try {
      final res = await api.statsSubscribe();
      applySnapshot(res.snapshot);
    } catch (e) {
      subscribeError = '$e';
      notifyListeners();
    }
  }

  Future<void> stop() async {
    await _sub?.cancel();
    _sub = null;
    try {
      await api.statsUnsubscribe();
    } catch (_) {}
  }

  void _onPush(StatsPush push) {
    if (push.hasNode()) {
      final n = push.node;
      if (n.nodeName.isNotEmpty) {
        _nodes[n.nodeName] = n;
        _netPeaks.putIfAbsent(n.nodeName, () => _NetPeak()).update(n.netInBps, n.netOutBps);
      }
    } else if (push.hasPod()) {
      final p = push.pod;
      if (p.nodeName.isNotEmpty && p.podName.isNotEmpty) {
        final key = _podKey(p);
        _pods[key] = p;
        _netPeaks.putIfAbsent(_podNetKey(p), () => _NetPeak()).update(p.netInBps, p.netOutBps);
        _pruneStalePods();
      }
    } else if (push.hasVolume()) {
      final v = push.volume;
      final key = v.nodeName.isNotEmpty ? '${v.nodeName}/${v.namespace}/${v.pvcName}' : '${v.namespace}/${v.pvcName}';
      if (key != '/') _volumes[key] = v;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    unawaited(_reconnectedSub?.cancel());
    _reconnectedSub = null;
    unawaited(stop());
    super.dispose();
  }
}

class AdminPodGroup {
  AdminPodGroup({required this.namespace, required this.workload, required this.pods});

  final String namespace;
  final String workload;
  final List<PodStat> pods;

  String get title => '$namespace/$workload';
}

class AdminPodNamespace {
  const AdminPodNamespace({required this.namespace, required this.workloads});

  final String namespace;
  final List<AdminPodGroup> workloads;

  int get podCount => workloads.fold<int>(0, (n, g) => n + g.pods.length);
}

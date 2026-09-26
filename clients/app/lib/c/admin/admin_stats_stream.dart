import 'dart:async';

import 'package:alienai_c35/c/admin/admin_api.dart';
import 'package:alienai_c35/c/admin/admin_format.dart';
import 'package:alienai_c35/c/pb/c35/stats.pb.dart';
import 'package:flutter/foundation.dart';

class _NetPeak {
  DateTime _since = DateTime.now();
  double _max = 1;

  double get max => _max;

  void update(double inBps, double outBps) {
    final now = DateTime.now();
    final sample = inBps > outBps ? inBps : outBps;
    if (now.difference(_since).inSeconds > 60) {
      _since = now;
      _max = sample < 1 ? 1 : sample;
      return;
    }
    if (sample > _max) _max = sample;
    if (_max < 1) _max = 1;
  }
}

class AdminStatsStream extends ChangeNotifier {
  AdminStatsStream(this.api);

  final AdminApi api;
  StreamSubscription<StatsPush>? _sub;
  StreamSubscription<void>? _reconnectedSub;
  String? subscribeError;
  final _nodes = <String, NodeStat>{};
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

  double networkMaxBps(String nodeName) => _netPeaks[nodeName]?.max ?? 1;

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

  Future<void> start() async {
    _reconnectedSub ??= api.chatConn.onReconnected.listen((_) => unawaited(_subscribe()));
    await _subscribe();
  }

  Future<void> _subscribe() async {
    await _sub?.cancel();
    _sub = api.chatConn.onStatsPush.listen(_onPush);
    subscribeError = null;
    notifyListeners();
    try {
      await api.statsSubscribe();
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

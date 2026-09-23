import 'dart:async';

import 'package:alienai_c35/c/admin/admin_api.dart';
import 'package:alienai_c35/c/admin/admin_format.dart';
import 'package:alienai_c35/c/pb/c35/stats.pb.dart';
import 'package:flutter/foundation.dart';

class AdminStatsStream extends ChangeNotifier {
  AdminStatsStream(this.api);

  final AdminApi api;
  StreamSubscription<StatsPush>? _sub;
  final _nodes = <String, NodeStat>{};
  final _volumes = <String, VolumeStat>{};

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

  Future<void> start() async {
    await _sub?.cancel();
    _sub = api.chatConn.onStatsPush.listen(_onPush);
    await api.statsSubscribe();
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
      if (n.nodeName.isNotEmpty) _nodes[n.nodeName] = n;
    } else if (push.hasVolume()) {
      final v = push.volume;
      final key = '${v.namespace}/${v.pvcName}';
      if (key != '/') _volumes[key] = v;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    unawaited(stop());
    super.dispose();
  }
}

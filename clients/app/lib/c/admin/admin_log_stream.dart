import 'dart:async';

import 'package:alienai_c35/c/admin/admin_api.dart';
import 'package:alienai_c35/c/pb/c35/admin.pb.dart';
import 'package:alienai_c35/c/pb/c35/log.pb.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flutter/foundation.dart';

class AdminLogFilters {
  const AdminLogFilters({
    this.ownerIid,
    this.sinceMs = Int64.ZERO,
    this.untilMs = Int64.ZERO,
    this.text = '',
    this.kind,
    this.topic,
    this.limit = 500,
  });

  final int? ownerIid;
  final Int64 sinceMs;
  final Int64 untilMs;
  final String text;
  final String? kind;
  final String? topic;
  final int limit;

  ReqAdminLogList toReq() {
    final req = ReqAdminLogList(
      sinceMs: sinceMs,
      untilMs: untilMs,
      text: text.trim(),
      limit: limit,
    );
    if (ownerIid != null) req.ownerIid = Int64(ownerIid!);
    if (kind != null && kind!.isNotEmpty) req.kind = kind!;
    if (topic != null && topic!.isNotEmpty) req.topic = topic!;
    return req;
  }

  bool matches(Log row) {
    if (ownerIid != null && row.ownerIid.toInt() != ownerIid) return false;
    final ts = row.createdTsMs.toInt();
    if (sinceMs > Int64.ZERO && ts < sinceMs.toInt()) return false;
    if (untilMs > Int64.ZERO && ts > untilMs.toInt()) return false;
    final q = text.trim().toLowerCase();
    if (q.isNotEmpty && !row.text.toLowerCase().contains(q)) return false;
    if (kind != null && kind!.isNotEmpty && row.kind != kind) return false;
    if (topic != null && topic!.isNotEmpty && row.topic != topic) return false;
    return true;
  }
}

class AdminLogStream extends ChangeNotifier {
  AdminLogStream(this.api);

  final AdminApi api;
  final _logs = <Int64, Log>{};
  StreamSubscription? _sub;
  AdminLogFilters _filters = const AdminLogFilters();
  var _loading = false;
  String? _error;

  List<Log> get logs {
    final list = _logs.values.toList(growable: false);
    list.sort((a, b) => b.createdTsMs.compareTo(a.createdTsMs));
    return list;
  }

  bool get loading => _loading;
  String? get error => _error;
  AdminLogFilters get filters => _filters;

  Future<void> refresh(AdminLogFilters filters) async {
    _filters = filters;
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final rows = await api.adminLogList(filters.toReq());
      _logs
        ..clear()
        ..addEntries(rows.map((r) => MapEntry(r.id, r)));
      await _sub?.cancel();
      _sub = api.chatConn.onLogPush.listen(_onPush);
      await api.logSubscribe(ownerIid: filters.ownerIid);
    } catch (e) {
      _error = '$e';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  void _onPush(LogPush push) {
    if (!push.hasRow()) return;
    final row = push.row;
    if (!_filters.matches(row)) return;
    _logs[row.id] = row;
    notifyListeners();
  }

  Future<void> stop() async {
    await _sub?.cancel();
    _sub = null;
    try {
      await api.logUnsubscribe();
    } catch (_) {}
  }

  @override
  void dispose() {
    unawaited(stop());
    super.dispose();
  }
}

import 'dart:convert';

import 'package:alienai_c35/c/api/referral_conn.dart';
import 'package:alienai_c35/c/chat/chat_conn.dart';
import 'package:alienai_c35/c/device/device_api.dart';
import 'package:alienai_c35/c/log.dart';
import 'package:alienai_c35/c/pb/c35/identity.pb.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flutter/foundation.dart';

bool deviceOnlineFromMeta(String metaJson) {
  if (metaJson.trim().isEmpty) return false;
  try {
    final m = jsonDecode(metaJson);
    if (m is! Map) return false;
    final lastSeen = m['last_seen'] ?? m['last_seen_ms'];
    if (lastSeen == null) return false;
    final ms = lastSeen is num ? lastSeen.toInt() : int.tryParse('$lastSeen') ?? 0;
    if (ms <= 0) return false;
    return DateTime.now().millisecondsSinceEpoch - ms < 120000;
  } catch (_) {
    return false;
  }
}

class DeviceStore extends ChangeNotifier {
  DeviceStore({ChatConn? conn, ReferralConn? invoke}) : _conn = conn ?? ChatConn(), _invoke = invoke ?? ReferralConn();

  final ChatConn _conn;
  final ReferralConn _invoke;

  ChatConn get conn => _conn;

  var _loading = false;
  var _search = '';
  final _rows = <IdentityListRow>[];
  String? _selectedId;

  bool get loading => _loading;
  String get search => _search;
  String? get selectedId => _selectedId;
  List<IdentityListRow> get rows => _rows;

  List<IdentityListRow> get filtered {
    final q = _search.trim().toLowerCase();
    if (q.isEmpty) return List.unmodifiable(_rows);
    return _rows.where((r) {
      final id = r.identity;
      return id.name.toLowerCase().contains(q) || id.type.toLowerCase().contains(q) || id.alienId.toLowerCase().contains(q);
    }).toList(growable: false);
  }

  IdentityListRow? rowById(String? id) {
    if (id == null) return null;
    for (final r in _rows) {
      if (r.identity.iid.toString() == id) return r;
    }
    return null;
  }

  void searchPut(String value) {
    if (_search == value) return;
    _search = value;
    notifyListeners();
  }

  void select(String? id) {
    if (_selectedId == id) return;
    _selectedId = id;
    notifyListeners();
  }

  Future<void> ensureConnected({String locale = 'en'}) async {
    if (_conn.connected) return;
    await _conn.connect(locale: locale);
  }

  Future<void> refresh({bool includeArchived = false}) async {
    _loading = true;
    notifyListeners();
    try {
      await ensureConnected();
      final res = await identityList(_conn, const ['remote', 'iot'], includeArchived: includeArchived);
      _rows
        ..clear()
        ..addAll(res.rows);
      if (_selectedId != null && rowById(_selectedId) == null) _selectedId = null;
      if (_selectedId == null && _rows.isNotEmpty) _selectedId = _rows.first.identity.iid.toString();
    } catch (e) {
      lError('device refresh: $e');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<IdentityListRow?> pair(String code) async {
    try {
      final res = await devicePair(_invoke, code);
      await refresh();
      final id = res.device.identity.iid.toString();
      _selectedId = id;
      notifyListeners();
      return res.device;
    } catch (e) {
      lError('device pair: $e');
      rethrow;
    }
  }

  Future<void> pinPut(String id, bool pinned) => _grantPatch(id, ReqIdentityGrantPatch(resourceIid: Int64.parseInt(id), isPinned: pinned));

  Future<void> archivePut(String id, bool archived) => _grantPatch(id, ReqIdentityGrantPatch(resourceIid: Int64.parseInt(id), archived: archived));

  Future<void> _grantPatch(String id, ReqIdentityGrantPatch req) async {
    try {
      await ensureConnected();
      final res = await identityGrantPatch(_conn, req);
      final i = _rows.indexWhere((r) => r.identity.iid.toString() == id);
      if (i >= 0) {
        _rows[i] = res.row;
      } else {
        _rows.add(res.row);
      }
      _rows.sort((a, b) {
        final pin = (b.isPinned ? 1 : 0) - (a.isPinned ? 1 : 0);
        if (pin != 0) return pin;
        final order = a.sortOrder.compareTo(b.sortOrder);
        if (order != 0) return order;
        return b.identity.updatedTsMs.compareTo(a.identity.updatedTsMs);
      });
      notifyListeners();
    } catch (e) {
      lError('device grant patch: $e');
      rethrow;
    }
  }
}

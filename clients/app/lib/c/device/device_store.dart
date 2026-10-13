import 'dart:async';
import 'dart:convert';
import 'package:alienai_c35/c/api/referral_conn.dart';
import 'package:alienai_c35/c/chat/chat_conn.dart';
import 'package:alienai_c35/c/device/device_api.dart';
import 'package:alienai_c35/c/device/device_presence_cache.dart';
import 'package:alienai_c35/c/log.dart';
import 'package:alienai_c35/c/remote/remote_session.dart';
import 'package:alienai_c35/c/pb/c35/device.pb.dart';
import 'package:alienai_c35/c/pb/c35/identity.pb.dart';
import 'package:alienai_c35/c/session.dart';
import 'package:alienai_c35/c/store/chat_store.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Agent control-plane presence (`meta.last_seen_ts_ms` on the device identity).
bool deviceOnlineFromMeta(String metaJson) {
  if (metaJson.trim().isEmpty) return false;
  try {
    final m = jsonDecode(metaJson);
    if (m is! Map) return false;
    if (m['online'] == false) return false;
    final lastSeen = m['last_seen_ts_ms'] ?? m['last_seen'] ?? m['last_seen_ms'];
    if (lastSeen == null) return m['online'] == true;
    final ms = lastSeen is num ? lastSeen.toInt() : int.tryParse('$lastSeen') ?? 0;
    if (ms <= 0) return m['online'] == true;
    return DateTime.now().millisecondsSinceEpoch - ms < 120000;
  } catch (_) {
    return false;
  }
}

/// Cloud dot: fresh agent presence, or an active WebRTC session (signaling path is live).
bool deviceClusterOnline(String metaJson, {bool remoteSessionActive = false}) =>
    deviceOnlineFromMeta(metaJson) || remoteSessionActive;

/// `playwright` when absent — see _/specs/browser-extension.md.
/// `true` / `false` when agent reports `meta.browser_ready`; `null` if unknown (legacy rows).
bool? deviceBrowserReadyFromMeta(String metaJson) {
  if (metaJson.trim().isEmpty) return null;
  try {
    final m = jsonDecode(metaJson);
    if (m is! Map) return null;
    final v = m['browser_ready'];
    if (v is bool) return v;
    if (v == true || v == 'true' || v == 1 || v == '1') return true;
    if (v == false || v == 'false' || v == 0 || v == '0') return false;
    return null;
  } catch (_) {
    return null;
  }
}

bool deviceNeedsChromeExtensionSetup({
  required String deviceType,
  required String metaJson,
}) {
  final t = deviceType.toLowerCase();
  if (t != 'windows' && t != 'linux') return false;
  final ready = deviceBrowserReadyFromMeta(metaJson);
  return ready != true;
}

String deviceChromeSetupPromptText(String deviceName) =>
    'Set up Google Chrome and the Alien AI Remote extension on $deviceName for faster Google Sheets and web automation (uses my Chrome logins, cheaper than web search). Run browser.ensure with repairs.';

String deviceBrowserEngineFromMeta(
  String metaJson, {
  String deviceName = '',
  String deviceType = '',
}) {
  if (metaJson.trim().isNotEmpty) {
    try {
      final m = jsonDecode(metaJson);
      if (m is Map) {
        final engine = m['browser_engine']?.toString().trim().toLowerCase();
        if (engine == 'extension' || engine == 'playwright') return engine!;
      }
    } catch (_) {}
  }
  if (deviceType.toLowerCase() == 'browser' &&
      deviceName.toLowerCase().contains('google chrome')) {
    return 'extension';
  }
  return 'playwright';
}

class DeviceStore extends ChangeNotifier {
  DeviceStore({ChatConn? conn, ReferralConn? invoke, ChatStore? shellStore})
      : _conn = conn ?? ChatConn(),
        _invoke = invoke ?? ReferralConn(),
        _shellStore = shellStore;

  final ChatConn _conn;
  final ReferralConn _invoke;
  final ChatStore? _shellStore;

  void _shellDevicesCountSync() {
    final n = _rows.where((r) => r.archivedTsMs == Int64.ZERO).length;
    unawaited(_shellStore?.navCountsDevicesPut(n));
  }

  ChatConn get conn => _conn;

  var _loading = false;
  var _search = '';
  var _cacheRestored = false;
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
    if (!_conn.connected) await _conn.connect(locale: locale);
    if (_conn.status.value == ChatConnStatus.connected) return;
    for (var i = 0; i < 300; i++) {
      if (_conn.status.value == ChatConnStatus.connected) return;
      if (!_conn.connected) await _conn.connect(locale: locale);
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
    if (_conn.status.value != ChatConnStatus.connected) throw 'not connected';
  }

  void _sortRows() => _rows.sort((a, b) {
        final pin = (b.isPinned ? 1 : 0) - (a.isPinned ? 1 : 0);
        if (pin != 0) return pin;
        final order = a.sortOrder.compareTo(b.sortOrder);
        if (order != 0) return order;
        return b.identity.updatedTsMs.compareTo(a.identity.updatedTsMs);
      });

  Future<void> _restoreCacheIfNeeded() async {
    if (_cacheRestored) return;
    _cacheRestored = true;
    final cached = await deviceListCacheRestore(Session.instance.uid);
    if (cached.isEmpty) return;
    _rows.addAll(cached);
    _sortRows();
    if (_selectedId == null && _rows.isNotEmpty) _selectedId = _rows.first.identity.iid.toString();
    _shellDevicesCountSync();
    notifyListeners();
  }

  void applyPresencePush(DevicePresencePush push) {
    DevicePresenceCache.instance.apply(push);
    final id = push.deviceIid.toString();
    final i = _rows.indexWhere((r) => r.identity.iid.toString() == id);
    if (i < 0) {
      unawaited(refresh());
      return;
    }
    final row = _rows[i];
    final identity = row.identity.clone()..metaJson = push.metaJson;
    if (push.updatedTsMs > Int64.ZERO) identity.updatedTsMs = push.updatedTsMs;
    _rows[i] = IdentityListRow(
      identity: identity,
      grantRole: row.grantRole,
      isPinned: row.isPinned,
      sortOrder: row.sortOrder,
      archivedTsMs: row.archivedTsMs,
    );
    notifyListeners();
    unawaited(deviceListCacheSave(Session.instance.uid, _rows));
  }

  Future<void> refresh({bool includeArchived = false}) async {
    await _restoreCacheIfNeeded();
    final showSpinner = _rows.isEmpty;
    if (showSpinner) {
      _loading = true;
      notifyListeners();
    }
    try {
      await ensureConnected();
      final res = await identityList(_conn, const ['remote', 'iot'], includeArchived: includeArchived)
          .timeout(const Duration(seconds: 30));
      _rows
        ..clear()
        ..addAll(res.rows);
      _sortRows();
      DevicePresenceCache.instance.metasPut({
        for (final row in _rows) row.identity.iid.toString(): row.identity.metaJson,
      });
      if (_selectedId != null && rowById(_selectedId) == null) _selectedId = null;
      if (_selectedId == null && _rows.isNotEmpty) _selectedId = _rows.first.identity.iid.toString();
      await deviceListCacheSave(Session.instance.uid, _rows);
      _shellDevicesCountSync();
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
      _shellDevicesCountSync();
      notifyListeners();
      await deviceListCacheSave(Session.instance.uid, _rows);
      return res.device;
    } catch (e) {
      lError('device pair: $e');
      rethrow;
    }
  }

  IdentityListRow _rowCopy(
    IdentityListRow row, {
    bool? isPinned,
    int? sortOrder,
  }) =>
      IdentityListRow(
        identity: row.identity,
        grantRole: row.grantRole,
        isPinned: isPinned ?? row.isPinned,
        sortOrder: sortOrder ?? row.sortOrder,
        archivedTsMs: row.archivedTsMs,
      );

  int _nextSortOrderInGroup(bool pinned) {
    var next = 10;
    for (final r in _rows) {
      if (r.isPinned != pinned) continue;
      if (r.sortOrder >= next) next = r.sortOrder + 10;
    }
    return next;
  }

  void _reassignSortOrdersInGroup(bool pinned) {
    var order = 10;
    for (var i = 0; i < _rows.length; i++) {
      if (_rows[i].isPinned != pinned) continue;
      _rows[i] = _rowCopy(_rows[i], sortOrder: order);
      order += 10;
    }
  }

  Future<void> pinPut(String id, bool pinned) async {
    final i = _rows.indexWhere((r) => r.identity.iid.toString() == id);
    if (i < 0) throw 'Device not found';
    final previous = _rows[i];
    if (previous.isPinned == pinned) return;

    final newSort = _nextSortOrderInGroup(pinned);
    _rows[i] = _rowCopy(previous, isPinned: pinned, sortOrder: newSort);
    _sortRows();
    notifyListeners();
    unawaited(deviceListCacheSave(Session.instance.uid, _rows));

    try {
      await ensureConnected();
      final res = await identityGrantPatch(
        _conn,
        ReqIdentityGrantPatch(
          resourceIid: previous.identity.iid,
          isPinned: pinned,
          sortOrder: newSort,
        ),
      );
      final j = _rows.indexWhere((r) => r.identity.iid.toString() == id);
      if (j >= 0) {
        _rows[j] = res.row;
      } else {
        _rows.add(res.row);
      }
      _sortRows();
      _shellDevicesCountSync();
      notifyListeners();
      await deviceListCacheSave(Session.instance.uid, _rows);
    } catch (e) {
      final j = _rows.indexWhere((r) => r.identity.iid.toString() == id);
      if (j >= 0) _rows[j] = previous;
      _sortRows();
      notifyListeners();
      unawaited(deviceListCacheSave(Session.instance.uid, _rows));
      lError('device pin put: $e');
      rethrow;
    }
  }

  Future<void> reorderPut(int oldIndex, int newIndex) async {
    if (_search.trim().isNotEmpty) return;
    if (oldIndex == newIndex ||
        oldIndex < 0 ||
        newIndex < 0 ||
        oldIndex >= _rows.length ||
        newIndex >= _rows.length) {
      return;
    }
    final pinned = _rows[oldIndex].isPinned;
    if (_rows[newIndex].isPinned != pinned) {
      notifyListeners();
      return;
    }

    final snapshot = List<IdentityListRow>.from(_rows);
    final item = _rows.removeAt(oldIndex);
    _rows.insert(newIndex, item);
    _reassignSortOrdersInGroup(pinned);
    notifyListeners();
    unawaited(deviceListCacheSave(Session.instance.uid, _rows));

    try {
      await ensureConnected();
      for (final row in _rows) {
        if (row.isPinned != pinned) continue;
        final sid = row.identity.iid.toString();
        final before = snapshot.firstWhere((r) => r.identity.iid.toString() == sid);
        if (before.sortOrder == row.sortOrder) continue;
        final res = await identityGrantPatch(
          _conn,
          ReqIdentityGrantPatch(
            resourceIid: row.identity.iid,
            sortOrder: row.sortOrder,
          ),
        );
        final j = _rows.indexWhere((r) => r.identity.iid.toString() == sid);
        if (j >= 0) _rows[j] = res.row;
      }
      notifyListeners();
      await deviceListCacheSave(Session.instance.uid, _rows);
    } catch (e) {
      _rows
        ..clear()
        ..addAll(snapshot);
      _sortRows();
      notifyListeners();
      unawaited(deviceListCacheSave(Session.instance.uid, _rows));
      lError('device reorder: $e');
      rethrow;
    }
  }

  Future<void> archivePut(String id, bool archived) => _grantPatch(id, ReqIdentityGrantPatch(resourceIid: Int64.parseInt(id), archived: archived));

  Future<void> deletePut(String id) async {
    final row = rowById(id);
    if (row == null) throw 'Device not found';
    final iid = row.identity.iid.toInt();
    try {
      await ensureConnected();
      await identityDelete(_conn, iid);
      if (row.identity.kind.toLowerCase() == 'remote') {
        await RemoteSession.dispose(iid);
      }
      _rows.removeWhere((r) => r.identity.iid.toString() == id);
      if (_selectedId == id) {
        _selectedId = _rows.isEmpty ? null : _rows.first.identity.iid.toString();
      }
      _shellDevicesCountSync();
      notifyListeners();
      await deviceListCacheSave(Session.instance.uid, _rows);
    } catch (e) {
      lError('device delete: $e');
      rethrow;
    }
  }

  Future<void> namePut(String id, String name) async {
    final i = _rows.indexWhere((r) => r.identity.iid.toString() == id);
    if (i < 0) throw 'Device not found';
    final row = _rows[i];
    final trimmed = name.trim();
    if (trimmed.isEmpty) throw 'Name required';
    if (row.identity.name == trimmed) return;

    final previous = _rows[i];
    final identity = row.identity.clone()..name = trimmed;
    _rows[i] = IdentityListRow(
      identity: identity,
      grantRole: row.grantRole,
      isPinned: row.isPinned,
      sortOrder: row.sortOrder,
      archivedTsMs: row.archivedTsMs,
    );
    notifyListeners();
    unawaited(deviceListCacheSave(Session.instance.uid, _rows));

    try {
      await ensureConnected();
      final res = await identityPut(
        _conn,
        ReqIdentityPut(iid: identity.iid, kind: identity.kind, type: identity.type, name: trimmed, metaJson: identity.metaJson),
      );
      if (!res.hasRow()) return;
      final j = _rows.indexWhere((r) => r.identity.iid.toString() == id);
      if (j >= 0) {
        _rows[j] = res.row;
      } else {
        _rows.add(res.row);
      }
      _sortRows();
      notifyListeners();
      await deviceListCacheSave(Session.instance.uid, _rows);
    } catch (e) {
      final j = _rows.indexWhere((r) => r.identity.iid.toString() == id);
      if (j >= 0) _rows[j] = previous;
      notifyListeners();
      unawaited(deviceListCacheSave(Session.instance.uid, _rows));
      lError('device name put: $e');
      rethrow;
    }
  }

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
      _sortRows();
      _shellDevicesCountSync();
      notifyListeners();
      await deviceListCacheSave(Session.instance.uid, _rows);
    } catch (e) {
      lError('device grant patch: $e');
      rethrow;
    }
  }
}

String _deviceListCacheKey(int ownerUid) => 'c35.device.list.v1.$ownerUid';

Future<void> deviceListCacheClear(int ownerUid) async {
  if (ownerUid <= 0) return;
  final p = await SharedPreferences.getInstance();
  await p.remove(_deviceListCacheKey(ownerUid));
}

Future<List<IdentityListRow>> deviceListCacheRestore(int ownerUid) async {
  if (ownerUid <= 0) return [];
  final p = await SharedPreferences.getInstance();
  final raw = p.getString(_deviceListCacheKey(ownerUid));
  if (raw == null || raw.isEmpty) return [];
  try {
    return List<IdentityListRow>.from(ResIdentityList.fromBuffer(base64Decode(raw)).rows);
  } catch (_) {
    return [];
  }
}

Future<void> deviceListCacheSave(int ownerUid, List<IdentityListRow> rows) async {
  if (ownerUid <= 0) return;
  final p = await SharedPreferences.getInstance();
  await p.setString(_deviceListCacheKey(ownerUid), base64Encode(ResIdentityList(rows: rows).writeToBuffer()));
}

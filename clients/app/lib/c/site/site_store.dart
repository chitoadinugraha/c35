import 'dart:convert';

import 'package:alienai_c35/c/chat/chat_conn.dart';
import 'package:alienai_c35/c/chat/space_hints.dart';
import 'package:alienai_c35/c/hint/hint_store.dart';
import 'package:alienai_c35/c/log.dart';
import 'package:alienai_c35/c/pb/c35/hint.pb.dart' as hint_pb;
import 'package:alienai_c35/c/pb/c35/identity.pb.dart';
import 'package:alienai_c35/c/pb/c35/site.pb.dart';
import 'package:alienai_c35/c/session.dart';
import 'package:alienai_c35/c/device/device_api.dart';
import 'package:alienai_c35/c/site/site_api.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SiteStore extends ChangeNotifier {
  SiteStore({ChatConn? conn}) : _conn = conn ?? ChatConn();

  final ChatConn _conn;
  late final SiteApi _api = SiteApi(_conn);

  ChatConn get conn => _conn;
  SiteApi get api => _api;

  var _loading = false;
  var _search = '';
  final _rows = <SiteRow>[];
  String? _selectedId;
  var _cacheRestored = false;
  String? _refreshError;

  bool get loading => _loading;
  String? get refreshError => _refreshError;
  String get search => _search;
  String? get selectedId => _selectedId;
  List<SiteRow> get rows => _rows;

  List<SiteRow> get filtered {
    final q = _search.trim().toLowerCase();
    if (q.isEmpty) return List.unmodifiable(_rows);
    return _rows
        .where((r) =>
            r.name.toLowerCase().contains(q) ||
            r.alienId.toLowerCase().contains(q) ||
            '${r.siteIid}'.contains(q))
        .toList(growable: false);
  }

  SiteRow? rowById(String? id) {
    if (id == null) return null;
    for (final r in _rows) {
      if (r.siteIid.toString() == id) return r;
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

  Future<void> _restoreCacheIfNeeded() async {
    if (_cacheRestored) return;
    _cacheRestored = true;
    final uid = Session.instance.uid;
    final cached = await _siteListCacheRestore(uid);
    if (cached.isEmpty) {
      final hints = siteRowsFromHints(HintStore.instance.items);
      if (hints.isNotEmpty) _rows.addAll(hints);
    } else {
      _rows.addAll(cached);
    }
    if (_rows.isNotEmpty) {
      if (_selectedId == null) _selectedId = _rows.first.siteIid.toString();
      notifyListeners();
    }
  }

  Future<void> refresh({bool archived = false}) async {
    await _restoreCacheIfNeeded();
    final showSpinner = _rows.isEmpty;
    if (showSpinner) {
      _loading = true;
      notifyListeners();
    }
    try {
      await ensureConnected();
      final sites = await _api.list(archived: archived);
      _rows
        ..clear()
        ..addAll(sites);
      if (_selectedId != null && rowById(_selectedId) == null) _selectedId = null;
      if (_selectedId == null && _rows.isNotEmpty) _selectedId = _rows.first.siteIid.toString();
      await _siteListCacheSave(Session.instance.uid, _rows);
      _refreshError = null;
    } catch (e) {
      lError('site refresh: $e');
      _refreshError = '$e';
      if (_rows.isEmpty) {
        final hints = siteRowsFromHints(HintStore.instance.items);
        if (hints.isNotEmpty) _rows.addAll(hints);
      }
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> pinPut(String id, bool pinned) => _grantPatch(id, ReqIdentityGrantPatch(resourceIid: Int64.parseInt(id), isPinned: pinned));

  Future<void> renamePut(String id, String name) async {
    final row = rowById(id);
    if (row == null) throw 'Site not found';
    final trimmed = name.trim();
    if (trimmed.isEmpty) throw 'Name required';
    try {
      await ensureConnected();
      final res = await _conn.identityPut(ReqIdentityPut(
        iid: row.siteIid,
        kind: 'site',
        name: trimmed,
        pic: row.pic,
        alienId: row.alienId,
      ));
      if (!res.hasRow()) return;
      final i = _rows.indexWhere((r) => r.siteIid.toString() == id);
      if (i >= 0) {
        _rows[i].name = res.row.identity.name;
        notifyListeners();
        await _siteListCacheSave(Session.instance.uid, _rows);
      }
    } catch (e) {
      lError('site rename put: $e');
      rethrow;
    }
  }

  Future<void> _grantPatch(String id, ReqIdentityGrantPatch req) async {
    try {
      await ensureConnected();
      final res = await _conn.identityGrantPatch(req);
      if (!res.hasRow()) return;
      final i = _rows.indexWhere((r) => r.siteIid.toString() == id);
      if (i >= 0) {
        _rows[i].isPinned = res.row.isPinned;
        _rows[i].sortOrder = res.row.sortOrder;
      } else {
        return;
      }
      _rows.sort((a, b) {
        final pin = (b.isPinned ? 1 : 0) - (a.isPinned ? 1 : 0);
        if (pin != 0) return pin;
        final order = a.sortOrder.compareTo(b.sortOrder);
        if (order != 0) return order;
        return b.updatedTsMs.compareTo(a.updatedTsMs);
      });
      notifyListeners();
      await _siteListCacheSave(Session.instance.uid, _rows);
    } catch (e) {
      lError('site grant patch: $e');
      rethrow;
    }
  }

  Future<int> siteCreate({
    required String name,
    required String alienId,
    required String tagline,
    required SiteCreateFeatures features,
    String pic = '',
    String locale = 'en',
  }) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) throw 'Name required';
    final slug = siteAlienIdSlug(alienId.trim().isEmpty ? trimmed : alienId);
    if (slug.isEmpty) throw 'Site URL required';
    await ensureConnected(locale: locale);
    Int64? siteIid;
    try {
      final res = await _conn.identityPut(ReqIdentityPut(kind: 'site', type: 'web', name: trimmed, alienId: slug, pic: pic));
      if (!res.hasRow()) throw 'Site create failed';
      siteIid = res.row.identity.iid;
      await _api.configPut(siteIid.toInt(), capabilitiesJson: siteCreateCapabilitiesJson(features));
      final draft = siteCreateDraft(
        siteIid: siteIid,
        name: trimmed,
        tagline: tagline.trim(),
        pic: pic,
      );
      await _conn.siteDraftPut(draft, skipPublish: true);
      final row = siteRowFromIdentity(res.row);
      _rows.add(row);
      _rows.sort((a, b) {
        final pin = (b.isPinned ? 1 : 0) - (a.isPinned ? 1 : 0);
        if (pin != 0) return pin;
        final order = a.sortOrder.compareTo(b.sortOrder);
        if (order != 0) return order;
        return b.updatedTsMs.compareTo(a.updatedTsMs);
      });
      _selectedId = siteIid.toString();
      _refreshError = null;
      await _siteListCacheSave(Session.instance.uid, _rows);
      notifyListeners();
      return siteIid.toInt();
    } catch (e) {
      lError('site create: $e');
      if (siteIid != null) {
        try {
          await identityDelete(_conn, siteIid.toInt());
        } catch (_) {}
      }
      rethrow;
    }
  }
}

String _siteListCacheKey(int ownerUid) => 'c35.site.list.v1.$ownerUid';

Future<void> siteListCacheClear(int ownerUid) async {
  if (ownerUid <= 0) return;
  final p = await SharedPreferences.getInstance();
  await p.remove(_siteListCacheKey(ownerUid));
}

Future<List<SiteRow>> _siteListCacheRestore(int ownerUid) async {
  if (ownerUid <= 0) return [];
  final p = await SharedPreferences.getInstance();
  final raw = p.getString(_siteListCacheKey(ownerUid));
  if (raw == null || raw.isEmpty) return [];
  try {
    return List<SiteRow>.from(ResSiteList.fromBuffer(base64Decode(raw)).sites);
  } catch (_) {
    return [];
  }
}

Future<void> _siteListCacheSave(int ownerUid, List<SiteRow> rows) async {
  if (ownerUid <= 0) return;
  final p = await SharedPreferences.getInstance();
  await p.setString(_siteListCacheKey(ownerUid), base64Encode(ResSiteList(sites: rows).writeToBuffer()));
}

String? _siteIidFromHintId(String id) {
  const prefix = 'hint.site:';
  if (!id.startsWith(prefix)) return null;
  final rest = id.substring(prefix.length).trim();
  return rest.isEmpty ? null : rest;
}

String? _alienIdFromVisitUrl(String url) {
  final u = Uri.tryParse(url.trim());
  if (u == null || u.pathSegments.isEmpty) return null;
  final seg = u.pathSegments.firstWhere((s) => s.isNotEmpty, orElse: () => '');
  return seg.isEmpty ? null : seg;
}

SiteRow? _siteRowFromHintItem(hint_pb.HintItem item) {
  final siteIidStr = _siteIidFromHintId(item.id);
  if (siteIidStr == null) return null;
  final siteIid = Int64.parseInt(siteIidStr);
  var alienId = '';
  var pic = item.icon;
  for (final child in item.items) {
    if (!child.hasAction() || child.action.kind != 'open_url') continue;
    final payload = hintPayloadParse(child.action.payloadJson);
    alienId = _alienIdFromVisitUrl('${payload['url'] ?? ''}') ?? alienId;
  }
  if (pic.startsWith('mdi:')) pic = '';
  return SiteRow(
    siteIid: siteIid,
    alienId: alienId,
    name: item.label,
    pic: pic,
    publishedVersionId: '',
    updatedTsMs: Int64.ZERO,
    isArchived: false,
    isPinned: false,
    sortOrder: item.sort,
  );
}

List<SiteRow> siteRowsFromHints(List<hint_pb.HintItem> items) {
  final byIid = <String, SiteRow>{};
  for (final item in items) {
    final row = _siteRowFromHintItem(item);
    if (row == null) continue;
    final key = row.siteIid.toString();
    final prev = byIid[key];
    byIid[key] = prev == null
        ? row
        : SiteRow(
            siteIid: row.siteIid,
            alienId: row.alienId.isNotEmpty ? row.alienId : prev.alienId,
            name: row.name.isNotEmpty ? row.name : prev.name,
            pic: row.pic.isNotEmpty ? row.pic : prev.pic,
            publishedVersionId: prev.publishedVersionId,
            updatedTsMs: prev.updatedTsMs,
            isArchived: prev.isArchived,
            isPinned: prev.isPinned,
            sortOrder: prev.sortOrder,
          );
  }
  final out = byIid.values.toList(growable: false);
  out.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  return out;
}

import 'package:alienai_c35/c/chat/chat_conn.dart';
import 'package:alienai_c35/c/log.dart';
import 'package:alienai_c35/c/pb/c35/site.pb.dart';
import 'package:alienai_c35/c/site/site_api.dart';
import 'package:flutter/foundation.dart';

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

  bool get loading => _loading;
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
    if (_conn.connected) return;
    await _conn.connect(locale: locale);
  }

  Future<void> refresh({bool archived = false}) async {
    _loading = true;
    notifyListeners();
    try {
      await ensureConnected();
      final sites = await _api.list(archived: archived);
      _rows
        ..clear()
        ..addAll(sites);
      if (_selectedId != null && rowById(_selectedId) == null) _selectedId = null;
      if (_selectedId == null && _rows.isNotEmpty) _selectedId = _rows.first.siteIid.toString();
    } catch (e) {
      lError('site refresh: $e');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}

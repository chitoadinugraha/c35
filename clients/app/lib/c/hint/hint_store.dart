import 'dart:convert';

import 'package:alienai_c35/c/pb/c35/hint.pb.dart';
import 'package:alienai_c35/c/session.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _revKeyLegacy = 'c35.hint.rev';
const _pbKeyLegacy = 'c35.hint.json';

String _hintRevKey(int uid) => 'c35.hint.rev.$uid';
String _hintPbKey(int uid) => 'c35.hint.json.$uid';

class HintStore extends ChangeNotifier {
  HintStore._();
  static final HintStore instance = HintStore._();

  var _rev = 0;
  var _loadedUid = 0;
  final _items = <HintItem>[];

  int get rev => _rev;
  List<HintItem> get items => List.unmodifiable(_items);

  int _uid() {
    final uid = Session.instance.uid;
    return uid > 0 ? uid : 0;
  }

  Future<void> _migrateLegacyIfNeeded(SharedPreferences p, int uid) async {
    if (uid <= 0) return;
    if (p.containsKey(_hintRevKey(uid)) || p.containsKey(_hintPbKey(uid))) return;
    final legacyRev = p.getInt(_revKeyLegacy);
    final legacyRaw = p.getString(_pbKeyLegacy);
    if (legacyRev == null && (legacyRaw == null || legacyRaw.isEmpty)) return;
    if (legacyRev != null) await p.setInt(_hintRevKey(uid), legacyRev);
    if (legacyRaw != null && legacyRaw.isNotEmpty) await p.setString(_hintPbKey(uid), legacyRaw);
    await p.remove(_revKeyLegacy);
    await p.remove(_pbKeyLegacy);
  }

  Future<void> restore() async {
    final uid = _uid();
    final p = await SharedPreferences.getInstance();
    await _migrateLegacyIfNeeded(p, uid);
    _rev = 0;
    _items.clear();
    if (uid > 0) {
      _rev = p.getInt(_hintRevKey(uid)) ?? 0;
      final raw = p.getString(_hintPbKey(uid));
      if (raw != null && raw.isNotEmpty) {
        try {
          final catalog = HintCatalog.fromBuffer(base64Decode(raw));
          _items.addAll(catalog.items);
          if (catalog.hasUpdatedTsMs()) _rev = catalog.updatedTsMs.toInt();
        } catch (_) {
          _items.clear();
        }
      }
    }
    _loadedUid = uid;
    notifyListeners();
  }

  Future<void> merge(HintCatalog? hints, {required int sinceMs}) async {
    if (hints == null) return;
    final updated = hints.updatedTsMs.toInt();
    if (updated <= _rev) return;
    final uid = _uid();
    if (uid <= 0) return;
    if (_loadedUid != uid) await restore();
    _rev = updated;
    if (hints.items.isNotEmpty) {
      _items
        ..clear()
        ..addAll(hints.items);
    }
    final p = await SharedPreferences.getInstance();
    await p.setInt(_hintRevKey(uid), _rev);
    final catalog = HintCatalog(updatedTsMs: Int64(_rev), items: _items);
    await p.setString(_hintPbKey(uid), base64Encode(catalog.writeToBuffer()));
    notifyListeners();
  }

  Future<void> clearForUid(int uid) async {
    if (uid <= 0) return;
    final p = await SharedPreferences.getInstance();
    await p.remove(_hintRevKey(uid));
    await p.remove(_hintPbKey(uid));
    if (_loadedUid == uid) {
      _rev = 0;
      _items.clear();
      _loadedUid = 0;
      notifyListeners();
    }
  }
}

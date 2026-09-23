import 'dart:convert';

import 'package:alienai_c35/c/pb/c35/hint.pb.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _revKey = 'c35.hint.rev';
const _pbKey = 'c35.hint.json';

class HintStore extends ChangeNotifier {
  HintStore._();
  static final HintStore instance = HintStore._();

  var _rev = 0;
  final _items = <HintItem>[];

  int get rev => _rev;
  List<HintItem> get items => List.unmodifiable(_items);

  Future<void> restore() async {
    final p = await SharedPreferences.getInstance();
    _rev = p.getInt(_revKey) ?? 0;
    final raw = p.getString(_pbKey);
    _items.clear();
    if (raw != null && raw.isNotEmpty) {
      try {
        final bytes = base64Decode(raw);
        final catalog = HintCatalog.fromBuffer(bytes);
        _items.addAll(catalog.items);
        if (catalog.hasUpdatedTsMs()) _rev = catalog.updatedTsMs.toInt();
      } catch (_) {
        _items.clear();
      }
    }
    notifyListeners();
  }

  Future<void> merge(HintCatalog? hints, {required int sinceMs}) async {
    if (hints == null) return;
    final updated = hints.updatedTsMs.toInt();
    if (updated <= _rev) return;
    _rev = updated;
    if (hints.items.isNotEmpty) {
      _items
        ..clear()
        ..addAll(hints.items);
    }
    final p = await SharedPreferences.getInstance();
    await p.setInt(_revKey, _rev);
    final catalog = HintCatalog(updatedTsMs: Int64(_rev), items: _items);
    await p.setString(_pbKey, base64Encode(catalog.writeToBuffer()));
    notifyListeners();
  }
}

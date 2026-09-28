import 'dart:convert';

import 'package:alienai_c35/c/catalog/catalog_api.dart';
import 'package:alienai_c35/c/chat/chat_conn.dart';
import 'package:alienai_c35/c/pb/c35/catalog.pb.dart';
import 'package:alienai_c35/c/session.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

String _mentionRevKey(int uid) => 'c35.mention.rev.$uid';
String _mentionPbKey(int uid) => 'c35.mention.pb.$uid';

Future<void> mentionCatalogCacheClear(int uid) async {
  if (uid <= 0) return;
  final p = await SharedPreferences.getInstance();
  await p.remove(_mentionRevKey(uid));
  await p.remove(_mentionPbKey(uid));
}

class MentionCatalogStore extends ChangeNotifier {
  final _items = <String, MentionItem>{};
  Int64 _rev = Int64.ZERO;
  var _loadedUid = 0;

  int get rev => _rev.toInt();

  List<CatalogMention> get mentions {
    final rows = _items.values.where((m) => m.enabled).map(CatalogMention.fromMentionItem).toList();
    rows.sort((a, b) => a.sort.compareTo(b.sort));
    return rows;
  }

  int _uid() {
    final uid = Session.instance.uid;
    return uid > 0 ? uid : 0;
  }

  Future<void> restore() async {
    final uid = _uid();
    _rev = Int64.ZERO;
    _items.clear();
    if (uid > 0) {
      final p = await SharedPreferences.getInstance();
      _rev = Int64(p.getInt(_mentionRevKey(uid)) ?? 0);
      final raw = p.getString(_mentionPbKey(uid));
      if (raw != null && raw.isNotEmpty) {
        try {
          final catalog = MentionCatalog.fromBuffer(base64Decode(raw));
          putItems(catalog.items);
          if (catalog.hasRev()) _rev = catalog.rev;
        } catch (_) {
          _items.clear();
        }
      }
    }
    _loadedUid = uid;
    notifyListeners();
  }

  Future<void> mergeCatalog(MentionCatalog? catalog, {required int sinceMs}) async {
    if (catalog == null) return;
    final updated = catalog.rev.toInt();
    if (updated <= sinceMs && catalog.items.isEmpty) return;
    if (updated <= _rev.toInt() && catalog.items.isEmpty) return;
    final uid = _uid();
    if (uid <= 0) return;
    if (_loadedUid != uid) await restore();
    if (catalog.hasRev()) _rev = catalog.rev;
    if (catalog.items.isNotEmpty) {
      _items.clear();
      putItems(catalog.items);
    }
    final p = await SharedPreferences.getInstance();
    await p.setInt(_mentionRevKey(uid), _rev.toInt());
    final snap = MentionCatalog(rev: _rev, items: _items.values.toList());
    await p.setString(_mentionPbKey(uid), base64Encode(snap.writeToBuffer()));
    notifyListeners();
  }

  void putItems(List<MentionItem> items) {
    for (final item in items) {
      if (item.id.isEmpty || !item.enabled) continue;
      _items[item.id] = item;
    }
  }

  List<CatalogMention> mentionListFilter(List<CatalogMention> rows, String q, {int limit = 20}) {
    final lq = q.toLowerCase();
    if (lq.isEmpty) return rows.take(limit).toList(growable: false);
    return rows
        .where((m) {
          if (m.id.toLowerCase().contains(lq)) return true;
          if (m.displayLabel.toLowerCase().contains(lq)) return true;
          final cap = m.displayCaption;
          return cap.isNotEmpty && cap.toLowerCase().contains(lq);
        })
        .take(limit)
        .toList(growable: false);
  }

  Future<void> refresh(ChatConn conn) async {
    final res = await conn.mentionList(sinceMs: Int64(rev));
    await mergeCatalog(MentionCatalog(rev: res.rev, items: res.mentions), sinceMs: rev);
  }

  Future<void> clearForUid(int uid) async {
    if (uid <= 0) return;
    final p = await SharedPreferences.getInstance();
    await p.remove(_mentionRevKey(uid));
    await p.remove(_mentionPbKey(uid));
    if (_loadedUid == uid) {
      _rev = Int64.ZERO;
      _items.clear();
      _loadedUid = 0;
      notifyListeners();
    }
  }
}

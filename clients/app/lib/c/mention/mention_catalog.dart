import 'package:alienai_c35/c/catalog/catalog_api.dart';
import 'package:alienai_c35/c/chat/chat_conn.dart';
import 'package:alienai_c35/c/pb/c35/catalog.pb.dart';
import 'package:fixnum/fixnum.dart';

class MentionCatalogStore {
  final _items = <String, MentionItem>{};
  Int64 _rev = Int64.ZERO;

  List<CatalogMention> get mentions {
    final rows = _items.values.where((m) => m.enabled).map(CatalogMention.fromMentionItem).toList();
    rows.sort((a, b) => a.sort.compareTo(b.sort));
    return rows;
  }

  void mergeCatalog(MentionCatalog? catalog) {
    if (catalog == null) return;
    if (catalog.hasRev() && catalog.rev > _rev) {
      _rev = catalog.rev;
      _items.clear();
    }
    putItems(catalog.items);
  }

  void mergeList(ResMentionList res) {
    if (res.hasRev() && res.rev > _rev) {
      _rev = res.rev;
      _items.clear();
    }
    putItems(res.mentions);
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
    return rows.where((m) {
      if (m.id.toLowerCase().contains(lq)) return true;
      if (m.displayLabel.toLowerCase().contains(lq)) return true;
      final cap = m.displayCaption;
      return cap.isNotEmpty && cap.toLowerCase().contains(lq);
    }).take(limit).toList(growable: false);
  }

  Future<void> refresh(ChatConn conn) async => mergeList(await conn.mentionList());
}

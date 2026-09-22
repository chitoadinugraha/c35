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

  Future<void> refresh(ChatConn conn) async => mergeList(await conn.mentionList());

  Future<List<CatalogMention>> search(ChatConn conn, {String q = '', List<String> kinds = const [], int limit = 20}) async {
    final res = await conn.mentionSearch(q: q, kinds: kinds, limit: limit);
    putItems(res.mentions);
    return res.mentions.map(CatalogMention.fromMentionItem).toList(growable: false);
  }
}

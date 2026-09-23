import 'package:alienai_c35/c/pb/c35/collection.pb.dart';
import 'package:alienai_c35/c/pb/c35/site.pb.dart';
import 'package:alienai_c35/c/ui/money_format.dart';
import 'package:fixnum/fixnum.dart';

String siteRowKey(TableDef def, Map<String, String> cells) {
  final keys = def.primaryKey.split(',').map((k) => k.trim()).where((k) => k.isNotEmpty);
  if (keys.isEmpty) return cells.values.join('|');
  return keys.map((k) => cells[k] ?? '').join('|');
}

List<Map<String, String>> uiTableFilterRows(List<Map<String, String>> rows, String query, Iterable<ColDef> cols) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return rows;
  return rows
      .where((row) => cols.any((c) => (row[c.key] ?? '').toLowerCase().contains(q)))
      .toList(growable: false);
}

List<Map<String, String>> uiTableSortRows(
  List<Map<String, String>> rows,
  String? colKey, {
  bool ascending = true,
}) {
  if (colKey == null || colKey.isEmpty) return rows;
  final sorted = [...rows];
  sorted.sort((a, b) {
    final av = a[colKey] ?? '';
    final bv = b[colKey] ?? '';
    final cmp = av.toLowerCase().compareTo(bv.toLowerCase());
    return ascending ? cmp : -cmp;
  });
  return sorted;
}

String _fmtTs(Int64 ms) {
  if (ms <= Int64.ZERO) return '';
  final dt = DateTime.fromMillisecondsSinceEpoch(ms.toInt(), isUtc: true).toLocal();
  return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
}

Map<String, String> siteProductCells(SiteProduct p) => {
      'site_iid': '${p.siteIid}',
      'product_id': '${p.productId}',
      'name': p.name,
      'desc': p.desc,
      'sku': p.sku,
      'unit': p.unit,
      'price': p.price <= Int64.ZERO ? '' : moneyFmtIdr(p.price.toInt()),
      'pic': p.pic,
      'category': p.category,
      'stock_qty': '${p.stockQty}',
      'can_sell': p.canSell ? 'yes' : 'no',
      'can_reserve': p.canReserve ? 'yes' : 'no',
      'track_stock': p.trackStock ? 'yes' : 'no',
      'is_archived': p.isArchived ? 'yes' : 'no',
      'product_json': p.productJson,
      'updated_ts_ms': _fmtTs(p.updatedTsMs),
    };

Map<String, String> siteContactCells(SiteContact c) => {
      'site_iid': '${c.siteIid}',
      'contact_id': '${c.contactId}',
      'name': c.name,
      'phone': c.phone,
      'email': c.email,
      'address': c.address,
      'note': c.note,
      'meta_json': c.metaJson,
      'is_archived': c.isArchived ? 'yes' : 'no',
      'updated_ts_ms': _fmtTs(c.updatedTsMs),
    };

Map<String, String> siteObjectCells(SiteObject o) => {
      'site_iid': '${o.siteIid}',
      'id': '${o.id}',
      'client_id': o.clientId,
      'name': o.name,
      'code': o.code,
      'kind': o.kind,
      'can_order': o.canOrder ? 'yes' : 'no',
      'can_be_reserved': o.canBeReserved ? 'yes' : 'no',
      'is_active': o.isActive ? 'yes' : 'no',
      'desc': o.desc,
      'pic': o.pic,
      'meta_json': o.metaJson,
      'updated_ts_ms': _fmtTs(o.updatedTsMs),
    };

SiteProduct siteProductApplyCell(SiteProduct base, ColDef col, String value) {
  final p = base.clone();
  switch (col.key) {
    case 'name':
      p.name = value;
    case 'desc':
      p.desc = value;
    case 'sku':
      p.sku = value;
    case 'unit':
      p.unit = value;
    case 'pic':
      p.pic = value;
    case 'category':
      p.category = value;
    case 'product_json':
      p.productJson = value;
    case 'price':
      final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
      p.price = Int64(int.tryParse(digits) ?? 0);
    case 'stock_qty':
      p.stockQty = int.tryParse(value) ?? 0;
    case 'can_sell':
      p.canSell = value.toLowerCase() == 'yes' || value == '1' || value.toLowerCase() == 'true';
    case 'can_reserve':
      p.canReserve = value.toLowerCase() == 'yes' || value == '1' || value.toLowerCase() == 'true';
    case 'track_stock':
      p.trackStock = value.toLowerCase() == 'yes' || value == '1' || value.toLowerCase() == 'true';
    case 'is_archived':
      p.isArchived = value.toLowerCase() == 'yes' || value == '1' || value.toLowerCase() == 'true';
  }
  return p;
}

SiteContact siteContactApplyCell(SiteContact base, ColDef col, String value) {
  final c = base.clone();
  switch (col.key) {
    case 'name':
      c.name = value;
    case 'phone':
      c.phone = value;
    case 'email':
      c.email = value;
    case 'address':
      c.address = value;
    case 'note':
      c.note = value;
    case 'meta_json':
      c.metaJson = value;
    case 'is_archived':
      c.isArchived = value.toLowerCase() == 'yes' || value == '1' || value.toLowerCase() == 'true';
  }
  return c;
}

SiteObject siteObjectApplyCell(SiteObject base, ColDef col, String value) {
  final o = base.clone();
  switch (col.key) {
    case 'name':
      o.name = value;
    case 'client_id':
      o.clientId = value;
    case 'code':
      o.code = value;
    case 'kind':
      o.kind = value;
    case 'desc':
      o.desc = value;
    case 'pic':
      o.pic = value;
    case 'meta_json':
      o.metaJson = value;
    case 'can_order':
      o.canOrder = value.toLowerCase() == 'yes' || value == '1' || value.toLowerCase() == 'true';
    case 'can_be_reserved':
      o.canBeReserved = value.toLowerCase() == 'yes' || value == '1' || value.toLowerCase() == 'true';
    case 'is_active':
      o.isActive = value.toLowerCase() == 'yes' || value == '1' || value.toLowerCase() == 'true';
  }
  return o;
}

Map<String, String> siteProductEmbedCells(SiteProductEmbed e) => {
      'site_iid': '${e.siteIid}',
      'embed_id': '${e.embedId}',
      'product_id': '${e.productId}',
      'label': e.label,
      'updated_ts_ms': _fmtTs(e.updatedTsMs),
    };

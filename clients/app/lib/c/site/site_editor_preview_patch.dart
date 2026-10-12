import 'dart:convert';

import 'package:alienai_c35/c/config.dart';
import 'package:alienai_c35/c/pb/c35/site.pb.dart';
import 'package:alienai_c35/c/site/design/site_design_store.dart';
import 'package:alienai_c35/c/site/site_draft_extras.dart';
import 'package:alienai_c35/c/site/site_draft_meta.dart';
import 'package:alienai_c35/c/site/site_info_sync.dart';
import 'package:alienai_c35/c/site/site_post_media.dart';
import 'package:alienai_c35/c/site/site_schedule.dart';

void siteEditorPreviewPatchSiteRow(Map<String, dynamic> boot, SiteRow row) {
  boot['name'] = row.name;
  if (row.alienId.isNotEmpty) boot['alien_id'] = row.alienId;
  if (row.pic.isNotEmpty) boot['avatar_url'] = row.pic;
}

Map<String, dynamic> siteEditorPreviewProductRow(SiteProduct p) {
  final pic = p.pic.trim();
  var picUrl = pic;
  if (pic.isNotEmpty && !pic.startsWith('http')) {
    final base = C35Config.authApiBase.replaceAll(RegExp(r'/+$'), '');
    picUrl = '$base/v1/file/${Uri.encodeComponent(pic)}';
  }
  return {
    'product_id': p.productId.toInt(),
    'name': p.name,
    'desc': p.desc,
    'price': p.price.toInt(),
    'pic': picUrl,
    'icon': p.icon,
    'category': p.category,
    'can_reserve': p.canReserve,
  };
}

void siteEditorPreviewUpsertProduct(Map<String, dynamic> boot, SiteProduct p) {
  if (p.isArchived) {
    siteEditorPreviewRemoveProduct(boot, p.productId.toInt());
    return;
  }
  final row = siteEditorPreviewProductRow(p);
  final commerce = boot['commerce_boot'];
  if (commerce is Map<String, dynamic>) {
    final products = commerce['products'];
    if (products is List) {
      final id = p.productId.toInt();
      var found = false;
      for (var i = 0; i < products.length; i++) {
        final item = products[i];
        if (item is Map && (item['product_id'] as num?)?.toInt() == id) {
          products[i] = row;
          found = true;
          break;
        }
      }
      if (!found) products.add(row);
    }
  }
  final preload = boot['product_preload'];
  if (preload is Map) {
    for (final entry in preload.entries) {
      final list = entry.value;
      if (list is! List) continue;
      final id = p.productId.toInt();
      var found = false;
      for (var i = 0; i < list.length; i++) {
        final item = list[i];
        if (item is Map && (item['product_id'] as num?)?.toInt() == id) {
          list[i] = row;
          found = true;
          break;
        }
      }
      if (!found) list.add(row);
    }
  }
}

bool siteEditorPreviewCommerceEnabled(Map<String, dynamic> boot) {
  final caps = boot['capabilities'];
  if (caps is Map) {
    final commerce = caps['commerce'];
    if (commerce == true) return true;
  }
  final commerce = boot['commerce_boot'];
  if (commerce is Map && commerce['enabled'] == true) return true;
  return false;
}

const _defaultProductGridBlockId = 'product_grid1';

List<Map<String, dynamic>> _siteEditorPreviewProductRowsFromBoot(Map<String, dynamic> boot) {
  final commerce = boot['commerce_boot'];
  if (commerce is! Map) return const [];
  final products = commerce['products'];
  if (products is! List) return const [];
  return products.whereType<Map<String, dynamic>>().toList(growable: false);
}

List<Map<String, dynamic>> siteEditorPreviewProductRowsForGridProps(
  List<Map<String, dynamic>> rows,
  Map<String, dynamic> props,
) {
  final category = props['category']?.toString().trim() ?? '';
  if (category.isEmpty) return rows;
  return rows
      .where((p) => (p['category']?.toString().trim() ?? '') == category)
      .toList(growable: false);
}

void siteEditorPreviewEnsureProductGridBlock(Map<String, dynamic> boot) {
  if (!siteEditorPreviewCommerceEnabled(boot)) return;
  final pages = boot['pages'];
  if (pages is! List || pages.isEmpty) return;
  final first = pages.first;
  if (first is! Map) return;
  final blocksRaw = first['blocks'];
  final blocks = blocksRaw is List ? blocksRaw : <dynamic>[];
  if (blocksRaw is! List) {
    first['blocks'] = blocks;
  }
  for (final b in blocks) {
    if (b is Map && b['type']?.toString() == 'product_grid') return;
  }
  blocks.add({
    'id': _defaultProductGridBlockId,
    'type': 'product_grid',
    'props': const {'filter': 'all'},
  });
}

void siteEditorPreviewApplyProductPreloadForGrids(Map<String, dynamic> boot, List<Map<String, dynamic>> allRows) {
  final preloadRaw = boot['product_preload'];
  final preload = preloadRaw is Map<String, dynamic>
      ? preloadRaw
      : preloadRaw is Map
          ? preloadRaw.map((k, v) => MapEntry(k.toString(), v))
          : <String, dynamic>{};
  if (preloadRaw is! Map) boot['product_preload'] = preload;

  final pages = boot['pages'];
  if (pages is! List) return;
  for (final page in pages) {
    if (page is! Map) continue;
    final blocks = page['blocks'];
    if (blocks is! List) continue;
    for (final block in blocks) {
      if (block is! Map) continue;
      if (block['type']?.toString() != 'product_grid') continue;
      final id = block['id']?.toString() ?? '';
      if (id.isEmpty) continue;
      final props = block['props'];
      final propsMap = props is Map<String, dynamic>
          ? props
          : props is Map
              ? props.map((k, v) => MapEntry(k.toString(), v))
              : const <String, dynamic>{};
      preload[id] = siteEditorPreviewProductRowsForGridProps(allRows, propsMap);
    }
  }
}

/// Ensures a home [product_grid] block and `product_preload` when commerce is on.
void siteEditorPreviewSyncCommerceCatalog(Map<String, dynamic> boot, [Iterable<SiteProduct>? products]) {
  if (!siteEditorPreviewCommerceEnabled(boot)) return;

  final List<Map<String, dynamic>> rows;
  if (products != null) {
    rows = <Map<String, dynamic>>[];
    for (final p in products) {
      if (p.isArchived || !p.canSell) continue;
      rows.add(siteEditorPreviewProductRow(p));
    }
    rows.sort((a, b) => ((a['product_id'] as num?) ?? 0).compareTo((b['product_id'] as num?) ?? 0));
  } else {
    rows = List<Map<String, dynamic>>.from(_siteEditorPreviewProductRowsFromBoot(boot));
  }
  if (rows.isEmpty) return;

  siteEditorPreviewEnsureProductGridBlock(boot);
  final commerce = boot['commerce_boot'];
  if (commerce is Map) {
    commerce['enabled'] = true;
    commerce['products'] = rows;
  } else {
    boot['commerce_boot'] = {'enabled': true, 'products': rows};
  }
  siteEditorPreviewApplyProductPreloadForGrids(boot, rows);
}

void siteEditorPreviewRemoveProduct(Map<String, dynamic> boot, int productId) {
  final commerce = boot['commerce_boot'];
  if (commerce is Map<String, dynamic>) {
    final products = commerce['products'];
    if (products is List) {
      products.removeWhere((e) => e is Map && (e['product_id'] as num?)?.toInt() == productId);
    }
  }
  final preload = boot['product_preload'];
  if (preload is Map) {
    for (final entry in preload.entries) {
      final list = entry.value;
      if (list is List) {
        list.removeWhere((e) => e is Map && (e['product_id'] as num?)?.toInt() == productId);
      }
    }
  }
}

void siteEditorPreviewPatchDraftMeta(
  Map<String, dynamic> boot, {
  List<SiteTaxDraft>? taxes,
  SiteProductDesignDraft? productDesign,
  String? catalogDisplay,
}) {
  final meta = boot['meta'];
  final map = meta is Map<String, dynamic> ? Map<String, dynamic>.from(meta) : <String, dynamic>{};
  if (taxes != null) {
    map['taxes'] = taxes.map(siteTaxDraftToJson).toList(growable: false);
  }
  if (productDesign != null) {
    map['product_design'] = siteProductDesignToJson(productDesign);
    boot['product_design'] = map['product_design'];
  }
  if (catalogDisplay != null) {
    map['catalog_display'] = siteCatalogDisplayNormalize(catalogDisplay);
  }
  boot['meta'] = map;
}

Map<String, dynamic> siteEditorPreviewLinkRow(SiteLink link) => {
      'link_id': link.linkId.toInt(),
      'sort_order': link.sortOrder,
      'label': link.label,
      'url': link.url,
      'icon': link.icon,
      'display': link.display,
      'is_pinned': link.isPinned,
    };

void siteEditorPreviewUpsertLink(Map<String, dynamic> boot, SiteLink link) {
  if (!link.active) {
    siteEditorPreviewRemoveLink(boot, link.linkId.toInt());
    return;
  }
  final row = siteEditorPreviewLinkRow(link);
  final links = boot['links'];
  final list = links is List ? links : <dynamic>[];
  boot['links'] = list;
  final id = link.linkId.toInt();
  var found = false;
  for (var i = 0; i < list.length; i++) {
    final item = list[i];
    if (item is Map && (item['link_id'] as num?)?.toInt() == id) {
      list[i] = row;
      found = true;
      break;
    }
  }
  if (!found) list.add(row);
}

void siteEditorPreviewRemoveLink(Map<String, dynamic> boot, int linkId) {
  final links = boot['links'];
  if (links is List) {
    links.removeWhere((e) => e is Map && (e['link_id'] as num?)?.toInt() == linkId);
  }
}

void siteEditorPreviewSetLinks(Map<String, dynamic> boot, List<SiteLink> links) {
  boot['links'] = links.where((l) => l.active).map(siteEditorPreviewLinkRow).toList(growable: false);
}

void siteEditorPreviewPatchDesignStore(Map<String, dynamic> boot, SiteDesignStore store) {
  final theme = store.toThemeMap();
  boot['theme'] = theme;
  boot['design'] = Map<String, dynamic>.from(theme);
  boot['effects'] = theme['effects'] ?? const [];
  siteEditorPreviewPatchDraftMeta(boot, productDesign: store.productDesign);
}

Map<String, dynamic> siteEditorPreviewPostSummary(SitePost post) {
  final paths = sitePostMediaPaths(post);
  return {
    'post_id': post.postId.toInt(),
    'title': post.title,
    'caption': post.caption,
    'thumb': post.thumb,
    'feed_kind': post.feedKind.isEmpty ? 'post' : post.feedKind,
    'media_count': paths.length,
  };
}

void siteEditorPreviewUpsertPost(Map<String, dynamic> boot, SitePost post) {
  if (!post.onStorefront) {
    siteEditorPreviewRemovePost(boot, post.postId.toInt());
    return;
  }
  final row = siteEditorPreviewPostSummary(post);
  final posts = boot['posts_preload'];
  final list = posts is List ? posts : <dynamic>[];
  boot['posts_preload'] = list;
  final id = post.postId.toInt();
  var found = false;
  for (var i = 0; i < list.length; i++) {
    final item = list[i];
    if (item is Map && (item['post_id'] as num?)?.toInt() == id) {
      list[i] = row;
      found = true;
      break;
    }
  }
  if (!found) list.add(row);
}

void siteEditorPreviewRemovePost(Map<String, dynamic> boot, int postId) {
  final posts = boot['posts_preload'];
  if (posts is List) {
    posts.removeWhere((e) => e is Map && (e['post_id'] as num?)?.toInt() == postId);
  }
}

String _siteEditorPreviewFileUrl(String pic) {
  final trimmed = pic.trim();
  if (trimmed.isEmpty) return '';
  if (trimmed.startsWith('http')) return trimmed;
  final base = C35Config.authApiBase.replaceAll(RegExp(r'/+$'), '');
  return '$base/v1/file/${Uri.encodeComponent(trimmed)}';
}

Map<String, dynamic> _contactMetaMap(SiteContact contact) {
  final raw = contact.metaJson.trim();
  if (raw.isEmpty) return {};
  try {
    final decoded = jsonDecode(raw);
    if (decoded is Map) {
      return decoded.map((k, v) => MapEntry(k.toString(), v));
    }
  } catch (_) {}
  return {};
}

Map<String, dynamic>? siteEditorPreviewFeaturedContactRow(SiteContact contact) {
  final meta = _contactMetaMap(contact);
  final featured = meta['featured']?.toString().trim() ?? '';
  if (featured != 'partners' && featured != 'clients') return null;
  final picRaw = meta['pic']?.toString() ?? meta['avatar']?.toString() ?? '';
  return {
    'id': contact.contactId.toInt(),
    'name': contact.name,
    'pic': _siteEditorPreviewFileUrl(picRaw),
    'featured': featured,
  };
}

void siteEditorPreviewSetFeaturedContacts(Map<String, dynamic> boot, Iterable<SiteContact> contacts) {
  final list = <Map<String, dynamic>>[];
  for (final c in contacts) {
    final row = siteEditorPreviewFeaturedContactRow(c);
    if (row != null) list.add(row);
  }
  list.sort((a, b) => (a['name'] as String).toLowerCase().compareTo((b['name'] as String).toLowerCase()));
  boot['featured_contacts'] = list;
}

Map<String, dynamic> siteEditorPreviewCommerceObjectRow(SiteObject object) {
  final pic = object.pic.trim();
  var picUrl = pic;
  if (pic.isNotEmpty && !pic.startsWith('http')) {
    picUrl = _siteEditorPreviewFileUrl(pic);
  }
  return {
    'id': object.id.toInt(),
    'name': object.name,
    'code': object.code,
    'pic': picUrl,
    'kind': object.kind,
    'product_id': object.productId.toInt(),
  };
}

bool _commerceObjectInBoot(SiteObject object) => object.isActive && object.canBeReserved;

void siteEditorPreviewRefreshCommerceObjects(Map<String, dynamic> boot, Iterable<SiteObject> objects) {
  final list = objects.where(_commerceObjectInBoot).map(siteEditorPreviewCommerceObjectRow).toList(growable: false);
  list.sort((a, b) {
    final c = (a['name'] as String).toLowerCase().compareTo((b['name'] as String).toLowerCase());
    if (c != 0) return c;
    return (a['code'] as String).toLowerCase().compareTo((b['code'] as String).toLowerCase());
  });
  final commerce = boot['commerce_boot'];
  if (commerce is Map) {
    commerce['objects'] = list;
  }
}

void siteEditorPreviewUpsertCommerceObject(Map<String, dynamic> boot, SiteObject object) {
  if (!_commerceObjectInBoot(object)) {
    siteEditorPreviewRemoveCommerceObject(boot, object.id.toInt());
    return;
  }
  final row = siteEditorPreviewCommerceObjectRow(object);
  final commerce = boot['commerce_boot'];
  if (commerce is! Map) return;
  final objects = commerce['objects'];
  final list = objects is List ? objects : <dynamic>[];
  commerce['objects'] = list;
  final id = object.id.toInt();
  var found = false;
  for (var i = 0; i < list.length; i++) {
    final item = list[i];
    if (item is Map && (item['id'] as num?)?.toInt() == id) {
      list[i] = row;
      found = true;
      break;
    }
  }
  if (!found) list.add(row);
}

void siteEditorPreviewRemoveCommerceObject(Map<String, dynamic> boot, int objectId) {
  final commerce = boot['commerce_boot'];
  if (commerce is Map) {
    final objects = commerce['objects'];
    if (objects is List) {
      objects.removeWhere((e) => e is Map && (e['id'] as num?)?.toInt() == objectId);
    }
  }
}

List<Map<String, dynamic>> siteEditorPreviewDefaultPaymentMethods() => [
      {
        'id': 'cash',
        'type': 'cash',
        'title': 'Bayar di tempat',
        'icon': 'material-symbols:payments-outline',
      },
      {
        'id': 'transfer',
        'type': 'transfer',
        'title': 'Transfer bank',
        'icon': 'material-symbols:account-balance-outline',
      },
      {
        'id': 'qris',
        'type': 'qris',
        'title': 'QRIS',
        'icon': 'material-symbols:qr-code-scanner',
      },
    ];

List<Map<String, dynamic>> siteEditorPreviewPaymentMethodsFromMeta(Map<String, dynamic> meta) {
  final items = meta['payment_accounts'];
  if (items is! List) return siteEditorPreviewDefaultPaymentMethods();
  final mapped = <Map<String, dynamic>>[];
  for (final row in items) {
    if (row is! Map) continue;
    final m = row.map((k, v) => MapEntry(k.toString(), v));
    final id = m['id']?.toString().trim() ?? '';
    if (id.isEmpty) continue;
    final bank = m['bank']?.toString().trim() ?? '';
    final accountName = m['account_name']?.toString().trim() ?? '';
    final accountNumber = m['account_number']?.toString().trim() ?? '';
    final qrisPic = m['qris_pic']?.toString().trim() ?? '';
    final titleParts = [bank, accountName].where((s) => s.isNotEmpty).toList(growable: false);
    var title = titleParts.join(' · ');
    if (title.isEmpty) {
      title = accountNumber.isEmpty ? id : accountNumber;
    }
    final typ = qrisPic.isEmpty ? 'transfer' : 'qris';
    mapped.add({
      'id': id,
      'type': typ,
      'title': title,
      'bank': bank,
      'account_name': accountName,
      'account_number': accountNumber,
      'qris_pic': qrisPic,
    });
  }
  if (mapped.isEmpty) return siteEditorPreviewDefaultPaymentMethods();
  return mapped;
}

void siteEditorPreviewApplyMetaMap(Map<String, dynamic> boot, Map<String, dynamic> meta) {
  boot['meta'] = Map<String, dynamic>.from(meta);
  final productDesign = meta['product_design'];
  if (productDesign != null) {
    boot['product_design'] = productDesign;
  }
  final commerce = boot['commerce_boot'];
  if (commerce is Map) {
    commerce['payment_methods'] = siteEditorPreviewPaymentMethodsFromMeta(meta);
    final taxes = meta['taxes'];
    if (taxes is List) commerce['taxes'] = taxes;
  }
}

void siteEditorPreviewMergeMetaJson(Map<String, dynamic> boot, String metaJson) {
  final map = siteDraftJsonMap(metaJson);
  siteEditorPreviewApplyMetaMap(boot, map);
}

List<Map<String, dynamic>> siteEditorPreviewPagesFromDoc(SiteDoc doc) {
  return doc.pages.map((page) {
    final blocks = page.blocks.map((block) {
      Map<String, dynamic> props = {};
      if (block.propsJson.trim().isNotEmpty) {
        try {
          final decoded = jsonDecode(block.propsJson);
          if (decoded is Map<String, dynamic>) {
            props = decoded;
          } else if (decoded is Map) {
            props = decoded.map((k, v) => MapEntry(k.toString(), v));
          }
        } catch (_) {}
      }
      return {
        'id': block.id,
        'type': block.type,
        'props': props,
      };
    }).toList(growable: false);
    return {
      'path': page.path,
      'title': page.title,
      'blocks': blocks,
    };
  }).toList(growable: false);
}

void siteEditorPreviewPatchDocPages(Map<String, dynamic> boot, SiteDoc doc) {
  boot['pages'] = siteEditorPreviewPagesFromDoc(doc);
}

bool siteEditorPreviewHomeBlocksEmpty(Map<String, dynamic> boot) {
  final pages = boot['pages'];
  if (pages is! List || pages.isEmpty) return true;
  final first = pages.first;
  if (first is! Map) return true;
  final blocks = first['blocks'];
  if (blocks is! List) return true;
  return blocks.isEmpty;
}

SiteInfoSnapshot siteEditorPreviewInfoSnapshot(SiteRow row, String metaJson) {
  var locationLabel = '';
  var locationHref = '';
  double? lat;
  double? lng;
  siteMetaLocationRead(metaJson, (label, href, latitude, longitude) {
    locationLabel = label;
    locationHref = href;
    lat = latitude;
    lng = longitude;
  });
  return SiteInfoSnapshot(
    name: row.name,
    tagline: siteMetaTaglineRead(metaJson),
    pic: row.pic,
    locationLabel: locationLabel,
    locationHref: locationHref,
    latitude: lat,
    longitude: lng,
    openHours: siteScheduleSlotsFromMetaJson(metaJson),
  );
}

SiteDoc siteEditorPreviewSeedDoc(SiteInfoSnapshot snap) {
  final name = snap.name.trim().isNotEmpty ? snap.name.trim() : 'Site';
  final props = <String, dynamic>{
    'title': name,
    if (snap.tagline.isNotEmpty) 'subtitle': snap.tagline,
    if (snap.pic.isNotEmpty) 'pic': snap.pic,
  };
  return SiteDoc(
    pages: [
      SitePage(
        path: '/',
        title: name,
        blocks: [SiteBlock(id: 'hero1', type: 'hero', propsJson: jsonEncode(props))],
      ),
    ],
    themeJson: '{"accent":"#2563eb"}',
    metaJson: siteMetaMergeInfo('{}', tagline: snap.tagline.isEmpty ? null : snap.tagline),
  );
}

/// Ensures editor preview has home blocks (draft doc, or a hero seeded from site info).
void siteEditorPreviewApplyDocToBoot(Map<String, dynamic> boot, SiteRow row, SiteDoc doc) {
  var next = doc.clone();
  final snap = siteEditorPreviewInfoSnapshot(row, next.metaJson);
  if (next.pages.isEmpty || next.pages.every((p) => p.blocks.isEmpty)) {
    next = siteEditorPreviewSeedDoc(snap);
  }
  next = siteInfoApplyToDoc(next, snap);
  siteEditorPreviewPatchDocPages(boot, next);
  siteEditorPreviewMergeMetaJson(boot, next.metaJson);
  siteEditorPreviewPatchSiteRow(boot, row);
}

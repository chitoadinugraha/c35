import 'dart:convert';

import 'package:alienai_c35/c/chat/chat_conn.dart';
import 'package:alienai_c35/c/pb/c35/collection.pb.dart';
import 'package:alienai_c35/c/pb/c35/site.pb.dart';
import 'package:alienai_c35/c/device/device_api.dart';
import 'package:alienai_c35/c/pb/c35/identity.pb.dart';
import 'package:alienai_c35/c/site/collection_def.dart';
import 'package:fixnum/fixnum.dart';

SiteRow siteRowFromIdentity(IdentityListRow row) {
  final id = row.identity;
  return SiteRow(
    siteIid: id.iid,
    alienId: id.alienId,
    name: id.name,
    pic: id.pic,
    publishedVersionId: '',
    updatedTsMs: id.updatedTsMs,
    isArchived: row.archivedTsMs > Int64.ZERO,
    isPinned: row.isPinned,
    sortOrder: row.sortOrder,
  );
}

Future<List<SiteRow>> siteListFetch(ChatConn conn, {bool archived = false}) async {
  try {
    final res = await conn.siteList(archived: archived);
    if (res.sites.isNotEmpty) return res.sites;
  } catch (_) {}
  final res = await identityList(conn, const ['site'], includeArchived: archived);
  return res.rows.map(siteRowFromIdentity).toList(growable: false);
}

class SiteCreateFeatures {
  SiteCreateFeatures({this.product = false, this.pos = false, this.attendance = false, this.reservation = false});

  bool product;
  bool pos;
  bool attendance;
  bool reservation;
}

SiteCreateFeatures siteCreateFeaturesNormalize(SiteCreateFeatures f) {
  if (f.pos) f.product = true;
  if (!f.product) f.pos = false;
  return f;
}

Map<String, bool> siteCreateFeaturesToCaps(SiteCreateFeatures f) {
  final n = siteCreateFeaturesNormalize(f);
  return {
    'commerce': n.product || n.pos,
    'booking': n.reservation,
    'queue': false,
    'attendance': n.attendance,
  };
}

String siteCreateCapabilitiesJson(SiteCreateFeatures f) => jsonEncode(siteCreateFeaturesToCaps(f));

String siteAlienIdSlug(String name) {
  var s = name.trim().toLowerCase();
  s = s.replaceAll(RegExp(r'[^a-z0-9\s_-]'), '');
  s = s.replaceAll(RegExp(r'[\s_]+'), '-');
  s = s.replaceAll(RegExp(r'-+'), '-').replaceAll(RegExp(r'^-|-$'), '');
  if (s.length > 48) s = s.substring(0, 48).replaceAll(RegExp(r'-+$'), '');
  return s;
}

String siteTaglineSuggest({required String name, required String locale}) {
  final n = name.trim();
  if (n.isEmpty) return '';
  final id = locale.toLowerCase().startsWith('id');
  final templates = id
      ? [
          '$n — tempat terbaik untuk belanja dan layanan.',
          'Selamat datang di $n. Kualitas dan pelayanan terbaik.',
          '$n siap melayani kebutuhan Anda setiap hari.',
          'Temukan produk dan layanan terbaik di $n.',
        ]
      : [
          '$n — your place for great products and service.',
          'Welcome to $n. Quality you can trust.',
          '$n is here for you every day.',
          'Discover what $n has to offer.',
        ];
  return templates[n.hashCode.abs() % templates.length];
}

SiteDraft siteCreateDraft({required Int64 siteIid, required String name, required String tagline, String pic = ''}) {
  final props = <String, dynamic>{'title': name, if (tagline.isNotEmpty) 'subtitle': tagline, if (pic.isNotEmpty) 'pic': pic};
  final doc = SiteDoc(
    pages: [
      SitePage(
        path: '/',
        title: name,
        blocks: [SiteBlock(id: 'hero1', type: 'hero', propsJson: jsonEncode(props))],
      ),
    ],
    themeJson: '{"accent":"#2563eb"}',
    metaJson: jsonEncode({'seo_title': name, if (tagline.isNotEmpty) 'tagline': tagline}),
  );
  return SiteDraft(siteIid: siteIid, doc: doc);
}

class SiteApi {
  SiteApi(this.conn);

  final ChatConn conn;

  Future<List<SiteRow>> list({bool archived = false}) => siteListFetch(conn, archived: archived);

  Future<List<TableDef>> collectionDefs({int siteIid = 0}) async {
    try {
      final res = await conn.collectionDefList(siteIid: siteIid);
      if (res.tables.isNotEmpty) return res.tables;
    } catch (_) {}
    return collectionDefListFallback();
  }

  Future<List<SiteProductEmbed>> productEmbedList(int siteIid) async {
    final res = await conn.sync(collections: const ['site_product_embed']);
    return res.siteProductEmbeds.where((e) => e.siteIid.toInt() == siteIid).toList(growable: false);
  }

  Future<ResSitePublish> publish(int siteIid) => conn.sitePublish(siteIid);

  Future<ResSitePreviewToken> sitePreviewToken(int siteIid, {int ttlSecs = 300}) =>
      conn.sitePreviewToken(siteIid, ttlSecs: ttlSecs);

  Future<SiteConfig> configGet(int siteIid) async {
    final res = await conn.siteDraftGet(siteIid);
    if (!res.hasConfig()) throw 'site config not found';
    return res.config;
  }

  Future<SiteConfig> configPut(int siteIid, {required String capabilitiesJson}) async {
    final res = await conn.siteConfigPut(siteIid, capabilitiesJson: capabilitiesJson);
    if (!res.hasConfig()) throw 'site config put failed';
    return res.config;
  }

  Future<List<SiteProduct>> productList(int siteIid) async {
    final res = await conn.siteProductList(siteIid);
    return res.products;
  }

  Future<SiteProduct> productPut(int siteIid, SiteProduct product, {List<SiteProductEmbed>? embeds}) async {
    final payload = product.clone();
    if (embeds != null) {
      final base = _productJsonMap(payload.productJson);
      base['_embeds'] = embeds
          .map((e) => {'embed_id': e.embedId.toInt(), 'label': e.label})
          .toList(growable: false);
      payload.productJson = jsonEncode(base);
    }
    final res = await conn.siteProductPut(siteIid, payload);
    final out = product.clone();
    if (res.hasProductId()) {
      out.productId = res.productId;
    } else if (out.productId <= Int64.ZERO) {
      throw 'product put failed';
    }
    return out;
  }

  Map<String, dynamic> _productJsonMap(String raw) {
    if (raw.trim().isEmpty) return {};
    try {
      final decoded = jsonDecode(raw);
      return decoded is Map<String, dynamic> ? decoded : {};
    } catch (_) {
      return {};
    }
  }

  Future<List<SiteContact>> contactList(int siteIid) async {
    final res = await conn.siteContactList(siteIid);
    return res.contacts;
  }

  Future<SiteContact> contactPut(int siteIid, SiteContact contact) async {
    final res = await conn.siteContactPut(siteIid, contact);
    final out = contact.clone();
    if (res.hasContactId()) {
      out.contactId = res.contactId;
    } else if (out.contactId <= Int64.ZERO) {
      throw 'contact put failed';
    }
    return out;
  }

  Future<List<SiteObject>> objectList(int siteIid) async {
    final res = await conn.siteObjectList(siteIid);
    return res.objs;
  }

  Future<SiteObject> objectPut(int siteIid, SiteObject object) async {
    final res = await conn.siteObjectPut(siteIid, object);
    final out = object.clone();
    if (res.hasId()) {
      out.id = res.id;
    } else if (out.id <= Int64.ZERO) {
      throw 'object put failed';
    }
    return out;
  }

  Future<List<SiteDomain>> domainList(int siteIid) async {
    final res = await conn.siteDomainList(siteIid);
    return res.domains;
  }

  Future<SiteDomain> domainPut(int siteIid, SiteDomain domain) async {
    final res = await conn.siteDomainPut(siteIid, domain);
    final out = domain.clone();
    if (res.hasId()) {
      out.id = res.id;
    } else if (out.id <= Int64.ZERO) {
      throw 'domain put failed';
    }
    return out;
  }

  Future<ResSiteDomainVerify> domainVerify(int siteIid, int domainId, {bool forceTls = false}) =>
      conn.siteDomainVerify(siteIid, domainId, forceTls: forceTls);

  TableDef? tableDefFor(List<TableDef> defs, String collection) =>
      defs.where((d) => d.collection == collection).firstOrNull;

  SiteProduct productNew(int siteIid) => SiteProduct(siteIid: Int64(siteIid), name: 'New product', canSell: true);

  SiteContact contactNew(int siteIid) => SiteContact(siteIid: Int64(siteIid), name: 'New contact');

  SiteObject objectNew(int siteIid) => SiteObject(siteIid: Int64(siteIid), name: 'New object', isActive: true);

  SiteDomain domainNew(int siteIid) => SiteDomain(siteIid: Int64(siteIid), hostname: 'example.com');

  SiteProductEmbed productEmbedNew(int siteIid, Int64 productId) =>
      SiteProductEmbed(siteIid: Int64(siteIid), productId: productId, label: 'New label');

  TableDef? domainTableDef(List<TableDef> defs) =>
      tableDefFor(defs, 'site.domain') ?? collectionDefForFallback('site.domain');
}

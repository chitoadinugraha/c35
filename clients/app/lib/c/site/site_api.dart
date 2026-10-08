import 'dart:convert';

import 'package:alienai_c35/c/chat/chat_conn.dart';
import 'package:alienai_c35/c/pb/c35/collection.pb.dart';
import 'package:alienai_c35/c/pb/c35/site.pb.dart';
import 'package:alienai_c35/c/device/device_api.dart';
import 'package:alienai_c35/c/pb/c35/identity.pb.dart';
import 'package:alienai_c35/c/site/collection_def.dart';
import 'package:alienai_c35/c/session.dart';
import 'package:alienai_c35/c/site/site_commerce_cache.dart';
import 'package:alienai_c35/c/site/site_draft_meta.dart';
import 'package:alienai_c35/c/site/site_product_json.dart';
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

const siteHandleMinLen = 3;
const siteHandleMaxLen = 48;
const siteUrlPrefix = 'alienai.id/';

String? siteHandleFormatError(String raw) {
  final slug = siteAlienIdSlug(raw);
  if (slug.length < siteHandleMinLen) return 'At least $siteHandleMinLen characters';
  if (slug.length > siteHandleMaxLen) return 'At most $siteHandleMaxLen characters';
  if (RegExp(r'^\d+$').hasMatch(slug)) return 'Use letters, not only numbers';
  return null;
}

String siteTaglineSuggest({required String name, required String locale, int pick = 0}) {
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
  final i = (n.hashCode + pick) % templates.length;
  return templates[i < 0 ? i + templates.length : i];
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
    return res.siteProductEmbeds
        .where((e) => e.siteIid.toInt() == siteIid && !e.hasDeletedTsMs())
        .toList(growable: false);
  }

  Future<ResSitePublish> publish(int siteIid) => conn.sitePublish(siteIid);

  Future<ResSitePreviewToken> sitePreviewToken(int siteIid, {int ttlSecs = 300}) =>
      conn.sitePreviewToken(siteIid, ttlSecs: ttlSecs);

  Future<ResSiteHandlePut> handlePut(int siteIid, String newAlienId) =>
      conn.siteHandlePut(siteIid, siteAlienIdSlug(newAlienId));

  Future<ResSiteBootGet> bootGet(int siteIid, {SiteBootMode mode = SiteBootMode.SITE_BOOT_MODE_DRAFT}) =>
      conn.siteBootGet(siteIid, mode: mode);

  Future<SiteConfig> configGet(int siteIid) async {
    final uid = Session.instance.uid;
    try {
      final res = await conn.siteDraftGet(siteIid);
      if (!res.hasConfig()) throw 'site config not found';
      final config = res.config;
      await siteCapabilitiesCacheSave(uid, siteIid, config.capabilitiesJson);
      return config;
    } catch (e) {
      final cached = await siteCapabilitiesCacheRestore(uid, siteIid);
      if (cached != null) {
        return SiteConfig(siteIid: Int64(siteIid), capabilitiesJson: cached);
      }
      rethrow;
    }
  }

  Future<SiteConfig> configPut(int siteIid, {required String capabilitiesJson}) async {
    final res = await conn.siteConfigPut(siteIid, capabilitiesJson: capabilitiesJson);
    if (!res.hasConfig()) throw 'site config put failed';
    return res.config;
  }

  Future<List<SiteProduct>> productList(int siteIid) async {
    final uid = Session.instance.uid;
    try {
      final res = await conn.siteProductList(siteIid);
      await siteProductCacheSave(uid, siteIid, res.products);
      return res.products;
    } catch (e) {
      final cached = await siteProductCacheRestore(uid, siteIid);
      if (cached.isNotEmpty) return cached;
      rethrow;
    }
  }

  Future<SiteDraft> draftGet(int siteIid) async {
    final res = await conn.siteDraftGet(siteIid);
    if (!res.hasDraft()) throw 'site draft not found';
    return res.draft;
  }

  Future<SiteDraft> draftPut(SiteDraft draft, {bool skipPublish = false}) async {
    await conn.siteDraftPut(draft, skipPublish: skipPublish);
    return draft;
  }

  Future<SiteProduct> productPut(int siteIid, SiteProduct product, {List<SiteProductEmbed>? embeds}) async {
    final payload = product.clone();
    if (embeds != null) {
      final base = siteProductJsonMap(payload.productJson);
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

  Future<void> productDelete(int siteIid, Int64 productId) async {
    final res = await conn.siteProductDelete(siteIid, productId.toInt());
    if (!res.ok) throw 'product delete failed';
  }

  Future<void> productReorder(int siteIid, List<({Int64 id, int sortOrder})> entries) async {
    final payload = entries
        .map((e) => SiteProductReorderEntry(productId: e.id, sortOrder: e.sortOrder))
        .toList(growable: false);
    final res = await conn.siteProductReorder(siteIid, payload);
    if (!res.ok) throw 'product reorder failed';
  }

  Future<SiteDraftMeta> draftGetMeta(int siteIid) async {
    final res = await conn.siteDraftGet(siteIid);
    if (!res.hasDraft()) throw 'site draft not found';
    return siteDraftMetaParse(res.draft.doc.metaJson);
  }

  Future<void> draftPutMeta(
    int siteIid, {
    List<SiteTaxDraft>? taxes,
    SiteProductDesignDraft? productDesign,
  }) async {
    final res = await conn.siteDraftGet(siteIid);
    if (!res.hasDraft()) throw 'site draft not found';
    final draft = res.draft.clone();
    draft.doc = siteDocWithMetaJson(
      draft.doc,
      siteDraftMetaMerge(draft.doc.metaJson, taxes: taxes, productDesign: productDesign),
    );
    await conn.siteDraftPut(draft);
  }

  Future<List<SiteContact>> contactList(int siteIid) async {
    final uid = Session.instance.uid;
    try {
      final res = await conn.siteContactList(siteIid);
      await siteContactCacheSave(uid, siteIid, res.contacts);
      return res.contacts;
    } catch (e) {
      final cached = await siteContactCacheRestore(uid, siteIid);
      if (cached.isNotEmpty) return cached;
      return const [];
    }
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

  Future<List<SiteLink>> linkList(int siteIid) async {
    final res = await conn.siteLinkList(siteIid);
    return res.links;
  }

  Future<SiteLink> linkPut(int siteIid, SiteLink link) async {
    final res = await conn.siteLinkPut(siteIid, link);
    final out = link.clone();
    if (res.hasLinkId()) {
      out.linkId = res.linkId;
    } else if (out.linkId <= Int64.ZERO) {
      throw 'link put failed';
    }
    return out;
  }

  Future<void> linkDelete(int siteIid, int linkId) async {
    final res = await conn.siteLinkDelete(siteIid, linkId);
    if (!res.ok) throw 'link delete failed';
  }

  Future<List<SiteGrant>> grantList(int siteIid) async {
    final res = await conn.siteGrantList(siteIid);
    return res.grants;
  }

  Future<void> grantPut(int siteIid, {Int64 granteeIid = Int64.ZERO, String granteeAlienId = '', required String role}) async {
    final res = await conn.siteGrantPut(siteIid, granteeIid: granteeIid, granteeAlienId: granteeAlienId, role: role);
    if (!res.ok) throw 'grant put failed';
  }

  Future<void> grantDelete(int siteIid, int granteeIid) async {
    final res = await conn.siteGrantDelete(siteIid, granteeIid);
    if (!res.ok) throw 'grant delete failed';
  }

  Future<List<SiteQueue>> queueList(int siteIid) async {
    final res = await conn.siteQueueList(siteIid);
    return res.queues;
  }

  Future<SiteQueue> queuePut(int siteIid, SiteQueue queue) async {
    final res = await conn.siteQueuePut(siteIid, queue);
    final out = queue.clone();
    if (res.hasQueueId()) {
      out.queueId = res.queueId;
    } else if (out.queueId <= Int64.ZERO) {
      out.queueId = Int64(1);
    }
    return out;
  }

  Future<int> queueAdvanceServing(int siteIid, {int queueId = 1}) async {
    final res = await conn.siteQueueAdvance(siteIid, queueId: queueId);
    return res.servingTicketNo;
  }

  SiteQueue queueNew(int siteIid) => SiteQueue(siteIid: Int64(siteIid), queueId: Int64(1), name: 'Main', isActive: true);

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

  SiteLink linkNew(int siteIid) => SiteLink(siteIid: Int64(siteIid), label: 'New link', url: 'https://', active: true);

  SiteDomain domainNew(int siteIid) => SiteDomain(siteIid: Int64(siteIid), hostname: 'example.com');

  SiteProductEmbed productEmbedNew(int siteIid, Int64 productId) =>
      SiteProductEmbed(siteIid: Int64(siteIid), productId: productId, label: 'New label');

  TableDef? domainTableDef(List<TableDef> defs) =>
      tableDefFor(defs, 'site.domain') ?? collectionDefForFallback('site.domain');
}

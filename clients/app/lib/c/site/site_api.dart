import 'dart:convert';

import 'package:alienai_c35/c/chat/chat_conn.dart';
import 'package:alienai_c35/c/pb/c35/collection.pb.dart';
import 'package:alienai_c35/c/pb/c35/site.pb.dart';
import 'package:alienai_c35/c/site/collection_def.dart';
import 'package:fixnum/fixnum.dart';

class SiteApi {
  SiteApi(this.conn);

  final ChatConn conn;

  Future<List<SiteRow>> list({bool archived = false}) async {
    final res = await conn.siteList(archived: archived);
    return res.sites;
  }

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

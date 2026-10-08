import 'dart:convert';

import 'package:alienai_c35/c/pb/c35/site.pb.dart';
import 'package:shared_preferences/shared_preferences.dart';

String _productKey(int ownerUid, int siteIid) => 'c35.site.products.v1.$ownerUid.$siteIid';
String _contactKey(int ownerUid, int siteIid) => 'c35.site.contacts.v1.$ownerUid.$siteIid';
String _capabilitiesKey(int ownerUid, int siteIid) => 'c35.site.capabilities.v1.$ownerUid.$siteIid';

Future<void> siteProductCacheSave(int ownerUid, int siteIid, List<SiteProduct> products) async {
  if (ownerUid <= 0 || siteIid <= 0) return;
  final p = await SharedPreferences.getInstance();
  await p.setString(_productKey(ownerUid, siteIid), base64Encode(ResSiteProductList(products: products).writeToBuffer()));
}

Future<List<SiteProduct>> siteProductCacheRestore(int ownerUid, int siteIid) async {
  if (ownerUid <= 0 || siteIid <= 0) return [];
  final p = await SharedPreferences.getInstance();
  final raw = p.getString(_productKey(ownerUid, siteIid));
  if (raw == null || raw.isEmpty) return [];
  try {
    return List<SiteProduct>.from(ResSiteProductList.fromBuffer(base64Decode(raw)).products);
  } catch (_) {
    return [];
  }
}

Future<void> siteContactCacheSave(int ownerUid, int siteIid, List<SiteContact> contacts) async {
  if (ownerUid <= 0 || siteIid <= 0) return;
  final p = await SharedPreferences.getInstance();
  await p.setString(_contactKey(ownerUid, siteIid), base64Encode(ResSiteContactList(contacts: contacts).writeToBuffer()));
}

Future<List<SiteContact>> siteContactCacheRestore(int ownerUid, int siteIid) async {
  if (ownerUid <= 0 || siteIid <= 0) return [];
  final p = await SharedPreferences.getInstance();
  final raw = p.getString(_contactKey(ownerUid, siteIid));
  if (raw == null || raw.isEmpty) return [];
  try {
    return List<SiteContact>.from(ResSiteContactList.fromBuffer(base64Decode(raw)).contacts);
  } catch (_) {
    return [];
  }
}

Future<void> siteCapabilitiesCacheSave(int ownerUid, int siteIid, String capabilitiesJson) async {
  if (ownerUid <= 0 || siteIid <= 0) return;
  final trimmed = capabilitiesJson.trim();
  if (trimmed.isEmpty) return;
  final p = await SharedPreferences.getInstance();
  await p.setString(_capabilitiesKey(ownerUid, siteIid), trimmed);
}

Future<String?> siteCapabilitiesCacheRestore(int ownerUid, int siteIid) async {
  if (ownerUid <= 0 || siteIid <= 0) return null;
  final p = await SharedPreferences.getInstance();
  final raw = p.getString(_capabilitiesKey(ownerUid, siteIid));
  if (raw == null || raw.isEmpty) return null;
  return raw;
}

import 'dart:convert';

import 'package:alienai_c35/c/chat/chat_conn.dart';
import 'package:alienai_c35/c/pb/c35/identity.pb.dart';
import 'package:alienai_c35/c/site/site_api.dart';
import 'package:fixnum/fixnum.dart';

const _assistantBotCapKey = 'assistant_bot_iid';

int? siteAssistantBotIidFromCapabilities(String capabilitiesJson) {
  if (capabilitiesJson.trim().isEmpty) return null;
  try {
    final raw = jsonDecode(capabilitiesJson);
    if (raw is! Map) return null;
    final v = raw[_assistantBotCapKey];
    if (v is int && v > 0) return v;
    if (v is num && v > 0) return v.toInt();
  } catch (_) {}
  return null;
}

Map<String, dynamic> _capabilitiesMap(String capabilitiesJson) {
  if (capabilitiesJson.trim().isEmpty) return {};
  try {
    final raw = jsonDecode(capabilitiesJson);
    if (raw is Map) return raw.map((k, v) => MapEntry(k.toString(), v));
  } catch (_) {}
  return {};
}

/// Ensures a site-scoped assistant bot exists; stores `assistant_bot_iid` in site capabilities JSON.
Future<int> siteAssistantBotEnsure({
  required ChatConn conn,
  required SiteApi api,
  required int siteIid,
  required String siteName,
}) async {
  final config = await api.configGet(siteIid);
  final existing = siteAssistantBotIidFromCapabilities(config.capabilitiesJson);
  if (existing != null && existing > 0) return existing;

  final label = siteName.trim().isEmpty ? 'Site' : siteName.trim();
  final meta = jsonEncode({
    'active': false,
    'parent_site_iid': siteIid,
    'source': 'site_assistant',
  });
  final res = await conn.identityPut(
    ReqIdentityPut(
      iid: Int64.ZERO,
      kind: 'bot',
      type: 'chat',
      name: '$label AI',
      metaJson: meta,
    ),
  );
  if (!res.hasRow() || !res.row.hasIdentity()) {
    throw 'Could not create site assistant bot';
  }
  final botIid = res.row.identity.iid.toInt();
  final caps = _capabilitiesMap(config.capabilitiesJson);
  caps[_assistantBotCapKey] = botIid;
  await api.configPut(siteIid, capabilitiesJson: jsonEncode(caps));
  return botIid;
}

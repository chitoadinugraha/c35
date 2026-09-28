import 'dart:convert';

import 'package:alienai_c35/c/chat/chat_conn.dart';
import 'package:alienai_c35/c/pb/c35/chat.pb.dart';
import 'package:alienai_c35/c/pb/c35/identity.pb.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<ResIdentityPut> identityPut(ChatConn conn, ReqIdentityPut req) => conn.identityPut(req);

Future<ResIdentityList> identityList(ChatConn conn, List<String> kinds, {bool includeArchived = false}) =>
    conn.identityList(kinds, includeArchived: includeArchived);

Future<ResIdentityGrantPatch> identityGrantPatch(ChatConn conn, ReqIdentityGrantPatch req) => conn.identityGrantPatch(req);

Future<void> identityDelete(ChatConn conn, int iid) async {
  final res = await conn.identityDelete(iid);
  if (!res.ok) throw res.error.isNotEmpty ? res.error : 'Delete failed';
}

Future<ResBotPeerList> botPeerList(ChatConn conn, int botIid, {bool includeArchived = false, int limit = 100}) =>
    conn.botPeerList(botIid, includeArchived: includeArchived, limit: limit);

Future<ResChatStop> chatStop(ChatConn conn, int chatId, bool stopped) => conn.chatStop(chatId, stopped);

Future<ResChatSend> chatSend(ChatConn conn, int chatId, String text, {String attachmentsJson = '[]'}) =>
    conn.chatSend(chatId, text, attachmentsJson: attachmentsJson);

Future<ResBotPeerCreate> botPeerCreate(ChatConn conn, int botIid, {String title = ''}) =>
    conn.botPeerCreate(botIid, title: title);

Future<ResBotPeerAppSend> botPeerAppSend(ChatConn conn, int chatId, String text, {String attachmentsJson = '[]'}) =>
    conn.botPeerAppSend(chatId, text, attachmentsJson: attachmentsJson);

Future<ResBotPeerDelete> botPeerDelete(ChatConn conn, int chatId) => conn.botPeerDelete(chatId);

String _botListCacheKey(int ownerUid) => 'c35.bot.list.v1.$ownerUid';

Future<void> botListCacheClear(int ownerUid) async {
  if (ownerUid <= 0) return;
  final p = await SharedPreferences.getInstance();
  await p.remove(_botListCacheKey(ownerUid));
}

Future<List<IdentityListRow>> botListCacheRestore(int ownerUid) async {
  if (ownerUid <= 0) return [];
  final p = await SharedPreferences.getInstance();
  final raw = p.getString(_botListCacheKey(ownerUid));
  if (raw == null || raw.isEmpty) return [];
  try {
    return List<IdentityListRow>.from(ResIdentityList.fromBuffer(base64Decode(raw)).rows);
  } catch (_) {
    return [];
  }
}

Future<void> botListCacheSave(int ownerUid, List<IdentityListRow> rows) async {
  if (ownerUid <= 0) return;
  final p = await SharedPreferences.getInstance();
  await p.setString(_botListCacheKey(ownerUid), base64Encode(ResIdentityList(rows: rows).writeToBuffer()));
}

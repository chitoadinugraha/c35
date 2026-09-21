import 'package:alienai_c35/c/chat/chat_conn.dart';
import 'package:alienai_c35/c/pb/c35/chat.pb.dart';
import 'package:alienai_c35/c/pb/c35/identity.pb.dart';

Future<ResIdentityPut> identityPut(ChatConn conn, ReqIdentityPut req) => conn.identityPut(req);

Future<ResBotPeerList> botPeerList(ChatConn conn, int botIid, {bool includeArchived = false, int limit = 100}) =>
    conn.botPeerList(botIid, includeArchived: includeArchived, limit: limit);

Future<ResChatStop> chatStop(ChatConn conn, int chatId, bool stopped) => conn.chatStop(chatId, stopped);

Future<ResChatSend> chatSend(ChatConn conn, int chatId, String text, {String attachmentsJson = '[]'}) =>
    conn.chatSend(chatId, text, attachmentsJson: attachmentsJson);

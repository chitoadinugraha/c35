import 'dart:async';

import 'package:alienai_c35/c/api/referral_conn.dart';
import 'package:alienai_c35/c/chat/chat_conn.dart';
import 'package:alienai_c35/c/pb/c35/channel.pb.dart';
import 'package:alienai_c35/c/pb/c35/wire.pb.dart';
import 'package:alienai_c35/widgets/bots/io_channel_telegram_connect.dart';
import 'package:alienai_c35/widgets/bots/io_channel_whatsapp_meta_connect.dart';
import 'package:alienai_c35/widgets/bots/io_channel_whatsapp_pair.dart';
import 'package:fixnum/fixnum.dart';
import 'package:uuid/uuid.dart';

Stream<ChannelPairPush> onChannelPairPush(ChatConn conn) => conn.onChannelPairPush;

Future<ResChannelTelegramConnect> telegramConnect(ChatConn conn, ReqChannelTelegramConnect req) async {
  final res = await conn.invoke(InvokeReq(reqId: const Uuid().v4(), channelTelegramConnect: req));
  invokeResThrow(res, fallback: 'Telegram connect failed');
  if (!res.hasChannelTelegramConnect()) throw 'No telegram connect data';
  return res.channelTelegramConnect;
}

Future<ResChannelWhatsappMetaConnect> whatsappMetaConnect(ChatConn conn, ReqChannelWhatsappMetaConnect req) async {
  final res = await conn.invoke(InvokeReq(reqId: const Uuid().v4(), channelWhatsappMetaConnect: req));
  invokeResThrow(res, fallback: 'WhatsApp connect failed');
  if (!res.hasChannelWhatsappMetaConnect()) throw 'No WhatsApp connect data';
  return res.channelWhatsappMetaConnect;
}

Future<ResChannelWhatsappPair> whatsappPairStart(ChatConn conn, int botIid, {String channelId = ''}) async {
  final res = await conn.channelWhatsappPairStart(botIid, channelId: channelId);
  if (!res.ok) throw res.error.isNotEmpty ? res.error : 'Pair start failed';
  return res;
}

Future<ResChannelWhatsappPair> whatsappPairWatch(ChatConn conn, int botIid, String channelId) async {
  final res = await conn.channelWhatsappPairWatch(botIid, channelId);
  if (!res.ok) throw res.error.isNotEmpty ? res.error : 'Pair watch failed';
  return res;
}

Future<void> whatsappPairAbort(ChatConn conn, int botIid, String channelId) async {
  final res = await conn.channelWhatsappPairAbort(botIid, channelId);
  if (!res.ok) throw res.error.isNotEmpty ? res.error : 'Pair abort failed';
}

ChannelTelegramConnectFn channelTelegramConnectFn(ChatConn conn) =>
    ({required int botIid, required String botToken, ChannelConnectLogCallback? onLog}) async {
      onLog?.call(line: 'Connecting to Telegram…', step: 1, total: 2, done: false, ok: true);
      try {
        final res = await telegramConnect(conn, ReqChannelTelegramConnect(botIid: Int64(botIid), botToken: botToken));
        onLog?.call(line: 'Connected', step: 2, total: 2, done: true, ok: true);
        return res.channel;
      } catch (e) {
        onLog?.call(line: '$e', step: 2, total: 2, done: true, ok: false);
        rethrow;
      }
    };

ChannelWhatsappMetaConnectFn channelWhatsappMetaConnectFn(ChatConn conn) =>
    ({required int botIid, required String accessToken, required String phoneNumberId, String wabaId = '', String verifyToken = '', ChannelConnectLogCallback? onLog}) async {
      onLog?.call(line: 'Connecting to WhatsApp Cloud…', step: 1, total: 2, done: false, ok: true);
      try {
        final res = await whatsappMetaConnect(
          conn,
          ReqChannelWhatsappMetaConnect(botIid: Int64(botIid), accessToken: accessToken, phoneNumberId: phoneNumberId),
        );
        onLog?.call(line: 'Connected', step: 2, total: 2, done: true, ok: true);
        return ChannelWhatsappMetaConnectResult(channel: res.channel, webhookUrl: res.webhookUrl, verifyToken: res.verifyToken);
      } catch (e) {
        onLog?.call(line: '$e', step: 2, total: 2, done: true, ok: false);
        rethrow;
      }
    };

ChannelWhatsappPairStartFn channelWhatsappPairStartFn(ChatConn conn) =>
    ({required int botIid, String channelId = '', void Function(ChannelPairPush push)? onUpdate}) async {
      StreamSubscription<ChannelPairPush>? sub;
      var watchId = channelId;
      if (onUpdate != null) {
        sub = conn.onChannelPairPush.listen((push) {
          if (push.botIid.toInt() != botIid) return;
          if (watchId.isNotEmpty && push.channelId != watchId) return;
          onUpdate(push);
          if (push.status == 'connected' || push.status == 'error' || push.status == 'disconnected') {
            unawaited(sub?.cancel());
          }
        });
      }
      try {
        final res = await whatsappPairStart(conn, botIid, channelId: channelId);
        if (res.channel.id.isNotEmpty) watchId = res.channel.id;
        return res;
      } catch (e) {
        await sub?.cancel();
        rethrow;
      }
    };

ChannelWhatsappPairWatchFn channelWhatsappPairWatchFn(ChatConn conn) =>
    ({required int botIid, required String channelId}) => whatsappPairWatch(conn, botIid, channelId).then((_) {});

ChannelWhatsappPairAbortFn channelWhatsappPairAbortFn(ChatConn conn) =>
    ({required int botIid, required String channelId}) => whatsappPairAbort(conn, botIid, channelId);

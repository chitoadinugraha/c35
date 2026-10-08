import 'dart:convert';

import 'package:alienai_c35/c/pb/c35/tx.pb.dart';
import 'package:alienai_c35/c/session.dart';
import 'package:alienai_c35/c/snowflake.dart';
import 'package:alienai_c35/c/ui/ui_friendly_error.dart';
import 'package:alienai_c35/widgets/sites/tx/tx_api.dart';
import 'package:fixnum/fixnum.dart';
import 'package:shared_preferences/shared_preferences.dart';

String _queueKey(int siteIid) => 'c35_tx_offline_queue_${Session.instance.uid}_$siteIid';

class TxOfflineQueue {
  static Future<void> txEnsureClientTxId(Tx tx) async {
    if (tx.txId > Int64.ZERO) return;
    tx.txId = Int64(await snowflakeIdNext());
  }

  static Future<List<Tx>> listPending(int siteIid) async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(_queueKey(siteIid));
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list.map((e) => Tx.fromBuffer(base64Decode(e as String))).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> enqueue(int siteIid, Tx tx) async {
    await txEnsureClientTxId(tx);
    final pending = await listPending(siteIid);
    final id = tx.txId;
    final next = [...pending.where((t) => t.txId != id), tx];
    final p = await SharedPreferences.getInstance();
    final encoded = next.map((t) => base64Encode(t.writeToBuffer())).toList();
    await p.setString(_queueKey(siteIid), jsonEncode(encoded));
  }

  static Future<void> remove(int siteIid, Int64 txId) async {
    final pending = await listPending(siteIid);
    final next = pending.where((t) => t.txId != txId).toList();
    final p = await SharedPreferences.getInstance();
    if (next.isEmpty) {
      await p.remove(_queueKey(siteIid));
      return;
    }
    final encoded = next.map((t) => base64Encode(t.writeToBuffer())).toList();
    await p.setString(_queueKey(siteIid), jsonEncode(encoded));
  }

  static Future<int> pendingCount(int siteIid) async => (await listPending(siteIid)).length;

  /// Upload queued sales with stable [Tx.txId]. Returns count synced; stops on first hard error.
  static Future<int> syncSite(TxApi api, int siteIid) async {
    var synced = 0;
    while (true) {
      final pending = await listPending(siteIid);
      if (pending.isEmpty) return synced;
      final tx = pending.first;
      try {
        await api.put(tx.clone()..siteIid = Int64(siteIid));
        await remove(siteIid, tx.txId);
        synced++;
      } catch (e) {
        if (uiIsConnectionError(e.toString())) return synced;
        rethrow;
      }
    }
  }
}

bool txSaveShouldQueueOffline({required bool connected, Object? putError}) {
  if (!connected) return true;
  if (putError == null) return false;
  return uiIsConnectionError(putError.toString());
}

import 'package:alienai_c35/c/chat/chat_conn.dart';
import 'package:alienai_c35/c/pb/c35/tx.pb.dart';
import 'package:alienai_c35/c/site/tx_format.dart';
import 'package:alienai_c35/widgets/sites/tx/tx_offline_queue.dart';
import 'package:fixnum/fixnum.dart';

class TxApi {
  TxApi(this.conn);

  final ChatConn conn;

  Future<Tx> get(int siteIid, Int64 txId) async {
    final res = await conn.txGet(siteIid, txId);
    if (!res.hasTx()) throw 'transaction not found';
    return res.tx;
  }

  Future<List<Tx>> list(int siteIid, {String q = '', int limit = 100}) async {
    final res = await conn.txList(siteIid, q: q, limit: limit);
    return res.txs;
  }

  Future<Tx> put(Tx tx) async {
    final res = await conn.txPut(tx);
    if (!res.hasTx()) throw 'transaction save failed';
    return res.tx;
  }

  Future<ResTxPreview> preview(Tx tx) => conn.txPreview(tx);

  bool get isConnected => conn.status.value == ChatConnStatus.connected;

  Future<Tx> putSale(int siteIid, Tx tx, {bool queueOffline = true}) async {
    final payload = txEnsureCashPayment(tx.clone()..siteIid = Int64(siteIid));
    final err = txValidateSale(payload);
    if (err != null) throw err;
    if (!isConnected && queueOffline) return _putSaleOffline(siteIid, payload);
    try {
      return await put(payload);
    } catch (e) {
      if (queueOffline && txSaveShouldQueueOffline(connected: isConnected, putError: e)) {
        return _putSaleOffline(siteIid, payload);
      }
      rethrow;
    }
  }

  Future<Tx> _putSaleOffline(int siteIid, Tx payload) async {
    await TxOfflineQueue.enqueue(siteIid, payload);
    return payload;
  }

  Future<int> syncOfflineQueue(int siteIid) => TxOfflineQueue.syncSite(this, siteIid);

  Future<int> offlinePendingCount(int siteIid) => TxOfflineQueue.pendingCount(siteIid);

  Tx newSale(int siteIid) => txNewSale(siteIid);
}

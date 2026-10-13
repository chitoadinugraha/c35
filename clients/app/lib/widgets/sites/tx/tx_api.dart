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

  Future<Tx> getFull(int siteIid, Int64 txId) => get(siteIid, txId);

  Future<List<Tx>> list(int siteIid, {String q = '', int limit = 100}) async {
    final res = await conn.txList(siteIid, q: q, limit: limit);
    return res.txs;
  }

  /// Open sales for POS queue panels (headers only; use [get] for line items).
  Future<List<Tx>> listSales(
    int siteIid, {
    TxState? state,
    bool openOnly = false,
    int limit = 100,
  }) async {
    final res = await conn.txList(
      siteIid,
      limit: limit,
      type: TxType.TX_TYPE_SALE,
      state: state,
      openOnly: state == null ? openOnly : false,
    );
    return res.txs;
  }

  Future<Tx> put(Tx tx) async {
    final res = await conn.txPut(tx);
    if (!res.hasTx()) throw 'transaction save failed';
    return res.tx;
  }

  Future<Tx> updateState(
    int siteIid,
    Tx tx,
    TxState newState, {
    bool? isPaid,
    bool? isTaskAssigned,
    String? cancelReason,
  }) async {
    final payload = tx.clone()..siteIid = Int64(siteIid);
    payload.state = newState;
    if (isPaid != null) payload.isPaid = isPaid;
    if (isTaskAssigned != null) payload.isTaskAssigned = isTaskAssigned;
    if (cancelReason != null) payload.cancelReason = cancelReason;
    return put(payload);
  }

  Future<Tx> markOrderDone(int siteIid, Tx tx) async {
    final payload = tx.clone()..siteIid = Int64(siteIid);
    payload.state = TxState.TX_STATE_OK;
    for (final item in payload.items) {
      item.fulfillmentState = TxItemFulfillmentState.TX_ITEM_FULFILLMENT_DONE;
    }
    return put(payload);
  }

  /// Payment verified; cashier-only sites skip the `pending` kitchen stop.
  Future<Tx> completePaidSale(int siteIid, Tx tx) async {
    final payload = tx.clone()..siteIid = Int64(siteIid);
    payload.state = TxState.TX_STATE_OK;
    payload.isPaid = true;
    for (final item in payload.items) {
      item.fulfillmentState = TxItemFulfillmentState.TX_ITEM_FULFILLMENT_DONE;
    }
    return put(payload);
  }

  Future<ResTxPreview> preview(Tx tx) => conn.txPreview(tx);

  bool get isConnected => conn.status.value == ChatConnStatus.connected;

  Future<Tx> putSale(int siteIid, Tx tx, {bool queueOffline = true}) async {
    final payload = txEnsureCashPayment(tx.clone()..siteIid = Int64(siteIid));
    await TxOfflineQueue.txEnsureClientTxId(payload);
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

  /// New sale with a stable client [Tx.txId] for draft receipts and offline sync.
  Future<Tx> newSale(int siteIid) async {
    final tx = txNewSale(siteIid);
    await TxOfflineQueue.txEnsureClientTxId(tx);
    return tx;
  }
}

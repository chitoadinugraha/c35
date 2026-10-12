import 'package:alienai_c35/c/pb/c35/tx.pb.dart';
import 'package:alienai_c35/widgets/sites/tx/pos_queue/pos_queue_mode.dart';
import 'package:alienai_c35/widgets/sites/tx/pos_queue/tx_queue_helpers.dart';
import 'package:alienai_c35/widgets/sites/tx/tx_api.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flutter/foundation.dart';

class PosQueueStore extends ChangeNotifier {
  PosQueueStore({
    required this.txApi,
    required this.siteIid,
    PosQueueMode initialMode = PosQueueMode.paymentVerification,
  }) : mode = initialMode;

  final TxApi txApi;
  final int siteIid;

  PosQueueMode mode;

  int paymentCount = 0;
  int orderCount = 0;
  bool busy = false;
  String? error;

  final List<Tx> _rows = <Tx>[];
  Tx? selected;
  Tx? detail;

  List<Tx> get rows => List<Tx>.unmodifiable(_rows);

  Future<void> refreshCounts() async {
    try {
      final sales = await txApi.listSales(siteIid, limit: 200);
      paymentCount = sales.where(txQueueIsPaymentVerification).length;
      orderCount = sales.where(txQueueIsOpenOrder).length;
      error = null;
    } catch (e) {
      error = e.toString();
    }
    notifyListeners();
  }

  Future<void> listFor(PosQueueMode queueMode) async {
    mode = queueMode;
    busy = true;
    selected = null;
    detail = null;
    error = null;
    notifyListeners();
    try {
      final sales = await txApi.listSales(siteIid, limit: 200);
      _rows
        ..clear()
        ..addAll(sales.where((t) => txQueueMatchesMode(t, queueMode)));
      _rows.sort((a, b) => b.txId.compareTo(a.txId));
      paymentCount = sales.where(txQueueIsPaymentVerification).length;
      orderCount = sales.where(txQueueIsOpenOrder).length;
    } catch (e) {
      _rows.clear();
      error = e.toString();
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<void> loadDetail(Int64 txId) async {
    busy = true;
    error = null;
    notifyListeners();
    try {
      detail = await txApi.get(siteIid, txId);
      selected = detail;
    } catch (e) {
      detail = null;
      error = e.toString();
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  void clearSelection() {
    selected = null;
    detail = null;
    notifyListeners();
  }

  Future<Tx?> confirmPayment(Int64 txId) async {
    final base = detail?.txId == txId ? detail! : await txApi.get(siteIid, txId);
    busy = true;
    notifyListeners();
    try {
      final tx = await txApi.updateState(
        siteIid,
        base,
        TxState.TX_STATE_PENDING,
        isPaid: true,
      );
      await _afterMutation(txId, tx);
      return tx;
    } catch (e) {
      error = e.toString();
      return null;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<Tx?> declinePayment(Int64 txId, {String? reason}) async {
    final base = detail?.txId == txId ? detail! : await txApi.get(siteIid, txId);
    busy = true;
    notifyListeners();
    try {
      final tx = await txApi.updateState(
        siteIid,
        base,
        TxState.TX_STATE_CANCELLED,
        cancelReason: reason?.trim().isNotEmpty == true ? reason!.trim() : null,
      );
      await _afterMutation(txId, tx);
      return tx;
    } catch (e) {
      error = e.toString();
      return null;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<Tx?> takeOrder(Int64 txId) async {
    final base = detail?.txId == txId ? detail! : await txApi.get(siteIid, txId);
    busy = true;
    notifyListeners();
    try {
            final current = base.state;
      final tx = await txApi.updateState(
        siteIid,
        base,
        current,
        isTaskAssigned: true,
      );
      await _afterMutation(txId, tx);
      return tx;
    } catch (e) {
      error = e.toString();
      return null;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<Tx?> markOrderDone(Int64 txId) async {
    final base = detail?.txId == txId ? detail! : await txApi.get(siteIid, txId);
    busy = true;
    notifyListeners();
    try {
      final tx = await txApi.markOrderDone(siteIid, base);
      await _afterMutation(txId, tx);
      return tx;
    } catch (e) {
      error = e.toString();
      return null;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<void> _afterMutation(Int64 txId, Tx tx) async {
    _rows.removeWhere((t) => t.txId == txId);
    if (txQueueMatchesMode(tx, mode)) {
      _rows.insert(0, tx);
      selected = tx;
      detail = tx;
    } else {
      selected = null;
      detail = null;
    }
    await refreshCounts();
  }
}

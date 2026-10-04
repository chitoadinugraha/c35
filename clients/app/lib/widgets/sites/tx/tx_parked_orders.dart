import 'package:alienai_c35/c/pb/c35/tx.pb.dart';
import 'package:alienai_c35/c/site/tx_format.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

/// Representation of a parked (held) transaction cart.
class ParkedTx {
  ParkedTx({
    required this.id,
    required this.note,
    required this.timestamp,
    required this.tx,
    int? itemCount,
    Int64? totalAmount,
  })  : itemCount = itemCount ??
            tx.items.fold(0, (sum, it) => sum + (it.qty > 0 ? it.qty : 1)),
        totalAmount = totalAmount ?? txItemsNominal(tx);

  final String id;
  final String note;
  final DateTime timestamp;
  final Tx tx;
  final int itemCount;
  final Int64 totalAmount;
}

/// In-memory state manager for parked orders per [siteIid].
class TxParkedOrders extends ChangeNotifier {
  TxParkedOrders._();

  /// Singleton instance.
  static final TxParkedOrders instance = TxParkedOrders._();

  final Map<int, List<ParkedTx>> _orders = {};

  /// Returns unmodifiable list of parked transactions for [siteIid], newest first.
  List<ParkedTx> list(int siteIid) =>
      List.unmodifiable(_orders[siteIid] ?? const []);

  /// Returns the number of parked transactions for [siteIid].
  int count(int siteIid) => _orders[siteIid]?.length ?? 0;

  /// Holds [tx] for [siteIid] with an optional descriptive [note].
  ParkedTx add(int siteIid, Tx tx, {String? note}) {
    final orders = _orders.putIfAbsent(siteIid, () => <ParkedTx>[]);
    final trimmed = note?.trim();
    final defaultNote = 'Order #${orders.length + 1}';
    final parked = ParkedTx(
      id: const Uuid().v4(),
      note: (trimmed != null && trimmed.isNotEmpty) ? trimmed : defaultNote,
      timestamp: DateTime.now(),
      tx: tx.clone(),
    );
    orders.insert(0, parked);
    notifyListeners();
    return parked;
  }

  /// Restores a previously removed [order] back into [siteIid]'s parked list.
  void restore(int siteIid, ParkedTx order) {
    final orders = _orders.putIfAbsent(siteIid, () => <ParkedTx>[]);
    if (!orders.any((o) => o.id == order.id)) {
      orders.insert(0, order);
      notifyListeners();
    }
  }

  /// Removes and returns the parked transaction matching [id] for [siteIid].
  ParkedTx? remove(int siteIid, String id) {
    final orders = _orders[siteIid];
    if (orders == null) return null;
    final idx = orders.indexWhere((o) => o.id == id);
    if (idx != -1) {
      final removed = orders.removeAt(idx);
      notifyListeners();
      return removed;
    }
    return null;
  }

  /// Clears all parked transactions for [siteIid].
  void clear(int siteIid) {
    final orders = _orders[siteIid];
    if (orders != null && orders.isNotEmpty) {
      orders.clear();
      notifyListeners();
    }
  }
}

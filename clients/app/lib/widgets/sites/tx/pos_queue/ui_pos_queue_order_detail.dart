import 'package:alienai_c35/c/pb/c35/site.pb.dart';
import 'package:alienai_c35/c/pb/c35/tx.pb.dart';
import 'package:alienai_c35/c/ui/money_format.dart';
import 'package:alienai_c35/widgets/sites/tx/pos_queue/pos_queue_store.dart';
import 'package:alienai_c35/widgets/sites/tx/pos_queue/tx_queue_helpers.dart';
import 'package:alienai_c35/widgets/sites/tx/ui_site_product_thumb.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flutter/material.dart';

const _border = Color(0xFF27272A);
const _muted = Color(0xFF71717A);
const _text = Color(0xFFF4F4F5);
const _accent = Color(0xFF34D399);
const _amber = Color(0xFFF59E0B);

class UiPosQueueOrderDetail extends StatelessWidget {
  const UiPosQueueOrderDetail({
    super.key,
    required this.store,
    required this.tx,
    this.products = const [],
  });

  final PosQueueStore store;
  final Tx tx;
  final List<SiteProduct> products;

  SiteProduct? _productFor(TxItem item) {
    final id = item.productId.toInt();
    if (id <= 0) return null;
    for (final p in products) {
      if (p.productId.toInt() == id) return p;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final placed = txQueuePlacedAt(tx);
    final taken = tx.isTaskAssigned;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            children: [
              Text(
                '#${tx.txId} · ${txQueueCustomerLabel(tx)}',
                style: const TextStyle(color: _text, fontSize: 16, fontWeight: FontWeight.w600),
              ),
              if (placed != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(txQueueFormatTimeAgo(placed), style: const TextStyle(color: _muted, fontSize: 12)),
                ),
              if (taken)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: _amber.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: _amber.withValues(alpha: 0.4)),
                    ),
                    child: const Text('In progress', style: TextStyle(color: _amber, fontSize: 12)),
                  ),
                ),
              const SizedBox(height: 16),
              for (final item in tx.items) _line(item),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Total ${moneyFmtIdr(tx.total.toInt())}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: _muted, fontSize: 13),
              ),
              const SizedBox(height: 10),
              if (!taken)
                OutlinedButton(
                  onPressed: store.busy ? null : () => store.takeOrder(tx.txId),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _text,
                    side: const BorderSide(color: _border),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Take order'),
                ),
              if (!taken) const SizedBox(height: 8),
              FilledButton(
                onPressed: store.busy ? null : () => store.markOrderDone(tx.txId),
                style: FilledButton.styleFrom(
                  backgroundColor: _accent,
                  foregroundColor: const Color(0xFF052E1B),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: store.busy
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF052E1B)),
                      )
                    : const Text('Mark done'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _line(TxItem item) {
    final product = _productFor(item);
    final name = product?.name ?? 'Item ';
    final lineTotal = (item.totalNet > Int64.ZERO ? item.totalNet : item.totalPrice).toInt();
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          product != null
              ? UiSiteProductThumb(product: product, size: 48)
              : Container(
                  width: 48,
                  height: 48,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFF18181B),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _border),
                  ),
                  child: const Icon(Icons.restaurant, color: _muted, size: 22),
                ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(color: _text, fontSize: 14)),
                Text(
                  '${item.qty} × ${moneyFmtIdr(item.price.toInt())}',
                  style: const TextStyle(color: _muted, fontSize: 12),
                ),
              ],
            ),
          ),
          Text(moneyFmtIdr(lineTotal), style: const TextStyle(color: _text, fontSize: 14)),
        ],
      ),
    );
  }
}

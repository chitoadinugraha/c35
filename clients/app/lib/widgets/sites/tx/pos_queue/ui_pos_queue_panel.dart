import 'package:alienai_c35/c/pb/c35/site.pb.dart';
import 'package:alienai_c35/c/pb/c35/tx.pb.dart';
import 'package:alienai_c35/c/ui/money_format.dart';
import 'package:alienai_c35/widgets/sites/tx/pos_queue/page_pos_queue_desk.dart';
import 'package:alienai_c35/widgets/sites/tx/pos_queue/pos_queue_mode.dart';
import 'package:alienai_c35/widgets/sites/tx/pos_queue/pos_queue_store.dart';
import 'package:alienai_c35/widgets/sites/tx/pos_queue/tx_queue_helpers.dart';
import 'package:alienai_c35/widgets/sites/tx/pos_queue/ui_pos_queue_order_detail.dart';
import 'package:alienai_c35/widgets/sites/tx/pos_queue/ui_pos_queue_payment_detail.dart';
import 'package:alienai_c35/widgets/sites/tx/tx_api.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flutter/material.dart';

const _border = Color(0xFF27272A);
const _muted = Color(0xFF71717A);
const _text = Color(0xFFF4F4F5);
const _accent = Color(0xFF34D399);
const _amber = Color(0xFFF59E0B);

class UiPosQueuePanel extends StatefulWidget {
  const UiPosQueuePanel({
    super.key,
    required this.mode,
    required this.txApi,
    required this.siteIid,
    this.products = const [],
    this.expanded = false,
    this.onClose,
    this.store,
  });

  final PosQueueMode mode;
  final TxApi txApi;
  final int siteIid;
  final List<SiteProduct> products;
  final bool expanded;
  final VoidCallback? onClose;
  final PosQueueStore? store;

  @override
  State<UiPosQueuePanel> createState() => _UiPosQueuePanelState();
}

class _UiPosQueuePanelState extends State<UiPosQueuePanel> {
  late final PosQueueStore _store;
  var _ownsStore = false;

  @override
  void initState() {
    super.initState();
    if (widget.store != null) {
      _store = widget.store!;
    } else {
      _ownsStore = true;
      _store = PosQueueStore(txApi: widget.txApi, siteIid: widget.siteIid, initialMode: widget.mode);
    }
    _store.listFor(widget.mode);
    _store.addListener(_onStore);
  }

  @override
  void dispose() {
    _store.removeListener(_onStore);
    if (_ownsStore) _store.dispose();
    super.dispose();
  }

  void _onStore() {
    if (mounted) setState(() {});
  }

  String get _title => switch (widget.mode) {
        PosQueueMode.paymentVerification => 'Payment verification',
        PosQueueMode.orders => 'Orders',
      };

  IconData get _icon => switch (widget.mode) {
        PosQueueMode.paymentVerification => Icons.verified_outlined,
        PosQueueMode.orders => Icons.restaurant_menu_outlined,
      };

  Color get _iconColor => switch (widget.mode) {
        PosQueueMode.paymentVerification => _accent,
        PosQueueMode.orders => _amber,
      };

  int get _count => switch (widget.mode) {
        PosQueueMode.paymentVerification => _store.paymentCount,
        PosQueueMode.orders => _store.orderCount,
      };

  void _maximize() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PagePosQueueDesk(
          mode: widget.mode,
          txApi: widget.txApi,
          siteIid: widget.siteIid,
          products: widget.products,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final showingDetail = _store.detail != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _header(showingDetail),
        if (_store.error != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(_store.error!, style: const TextStyle(color: Colors.redAccent, fontSize: 12)),
          ),
        Expanded(
          child: showingDetail
              ? _detailBody(_store.detail!)
              : _listBody(),
        ),
      ],
    );
  }

  Widget _header(bool showingDetail) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 8, 8),
      child: Row(
        children: [
          if (showingDetail)
            IconButton(
              icon: const Icon(Icons.arrow_back, color: _muted, size: 20),
              onPressed: _store.clearSelection,
              visualDensity: VisualDensity.compact,
            )
          else
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _iconColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _iconColor.withValues(alpha: 0.35)),
              ),
              child: Icon(_icon, size: 20, color: _iconColor),
            ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              showingDetail ? 'Order #${_store.detail!.txId}' : '$_title ($_count)',
              style: const TextStyle(color: _text, fontSize: 16, fontWeight: FontWeight.w600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (!widget.expanded)
            IconButton(
              tooltip: 'Maximize',
              icon: const Icon(Icons.open_in_full, size: 20, color: _muted),
              onPressed: _maximize,
              visualDensity: VisualDensity.compact,
            ),
          if (widget.onClose != null)
            IconButton(
              icon: const Icon(Icons.close, size: 20, color: _muted),
              onPressed: widget.onClose,
              visualDensity: VisualDensity.compact,
            ),
        ],
      ),
    );
  }

  Widget _listBody() {
    if (_store.busy && _store.rows.isEmpty) {
      return const Center(child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2)));
    }
    if (_store.rows.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inbox_outlined, size: 48, color: _muted.withValues(alpha: 0.5)),
            const SizedBox(height: 12),
            Text('No open ${_title.toLowerCase()}', style: const TextStyle(color: _muted, fontSize: 14)),
          ],
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      itemCount: _store.rows.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final tx = _store.rows[i];
        return _QueueRow(
          tx: tx,
          mode: widget.mode,
          onTap: () => _store.loadDetail(tx.txId),
        );
      },
    );
  }

  Widget _detailBody(Tx tx) {
    return switch (widget.mode) {
      PosQueueMode.paymentVerification => UiPosQueuePaymentDetail(store: _store, tx: tx),
      PosQueueMode.orders => UiPosQueueOrderDetail(store: _store, tx: tx, products: widget.products),
    };
  }
}

class _QueueRow extends StatelessWidget {
  const _QueueRow({required this.tx, required this.mode, required this.onTap});

  final Tx tx;
  final PosQueueMode mode;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final total = tx.total > Int64.ZERO ? tx.total : tx.itemsTotal;
    final time = txQueuePlacedAt(tx);
    return Material(
      color: const Color(0xFF18181B),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: _border),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      txQueueCustomerLabel(tx),
                      style: const TextStyle(color: _text, fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '#${tx.txId}${time != null ? ' · ${txQueueFormatTimeAgo(time)}' : ''}',
                      style: const TextStyle(color: _muted, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Text(moneyFmtIdr(total.toInt()), style: const TextStyle(color: _accent, fontSize: 14, fontWeight: FontWeight.w600)),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right, color: _muted, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

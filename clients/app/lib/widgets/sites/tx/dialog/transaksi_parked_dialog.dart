import 'package:alienai_c35/c/ui/money_format.dart';
import 'package:alienai_c35/widgets/sites/tx/tx_parked_orders.dart';
import 'package:flutter/material.dart';

const _border = Color(0xFF27272A);
const _muted = Color(0xFF71717A);
const _text = Color(0xFFF4F4F5);
const _accent = Color(0xFF34D399);
const _amber = Color(0xFFF59E0B);

/// Displays a modal bottom sheet listing all parked orders for [siteIid].
///
/// Returns the [ParkedTx] if the cashier recalled an order, or `null` if closed.
Future<ParkedTx?> showTransaksiParkedDialog({
  required BuildContext context,
  required int siteIid,
}) =>
    showModalBottomSheet<ParkedTx>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF121215),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        side: BorderSide(color: _border),
      ),
      builder: (ctx) => _SheetParkedOrders(siteIid: siteIid),
    );

String formatTimeAgo(DateTime dateTime) {
  final diff = DateTime.now().difference(dateTime);
  if (diff.inSeconds < 45) {
    return 'Just now';
  } else if (diff.inMinutes < 60) {
    final mins = diff.inMinutes;
    return '$mins min${mins == 1 ? '' : 's'} ago';
  } else if (diff.inHours < 24) {
    final hrs = diff.inHours;
    return '$hrs hour${hrs == 1 ? '' : 's'} ago';
  } else {
    final days = diff.inDays;
    return '$days day${days == 1 ? '' : 's'} ago';
  }
}

class _SheetParkedOrders extends StatelessWidget {
  const _SheetParkedOrders({required this.siteIid});

  final int siteIid;

  Future<void> _confirmClearAll(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF18181B),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: _border),
        ),
        title: const Text('Clear all parked orders?', style: TextStyle(color: _text)),
        content: const Text(
          'All held carts for this site will be permanently discarded.',
          style: TextStyle(color: _muted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel', style: TextStyle(color: _muted)),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
            ),
            child: const Text('Clear all'),
          ),
        ],
      ),
    );
    if (ok == true) {
      TxParkedOrders.instance.clear(siteIid);
    }
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final maxHeight = media.size.height * 0.8;

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: SafeArea(
        child: ListenableBuilder(
          listenable: TxParkedOrders.instance,
          builder: (context, _) {
            final orders = TxParkedOrders.instance.list(siteIid);

            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Handle bar
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: _border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),

                  // Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: _amber.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.pause_circle_outline, size: 20, color: _amber),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Parked Orders (${orders.length})',
                        style: const TextStyle(
                          color: _text,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      if (orders.length > 1) ...[
                        TextButton(
                          onPressed: () => _confirmClearAll(context),
                          style: TextButton.styleFrom(
                            foregroundColor: _muted,
                            visualDensity: VisualDensity.compact,
                          ),
                          child: const Text('Clear all', style: TextStyle(fontSize: 12)),
                        ),
                        const SizedBox(width: 4),
                      ],
                      IconButton(
                        icon: const Icon(Icons.close, size: 20, color: _muted),
                        onPressed: () => Navigator.of(context).pop(),
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Orders list or Empty view
                  if (orders.isEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inbox_outlined, size: 48, color: _muted.withValues(alpha: 0.5)),
                          const SizedBox(height: 12),
                          const Text(
                            'No parked orders',
                            style: TextStyle(color: _text, fontSize: 15, fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Hold unfinished carts to serve another customer and recall them here.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: _muted, fontSize: 13),
                          ),
                        ],
                      ),
                    )
                  else
                    Flexible(
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: orders.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (ctx, index) {
                          final order = orders[index];
                          return _ParkedOrderTile(
                            order: order,
                            onRecall: () {
                              final recalled = TxParkedOrders.instance.remove(siteIid, order.id);
                              Navigator.of(context).pop(recalled ?? order);
                            },
                            onDelete: () {
                              TxParkedOrders.instance.remove(siteIid, order.id);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Discarded "${order.note}"'),
                                  duration: const Duration(seconds: 2),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ParkedOrderTile extends StatelessWidget {
  const _ParkedOrderTile({
    required this.order,
    required this.onRecall,
    required this.onDelete,
  });

  final ParkedTx order;
  final VoidCallback onRecall;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final itemsSummary = order.tx.items
        .map((i) => '${i.qty > 0 ? i.qty.toInt() : 1}x ${i.note.isNotEmpty ? i.note : "Item #${i.productId}"}')
        .take(3)
        .join(', ');

    return Dismissible(
      key: ValueKey(order.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: const Color(0xFFEF4444).withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.delete_outline, color: Colors.white, size: 20),
            SizedBox(width: 6),
            Text(
              'Discard',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ],
        ),
      ),
      onDismissed: (_) => onDelete(),
      child: Material(
        color: const Color(0xFF18181B),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: _border),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onRecall,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _amber.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.receipt_long_outlined, size: 20, color: _amber),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.note,
                        style: const TextStyle(
                          color: _text,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.access_time, size: 12, color: _muted),
                          const SizedBox(width: 4),
                          Text(
                            formatTimeAgo(order.timestamp),
                            style: const TextStyle(color: _muted, fontSize: 12),
                          ),
                          const Text(' • ', style: TextStyle(color: _muted, fontSize: 12)),
                          const Icon(Icons.shopping_bag_outlined, size: 12, color: _muted),
                          const SizedBox(width: 4),
                          Text(
                            '${order.itemCount} item${order.itemCount == 1 ? '' : 's'}',
                            style: const TextStyle(color: _muted, fontSize: 12),
                          ),
                        ],
                      ),
                      if (itemsSummary.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          itemsSummary,
                          style: TextStyle(
                            color: _muted.withValues(alpha: 0.7),
                            fontSize: 11,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      moneyFmtIdr(order.totalAmount.toInt()),
                      style: const TextStyle(
                        color: _accent,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 18, color: _muted),
                          tooltip: 'Discard',
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: onDelete,
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: _accent.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'Recall',
                            style: TextStyle(
                              color: _accent,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

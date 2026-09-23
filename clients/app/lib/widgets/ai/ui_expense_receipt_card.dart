import 'package:alienai_c35/c/expense/expense_receipt.dart';
import 'package:alienai_c35/widgets/ui/ui_img.dart';
import 'package:flutter/material.dart';

class UiExpenseReceiptCard extends StatefulWidget {
  const UiExpenseReceiptCard({super.key, required this.card, this.collapsed = true, this.locale = 'en-US'});

  final ExpenseReceiptCard card;
  final bool collapsed;
  final String locale;

  @override
  State<UiExpenseReceiptCard> createState() => _UiExpenseReceiptCardState();
}

class _UiExpenseReceiptCardState extends State<UiExpenseReceiptCard> {
  late final ExpansibleController _ctrl;

  bool get _isId => widget.locale.toLowerCase().startsWith('id');

  @override
  void initState() {
    super.initState();
    _ctrl = ExpansibleController();
    if (!widget.collapsed) _ctrl.expand();
  }

  Color get _coachColor {
    if (widget.card.duplicate && !widget.card.saved) return const Color(0xFF9CA3AF);
    if (widget.card.coach.isEmpty) return const Color(0xFF9CA3AF);
    return const Color(0xFF6EE7B7);
  }

  String _photoSrc() {
    final h = widget.card.photoHash.trim();
    if (h.isEmpty) return '';
    if (h.startsWith('http://') || h.startsWith('https://') || h.startsWith('/fs/')) return h;
    return '/fs/$h';
  }

  String _paymentLabel() {
    final m = widget.card.paymentMethod.trim().toLowerCase();
    if (m.isEmpty) return '';
    switch (m) {
      case 'cash':
        return _isId ? 'Tunai' : 'Cash';
      case 'card':
        return _isId ? 'Kartu' : 'Card';
      case 'transfer':
        return _isId ? 'Transfer' : 'Transfer';
      case 'ewallet':
        return _isId ? 'E-wallet' : 'E-wallet';
      default:
        return widget.card.paymentMethod;
    }
  }

  @override
  Widget build(BuildContext context) {
    final card = widget.card;
    final photo = _photoSrc();
    final payment = _paymentLabel();

    return Material(
      color: const Color(0xFF18181B),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: Color(0xFF27272A)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (card.headline.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: const BoxDecoration(
                color: Color(0xFF202024),
                border: Border(bottom: BorderSide(color: Color(0xFF27272A))),
              ),
              child: Row(
                children: [
                  Icon(
                    card.saved ? Icons.check_circle_outline_rounded : Icons.info_outline_rounded,
                    size: 14,
                    color: card.saved ? const Color(0xFF6EE7B7) : const Color(0xFFF59E0B),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      card.headline,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w500, color: Color(0xFFD4D4D8)),
                    ),
                  ),
                ],
              ),
            ),
          ExpansionTile(
            controller: _ctrl,
            tilePadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
            childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
            leading: photo.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: UiImg(src: photo, width: 36, height: 36, fit: BoxFit.cover),
                  )
                : Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E3A5F),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.receipt_long_rounded, size: 18, color: Color(0xFF60A5FA)),
                  ),
            title: Text(
              card.headline.isNotEmpty ? card.headline : (_isId ? 'Pengeluaran' : 'Expense'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFFF4F4F5)),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (card.subtitle.isNotEmpty)
                  Text(
                    card.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11.5, color: Color(0xFF9CA3AF)),
                  ),
                if (payment.isNotEmpty)
                  Text(
                    payment,
                    style: const TextStyle(fontSize: 11, color: Color(0xFF71717A)),
                  ),
                if (card.coach.isNotEmpty) ...[
                  const SizedBox(height: 1),
                  Text(
                    card.coach,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 11, color: _coachColor, height: 1.2),
                  ),
                ],
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  card.amountLabel(),
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFFF4F4F5)),
                ),
                const SizedBox(width: 2),
                const Icon(Icons.expand_more_rounded, size: 18, color: Color(0xFF71717A)),
              ],
            ),
            children: [
              const Divider(color: Color(0xFF27272A), height: 12),
              if (card.today.txCount > 0)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _isId ? 'Total Hari Ini' : 'Today\'s Total',
                        style: const TextStyle(fontSize: 11.5, color: Color(0xFF9CA3AF)),
                      ),
                      Text(
                        '${expenseFmtIdr(card.today.afterMinor)} · ${card.today.txCount} ${_isId ? 'transaksi' : 'tx'}',
                        style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(0xFFE4E4E7)),
                      ),
                    ],
                  ),
                ),
              if (card.items.isNotEmpty) ...[
                Text(
                  _isId ? 'Rincian Item' : 'Line Items',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF60A5FA)),
                ),
                const SizedBox(height: 6),
                for (final item in card.items)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.label(widget.locale),
                                style: const TextStyle(fontSize: 12.5, color: Color(0xFFF4F4F5)),
                              ),
                              if (item.qty > 1 || item.priceMinor > 0)
                                Text(
                                  item.qty > 1
                                      ? '${item.qty == item.qty.roundToDouble() ? item.qty.round() : item.qty} × ${expenseFmtIdr(item.priceMinor)}'
                                      : expenseFmtIdr(item.priceMinor),
                                  style: const TextStyle(fontSize: 11, color: Color(0xFF71717A)),
                                ),
                            ],
                          ),
                        ),
                        Text(
                          expenseFmtIdr(item.lineTotal()),
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFFA1A1AA)),
                        ),
                      ],
                    ),
                  ),
              ],
              if (card.duplicate && card.duplicateReason.trim().isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    card.duplicateReason,
                    style: const TextStyle(fontSize: 11, color: Color(0xFFF59E0B)),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

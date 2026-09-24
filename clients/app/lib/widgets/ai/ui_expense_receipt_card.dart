import 'package:alienai_c35/c/expense/expense_receipt.dart';
import 'package:alienai_c35/widgets/ai/ui_record_card.dart';
import 'package:flutter/material.dart';

typedef ExpenseItemsSave = Future<void> Function(List<ExpenseItemRow> items);
typedef ExpenseDeleteCallback = Future<void> Function();

class UiExpenseReceiptCard extends StatelessWidget {
  const UiExpenseReceiptCard({
    super.key,
    required this.card,
    this.collapsed = true,
    this.locale = 'en-US',
    this.onSave,
    this.onDelete,
  });

  final ExpenseReceiptCard card;
  final bool collapsed;
  final String locale;
  final ExpenseItemsSave? onSave;
  final ExpenseDeleteCallback? onDelete;

  String _paymentLabel(bool isId) {
    final m = card.paymentMethod.trim().toLowerCase();
    if (m.isEmpty) return '';
    switch (m) {
      case 'cash':
        return isId ? 'Tunai' : 'Cash';
      case 'card':
        return isId ? 'Kartu' : 'Card';
      case 'transfer':
        return isId ? 'Transfer' : 'Transfer';
      case 'ewallet':
      case 'wallet':
        return isId ? 'E-wallet' : 'E-wallet';
      case 'qris':
        return 'QRIS';
      default:
        return card.paymentMethod;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isId = locale.toLowerCase().startsWith('id');
    final payment = _paymentLabel(isId);
    final subtitle = [
      if (card.subtitle.isNotEmpty) card.subtitle,
      if (payment.isNotEmpty) payment,
    ].join(' · ');

    final chips = <RecordChipData>[
      if (payment.isNotEmpty) RecordChipData(label: isId ? 'Metode' : 'Payment', value: payment),
      if (card.subtitle.isNotEmpty) RecordChipData(label: isId ? 'Toko' : 'Merchant', value: card.subtitle),
    ];

    final contextLabel = card.today.txCount > 0 ? (isId ? 'Total Hari Ini' : "Today's Total") : '';
    final contextValue = card.today.txCount > 0
        ? '${expenseFmtIdr(card.today.afterMinor)} · ${card.today.txCount} ${isId ? 'transaksi' : 'tx'}'
        : '';

    return UiRecordCard(
      id: card.txId,
      title: card.headline.isNotEmpty ? card.headline : (isId ? 'Pengeluaran' : 'Expense'),
      subtitle: subtitle,
      headline: card.headline,
      coach: card.coach,
      photoHash: card.photoHash,
      leadingIcon: Icons.receipt_long_rounded,
      primaryMetric: card.amountLabel(),
      contextLabel: contextLabel,
      contextValue: contextValue,
      items: card.items
          .map(
            (i) => RecordItemData(
              name: i.name,
              nameAlt: i.nameId,
              qty: i.qty,
              unitPrice: i.priceMinor,
              totalPrice: i.lineTotal(),
              objId: i.objId,
            ),
          )
          .toList(),
      chips: chips,
      footerNote: card.duplicate && card.duplicateReason.trim().isNotEmpty ? card.duplicateReason : '',
      collapsed: collapsed,
      locale: locale,
      qtyMode: card.qtyMode,
      canEditName: card.canEditName,
      canEditQty: card.canEditQty,
      canEditPrice: card.canEditPrice,
      formatPrice: expenseFmtIdr,
      saved: card.saved,
      duplicate: card.duplicate,
      onSave: onSave != null
          ? (items) async {
              final mapped = items
                  .map(
                    (e) => ExpenseItemRow(
                      name: e.name,
                      nameId: e.nameAlt,
                      qty: e.qty,
                      priceMinor: e.unitPrice,
                      totalMinor: e.totalPrice,
                      objId: e.objId,
                    ),
                  )
                  .toList();
              await onSave!(mapped);
            }
          : null,
      onDelete: onDelete,
    );
  }
}

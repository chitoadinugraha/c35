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
      if (card.currency != 'IDR') card.currency,
    ].join(' · ');

    final chips = <RecordChipData>[
      if (payment.isNotEmpty) RecordChipData(label: isId ? 'Metode' : 'Payment', value: payment),
      if (card.subtitle.isNotEmpty) RecordChipData(label: isId ? 'Toko' : 'Merchant', value: card.subtitle),
      if (card.currency != 'IDR') RecordChipData(label: isId ? 'Mata Uang' : 'Currency', value: card.currency),
      if (card.taxMinor > 0) RecordChipData(label: isId ? 'Pajak' : 'Tax', value: expenseFmtCurrency(card.taxMinor, card.currency)),
      if (card.serviceMinor > 0) RecordChipData(label: isId ? 'Layanan' : 'Service', value: expenseFmtCurrency(card.serviceMinor, card.currency)),
      if (card.discountMinor > 0) RecordChipData(label: isId ? 'Diskon' : 'Discount', value: '-${expenseFmtCurrency(card.discountMinor, card.currency)}'),
      if (card.linkedConsumptionId != null && card.linkedConsumptionId!.isNotEmpty)
        RecordChipData(label: '🥗', value: isId ? 'Tercatat di Nutrisi' : 'Logged to Nutrition'),
    ];

    final contextLabel = card.today.txCount > 0 ? (isId ? 'Total Hari Ini' : "Today's Total") : '';
    final contextValue = card.today.txCount > 0
        ? '${expenseFmtCurrency(card.today.afterMinor, card.currency)} · ${card.today.txCount} ${isId ? 'transaksi' : 'tx'}'
        : '';

    String footer = '';
    if (card.duplicate && card.duplicateReason.trim().isNotEmpty) {
      footer = card.duplicateReason;
    } else if (!card.mathVerified) {
      footer = isId
          ? '⚠️ Rincian item berbeda dari total struk (periksa baris item)'
          : '⚠️ Item math differs from receipt total (please review items)';
    }

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
      footerNote: footer,
      collapsed: collapsed,
      locale: locale,
      qtyMode: card.qtyMode,
      canEditName: card.canEditName,
      canEditQty: card.canEditQty,
      canEditPrice: card.canEditPrice,
      formatPrice: (m) => expenseFmtCurrency(m, card.currency),
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

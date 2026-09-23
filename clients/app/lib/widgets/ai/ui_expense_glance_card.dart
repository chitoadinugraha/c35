import 'package:alienai_c35/c/expense/expense_glance.dart';
import 'package:alienai_c35/c/expense/expense_receipt.dart';
import 'package:alienai_c35/widgets/ui/ui_img.dart';
import 'package:flutter/material.dart';

class UiExpenseGlanceCard extends StatefulWidget {
  const UiExpenseGlanceCard({super.key, required this.card, this.collapsed = false, this.locale = 'en-US'});

  final ExpenseGlanceCard card;
  final bool collapsed;
  final String locale;

  @override
  State<UiExpenseGlanceCard> createState() => _UiExpenseGlanceCardState();
}

class _UiExpenseGlanceCardState extends State<UiExpenseGlanceCard> {
  late final ExpansibleController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = ExpansibleController();
    if (!widget.collapsed) _ctrl.expand();
  }

  String _photoSrc(String hash) {
    final h = hash.trim();
    if (h.isEmpty) return '';
    if (h.startsWith('http://') || h.startsWith('https://') || h.startsWith('/fs/')) return h;
    return '/fs/$h';
  }

  @override
  Widget build(BuildContext context) {
    final card = widget.card;
    final id = widget.locale.toLowerCase().startsWith('id');

    return Material(
      color: const Color(0xFF18181B),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: Color(0xFF27272A))),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        controller: _ctrl,
        initiallyExpanded: !widget.collapsed,
        tilePadding: const EdgeInsets.fromLTRB(14, 8, 14, 4),
        childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
        title: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 56,
              height: 56,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFF1E3A5F).withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: const Color(0xFF3B82F6).withValues(alpha: 0.4)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    card.amountLabel(),
                    style: const TextStyle(color: Color(0xFFF4F4F5), fontSize: 9.5, fontWeight: FontWeight.w700, height: 1.1),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(card.periodTitle(widget.locale), style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600, color: Color(0xFFF4F4F5))),
                  const SizedBox(height: 3),
                  Text(
                    id ? '${card.txCount} transaksi' : '${card.txCount} purchases',
                    style: const TextStyle(fontSize: 11.5, color: Color(0xFF9CA3AF), height: 1.3),
                  ),
                ],
              ),
            ),
          ],
        ),
        subtitle: card.coach.trim().isEmpty
            ? null
            : Padding(
                padding: const EdgeInsets.only(top: 6, left: 68),
                child: Text(card.coach, style: const TextStyle(fontSize: 12.5, color: Color(0xFF6EE7B7), height: 1.35)),
              ),
        children: [
          if (card.matchedQuery.trim().isNotEmpty && card.matchedTotalMinor > 0) ...[
            Text(
              id ? '“${card.matchedQuery}” · ${expenseFmtIdr(card.matchedTotalMinor)}' : '"${card.matchedQuery}" · ${expenseFmtIdr(card.matchedTotalMinor)}',
              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFFE4E4E7)),
            ),
            const SizedBox(height: 12),
          ],
          if (card.categoryBreakdown.isNotEmpty) ...[
            Text(id ? 'Per Kategori' : 'By Category', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF71717A))),
            const SizedBox(height: 6),
            for (final cat in card.categoryBreakdown)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Expanded(child: Text(cat.label, style: const TextStyle(fontSize: 12.5, color: Color(0xFFA1A1AA)))),
                    Text(expenseFmtIdr(cat.totalMinor), style: const TextStyle(fontSize: 12, color: Color(0xFF71717A))),
                  ],
                ),
              ),
            const SizedBox(height: 8),
          ],
          if (card.recent.isNotEmpty) ...[
            Text(id ? 'Transaksi Terbaru' : 'Recent Receipts', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF71717A))),
            const SizedBox(height: 6),
            for (final receipt in card.recent)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if (_photoSrc(receipt.photoHash).isNotEmpty)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: UiImg(src: _photoSrc(receipt.photoHash), width: 36, height: 36, fit: BoxFit.cover),
                      )
                    else
                      Container(
                        width: 36,
                        height: 36,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(color: const Color(0xFF27272A), borderRadius: BorderRadius.circular(6)),
                        child: const Icon(Icons.receipt_long_rounded, size: 16, color: Color(0xFF71717A)),
                      ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(receipt.label, style: const TextStyle(fontSize: 13, color: Color(0xFFF4F4F5))),
                          if (receipt.subtitle.isNotEmpty)
                            Text(receipt.subtitle, style: const TextStyle(fontSize: 11, color: Color(0xFF71717A))),
                        ],
                      ),
                    ),
                    Text(expenseFmtIdr(receipt.totalMinor), style: const TextStyle(fontSize: 12.5, color: Color(0xFFA1A1AA), fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}

import 'dart:async';

import 'package:alienai_c35/c/api/referral_conn.dart';
import 'package:alienai_c35/c/billing/billing_format.dart';
import 'package:alienai_c35/c/billing/billing_history_api.dart';
import 'package:alienai_c35/c/pb/c35/billing.pb.dart';
import 'package:alienai_c35/c/store/app_store.dart';
import 'package:alienai_c35/c/ui/ui_friendly_error.dart';
import 'package:alienai_c35/widgets/billing/ui_billing_topup_dialog.dart';
import 'package:alienai_c35/widgets/ui/ui_loading.dart';
import 'package:flutter/material.dart';

Future<void> billingHistorySheet(BuildContext context, {required ReferralConn conn}) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFF121215),
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
    builder: (_) => _BillingHistorySheet(conn: conn),
  );
}

class _BillingHistorySheet extends StatefulWidget {
  const _BillingHistorySheet({required this.conn});

  final ReferralConn conn;

  @override
  State<_BillingHistorySheet> createState() => _BillingHistorySheetState();
}

class _BillingHistorySheetState extends State<_BillingHistorySheet> {
  static const _text = Color(0xFFE4E4E7);
  static const _muted = Color(0xFFA1A1AA);
  static const _border = Color(0xFF27272A);
  static const _surface = Color(0xFF18181B);
  static const _accent = Color(0xFF34D399);
  static const _headerBtnH = 40.0;
  static const _headerH = 40.0;
  static const _headerBtnRadius = 10.0;

  ButtonStyle get _headerTopupStyle => FilledButton.styleFrom(
        minimumSize: const Size(0, _headerBtnH),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        backgroundColor: const Color(0xFF27272A),
        foregroundColor: _text,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_headerBtnRadius), side: const BorderSide(color: _border)),
      );

  late final _searchCtrl = TextEditingController();
  late final _searchFocus = FocusNode();
  var _loading = true;
  var _searchOpen = false;
  String? _error;
  List<BillingHistoryRow> _history = const [];
  late String _currency;
  var _search = '';

  @override
  void initState() {
    super.initState();
    final billing = AppStore.instance.billing;
    _currency = billingPrimaryCurrency(billing ?? BillingAccount());
    unawaited(_load());
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _openSearch() {
    setState(() => _searchOpen = true);
    WidgetsBinding.instance.addPostFrameCallback((_) => _searchFocus.requestFocus());
  }

  void _closeSearch() {
    _searchCtrl.clear();
    _searchFocus.unfocus();
    setState(() {
      _searchOpen = false;
      _search = '';
    });
  }

  List<String> get _currencies => billingWalletCurrencies(AppStore.instance.billing);

  List<BillingHistoryRow> get _filtered {
    final q = _search.trim().toLowerCase();
    if (q.isEmpty) return _history;
    return _history.where((r) => r.title.toLowerCase().contains(q) || r.status.toLowerCase().contains(q) || r.kind.toLowerCase().contains(q)).toList();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final history = await billingHistoryGet(widget.conn, currency: _currency);
      if (!mounted) return;
      setState(() {
        _history = history.rows;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = uiReferralError(e, fallback: 'Failed to load history');
      });
    }
  }

  void _onCurrency(String cur) {
    if (cur == _currency) return;
    setState(() => _currency = cur);
    unawaited(_load());
  }

  Future<void> _showWalletMenu(BuildContext anchorCtx, BillingAccount? billing) async {
    final box = anchorCtx.findRenderObject() as RenderBox?;
    if (box == null) return;
    final pos = box.localToGlobal(Offset.zero);
    final selected = await showMenu<String>(
      context: context,
      color: _surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: const BorderSide(color: _border)),
      position: RelativeRect.fromLTRB(pos.dx, pos.dy + box.size.height + 4, pos.dx + box.size.width, 0),
      items: _currencies.map((c) {
        final label = billingWalletBalanceLabel(billing, c);
        final active = c == _currency;
        return PopupMenuItem<String>(
          value: c,
          height: 44,
          child: Row(
            children: [
              SizedBox(width: 36, child: Text(c, style: TextStyle(color: active ? _accent : _muted, fontSize: 12, fontWeight: FontWeight.w600))),
              Expanded(child: Text(label, style: TextStyle(color: active ? _text : _muted, fontWeight: active ? FontWeight.w600 : FontWeight.w500))),
              if (active) const Icon(Icons.check_rounded, size: 16, color: _accent),
            ],
          ),
        );
      }).toList(),
    );
    if (selected != null) _onCurrency(selected);
  }

  String _rowDate(BillingHistoryRow row) {
    if (!row.hasTsMs() || row.tsMs.toInt() <= 0) return '';
    final dt = DateTime.fromMillisecondsSinceEpoch(row.tsMs.toInt());
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays == 0) return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height * 0.72;
    return SizedBox(
      height: height,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(child: Container(width: 36, height: 4, decoration: BoxDecoration(color: _border, borderRadius: BorderRadius.circular(99)))),
            const SizedBox(height: 14),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: _searchOpen ? _buildSearchHeader() : _buildBalanceHeader(),
            ),
            const SizedBox(height: 14),
            Expanded(child: _buildList()),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchHeader() => SizedBox(
        key: const ValueKey('search'),
        height: _headerH,
        child: Row(
          children: [
            const Icon(Icons.search_rounded, size: 20, color: _muted),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _searchCtrl,
                focusNode: _searchFocus,
                style: const TextStyle(color: _text, fontSize: 15, fontWeight: FontWeight.w500),
                decoration: const InputDecoration(
                  hintText: 'Search transactions…',
                  hintStyle: TextStyle(color: _muted, fontSize: 15),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: false,
                  contentPadding: EdgeInsets.zero,
                  isDense: true,
                ),
                onChanged: (v) => setState(() => _search = v),
              ),
            ),
            IconButton(
              onPressed: _closeSearch,
              icon: const Icon(Icons.close_rounded, size: 20, color: _muted),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: _headerBtnH, minHeight: _headerBtnH),
            ),
          ],
        ),
      );

  Widget _buildBalanceHeader() => ListenableBuilder(
        key: const ValueKey('balance'),
        listenable: AppStore.instance,
        builder: (_, __) {
          final billing = AppStore.instance.billing;
          final balanceLabel = billingWalletBalanceLabel(billing, _currency);
          return SizedBox(
            height: _headerH,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Builder(
                    builder: (anchorCtx) => Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => _showWalletMenu(anchorCtx, billing),
                        borderRadius: BorderRadius.circular(8),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Text(
                                balanceLabel,
                                style: const TextStyle(color: _text, fontSize: 22, fontWeight: FontWeight.w700, letterSpacing: -0.5, height: 1),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 2),
                            const Icon(Icons.keyboard_arrow_down_rounded, size: 20, color: _muted),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _openSearch,
                  icon: const Icon(Icons.search_rounded, size: 20, color: _muted),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: _headerBtnH, minHeight: _headerBtnH),
                ),
                const SizedBox(width: 4),
                FilledButton.icon(
                  onPressed: () => billingTopupDialog(context, conn: widget.conn, currency: _currency, onSubmitted: _load),
                  style: _headerTopupStyle,
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Top up', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                ),
              ],
            ),
          );
        },
      );

  Widget _buildList() {
    if (_loading) return const Center(child: UILoading());
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!, style: const TextStyle(color: Color(0xFFF87171))),
            const SizedBox(height: 12),
            OutlinedButton(onPressed: _load, child: const Text('Retry')),
          ],
        ),
      );
    }
    final rows = _filtered;
    if (rows.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_search.isEmpty ? Icons.receipt_long_outlined : Icons.search_off_rounded, size: 36, color: _border),
            const SizedBox(height: 12),
            Text(_search.isEmpty ? 'No transactions yet.' : 'No matches for "$_search".', style: const TextStyle(color: _muted)),
          ],
        ),
      );
    }
    return ListView.separated(
      itemCount: rows.length,
      separatorBuilder: (_, __) => const SizedBox(height: 6),
      itemBuilder: (_, i) => _HistoryTile(row: rows[i], date: _rowDate(rows[i])),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({required this.row, required this.date});

  final BillingHistoryRow row;
  final String date;

  static const _text = Color(0xFFE4E4E7);
  static const _muted = Color(0xFFA1A1AA);
  static const _border = Color(0xFF27272A);

  @override
  Widget build(BuildContext context) {
    final amt = row.hasAmount() ? row.amount : (row.amountUsd != 0 ? row.amountUsd : -row.amountIdr);
    final sign = amt < 0 ? '-' : '+';
    final isUsage = row.kind == 'usage';
    final icon = isUsage ? Icons.bolt_outlined : Icons.add_card_outlined;
    final iconColor = isUsage ? const Color(0xFFFBBF24) : const Color(0xFF60A5FA);
    return DecoratedBox(
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: const Color(0xFF18181B), border: Border.all(color: _border)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(color: iconColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(9)),
              child: Icon(icon, size: 18, color: iconColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(row.title, style: const TextStyle(color: _text, fontWeight: FontWeight.w600, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Text(row.status, style: const TextStyle(color: _muted, fontSize: 11)),
                      if (date.isNotEmpty) ...[
                        const Text(' · ', style: TextStyle(color: _border, fontSize: 11)),
                        Text(date, style: const TextStyle(color: _muted, fontSize: 11)),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            Text(
              '$sign${billingHistoryAmountLabel(row)}',
              style: TextStyle(color: sign == '-' ? const Color(0xFFF87171) : const Color(0xFF34D399), fontWeight: FontWeight.w700, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

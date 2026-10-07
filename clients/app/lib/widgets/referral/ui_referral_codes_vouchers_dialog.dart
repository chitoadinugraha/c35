import 'dart:async';

import 'package:alienai_c35/c/api/referral_conn.dart';
import 'package:alienai_c35/c/billing/billing_voucher_api.dart';
import 'package:alienai_c35/c/pb/c35/billing.pb.dart';
import 'package:alienai_c35/c/referral/referral_format.dart';
import 'package:alienai_c35/c/session.dart';
import 'package:alienai_c35/c/ui/money_format.dart';
import 'package:alienai_c35/c/ui/ui_friendly_error.dart';
import 'package:alienai_c35/pages/voucher/page_voucher_generate.dart';
import 'package:alienai_c35/widgets/referral/ui_referral_code_list.dart';
import 'package:alienai_c35/widgets/ui/ui_loading.dart';
import 'package:alienai_c35/widgets/ui/ui_tooltip.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';

  Future<void> referralCodesVouchersDialog(
  BuildContext context, {
  required ReferralConn conn,
  required int viewerIid,
  required bool canIssue,
}) async {
  assert(viewerIid >= 0);
  await showDialog<void>(
    context: context,
    builder: (ctx) => _ReferralCodesVouchersDialog(conn: conn, viewerIid: viewerIid, canIssue: canIssue),
  );
}

Future<void> referralCodeListDialog(BuildContext context, {required ReferralConn conn}) => referralCodesVouchersDialog(
      context,
      conn: conn,
      viewerIid: Session.instance.uid,
      canIssue: Session.instance.canIssueBillingVoucher,
    );

class _ReferralDialogPalette {
  static const bg = Color(0xFF18181B);
  static const header = Color(0xFF08080A);
  static const border = Color(0xFF27272A);
  static const text = Color(0xFFF4F4F5);
  static const muted = Color(0xFFA1A1AA);
  static const accent = Color(0xFF22C55E);
  static const error = Color(0xFFF87171);
}

class _ReferralCodesVouchersDialog extends StatefulWidget {
  const _ReferralCodesVouchersDialog({required this.conn, required this.viewerIid, required this.canIssue});

  final ReferralConn conn;
  final int viewerIid;
  final bool canIssue;

  @override
  State<_ReferralCodesVouchersDialog> createState() => _ReferralCodesVouchersDialogState();
}

class _ReferralCodesVouchersDialogState extends State<_ReferralCodesVouchersDialog> with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 3, vsync: this);
  var _voucherReloadKey = 0;

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _openWizard() async {
    final issued = await Navigator.push<bool>(
      context,
      MaterialPageRoute<bool>(builder: (_) => PageVoucherWizard(conn: widget.conn)),
    );
    if (issued == true && mounted) setState(() => _voucherReloadKey++);
  }

  @override
  Widget build(BuildContext context) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        backgroundColor: Colors.transparent,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 512, maxHeight: 720),
          child: Material(
            color: _ReferralDialogPalette.bg,
            elevation: 24,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: const Color(0xFF3F3F46).withValues(alpha: 0.95)),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
                  decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: _ReferralDialogPalette.border)),
                    color: _ReferralDialogPalette.header,
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.confirmation_number_outlined, size: 20, color: _ReferralDialogPalette.accent),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Text('Codes & vouchers', style: TextStyle(color: _ReferralDialogPalette.text, fontSize: 16, fontWeight: FontWeight.w700)),
                          ),
                          uiIconButton(
                            onPressed: () => Navigator.pop(context),
                            tooltip: 'Close',
                            icon: const Icon(Icons.close, size: 20, color: _ReferralDialogPalette.muted),
                          ),
                        ],
                      ),
                      TabBar(
                        controller: _tabs,
                        indicatorColor: _ReferralDialogPalette.accent,
                        labelColor: _ReferralDialogPalette.text,
                        unselectedLabelColor: _ReferralDialogPalette.muted,
                        tabs: const [
                          Tab(text: 'Referral codes'),
                          Tab(text: 'Vouchers'),
                          Tab(text: 'Redeem history'),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabs,
                    children: [
                      UiReferralAffiliateCodesPanel(conn: widget.conn),
                      _VouchersTab(key: ValueKey(_voucherReloadKey), conn: widget.conn, canIssue: widget.canIssue, onIssue: _openWizard),
                      _RedeemHistoryTab(conn: widget.conn),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}

class _VouchersTab extends StatefulWidget {
  const _VouchersTab({super.key, required this.conn, required this.canIssue, required this.onIssue});

  final ReferralConn conn;
  final bool canIssue;
  final VoidCallback onIssue;

  @override
  State<_VouchersTab> createState() => _VouchersTabState();
}

class _VouchersTabState extends State<_VouchersTab> {
  var _loading = true;
  String? _error;
  String _statusFilter = '';
  String _copiedCode = '';
  Timer? _copiedClear;
  List<BillingVoucherDoc> _items = [];
  ResBillingVoucherLimit? _limit;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _copiedClear?.cancel();
    super.dispose();
  }

  List<BillingVoucherDoc> get _filtered => _items.where((v) {
        final status = v.status.isEmpty ? 'active' : v.status;
        if (status == 'expired') return false;
        if (_statusFilter.isEmpty) return true;
        return status == _statusFilter;
      }).toList();

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await billingVoucherList(widget.conn);
      if (!mounted) return;
      setState(() {
        _items = List<BillingVoucherDoc>.from(res.items);
        _limit = res.hasLimit() ? res.limit : null;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = uiReferralError(e, fallback: 'Failed to load vouchers');
      });
    }
  }

  Future<void> _copyCode(String code) async {
    await Clipboard.setData(ClipboardData(text: code));
    setState(() => _copiedCode = code);
    _copiedClear?.cancel();
    _copiedClear = Timer(const Duration(seconds: 2), () {
      if (mounted && _copiedCode == code) setState(() => _copiedCode = '');
    });
  }

  Future<void> _showVoucherQr(BuildContext context, BillingVoucherDoc doc) async {
    final code = referralCodeNorm(doc.code);
    if (code.isEmpty) return;
    final title = doc.name.trim().isNotEmpty ? doc.name.trim() : 'Voucher';
    await showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: _ReferralDialogPalette.bg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: const Color(0xFF3F3F46).withValues(alpha: 0.95))),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 320),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: _ReferralDialogPalette.text, fontWeight: FontWeight.w700, fontSize: 15))),
                    uiIconButton(onPressed: () => Navigator.pop(ctx), tooltip: 'Close', icon: const Icon(Icons.close, size: 20, color: _ReferralDialogPalette.muted)),
                  ],
                ),
                if (doc.faceValueIdr > 0) ...[
                  const SizedBox(height: 4),
                  Text(moneyFmtIdr(doc.faceValueIdr), style: const TextStyle(color: _ReferralDialogPalette.accent, fontSize: 22, fontWeight: FontWeight.w800)),
                ],
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                  child: QrImageView(data: code, size: 200, backgroundColor: Colors.white),
                ),
                const SizedBox(height: 12),
                Text('Scan to redeem in Plans → Redeem', textAlign: TextAlign.center, style: const TextStyle(color: _ReferralDialogPalette.muted, fontSize: 11, height: 1.35)),
                const SizedBox(height: 10),
                SelectableText(referralCodeFormat(code), textAlign: TextAlign.center, style: const TextStyle(color: _ReferralDialogPalette.text, fontFamily: 'monospace', fontWeight: FontWeight.w700, letterSpacing: 1.1, fontSize: 13)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _voidVoucher(BillingVoucherDoc doc) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _ReferralDialogPalette.bg,
        title: const Text('Void voucher?', style: TextStyle(color: _ReferralDialogPalette.text)),
        content: Text(doc.code, style: const TextStyle(color: _ReferralDialogPalette.muted, fontFamily: 'monospace')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Void', style: TextStyle(color: _ReferralDialogPalette.error))),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await billingVoucherVoid(widget.conn, code: doc.code);
      await _load();
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = uiReferralError(e, fallback: 'Failed to void voucher'));
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    final limit = _limit;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (limit != null && limit.limitIdr > 0)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Issue limit', style: const TextStyle(color: _ReferralDialogPalette.muted, fontSize: 11, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    minHeight: 6,
                    value: limit.limitIdr > 0 ? (limit.usedIdr / limit.limitIdr).clamp(0.0, 1.0) : null,
                    backgroundColor: const Color(0xFF27272A),
                    color: _ReferralDialogPalette.accent,
                  ),
                ),
                const SizedBox(height: 6),
                Text('${moneyFmtIdr(limit.usedIdr)} / ${moneyFmtIdr(limit.limitIdr)}', style: const TextStyle(color: _ReferralDialogPalette.text, fontSize: 12)),
              ],
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 8, 0),
          child: Row(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final s in ['', 'active', 'redeemed', 'void'])
                        Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: FilterChip(
                            label: Text(s.isEmpty ? 'All' : s[0].toUpperCase() + s.substring(1)),
                            selected: _statusFilter == s,
                            onSelected: (_) => setState(() => _statusFilter = s),
                            selectedColor: _ReferralDialogPalette.accent.withValues(alpha: 0.25),
                            labelStyle: TextStyle(color: _statusFilter == s ? _ReferralDialogPalette.text : _ReferralDialogPalette.muted, fontSize: 12),
                            side: const BorderSide(color: _ReferralDialogPalette.border),
                            backgroundColor: const Color(0xFF27272A),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              if (widget.canIssue)
                FilledButton.icon(
                  onPressed: widget.onIssue,
                  style: FilledButton.styleFrom(backgroundColor: _ReferralDialogPalette.accent, foregroundColor: const Color(0xFF09090B), visualDensity: VisualDensity.compact),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Issue'),
                ),
              uiIconButton(onPressed: _loading ? null : _load, tooltip: 'Refresh', icon: const Icon(Icons.refresh, size: 20, color: _ReferralDialogPalette.muted)),
            ],
          ),
        ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(_error!, style: const TextStyle(color: _ReferralDialogPalette.error, fontSize: 12)),
          ),
        Expanded(
          child: _loading
              ? const UILoading(message: 'Loading vouchers…')
              : filtered.isEmpty
                  ? Center(child: Text(_statusFilter.isEmpty ? 'No vouchers yet' : 'No vouchers match', style: const TextStyle(color: _ReferralDialogPalette.muted)))
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, i) => _VoucherTile(
                        doc: filtered[i],
                        copied: _copiedCode == filtered[i].code,
                        onCopy: () => _copyCode(filtered[i].code),
                        onShowQr: () => _showVoucherQr(context, filtered[i]),
                        onVoid: filtered[i].status == 'active' ? () => _voidVoucher(filtered[i]) : null,
                      ),
                    ),
        ),
      ],
    );
  }
}

class _VoucherTile extends StatelessWidget {
  const _VoucherTile({required this.doc, required this.copied, required this.onCopy, required this.onShowQr, this.onVoid});

  final BillingVoucherDoc doc;
  final bool copied;
  final VoidCallback onCopy;
  final VoidCallback onShowQr;
  final VoidCallback? onVoid;

  Color _statusColor(String status) => switch (status) {
        'active' => _ReferralDialogPalette.accent,
        'redeemed' => const Color(0xFF60A5FA),
        'expired' => const Color(0xFFFBBF24),
        'void' => _ReferralDialogPalette.error,
        _ => _ReferralDialogPalette.muted,
      };

  String _metaLine(BillingVoucherDoc v) {
    final parts = <String>[];
    if (v.kind.isNotEmpty) parts.add(v.kind);
    if (v.planSlug.isNotEmpty) parts.add(v.planSlug);
    if (v.scope.isNotEmpty && v.scope != 'user') parts.add(v.scope);
    return parts.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final status = doc.status.isEmpty ? 'active' : doc.status;
    final statusColor = _statusColor(status);
    final dimmed = status != 'active';
    final title = doc.name.trim().isNotEmpty ? doc.name.trim() : 'Voucher';
    final formatted = referralCodeFormat(doc.code);
    final meta = _metaLine(doc);
    return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color.lerp(const Color(0xFF1C1C22), statusColor, dimmed ? 0.04 : 0.12)!,
              const Color(0xFF141418),
            ],
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF3F3F46).withValues(alpha: 0.9)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 10, 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 4,
                    height: 44,
                    decoration: BoxDecoration(color: statusColor.withValues(alpha: dimmed ? 0.45 : 1), borderRadius: BorderRadius.circular(4)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: _ReferralDialogPalette.text.withValues(alpha: dimmed ? 0.75 : 1), fontWeight: FontWeight.w700, fontSize: 14)),
                        if (meta.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Text(meta, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: _ReferralDialogPalette.muted, fontSize: 10)),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(999)),
                    child: Text(status, style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.w700)),
                  ),
                  if (onVoid != null) uiIconButton(tooltip: 'Void', onPressed: onVoid, icon: const Icon(Icons.block, size: 18, color: _ReferralDialogPalette.muted)),
                ],
              ),
            ),
            if (doc.faceValueIdr > 0)
              Padding(
                padding: const EdgeInsets.fromLTRB(28, 0, 14, 8),
                child: Text(
                  moneyFmtIdr(doc.faceValueIdr),
                  style: TextStyle(color: statusColor.withValues(alpha: dimmed ? 0.55 : 1), fontSize: 26, fontWeight: FontWeight.w800, height: 1.05),
                ),
              ),
            _VoucherPerforation(color: statusColor.withValues(alpha: 0.35)),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Material(
                      color: const Color(0xFF0C0C0F).withValues(alpha: 0.65),
                      borderRadius: BorderRadius.circular(10),
                      child: InkWell(
                        onTap: onCopy,
                        borderRadius: BorderRadius.circular(10),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                          child: Text(
                            formatted,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.w700, letterSpacing: 1.1, fontSize: 12, color: _ReferralDialogPalette.text.withValues(alpha: dimmed ? 0.7 : 1)),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  uiIconButton(tooltip: 'Show QR', onPressed: onShowQr, icon: Icon(Icons.qr_code_2_rounded, size: 20, color: dimmed ? _ReferralDialogPalette.muted : _ReferralDialogPalette.accent)),
                  uiIconButton(
                    tooltip: copied ? 'Copied' : 'Copy code',
                    onPressed: onCopy,
                    icon: Icon(copied ? Icons.check_circle_outline : Icons.content_copy_outlined, size: 18, color: copied ? _ReferralDialogPalette.accent : _ReferralDialogPalette.muted),
                  ),
                ],
              ),
            ),
          ],
        ),
    );
  }
}

class _VoucherPerforation extends StatelessWidget {
  const _VoucherPerforation({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 18,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned.fill(
              child: CustomPaint(painter: _VoucherDashedLinePainter(color: color)),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _VoucherNotch(side: _VoucherNotchSide.left),
                _VoucherNotch(side: _VoucherNotchSide.right),
              ],
            ),
          ],
        ),
      );
}

enum _VoucherNotchSide { left, right }

class _VoucherNotch extends StatelessWidget {
  const _VoucherNotch({required this.side});

  final _VoucherNotchSide side;

  @override
  Widget build(BuildContext context) => Container(
        width: 14,
        height: 14,
        decoration: const BoxDecoration(color: _ReferralDialogPalette.bg, shape: BoxShape.circle),
      );
}

class _VoucherDashedLinePainter extends CustomPainter {
  _VoucherDashedLinePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    const dash = 5.0;
    const gap = 4.0;
    var x = 20.0;
    final y = size.height / 2;
    while (x < size.width - 20) {
      canvas.drawLine(Offset(x, y), Offset(x + dash, y), paint);
      x += dash + gap;
    }
  }

  @override
  bool shouldRepaint(covariant _VoucherDashedLinePainter oldDelegate) => oldDelegate.color != color;
}

class _RedeemHistoryTab extends StatefulWidget {
  const _RedeemHistoryTab({required this.conn});

  final ReferralConn conn;

  @override
  State<_RedeemHistoryTab> createState() => _RedeemHistoryTabState();
}

class _RedeemHistoryTabState extends State<_RedeemHistoryTab> {
  var _loading = true;
  String? _error;
  List<BillingVoucherRedeemDoc> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await billingVoucherRedeemList(widget.conn);
      if (!mounted) return;
      setState(() {
        _items = List<BillingVoucherRedeemDoc>.from(res.items);
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = uiReferralError(e, fallback: 'Failed to load redeem history');
      });
    }
  }

  String _when(BillingVoucherRedeemDoc row) {
    final ms = row.redeemedTsMs.toInt();
    if (ms <= 0) return '';
    final at = DateTime.fromMillisecondsSinceEpoch(ms);
    return '${at.year}-${at.month.toString().padLeft(2, '0')}-${at.day.toString().padLeft(2, '0')} ${at.hour.toString().padLeft(2, '0')}:${at.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: uiIconButton(onPressed: _loading ? null : _load, tooltip: 'Refresh', icon: const Icon(Icons.refresh, size: 20, color: _ReferralDialogPalette.muted)),
          ),
          if (_error != null)
            Padding(padding: const EdgeInsets.all(12), child: Text(_error!, style: const TextStyle(color: _ReferralDialogPalette.error, fontSize: 12))),
          Expanded(
            child: _loading
                ? const UILoading(message: 'Loading history…')
                : _items.isEmpty
                    ? const Center(child: Text('No redemptions yet', style: TextStyle(color: _ReferralDialogPalette.muted)))
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        itemCount: _items.length,
                        separatorBuilder: (_, __) => const Divider(height: 16, color: _ReferralDialogPalette.border),
                        itemBuilder: (context, i) {
                          final row = _items[i];
                          final buyer = row.buyerName.trim().isNotEmpty ? row.buyerName.trim() : 'User ${row.buyerIid}';
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(row.code, style: const TextStyle(color: _ReferralDialogPalette.text, fontFamily: 'monospace', fontWeight: FontWeight.w700)),
                              const SizedBox(height: 4),
                              Text('$buyer · ${moneyFmtIdr(row.faceValueIdr)}', style: const TextStyle(color: _ReferralDialogPalette.muted, fontSize: 12)),
                              if (_when(row).isNotEmpty) Text(_when(row), style: const TextStyle(color: _ReferralDialogPalette.muted, fontSize: 11)),
                            ],
                          );
                        },
                      ),
          ),
        ],
      );
}

import 'package:alienai_c35/c/api/referral_conn.dart';
import 'package:alienai_c35/c/billing/billing_admin_adjust.dart';
import 'package:alienai_c35/c/pb/c35/billing.pb.dart';
import 'package:alienai_c35/c/referral/referral_format.dart';
import 'package:alienai_c35/c/ui/ui_friendly_error.dart';
import 'package:alienai_c35/c/ui/ui_format.dart';
import 'package:flutter/material.dart';

Future<void> referralAdminAdjustHistorySheet(
  BuildContext context, {
  required ReferralConn conn,
  int subjectUid = 0,
  String kind = '',
}) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF18181B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        side: BorderSide(color: Color(0xFF3F3F46)),
      ),
      builder: (ctx) => _ReferralAdminAdjustHistorySheet(conn: conn, subjectUid: subjectUid, kind: kind),
    );

class _ReferralAdminAdjustHistorySheet extends StatefulWidget {
  const _ReferralAdminAdjustHistorySheet({required this.conn, required this.subjectUid, required this.kind});

  final ReferralConn conn;
  final int subjectUid;
  final String kind;

  @override
  State<_ReferralAdminAdjustHistorySheet> createState() => _ReferralAdminAdjustHistorySheetState();
}

class _ReferralAdminAdjustHistorySheetState extends State<_ReferralAdminAdjustHistorySheet> {
  static const _text = Color(0xFFF4F4F5);
  static const _muted = Color(0xFFA1A1AA);
  static const _accent = Color(0xFF22C55E);
  static const _errorColor = Color(0xFFF87171);

  var _loading = true;
  var _errorMsg = '';
  var _reasonFilter = '';
  List<BillingAdminAdjustEntry> _items = const [];
  List<BillingAdminAdjustReasonTotal> _totals = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _errorMsg = '';
    });
    try {
      final res = await billingAdminAdjustList(
        widget.conn,
        subjectUid: widget.subjectUid,
        kind: widget.kind,
        reason: _reasonFilter,
        limit: 100,
      );
      if (!mounted) return;
      setState(() {
        _items = res.items;
        _totals = res.totals;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _errorMsg = uiReferralError(e, fallback: 'Could not load history.');
      });
    }
  }

  String _amount(BillingAdminAdjustEntry row) {
    final sign = row.direction == billingAdminAdjustDirCredit ? '+' : '−';
    final cur = row.currency.isNotEmpty ? row.currency : 'IDR';
    final body = referralCommissionAmountLabel(cur, row.amountUsd, row.amountIdr);
    return '$sign$body';
  }

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.sizeOf(context).height * 0.75;
    return SafeArea(
      child: SizedBox(
        height: h,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Text('Adjustment history', style: TextStyle(color: _text, fontSize: 16, fontWeight: FontWeight.w700)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: DropdownButtonFormField<String>(
                value: _reasonFilter.isEmpty ? '' : _reasonFilter,
                dropdownColor: const Color(0xFF18181B),
                style: const TextStyle(color: _text, fontSize: 13),
                decoration: const InputDecoration(labelText: 'Reason filter', isDense: true),
                items: [
                  const DropdownMenuItem(value: '', child: Text('All reasons')),
                  ...billingAdminAdjustReasons.map((r) => DropdownMenuItem(value: r.id, child: Text(r.label))),
                ],
                onChanged: _loading
                    ? null
                    : (v) {
                        setState(() => _reasonFilter = v ?? '');
                        _load();
                      },
              ),
            ),
            if (_totals.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: _totals
                      .map(
                        (t) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF27272A),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: const Color(0xFF3F3F46)),
                          ),
                          child: Text(
                            '${billingAdminAdjustReasonLabel(t.reason)}: Rp ${uiFmtGroupedInt(t.amountIdr.round())} (${t.count})',
                            style: const TextStyle(color: _muted, fontSize: 11),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(strokeWidth: 2, color: _accent))
                  : _errorMsg.isNotEmpty
                      ? Center(child: Text(_errorMsg, style: const TextStyle(color: _errorColor)))
                      : _items.isEmpty
                          ? const Center(child: Text('No adjustments yet', style: TextStyle(color: _muted)))
                          : ListView.separated(
                              padding: const EdgeInsets.all(16),
                              itemCount: _items.length,
                              separatorBuilder: (_, __) => const Divider(height: 16, color: Color(0xFF3F3F46)),
                              itemBuilder: (ctx, i) {
                                final row = _items[i];
                                final when = referralLedgerWhenLabel(row.createdTsMs.toInt());
                                return ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(
                                    '${row.kind} · ${billingAdminAdjustReasonLabel(row.reason)}',
                                    style: const TextStyle(color: _text, fontWeight: FontWeight.w600, fontSize: 13),
                                  ),
                                  subtitle: Text(
                                    [
                                      if (row.ownerName.isNotEmpty) row.ownerName,
                                      if (row.note.isNotEmpty) row.note,
                                      if (row.adjustedByName.isNotEmpty) 'by ${row.adjustedByName}',
                                      when,
                                    ].join(' · '),
                                    style: const TextStyle(color: _muted, fontSize: 11),
                                  ),
                                  trailing: Text(
                                    _amount(row),
                                    style: TextStyle(
                                      color: row.direction == billingAdminAdjustDirCredit ? _accent : _errorColor,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                    ),
                                  ),
                                );
                              },
                            ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:alienai_c35/c/api/referral_conn.dart';
import 'package:alienai_c35/c/pb/c35/referral.pb.dart';
import 'package:alienai_c35/c/referral/referral_commission_api.dart';
import 'package:alienai_c35/c/referral/referral_format.dart';
import 'package:alienai_c35/c/session.dart';
import 'package:alienai_c35/c/store/app_store.dart';
import 'package:alienai_c35/c/ui/money_format.dart';
import 'package:alienai_c35/c/ui/ui_friendly_error.dart';
import 'package:alienai_c35/widgets/referral/ui_referral_withdraw_sheet.dart';
import 'package:alienai_c35/widgets/ui/ui_loading.dart';
import 'package:flutter/material.dart';

Future<void> referralCommissionSheet(BuildContext context, {required ReferralConn conn}) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: const Color(0xFF18181B),
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
      child: _ReferralCommissionSheet(conn: conn),
    ),
  );
}

class _ReferralCommissionSheet extends StatefulWidget {
  const _ReferralCommissionSheet({required this.conn});

  final ReferralConn conn;

  @override
  State<_ReferralCommissionSheet> createState() => _ReferralCommissionSheetState();
}

class _ReferralCommissionSheetState extends State<_ReferralCommissionSheet> {
  static const _text = Color(0xFFF4F4F5);
  static const _muted = Color(0xFFA1A1AA);
  static const _accent = Color(0xFF60A5FA);

  var _loading = true;
  String? _error;
  List<CommissionLedgerEntry> _ledger = const [];
  var _availUsd = 0.0;
  var _availIdr = 0.0;

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
      final billing = AppStore.instance.billing;
      _availUsd = billing?.commissionAvailableUsd ?? 0;
      _availIdr = billing?.commissionAvailableIdr ?? 0;
      final res = await referralLedgerList(widget.conn);
      if (!mounted) return;
      setState(() {
        _ledger = res.items;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = uiReferralError(e, fallback: 'Could not load commission.');
      });
    }
  }

  Future<void> _withdraw() async {
    await referralCommissionWithdrawSheet(context, conn: widget.conn, registeredName: Session.instance.name);
    if (mounted) await _load();
  }

  String _ledgerAmount(CommissionLedgerEntry row) {
    if (row.amountIdr.abs() > 0) return moneyFmtIdr(row.amountIdr.abs());
    if (row.amountUsd.abs() > 0) return referralUsdLabel(row.amountUsd.abs());
    return '—';
  }

  @override
  Widget build(BuildContext context) {
    final balanceLabel = referralCommissionStripLabel(_availUsd, _availIdr);
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
            decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFF3F3F46))), color: Color(0xFF27272A)),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(color: const Color(0x1F3B82F6), borderRadius: BorderRadius.circular(12), border: Border.all(color: _accent.withValues(alpha: 0.25))),
                  child: const Icon(Icons.payments_outlined, size: 20, color: _accent),
                ),
                const SizedBox(width: 10),
                const Expanded(child: Text('Commission', style: TextStyle(color: _text, fontSize: 16, fontWeight: FontWeight.w700))),
                IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close, size: 20, color: _muted), visualDensity: VisualDensity.compact),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Available', style: TextStyle(color: _muted.withValues(alpha: 0.9), fontSize: 12)),
                const SizedBox(height: 4),
                Text(balanceLabel, style: const TextStyle(color: _text, fontSize: 24, fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: referralCommissionHasBalance(_availUsd, _availIdr) ? _withdraw : null,
                  icon: const Icon(Icons.north_east, size: 16),
                  label: const Text('Withdraw'),
                  style: FilledButton.styleFrom(backgroundColor: const Color(0xFF059669)),
                ),
                const SizedBox(height: 16),
                const Text('Ledger', style: TextStyle(color: _muted, fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                if (_error != null) Text(_error!, style: const TextStyle(color: Color(0xFFF87171), fontSize: 12)),
                if (_loading) const Padding(padding: EdgeInsets.all(24), child: UILoading(compact: true))
                else if (_ledger.isEmpty)
                  const Padding(padding: EdgeInsets.symmetric(vertical: 24), child: Text('No ledger entries yet', textAlign: TextAlign.center, style: TextStyle(color: _muted)))
                else
                  ConstrainedBox(
                    constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.4),
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: _ledger.length,
                      separatorBuilder: (context, index) => const Divider(height: 1, color: Color(0xFF27272A)),
                      itemBuilder: (ctx, i) {
                        final row = _ledger[i];
                        return ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          title: Text(row.entryType.isNotEmpty ? row.entryType : row.eventType, style: const TextStyle(color: _text, fontSize: 13)),
                          subtitle: Text(referralLedgerWhenLabel(row.createdTsMs.toInt()), style: const TextStyle(color: _muted, fontSize: 11)),
                          trailing: Text(_ledgerAmount(row), style: const TextStyle(color: _accent, fontWeight: FontWeight.w600, fontSize: 13)),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

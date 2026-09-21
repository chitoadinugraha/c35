import 'dart:async';

import 'package:alienai_c35/c/api/referral_conn.dart';
import 'package:alienai_c35/c/pb/c35/referral.pb.dart';
import 'package:alienai_c35/c/referral/referral_commission_api.dart';
import 'package:alienai_c35/c/ui/ui_format.dart';
import 'package:alienai_c35/widgets/ui/ui_input_decoration.dart';
import 'package:alienai_c35/widgets/ui/ui_user_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

Future<void> referralCommissionSimulateDialog(
  BuildContext context, {
  required ReferralConn conn,
  required int subjectUid,
  required String subjectName,
  required String subjectPic,
  int initialAmount = 100000,
}) =>
    showDialog<void>(
      context: context,
      builder: (ctx) => _ReferralCommissionSimulateDialog(
        conn: conn,
        subjectUid: subjectUid,
        subjectName: subjectName,
        subjectPic: subjectPic,
        initialAmount: initialAmount,
      ),
    );

class _ReferralCommissionSimulateDialog extends StatefulWidget {
  const _ReferralCommissionSimulateDialog({
    required this.conn,
    required this.subjectUid,
    required this.subjectName,
    required this.subjectPic,
    required this.initialAmount,
  });

  final ReferralConn conn;
  final int subjectUid;
  final String subjectName;
  final String subjectPic;
  final int initialAmount;

  @override
  State<_ReferralCommissionSimulateDialog> createState() => _ReferralCommissionSimulateDialogState();
}

class _ReferralCommissionSimulateDialogState extends State<_ReferralCommissionSimulateDialog> {
  static const _bg = Color(0xFF18181B);
  static const _text = Color(0xFFF4F4F5);
  static const _muted = Color(0xFFA1A1AA);
  static const _accent = Color(0xFF22C55E);

  late final _amountCtrl = TextEditingController(text: uiFmtGroupedInt(widget.initialAmount));
  ResReferralCommissionSimulate? _result;
  var _loading = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _simulate();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _amountCtrl.dispose();
    super.dispose();
  }

  int? get _amount => int.tryParse(_amountCtrl.text.replaceAll(RegExp(r'[^0-9]'), ''));

  void _onAmountChanged(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), _simulate);
  }

  Future<void> _simulate() async {
    final amount = _amount ?? 0;
    if (amount <= 0) {
      if (mounted) setState(() => _result = null);
      return;
    }
    setState(() => _loading = true);
    try {
      final res = await referralCommissionSimulate(widget.conn, subjectUid: widget.subjectUid, purchaseAmount: amount);
      if (!mounted) return;
      setState(() {
        _result = res;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Dialog(
        backgroundColor: _bg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Color(0xFF3F3F46))),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 420, maxHeight: MediaQuery.sizeOf(context).height * 0.82),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text('Commission breakdown', style: TextStyle(color: _text, fontSize: 16, fontWeight: FontWeight.w700)),
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, size: 20, color: _muted),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: Color(0xFF27272A)),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                  child: UiReferralCommissionBreakdown(
                    result: _result,
                    subjectUid: widget.subjectUid,
                    buyerName: widget.subjectName,
                    buyerPic: widget.subjectPic,
                    amountField: TextField(
                      controller: _amountCtrl,
                      onChanged: _onAmountChanged,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      style: const TextStyle(color: _text, fontSize: 22, fontWeight: FontWeight.w700),
                      textAlign: TextAlign.center,
                      decoration: UiInputDecoration.of(context, labelText: 'Purchase amount (IDR)', hintText: '100000'),
                    ),
                  ),
                ),
              ),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: _accent))),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
                child: FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
              ),
            ],
          ),
        ),
      );
}

class UiReferralCommissionBreakdown extends StatelessWidget {
  const UiReferralCommissionBreakdown({
    super.key,
    required this.result,
    required this.subjectUid,
    required this.buyerName,
    required this.buyerPic,
    this.amountField,
  });

  final ResReferralCommissionSimulate? result;
  final int subjectUid;
  final String buyerName;
  final String buyerPic;
  final Widget? amountField;

  @override
  Widget build(BuildContext context) {
    final res = result;
    final poolPct = res != null ? (res.poolRate * 100).round() : 0;
    final levels = res?.levels.where((l) => l.identityId.toInt() != subjectUid).toList() ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          decoration: BoxDecoration(
            color: const Color(0xFF27272A).withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF3F3F46)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text('Buyer', style: TextStyle(color: Color(0xFFA1A1AA), fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.4)),
                  ),
                  Flexible(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        UiUserAvatar(name: buyerName, pic: buyerPic, size: 20, showBorder: false),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            buyerName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Color(0xFFF4F4F5), fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (amountField != null) amountField!,
              if (res != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Pool ($poolPct%): Rp ${uiFmtGroupedInt(res.poolAmount.toInt())}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Color(0xFFA1A1AA), fontSize: 12),
                ),
              ],
            ],
          ),
        ),
        if (res != null)
          for (final level in levels) ...[
            const SizedBox(height: 10),
            const Center(child: Icon(Icons.arrow_downward_rounded, size: 22, color: Color(0xFF34D399))),
            const SizedBox(height: 10),
            _CommissionLevelRow(
              name: level.name,
              pic: level.avatarUrl,
              percent: level.percent,
              earnAmount: level.earnAmount.toInt(),
              highlight: level.earnAmount.toInt() > 0,
            ),
          ],
        if (res != null && levels.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 16),
            child: Text('No upline commission for this purchase', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFFA1A1AA), fontSize: 13)),
          ),
        if (res != null && res.undistributed.toInt() > 0) ...[
          const SizedBox(height: 14),
          Text(
            'Undistributed: Rp ${uiFmtGroupedInt(res.undistributed.toInt())}',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFFA1A1AA), fontSize: 12),
          ),
        ],
      ],
    );
  }
}

class _CommissionLevelRow extends StatelessWidget {
  const _CommissionLevelRow({required this.name, required this.pic, required this.percent, required this.earnAmount, required this.highlight});

  final String name;
  final String pic;
  final int percent;
  final int earnAmount;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    const emerald = Color(0xFF34D399);
    final border = highlight ? const Color(0xFF34D399) : const Color(0xFF3F3F46);
    final bg = highlight ? const Color(0x1422C55E) : const Color(0x0A22C55E);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border, width: highlight ? 1.5 : 1),
      ),
      child: Row(
        children: [
          UiUserAvatar(name: name, pic: pic, size: 36, showBorder: false),
          const SizedBox(width: 10),
          Expanded(
            child: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFFF4F4F5), fontWeight: FontWeight.w600)),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('$percent%', style: const TextStyle(color: emerald, fontSize: 12, fontWeight: FontWeight.w600)),
              Text('Rp ${uiFmtGroupedInt(earnAmount)}', style: const TextStyle(color: Color(0xFFF4F4F5), fontSize: 14, fontWeight: FontWeight.w700)),
            ],
          ),
        ],
      ),
    );
  }
}

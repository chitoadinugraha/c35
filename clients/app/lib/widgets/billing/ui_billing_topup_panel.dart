import 'package:alienai_c35/c/api/referral_conn.dart';
import 'package:alienai_c35/c/billing/billing_api.dart';
import 'package:alienai_c35/c/ui/ui_friendly_error.dart';
import 'package:alienai_c35/widgets/billing/billing_topup.dart';
import 'package:alienai_c35/widgets/ui/ui_input_decoration.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class UiBillingTopupPanel extends StatefulWidget {
  const UiBillingTopupPanel({super.key, required this.conn, this.currency = 'IDR', this.onSubmitted});

  final ReferralConn conn;
  final String currency;
  final VoidCallback? onSubmitted;

  @override
  State<UiBillingTopupPanel> createState() => _UiBillingTopupPanelState();
}

class _UiBillingTopupPanelState extends State<UiBillingTopupPanel> {
  static const _text = Color(0xFFE4E4E7);
  static const _muted = Color(0xFFA1A1AA);

  late final _amountCtrl = TextEditingController();
  late final _proofCtrl = TextEditingController();
  var _busy = false;
  String? _error;
  String? _success;
  late var _packIdr = billingTopupPacksIdr.first;
  late var _packUsd = billingTopupPacksUsd.first;

  bool get _usesIdr => widget.currency.toUpperCase() == 'IDR';

  @override
  void dispose() {
    _amountCtrl.dispose();
    _proofCtrl.dispose();
    super.dispose();
  }

  double get _amountIdr {
    final parsed = billingTopupParseIdr(_amountCtrl.text);
    return (parsed ?? _packIdr).toDouble();
  }

  double get _amountUsd {
    final parsed = double.tryParse(_amountCtrl.text.replaceAll(',', '.'));
    return parsed ?? _packUsd;
  }

  Future<void> _submit() async {
    if (_busy) return;
    final proof = _proofCtrl.text.trim();
    if (proof.isEmpty) {
      setState(() => _error = 'Paste bukti transfer (URL gambar)');
      return;
    }
    final idr = _usesIdr ? _amountIdr : 0.0;
    final usd = _usesIdr ? 0.0 : _amountUsd;
    if (!billingTopupAmountOk(amountUsd: usd, amountIdr: idr, usesIdr: _usesIdr)) {
      setState(() => _error = _usesIdr ? 'Minimum top-up ${billingTopupIdrLabel(billingTopupMinIdr)}' : 'Minimum top-up ${billingTopupUsdLabel(billingTopupMinUsd)}');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
      _success = null;
    });
    try {
      await billingTopupPut(widget.conn, amountUsd: usd, amountIdr: idr, proofUrl: proof);
      if (!mounted) return;
      setState(() {
        _busy = false;
        _success = 'Top-up submitted. Admin will review within 1x24 jam.';
      });
      widget.onSubmitted?.call();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = uiReferralError(e, fallback: 'Top-up failed');
      });
    }
  }

  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_usesIdr)
            Text(billingManualTransferInstructions(amountIdr: _packIdr), style: const TextStyle(color: _muted, fontSize: 12, height: 1.4))
          else
            const Text('Transfer to our USD account, then paste proof URL.', style: TextStyle(color: _muted, fontSize: 12, height: 1.4)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: (_usesIdr ? billingTopupPacksIdr : billingTopupPacksUsd).map((p) {
              final selected = _usesIdr ? _packIdr == p : _packUsd == p;
              return ChoiceChip(
                label: Text(_usesIdr ? billingTopupIdrLabel(p) : billingTopupUsdLabel(p)),
                selected: selected,
                onSelected: _busy
                    ? null
                    : (_) => setState(() {
                          if (_usesIdr) {
                            _packIdr = p;
                            _amountCtrl.text = p.toInt().toString();
                          } else {
                            _packUsd = p;
                            _amountCtrl.text = p.toStringAsFixed(0);
                          }
                        }),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _amountCtrl,
            enabled: !_busy,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
            decoration: UiInputDecoration.of(context, hintText: _usesIdr ? 'Jumlah (IDR)' : 'Amount (USD)'),
            style: const TextStyle(color: _text),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _proofCtrl,
            enabled: !_busy,
            decoration: UiInputDecoration.of(context, hintText: 'URL bukti transfer (https://...)'),
            style: const TextStyle(color: _text),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: const TextStyle(color: Color(0xFFF87171), fontSize: 12)),
          ],
          if (_success != null) ...[
            const SizedBox(height: 8),
            Text(_success!, style: const TextStyle(color: Color(0xFF34D399), fontSize: 12)),
          ],
          const SizedBox(height: 12),
          FilledButton(
            onPressed: _busy ? null : _submit,
            child: _busy ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Submit top-up'),
          ),
        ],
      );
}

import 'dart:async';

import 'package:alienai_c35/c/api/referral_conn.dart';
import 'package:alienai_c35/c/billing/billing_api.dart';
import 'package:alienai_c35/c/billing/finance_api.dart';
import 'package:alienai_c35/c/cas/cas_client.dart';
import 'package:alienai_c35/c/media/ask_media.dart';
import 'package:alienai_c35/c/media/media_types.dart';
import 'package:alienai_c35/c/pb/c35/billing.pb.dart';
import 'package:alienai_c35/c/ui/money_format.dart';
import 'package:alienai_c35/c/ui/ui_friendly_error.dart';
import 'package:alienai_c35/widgets/billing/billing_topup.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

enum BillingTopupMethod { qris, virtualAccount, manualTransfer }

class _WalletIdrInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return const TextEditingValue(text: '');
    final n = int.tryParse(digits) ?? 0;
    final formatted = moneyFmtIdrGrouped(n);
    return TextEditingValue(text: formatted, selection: TextSelection.collapsed(offset: formatted.length));
  }
}

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
  static const _accent = Color(0xFF34D399);

  late final _amountCtrl = TextEditingController();
  var _method = BillingTopupMethod.qris;
  var _busy = false;
  String? _error;
  ResBillingTopupPut? _result;
  Uint8List? _proofBytes;
  String? _proofMime;
  BillingReceiveAccount? _receiveAccount;

  bool get _usesIdr => widget.currency.toUpperCase() == 'IDR';

  double get _amountIdr {
    final parsed = billingTopupParseIdr(_amountCtrl.text);
    return (parsed ?? 0).toDouble();
  }

  double get _amountUsd {
    final parsed = double.tryParse(_amountCtrl.text.replaceAll(',', '.'));
    return parsed ?? 0;
  }

  bool get _amountOk => _usesIdr ? billingTopupAmountOk(amountUsd: 0, amountIdr: _amountIdr, usesIdr: true) : billingTopupAmountOk(amountUsd: _amountUsd, usesIdr: false);

  @override
  void initState() {
    super.initState();
    unawaited(_loadReceiveAccounts());
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadReceiveAccounts() async {
    try {
      final accounts = await financeReceiveAccountList(widget.conn, currency: widget.currency);
      if (!mounted) return;
      setState(() {
        _receiveAccount = accounts.isEmpty
            ? null
            : accounts.firstWhere((a) => a.isDefault, orElse: () => accounts.first);
      });
    } catch (_) {}
  }

  void _setPack(double value) {
    _amountCtrl.text = _usesIdr ? moneyFmtIdrGrouped(value.round()) : value.toStringAsFixed(0);
    setState(() {});
  }

  Future<void> _pickProof() async {
    final picked = await askMedia(context: context, types: const [MediaType.image], allowMultiple: false);
    if (picked == null || picked.isEmpty || !mounted) return;
    final item = picked.first;
    setState(() {
      _proofBytes = item.bytes;
      _proofMime = item.mime;
    });
  }

  Future<String?> _uploadProof() async {
    final bytes = _proofBytes;
    if (bytes == null) return null;
    final res = await casUpload(bytes: bytes, mime: _proofMime ?? 'image/jpeg', name: 'topup-proof.jpg');
    return res?.url;
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _submit() async {
    if (_busy || !_amountOk) {
      setState(() => _error = _usesIdr ? 'Minimum top-up ${billingTopupIdrLabel(billingTopupMinIdr)}' : 'Minimum top-up ${billingTopupUsdLabel(billingTopupMinUsd)}');
      return;
    }
    if (_method == BillingTopupMethod.manualTransfer && _proofBytes == null) {
      setState(() => _error = 'Upload transfer proof to continue');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
      _result = null;
    });
    try {
      final provider = _method == BillingTopupMethod.manualTransfer
          ? 'manual'
          : _usesIdr
              ? 'midtrans'
              : 'stripe';
      final paymentType = switch (_method) {
        BillingTopupMethod.virtualAccount => 'bank_transfer',
        BillingTopupMethod.manualTransfer => 'bank_transfer',
        _ => 'qris',
      };
      var proofUrl = '';
      if (_method == BillingTopupMethod.manualTransfer) {
        proofUrl = await _uploadProof() ?? '';
        if (proofUrl.isEmpty) throw Exception('Proof upload failed');
      }
      final res = await billingTopupPut(
        widget.conn,
        amountUsd: _usesIdr ? 0 : _amountUsd,
        amountIdr: _usesIdr ? _amountIdr : 0,
        proofUrl: proofUrl,
        provider: provider,
        paymentType: paymentType,
      );
      if (!mounted) return;
      setState(() {
        _busy = false;
        _result = res;
      });
      if (_method == BillingTopupMethod.manualTransfer || res.status == 'pending_review') {
        widget.onSubmitted?.call();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = uiReferralError(e, fallback: 'Top-up failed');
      });
    }
  }

  Widget _methodTile(BillingTopupMethod method, {bool compact = false}) {
    final selected = _method == method;
    final label = switch (method) {
      BillingTopupMethod.qris => 'QRIS',
      BillingTopupMethod.virtualAccount => 'Virtual Account',
      BillingTopupMethod.manualTransfer => 'Manual transfer',
    };
    final icon = switch (method) {
      BillingTopupMethod.qris => Icon(Icons.qr_code_2_rounded, size: 18, color: selected ? _accent : _muted),
      BillingTopupMethod.virtualAccount => Icon(Icons.account_balance_rounded, size: 18, color: selected ? _accent : _muted),
      BillingTopupMethod.manualTransfer => Icon(Icons.receipt_long_rounded, size: 18, color: selected ? _accent : _muted),
    };
    return Material(
      color: selected ? const Color(0x1434D399) : const Color(0xFF1A1A1E),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(compact ? 10 : 12),
        side: BorderSide(color: selected ? _accent : const Color(0xFF27272A)),
      ),
      child: InkWell(
        onTap: _busy ? null : () => setState(() => _method = method),
        borderRadius: BorderRadius.circular(compact ? 10 : 12),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 14, vertical: compact ? 10 : 12),
          child: compact
              ? Column(mainAxisSize: MainAxisSize.min, children: [
                  icon,
                  const SizedBox(height: 6),
                  Text(label, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: selected ? _accent : _text, fontSize: 10, fontWeight: selected ? FontWeight.w600 : FontWeight.w500)),
                ])
              : Row(children: [
                  icon,
                  const SizedBox(width: 12),
                  Expanded(child: Text(label, style: TextStyle(color: selected ? _accent : _text, fontSize: 13, fontWeight: selected ? FontWeight.w600 : FontWeight.w500))),
                  if (selected) const Icon(Icons.check_circle_rounded, size: 18, color: _accent),
                ]),
        ),
      ),
    );
  }

  Widget _manualTransferBox() {
    final acct = _receiveAccount;
    final bankId = acct?.bankId.isNotEmpty == true ? acct!.bankId : billingManualBank;
    final accountNumber = acct?.accountNumber.isNotEmpty == true ? acct!.accountNumber : billingManualAccount;
    final accountName = acct?.accountName.isNotEmpty == true ? acct!.accountName : billingManualAccountName;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: const Color(0x1FF59E0B), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0x66F59E0B))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(children: [
            Icon(Icons.account_balance_outlined, size: 18, color: Color(0xFFFBBF24)),
            SizedBox(width: 8),
            Text('Manual bank transfer', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
          ]),
          const SizedBox(height: 8),
          Text('$bankId · $accountNumber', style: const TextStyle(color: Color(0xFFD4D4D8), fontSize: 13)),
          Text(accountName, style: const TextStyle(color: Color(0xFF71717A), fontSize: 12)),
          if (_amountIdr > 0) ...[
            const SizedBox(height: 6),
            Text('Transfer exactly ${billingTopupIdrLabel(_amountIdr)}', style: const TextStyle(color: Color(0xFFFBBF24), fontSize: 12, fontWeight: FontWeight.w600)),
          ],
        ],
      ),
    );
  }

  Widget _paymentResult(ResBillingTopupPut res) {
    final qr = res.qrCodeData;
    final url = res.paymentUrl;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (res.status.isNotEmpty) Text('Status: ${res.status}', style: const TextStyle(color: _muted, fontSize: 12)),
        if (res.instruction.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(res.instruction, style: const TextStyle(color: _text, fontSize: 12, height: 1.4)),
        ],
        if (qr.isNotEmpty) ...[
          const SizedBox(height: 12),
          Center(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
              child: QrImageView(data: qr, size: 180, backgroundColor: Colors.white),
            ),
          ),
        ],
        if (url.isNotEmpty) ...[
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () => _openUrl(url),
            icon: const Icon(Icons.open_in_new, size: 16),
            label: Text(qr.isEmpty ? 'Open payment page' : 'Open payment URL'),
          ),
        ],
        if (res.status == 'pending_review') ...[
          const SizedBox(height: 8),
          const Text('Transfer proof submitted. Balance updates after review.', style: TextStyle(color: _muted, fontSize: 12)),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final packs = _usesIdr ? billingTopupPacksIdr : billingTopupPacksUsd;
    final result = _result;
    final canSubmit = _amountOk && (_method != BillingTopupMethod.manualTransfer || _proofBytes != null) && !_busy && result == null;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(_usesIdr ? 'Amount (IDR)' : 'Amount (USD)', style: const TextStyle(color: _muted, fontSize: 12)),
        const SizedBox(height: 8),
        TextField(
          controller: _amountCtrl,
          enabled: !_busy && result == null,
          keyboardType: TextInputType.number,
          inputFormatters: _usesIdr ? [_WalletIdrInputFormatter()] : [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
          decoration: InputDecoration(
            prefixText: _usesIdr ? 'Rp ' : '\$ ',
            prefixStyle: const TextStyle(color: Color(0xFF71717A), fontSize: 18),
            hintText: _usesIdr ? '50.000' : '10',
            hintStyle: const TextStyle(color: Color(0xFF52525B)),
            filled: true,
            fillColor: const Color(0xFF1A1A1E),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: packs.map((p) => ActionChip(
                label: Text(_usesIdr ? billingTopupIdrLabel(p) : billingTopupUsdLabel(p)),
                backgroundColor: const Color(0xFF1A1A1E),
                labelStyle: const TextStyle(color: Color(0xFFD4D4D8), fontSize: 12),
                side: const BorderSide(color: Color(0xFF27272A)),
                onPressed: _busy || result != null ? null : () => _setPack(p),
              )).toList(),
        ),
        if (_usesIdr) ...[
          const SizedBox(height: 16),
          const Text('Payment method', style: TextStyle(color: _muted, fontSize: 12)),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: _methodTile(BillingTopupMethod.qris, compact: true)),
            const SizedBox(width: 8),
            Expanded(child: _methodTile(BillingTopupMethod.virtualAccount, compact: true)),
            const SizedBox(width: 8),
            Expanded(child: _methodTile(BillingTopupMethod.manualTransfer, compact: true)),
          ]),
        ],
        if (_method == BillingTopupMethod.manualTransfer && _usesIdr) ...[
          const SizedBox(height: 12),
          _manualTransferBox(),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: _busy ? null : _pickProof,
            icon: Icon(_proofBytes == null ? Icons.upload_file : Icons.check_circle, size: 16, color: _accent),
            label: Text(_proofBytes == null ? 'Upload transfer proof' : 'Proof selected', style: const TextStyle(color: _accent)),
            style: OutlinedButton.styleFrom(side: BorderSide(color: _accent.withValues(alpha: 0.6))),
          ),
        ],
        if (_error != null) ...[
          const SizedBox(height: 8),
          Text(_error!, style: const TextStyle(color: Color(0xFFF87171), fontSize: 12)),
        ],
        if (result != null) ...[
          const SizedBox(height: 16),
          _paymentResult(result),
        ] else ...[
          const SizedBox(height: 16),
          FilledButton(
            onPressed: canSubmit ? _submit : null,
            style: FilledButton.styleFrom(backgroundColor: _accent, foregroundColor: const Color(0xFF09090B), padding: const EdgeInsets.symmetric(vertical: 14)),
            child: _busy
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF09090B)))
                : Text(_method == BillingTopupMethod.manualTransfer ? 'Submit for review' : 'Continue to payment'),
          ),
        ],
      ],
    );
  }
}

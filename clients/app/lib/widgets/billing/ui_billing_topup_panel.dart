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
  static const _border = Color(0xFF27272A);

  late final _amountCtrl = TextEditingController();
  var _step = 0;
  var _busy = false;
  String? _error;
  ResBillingTopupPut? _result;
  Uint8List? _proofBytes;
  String? _proofMime;
  List<BillingTopupMethodOption> _methods = const [];
  BillingTopupMethodOption? _selectedMethod;
  BillingReceiveAccount? _receiveAccount;
  Timer? _pollTimer;
  String _pollStatus = '';

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

  bool get _isManual => _selectedMethod?.provider == 'manual';

  double get _feeIdr => _isManual ? 0 : (_selectedMethod?.feeAmountIdr ?? 0);

  double get _grossIdr => _amountIdr + _feeIdr;

  bool get _isSettled => _pollStatus == 'settled';

  bool get _isPendingReview => _pollStatus == 'pending_review';

  @override
  void initState() {
    super.initState();
    unawaited(_loadMethods());
    unawaited(_loadReceiveAccounts());
  }

  Future<void> _loadReceiveAccounts() async {
    try {
      final accounts = await financeReceiveAccountList(widget.conn, currency: widget.currency);
      if (!mounted) return;
      setState(() {
        _receiveAccount = accounts.isEmpty ? null : accounts.firstWhere((a) => a.isDefault, orElse: () => accounts.first);
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadMethods() async {
    if (!_usesIdr) return;
    try {
      final res = await billingTopupMethods(widget.conn, sampleAmountIdr: _amountIdr > 0 ? _amountIdr : billingTopupMinIdr);
      if (!mounted) return;
      setState(() {
        _methods = res.methods;
        _selectedMethod = res.methods.isEmpty ? null : res.methods.first;
      });
    } catch (_) {}
  }

  Future<void> _refreshMethodFees() async {
    if (!_usesIdr || !_amountOk) return;
    try {
      final res = await billingTopupMethods(widget.conn, sampleAmountIdr: _amountIdr);
      if (!mounted) return;
      final prevId = _selectedMethod?.id;
      BillingTopupMethodOption? next;
      if (res.methods.isEmpty) {
        next = null;
      } else if (prevId == null) {
        next = res.methods.first;
      } else {
        final match = res.methods.where((m) => m.id == prevId);
        next = match.isEmpty ? res.methods.first : match.first;
      }
      setState(() {
        _methods = res.methods;
        _selectedMethod = next;
      });
    } catch (_) {}
  }

  void _setPack(double value) {
    _amountCtrl.text = _usesIdr ? moneyFmtIdrGrouped(value.round()) : value.toStringAsFixed(0);
    unawaited(_refreshMethodFees());
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

  void _startPolling(String orderId) {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) => unawaited(_pollStatusOnce(orderId)));
    unawaited(_pollStatusOnce(orderId));
  }

  Future<void> _pollStatusOnce(String orderId) async {
    try {
      final res = await billingTopupGet(widget.conn, orderId: orderId);
      if (!mounted) return;
      final status = res.request.status;
      setState(() => _pollStatus = status);
      if (status == 'settled' || status == 'failed' || status == 'expired' || status == 'rejected') {
        _pollTimer?.cancel();
        if (status == 'settled') widget.onSubmitted?.call();
      }
    } catch (_) {}
  }

  void _continueToPayment() {
    if (!_amountOk) {
      setState(() => _error = _usesIdr ? 'Minimum top-up ${billingTopupIdrLabel(billingTopupMinIdr)}' : 'Minimum top-up ${billingTopupUsdLabel(billingTopupMinUsd)}');
      return;
    }
    setState(() {
      _error = null;
      _step = 1;
    });
    if (!_isManual) unawaited(_createMidtransPayment());
  }

  Future<void> _createMidtransPayment() async {
    final method = _selectedMethod;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final paymentType = method?.paymentType.isNotEmpty == true ? method!.paymentType : 'qris';
      final res = await billingTopupPut(
        widget.conn,
        amountUsd: _usesIdr ? 0 : _amountUsd,
        amountIdr: _usesIdr ? _amountIdr : 0,
        proofUrl: '',
        provider: _usesIdr ? 'midtrans' : 'stripe',
        paymentType: paymentType,
      );
      if (!mounted) return;
      setState(() {
        _busy = false;
        _result = res;
        _pollStatus = res.status;
      });
      if (res.orderId.isNotEmpty) _startPolling(res.orderId);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = uiReferralError(e, fallback: 'Top-up failed');
      });
    }
  }

  Future<void> _submitManual() async {
    if (_proofBytes == null) {
      setState(() => _error = 'Upload transfer proof to continue');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final proofUrl = await _uploadProof() ?? '';
      if (proofUrl.isEmpty) throw Exception('Proof upload failed');
      final res = await billingTopupPut(
        widget.conn,
        amountUsd: 0,
        amountIdr: _amountIdr,
        proofUrl: proofUrl,
        provider: 'manual',
        paymentType: 'bank_transfer',
      );
      if (!mounted) return;
      setState(() {
        _busy = false;
        _result = res;
        _pollStatus = res.status;
      });
      if (res.orderId.isNotEmpty) _startPolling(res.orderId);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = uiReferralError(e, fallback: 'Top-up failed');
      });
    }
  }

  Widget _methodTile(BillingTopupMethodOption method) {
    final selected = _selectedMethod?.id == method.id;
    final isManual = method.provider == 'manual';
    final icon = isManual
        ? Icon(Icons.receipt_long_rounded, size: 18, color: selected ? _accent : _muted)
        : (method.id.contains('qris')
            ? Icon(Icons.qr_code_2_rounded, size: 18, color: selected ? _accent : _muted)
            : Icon(Icons.account_balance_rounded, size: 18, color: selected ? _accent : _muted));
    return Material(
      color: selected ? const Color(0x1434D399) : const Color(0xFF1A1A1E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: BorderSide(color: selected ? _accent : _border)),
      child: InkWell(
        onTap: _busy ? null : () => setState(() => _selectedMethod = method),
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              icon,
              const SizedBox(height: 6),
              Text(method.label, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: selected ? _accent : _text, fontSize: 10, fontWeight: selected ? FontWeight.w600 : FontWeight.w500)),
              if (method.note.isNotEmpty) ...[
                const SizedBox(height: 3),
                Text(method.note, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: isManual ? const Color(0xFFFBBF24) : _muted, fontSize: 9)),
              ],
              if (!isManual && method.feeAmountIdr > 0) ...[
                const SizedBox(height: 2),
                Text('+${billingTopupIdrLabel(method.feeAmountIdr)} fee', style: const TextStyle(color: _muted, fontSize: 9)),
              ],
            ],
          ),
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

  Widget _feeSummary() {
    if (_isManual || _feeIdr <= 0) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: const Color(0xFF1A1A1E), borderRadius: BorderRadius.circular(10), border: Border.all(color: _border)),
      child: Column(
        children: [
          _feeRow('Wallet credit', billingTopupIdrLabel(_amountIdr)),
          const SizedBox(height: 4),
          _feeRow('Payment fee', billingTopupIdrLabel(_feeIdr)),
          const Divider(color: _border, height: 16),
          _feeRow('You pay', billingTopupIdrLabel(_grossIdr), bold: true),
        ],
      ),
    );
  }

  Widget _feeRow(String label, String value, {bool bold = false}) => Row(
        children: [
          Text(label, style: TextStyle(color: _muted, fontSize: 12, fontWeight: bold ? FontWeight.w600 : FontWeight.w400)),
          const Spacer(),
          Text(value, style: TextStyle(color: bold ? _text : _muted, fontSize: 12, fontWeight: bold ? FontWeight.w700 : FontWeight.w500)),
        ],
      );

  Widget _statusBanner() {
    if (_isSettled) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: const Color(0x1434D399), borderRadius: BorderRadius.circular(12), border: Border.all(color: _accent)),
        child: const Row(children: [
          Icon(Icons.check_circle_rounded, color: _accent, size: 22),
          SizedBox(width: 10),
          Expanded(child: Text('Payment verified — balance updated', style: TextStyle(color: _accent, fontWeight: FontWeight.w600, fontSize: 13))),
        ]),
      );
    }
    if (_isPendingReview) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: const Color(0x1FF59E0B), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0x66F59E0B))),
        child: const Row(children: [
          Icon(Icons.hourglass_top_rounded, color: Color(0xFFFBBF24), size: 22),
          SizedBox(width: 10),
          Expanded(child: Text('Submitted for review — balance updates after admin approval', style: TextStyle(color: Color(0xFFFBBF24), fontWeight: FontWeight.w600, fontSize: 12))),
        ]),
      );
    }
    if (_pollStatus == 'failed' || _pollStatus == 'expired' || _pollStatus == 'rejected') {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: const Color(0x14F87171), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0x66F87171))),
        child: Row(children: [
          const Icon(Icons.error_outline_rounded, color: Color(0xFFF87171), size: 22),
          const SizedBox(width: 10),
          Expanded(child: Text('Payment ${_pollStatus.replaceAll('_', ' ')}', style: const TextStyle(color: Color(0xFFF87171), fontWeight: FontWeight.w600, fontSize: 13))),
        ]),
      );
    }
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: const Color(0xFF1A1A1E), borderRadius: BorderRadius.circular(10), border: Border.all(color: _border)),
      child: Row(children: [
        if (!_isManual && !_isSettled) ...[
          const SizedBox(width: 4, height: 4, child: CircularProgressIndicator(strokeWidth: 2, color: _muted)),
          const SizedBox(width: 10),
        ],
        Expanded(child: Text(_isManual ? 'Waiting for admin approval' : 'Waiting for payment…', style: const TextStyle(color: _muted, fontSize: 12))),
      ]),
    );
  }

  Widget _paymentResult(ResBillingTopupPut res) {
    final qr = res.qrCodeData;
    final url = res.paymentUrl;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _statusBanner(),
        if (res.instruction.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(res.instruction, style: const TextStyle(color: _text, fontSize: 12, height: 1.4)),
        ],
        if (_isManual) ...[
          const SizedBox(height: 12),
          _manualTransferBox(),
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
        if (url.isNotEmpty && !_isSettled) ...[
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () => _openUrl(url),
            icon: const Icon(Icons.open_in_new, size: 16),
            label: Text(qr.isEmpty ? 'Open payment page' : 'Open payment URL'),
            style: FilledButton.styleFrom(backgroundColor: _accent, foregroundColor: const Color(0xFF09090B)),
          ),
        ],
      ],
    );
  }

  Widget _buildSetupStep() {
    final packs = _usesIdr ? billingTopupPacksIdr : billingTopupPacksUsd;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(_usesIdr ? 'Amount (IDR)' : 'Amount (USD)', style: const TextStyle(color: _muted, fontSize: 12)),
        const SizedBox(height: 8),
        TextField(
          controller: _amountCtrl,
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
          onChanged: (_) {
            unawaited(_refreshMethodFees());
            setState(() {});
          },
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: packs
              .map((p) => ActionChip(
                    label: Text(_usesIdr ? billingTopupIdrLabel(p) : billingTopupUsdLabel(p)),
                    backgroundColor: const Color(0xFF1A1A1E),
                    labelStyle: const TextStyle(color: Color(0xFFD4D4D8), fontSize: 12),
                    side: const BorderSide(color: _border),
                    onPressed: _busy ? null : () => _setPack(p),
                  ))
              .toList(),
        ),
        if (_usesIdr && _methods.isNotEmpty) ...[
          const SizedBox(height: 16),
          const Text('Payment method', style: TextStyle(color: _muted, fontSize: 12)),
          const SizedBox(height: 8),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 0.88,
            children: _methods.map(_methodTile).toList(),
          ),
        ],
        if (_amountOk && !_isManual) ...[
          const SizedBox(height: 12),
          _feeSummary(),
        ],
        if (_error != null) ...[
          const SizedBox(height: 8),
          Text(_error!, style: const TextStyle(color: Color(0xFFF87171), fontSize: 12)),
        ],
        const SizedBox(height: 16),
        FilledButton(
          onPressed: !_amountOk ? null : _continueToPayment,
          style: FilledButton.styleFrom(backgroundColor: _accent, foregroundColor: const Color(0xFF09090B), padding: const EdgeInsets.symmetric(vertical: 14)),
          child: const Text('Continue'),
        ),
      ],
    );
  }

  Widget _buildPaymentStep() {
    final res = _result;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            IconButton(
              onPressed: _isSettled || _busy ? null : () => setState(() => _step = 0),
              icon: const Icon(Icons.arrow_back_rounded, color: _muted, size: 20),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                _isSettled ? 'Payment complete' : (_isManual ? 'Transfer instructions' : 'Complete payment'),
                style: const TextStyle(color: _text, fontWeight: FontWeight.w600, fontSize: 14),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_isManual && res == null) ...[
          _manualTransferBox(),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: _busy ? null : _pickProof,
            icon: Icon(_proofBytes == null ? Icons.upload_file : Icons.check_circle, size: 16, color: _accent),
            label: Text(_proofBytes == null ? 'Upload transfer proof' : 'Proof selected', style: const TextStyle(color: _accent)),
            style: OutlinedButton.styleFrom(side: BorderSide(color: _accent.withValues(alpha: 0.6))),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: const TextStyle(color: Color(0xFFF87171), fontSize: 12)),
          ],
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _busy || _proofBytes == null ? null : _submitManual,
            style: FilledButton.styleFrom(backgroundColor: _accent, foregroundColor: const Color(0xFF09090B), padding: const EdgeInsets.symmetric(vertical: 14)),
            child: _busy
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF09090B)))
                : const Text('Submit for review'),
          ),
        ] else if (_busy && res == null) ...[
          const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator(strokeWidth: 2, color: _accent))),
          const SizedBox(height: 8),
          const Text('Creating payment…', textAlign: TextAlign.center, style: TextStyle(color: _muted, fontSize: 12)),
        ] else if (res != null) ...[
          _paymentResult(res),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: const TextStyle(color: Color(0xFFF87171), fontSize: 12)),
          ],
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) => _step == 0 ? _buildSetupStep() : _buildPaymentStep();
}

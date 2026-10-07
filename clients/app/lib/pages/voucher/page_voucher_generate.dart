import 'dart:async';

import 'package:alienai_c35/c/api/referral_conn.dart';
import 'package:alienai_c35/c/billing/billing_summary_api.dart';
import 'package:alienai_c35/c/billing/billing_voucher_api.dart';
import 'package:alienai_c35/c/pb/c35/billing.pb.dart';
import 'package:alienai_c35/c/ui/money_format.dart';
import 'package:alienai_c35/c/ui/ui_friendly_error.dart';
import 'package:alienai_c35/widgets/billing/billing_plan_format.dart';
import 'package:alienai_c35/widgets/io/in_money_idr.dart';
import 'package:alienai_c35/widgets/ui/ui_input_decoration.dart';
import 'package:alienai_c35/widgets/ui/ui_page.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

enum _VoucherWizardKind {
  credit,
  userPackage,
  botPackage,
  customUserPackage,
  customBotPackage,
}

const _lockedPlanIdr = {
  'lite': {'monthly': 59000.0, 'yearly': 49000.0},
  'plus': {'monthly': 105000.0, 'yearly': 99000.0},
  'pro': {'monthly': 340000.0, 'yearly': 309000.0},
  'ultra': {'monthly': 1200000.0, 'yearly': 1000000.0},
  'bot.lite': {'monthly': 49000.0, 'yearly': 39000.0},
  'bot.small': {'monthly': 99000.0, 'yearly': 89000.0},
};

class PageVoucherWizard extends StatefulWidget {
  const PageVoucherWizard({super.key, required this.conn});

  final ReferralConn conn;

  @override
  State<PageVoucherWizard> createState() => _PageVoucherWizardState();
}

class _PageVoucherWizardState extends State<PageVoucherWizard> {
  static const _bg = Color(0xFF08080A);
  static const _card = Color(0xFF18181B);
  static const _text = Color(0xFFF4F4F5);
  static const _muted = Color(0xFFA1A1AA);
  static const _border = Color(0xFF27272A);
  static const _accent = Color(0xFF34D399);

  var _step = 0;
  var _busy = false;
  String? _error;
  _VoucherWizardKind _kind = _VoucherWizardKind.credit;
  var _billingPeriod = 'monthly';
  var _planSlug = 'lite';
  var _noExpiry = true;
  DateTime? _expiresAt;
  List<BillingPlanDoc> _userPlans = [];
  List<BillingPlanDoc> _botPlans = [];
  List<String> _issuedCodes = [];
  late final _nameCtrl = TextEditingController();
  late final _faceCtrl = TextEditingController();
  late final _listCtrl = TextEditingController();
  late final _creditCtrl = TextEditingController();
  late final _paymentRefCtrl = TextEditingController();
  late final _alienPoolCtrl = TextEditingController();
  late final _frontierPoolCtrl = TextEditingController();
  late final _qtyCtrl = TextEditingController(text: '1');

  bool get _isCustom => _kind == _VoucherWizardKind.customUserPackage || _kind == _VoucherWizardKind.customBotPackage;
  bool get _isPackage => _kind != _VoucherWizardKind.credit;
  bool get _scopeBot => _kind == _VoucherWizardKind.botPackage || _kind == _VoucherWizardKind.customBotPackage;
  bool get _lockedPackageRetail => _isPackage && !_isCustom;

  @override
  void initState() {
    super.initState();
    _applyRetailDefaults();
    unawaited(_loadPlans());
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _faceCtrl.dispose();
    _listCtrl.dispose();
    _creditCtrl.dispose();
    _paymentRefCtrl.dispose();
    _alienPoolCtrl.dispose();
    _frontierPoolCtrl.dispose();
    _qtyCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadPlans() async {
    try {
      final summary = await billingSummaryGet(widget.conn);
      if (!mounted) return;
      setState(() {
        _userPlans = List<BillingPlanDoc>.from(summary.plans);
        _botPlans = List<BillingPlanDoc>.from(summary.botPlans);
      });
      _applyRetailDefaults();
    } catch (_) {}
  }

  double? _parseIdr(String raw) => moneyParseIdr(raw);

  double _planListIdr(String slug, String period) {
    final plans = _scopeBot ? _botPlans : _userPlans;
    for (final p in plans) {
      if (p.slug.trim().toLowerCase() != slug.trim().toLowerCase()) continue;
      if (period == 'yearly') {
        final y = p.priceIdrYearlyList > 0 ? p.priceIdrYearlyList : p.priceIdrYearly;
        if (y > 0) return y;
      } else {
        final m = p.priceIdrMonthlyList > 0 ? p.priceIdrMonthlyList : p.priceIdrMonthly;
        if (m > 0) return m;
      }
    }
    final locked = _lockedPlanIdr[slug.trim().toLowerCase()];
    if (locked != null) return locked[period] ?? locked['monthly'] ?? 0;
    return 0;
  }

  void _applyRetailDefaults() {
    if (!_lockedPackageRetail) return;
    final list = _planListIdr(_planSlug, _billingPeriod);
    if (list <= 0) return;
    _faceCtrl.text = moneyFmtIdrGrouped(list.round());
  }

  String _planSlugLabel(String slug) => switch (slug.trim().toLowerCase()) {
        'bot.lite' => 'Bot Lite',
        'bot.small' => 'Bot Small',
        _ => billingPlanTierLabel(slug),
      };

  String _planDropdownLabel(String slug) {
    final idr = _planListIdr(slug, _billingPeriod);
    final name = _planSlugLabel(slug);
    if (idr <= 0) return name;
    return '$name · ${moneyFmtIdr(idr)}';
  }

  double _effectiveListIdr() {
    if (_lockedPackageRetail) return _planListIdr(_planSlug, _billingPeriod);
    return _parseIdr(_listCtrl.text) ?? 0;
  }

  List<String> get _planOptions => _scopeBot ? const ['bot.lite', 'bot.small'] : const ['lite', 'plus', 'pro', 'ultra'];

  double? get _marginIdr {
    final face = _parseIdr(_faceCtrl.text);
    if (face == null) return null;
    final list = _effectiveListIdr();
    if (list <= 0) return null;
    return list - face;
  }

  String? _validateStep0() {
    if (_nameCtrl.text.trim().isEmpty) return 'Display name is required';
    final face = _parseIdr(_faceCtrl.text);
    if (face == null || face <= 0) return 'Customer price (IDR) is required';
    if (!_lockedPackageRetail) {
      final list = _parseIdr(_listCtrl.text);
      if (list == null || list <= 0) return 'List price (IDR) is required';
    }
    if (_kind == _VoucherWizardKind.credit) {
      final credit = _parseIdr(_creditCtrl.text);
      if (credit == null || credit <= 0) return 'Credit amount (IDR) is required';
    }
    if (_isCustom) {
      final alien = _parseIdr(_alienPoolCtrl.text) ?? 0;
      if (alien <= 0) return 'Alien pool limit (IDR) is required for custom packages';
    }
    if (!_noExpiry && _expiresAt == null) return 'Pick an expiration date or choose No expiry';
    return null;
  }

  String? _validateStep1() {
    final qty = int.tryParse(_qtyCtrl.text.trim()) ?? 0;
    if (qty < 1 || qty > 50) return 'Quantity must be 1–50';
    return null;
  }

  void _nextFromStep0() {
    final err = _validateStep0();
    if (err != null) {
      setState(() => _error = err);
      return;
    }
    setState(() {
      _error = null;
      _step = 1;
    });
  }

  Future<void> _issue() async {
    final err = _validateStep1();
    if (err != null) {
      setState(() => _error = err);
      return;
    }
    final face = _parseIdr(_faceCtrl.text)!;
    final list = _effectiveListIdr();
    final qty = int.parse(_qtyCtrl.text.trim());
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final expiresMs = _noExpiry
          ? Int64.ZERO
          : Int64(_expiresAt!.copyWith(hour: 23, minute: 59, second: 59).millisecondsSinceEpoch);
      final res = await billingVoucherIssue(
        widget.conn,
        kind: _kind == _VoucherWizardKind.credit ? 'credit' : 'package',
        planSlug: _isPackage && !_isCustom ? _planSlug : '',
        durationMonths: _billingPeriod == 'yearly' ? 12 : 1,
        creditIdr: (_parseIdr(_creditCtrl.text) ?? 0).toDouble(),
        faceValueIdr: face,
        paymentRef: _paymentRefCtrl.text.trim(),
        name: _nameCtrl.text.trim(),
        scope: _scopeBot ? 'bot' : 'user',
        billingPeriod: _billingPeriod,
        listPriceIdr: list,
        alienPoolLimitIdr: _isCustom ? (_parseIdr(_alienPoolCtrl.text) ?? 0) : 0,
        frontierPoolLimitIdr: _isCustom ? (_parseIdr(_frontierPoolCtrl.text) ?? 0) : 0,
        expiresAtMs: expiresMs,
        quantity: qty,
      );
      if (!mounted) return;
      setState(() {
        _busy = false;
        _issuedCodes = res.codes.isNotEmpty ? List<String>.from(res.codes) : [res.code];
        _step = 2;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = uiReferralError(e, fallback: 'Failed to issue voucher');
      });
    }
  }

  Future<void> _copyAll() async {
    if (_issuedCodes.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: _issuedCodes.join('\n')));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Codes copied')));
  }

  Future<void> _printCodes() async {
    if (_issuedCodes.isEmpty) return;
    final doc = pw.Document();
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (ctx) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('Voucher codes', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 12),
            ..._issuedCodes.map((c) => pw.Padding(padding: const pw.EdgeInsets.only(bottom: 6), child: pw.Text(c, style: const pw.TextStyle(fontSize: 14)))),
          ],
        ),
      ),
    );
    await Printing.layoutPdf(onLayout: (_) => doc.save());
  }

  Future<void> _pickExpiry() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _expiresAt ?? now.add(const Duration(days: 30)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365 * 3)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(colorScheme: const ColorScheme.dark(primary: _accent, surface: _card)),
        child: child!,
      ),
    );
    if (picked != null && mounted) setState(() => _expiresAt = picked);
  }

  Widget _kindDropdown() => DropdownButtonFormField<_VoucherWizardKind>(
        initialValue: _kind,
        dropdownColor: _card,
        style: const TextStyle(color: _text),
        decoration: UiInputDecoration.of(context, labelText: 'Voucher type'),
        items: const [
          DropdownMenuItem(value: _VoucherWizardKind.credit, child: Text('Credit')),
          DropdownMenuItem(value: _VoucherWizardKind.userPackage, child: Text('User package')),
          DropdownMenuItem(value: _VoucherWizardKind.botPackage, child: Text('Bot package')),
          DropdownMenuItem(value: _VoucherWizardKind.customUserPackage, child: Text('Custom user package')),
          DropdownMenuItem(value: _VoucherWizardKind.customBotPackage, child: Text('Custom bot package')),
        ],
        onChanged: _busy
            ? null
            : (v) {
                if (v == null) return;
                setState(() {
                  _kind = v;
                  if (_scopeBot && !_planOptions.contains(_planSlug)) _planSlug = 'bot.lite';
                  if (!_scopeBot && !_planOptions.contains(_planSlug)) _planSlug = 'lite';
                });
                _applyRetailDefaults();
              },
      );

  Widget _step0Body() => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _kindDropdown(),
          const SizedBox(height: 12),
          TextField(controller: _nameCtrl, style: const TextStyle(color: _text), decoration: UiInputDecoration.of(context, labelText: 'Display name')),
          const SizedBox(height: 10),
          if (_isPackage && !_isCustom) ...[
            DropdownButtonFormField<String>(
              initialValue: _planSlug,
              dropdownColor: _card,
              style: const TextStyle(color: _text),
              decoration: UiInputDecoration.of(context, labelText: 'Plan'),
              items: [for (final s in _planOptions) DropdownMenuItem(value: s, child: Text(_planDropdownLabel(s)))],
              onChanged: _busy
                  ? null
                  : (v) {
                      if (v == null) return;
                      setState(() => _planSlug = v);
                      _applyRetailDefaults();
                    },
            ),
            const SizedBox(height: 10),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'monthly', label: Text('Monthly')),
                ButtonSegment(value: 'yearly', label: Text('Yearly')),
              ],
              selected: {_billingPeriod},
              onSelectionChanged: _busy
                  ? null
                  : (s) {
                      setState(() => _billingPeriod = s.first);
                      _applyRetailDefaults();
                    },
            ),
            const SizedBox(height: 8),
            Text('Retail list price: ${moneyFmtIdr(_planListIdr(_planSlug, _billingPeriod))}', style: const TextStyle(color: _muted, fontSize: 12)),
            const SizedBox(height: 10),
          ],
          if (_kind == _VoucherWizardKind.credit) ...[
            TextField(
              controller: _creditCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: moneyIdrInputFormatters,
              style: const TextStyle(color: _text),
              decoration: UiInputDecoration.of(context, labelText: 'Wallet credit (IDR)'),
            ),
            const SizedBox(height: 10),
          ],
          if (_isCustom) ...[
            TextField(
              controller: _alienPoolCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: moneyIdrInputFormatters,
              style: const TextStyle(color: _text),
              decoration: UiInputDecoration.of(context, labelText: 'Alien pool limit (IDR)'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _frontierPoolCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: moneyIdrInputFormatters,
              style: const TextStyle(color: _text),
              decoration: UiInputDecoration.of(context, labelText: 'Frontier pool limit (IDR)', hintText: 'Optional'),
            ),
            const SizedBox(height: 10),
          ],
          TextField(
            controller: _faceCtrl,
            keyboardType: TextInputType.number,
            inputFormatters: moneyIdrInputFormatters,
            style: const TextStyle(color: _text),
            decoration: UiInputDecoration.of(context, labelText: 'Customer price (IDR)', hintText: 'What the customer pays'),
            onChanged: (_) => setState(() {}),
          ),
          if (!_lockedPackageRetail) ...[
            const SizedBox(height: 10),
            TextField(
              controller: _listCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: moneyIdrInputFormatters,
              style: const TextStyle(color: _text),
              decoration: UiInputDecoration.of(context, labelText: 'List price (IDR)', hintText: 'Retail reference for margin'),
              onChanged: (_) => setState(() {}),
            ),
          ],
          if (_marginIdr != null) ...[
            const SizedBox(height: 6),
            Text(
              'Your margin (list − customer): ${moneyFmtIdr(_marginIdr!)}',
              style: TextStyle(color: _marginIdr! >= 0 ? _accent : const Color(0xFFF87171), fontSize: 12),
            ),
          ],
          const SizedBox(height: 10),
          TextField(controller: _paymentRefCtrl, style: const TextStyle(color: _text), decoration: UiInputDecoration.of(context, labelText: 'Payment reference', hintText: 'Optional')),
          const SizedBox(height: 14),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('No expiry', style: TextStyle(color: _text, fontSize: 14)),
            value: _noExpiry,
            activeThumbColor: _accent,
            onChanged: _busy ? null : (v) => setState(() => _noExpiry = v),
          ),
          if (!_noExpiry)
            OutlinedButton.icon(
              onPressed: _busy ? null : _pickExpiry,
              icon: const Icon(Icons.calendar_today_outlined, size: 18),
              label: Text(_expiresAt == null ? 'Pick expiration date' : 'Expires ${_expiresAt!.year}-${_expiresAt!.month}/${_expiresAt!.day}'),
            ),
        ],
      );

  Widget _step1Body() => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('How many voucher codes to issue?', style: TextStyle(color: _muted, fontSize: 13)),
          const SizedBox(height: 12),
          TextField(
            controller: _qtyCtrl,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: const TextStyle(color: _text, fontSize: 24, fontWeight: FontWeight.w700),
            decoration: UiInputDecoration.of(context, hintText: '1–50'),
          ),
          const SizedBox(height: 12),
          Text('Face ${moneyFmtIdr(_parseIdr(_faceCtrl.text) ?? 0)} each', style: const TextStyle(color: _muted, fontSize: 12)),
        ],
      );

  Widget _step2Body() => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('${_issuedCodes.length} code(s) issued', style: const TextStyle(color: _accent, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          ..._issuedCodes.map(
            (c) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: SelectableText(c, style: const TextStyle(color: _text, fontFamily: 'monospace', fontWeight: FontWeight.w700, letterSpacing: 1.2)),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: OutlinedButton(onPressed: _copyAll, child: const Text('Copy all'))),
              const SizedBox(width: 10),
              Expanded(child: FilledButton(onPressed: _printCodes, style: FilledButton.styleFrom(backgroundColor: _accent, foregroundColor: const Color(0xFF09090B)), child: const Text('Print'))),
            ],
          ),
        ],
      );

  @override
  Widget build(BuildContext context) => UiPage(
        title: 'Issue voucher',
        onBack: () {
          if (_step == 2) {
            Navigator.pop(context, true);
            return;
          }
          if (_step > 0) {
            setState(() => _step -= 1);
            return;
          }
          Navigator.pop(context, false);
        },
        backgroundColor: _bg,
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  LinearProgressIndicator(value: (_step + 1) / 3, minHeight: 3, color: _accent, backgroundColor: _border),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(14), border: Border.all(color: _border)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(switch (_step) { 0 => 'Step 1 — Details', 1 => 'Step 2 — Quantity', _ => 'Step 3 — Codes' }, style: const TextStyle(color: _muted, fontSize: 12, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 14),
                        if (_step == 0) _step0Body() else if (_step == 1) _step1Body() else _step2Body(),
                        if (_error != null) ...[
                          const SizedBox(height: 12),
                          Text(_error!, style: const TextStyle(color: Color(0xFFF87171), fontSize: 12)),
                        ],
                        if (_step < 2) ...[
                          const SizedBox(height: 16),
                          FilledButton(
                            onPressed: _busy
                                ? null
                                : () {
                                    if (_step == 0) {
                                      _nextFromStep0();
                                    } else {
                                      _issue();
                                    }
                                  },
                            style: FilledButton.styleFrom(backgroundColor: _accent, foregroundColor: const Color(0xFF09090B)),
                            child: _busy
                                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF09090B)))
                                : Text(_step == 0 ? 'Continue' : 'Issue vouchers'),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}

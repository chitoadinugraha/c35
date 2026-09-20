import 'dart:async';

import 'package:alienai_c35/c/api/referral_conn.dart';
import 'package:alienai_c35/c/pb/c35/wire.pb.dart';
import 'package:alienai_c35/c/pb/c35/referral.pb.dart';
import 'package:alienai_c35/c/referral/referral_format.dart';
import 'package:alienai_c35/c/ui/ui_friendly_error.dart';
import 'package:alienai_c35/widgets/referral/ui_referral_code_form.dart';
import 'package:alienai_c35/widgets/ui/ui_input_decoration.dart';
import 'package:alienai_c35/widgets/ui/ui_loading.dart';
import 'package:alienai_c35/widgets/ui/ui_tooltip.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';

Future<void> referralCodeListDialog(BuildContext context, {required ReferralConn conn}) async {
  await showDialog<void>(
    context: context,
    builder: (ctx) => _ReferralCodeListDialog(conn: conn),
  );
}

class _ReferralCodeListDialog extends StatefulWidget {
  const _ReferralCodeListDialog({required this.conn});

  final ReferralConn conn;

  @override
  State<_ReferralCodeListDialog> createState() => _ReferralCodeListDialogState();
}

class _ReferralCodeListDialogState extends State<_ReferralCodeListDialog> {
  late final _searchCtrl = TextEditingController();
  Timer? _debounce;
  Timer? _copiedClear;
  var _loading = true;
  var _showSearch = false;
  String _copiedCode = '';
  String? _error;
  List<ReferralCodeDoc> _codes = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _copiedClear?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  List<ReferralCodeDoc> get _filtered {
    final q = _searchCtrl.text.trim().toLowerCase();
    if (q.isEmpty) return _codes;
    return _codes.where((c) => c.code.toLowerCase().contains(q) || c.name.toLowerCase().contains(q)).toList();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await widget.conn.invoke(InvokeReq(reqId: const Uuid().v4(), referralCodeList: ReqReferralCodeList()));
      if (!mounted) return;
      invokeResThrow(res, fallback: 'Failed to load codes');
      setState(() {
        _codes = res.hasReferralCodeList() ? List<ReferralCodeDoc>.from(res.referralCodeList.items) : [];
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = uiReferralError(e, fallback: 'Failed to load codes');
      });
    }
  }

  Future<void> _copyCode(ReferralCodeDoc code) async {
    await Clipboard.setData(ClipboardData(text: referralCodeFormat(code.code)));
    setState(() => _copiedCode = code.code);
    _copiedClear?.cancel();
    _copiedClear = Timer(const Duration(seconds: 2), () {
      if (mounted && _copiedCode == code.code) setState(() => _copiedCode = '');
    });
  }

  Future<void> _openForm({ReferralCodeDoc? existing}) async {
    final saved = await referralCodeFormDialog(context, conn: widget.conn, existing: existing);
    if (saved != null && mounted) await _load();
  }

  Future<void> _deleteCode(ReferralCodeDoc code) async {
    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF18181B),
        title: const Text('Delete referral code?', style: TextStyle(color: Color(0xFFF4F4F5))),
        content: Text(referralCodeFormat(code.code), style: const TextStyle(color: Color(0xFFA1A1AA), fontFamily: 'monospace')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete', style: TextStyle(color: Color(0xFFEF4444)))),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      final res = await widget.conn.invoke(InvokeReq(reqId: const Uuid().v4(), referralCodeDelete: ReqReferralCodeDelete(code: code.code)));
      if (!mounted) return;
      invokeResThrow(res, fallback: 'Failed to delete code');
      await _load();
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = uiReferralError(e, fallback: 'Failed to delete code'));
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      backgroundColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 512, maxHeight: 720),
        child: Material(
          color: const Color(0xFF18181B),
          elevation: 24,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: const Color(0xFF3F3F46).withValues(alpha: 0.95)),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: Color(0xFF27272A))),
                  color: Color(0xFF08080A),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.confirmation_number_outlined, size: 20, color: Color(0xFF22C55E)),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text('Referral codes', style: TextStyle(color: Color(0xFFF4F4F5), fontSize: 16, fontWeight: FontWeight.w700)),
                    ),
                    uiIconButton(
                      onPressed: _loading ? null : () => _openForm(),
                      tooltip: 'Add code',
                      icon: const Icon(Icons.add, size: 20, color: Color(0xFFA1A1AA)),
                    ),
                    uiIconButton(
                      onPressed: () => setState(() => _showSearch = !_showSearch),
                      tooltip: 'Search',
                      icon: const Icon(Icons.search, size: 20, color: Color(0xFFA1A1AA)),
                    ),
                    uiIconButton(
                      onPressed: _loading ? null : _load,
                      tooltip: 'Refresh',
                      icon: const Icon(Icons.refresh, size: 20, color: Color(0xFFA1A1AA)),
                    ),
                    uiIconButton(
                      onPressed: () => Navigator.pop(context),
                      tooltip: 'Close',
                      icon: const Icon(Icons.close, size: 20, color: Color(0xFFA1A1AA)),
                    ),
                  ],
                ),
              ),
              if (_showSearch)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: (_) {
                      _debounce?.cancel();
                      _debounce = Timer(const Duration(milliseconds: 200), () {
                        if (mounted) setState(() {});
                      });
                    },
                    style: const TextStyle(color: Color(0xFFF4F4F5)),
                    decoration: UiInputDecoration.of(context, hintText: 'Search codes…'),
                  ),
                ),
              Expanded(
                child: _loading
                    ? const UILoading(message: 'Loading codes…')
                    : _error != null
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFFA1A1AA))),
                                  const SizedBox(height: 16),
                                  FilledButton(onPressed: _load, child: const Text('Retry')),
                                ],
                              ),
                            ),
                          )
                        : filtered.isEmpty
                            ? Center(
                                child: Text(
                                  _searchCtrl.text.trim().isNotEmpty ? 'No codes match' : 'No referral codes yet',
                                  style: const TextStyle(color: Color(0xFFA1A1AA)),
                                ),
                              )
                            : ListView.separated(
                                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                                itemCount: filtered.length,
                                separatorBuilder: (context, index) => const SizedBox(height: 10),
                                itemBuilder: (context, i) {
                                  final code = filtered[i];
                                  final copied = _copiedCode == code.code;
                                  final meta = referralCodePriceUsdLabel(code.priceUsd, code.durationMonths, code.maxUses, code.usedCount);
                                  final expires = referralCodeExpiresLabelMs(code.expiresAtMs.toInt());
                                  return _CodeTile(
                                    title: code.name.trim().isNotEmpty ? code.name.trim() : referralCodeTypeLabel(code.type),
                                    formatted: referralCodeFormat(code.code),
                                    meta: meta,
                                    expires: expires,
                                    copied: copied,
                                    onCopy: () => _copyCode(code),
                                    onEdit: () => _openForm(existing: code),
                                    onDelete: () => _deleteCode(code),
                                  );
                                },
                              ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CodeTile extends StatelessWidget {
  const _CodeTile({
    required this.title,
    required this.formatted,
    required this.meta,
    required this.expires,
    required this.copied,
    required this.onCopy,
    required this.onEdit,
    required this.onDelete,
  });

  final String title;
  final String formatted;
  final String meta;
  final String expires;
  final bool copied;
  final VoidCallback onCopy;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF22C55E);
    const muted = Color(0xFFA1A1AA);
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF18181B),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF3F3F46).withValues(alpha: 0.85)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(child: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFFF4F4F5), fontWeight: FontWeight.w700))),
                uiIconButton(
                  visualDensity: VisualDensity.compact,
                  tooltip: 'Edit',
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined, size: 18, color: muted),
                ),
                uiIconButton(
                  visualDensity: VisualDensity.compact,
                  tooltip: 'Delete',
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline, size: 18, color: muted),
                ),
              ],
            ),
            if (meta.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(meta, style: const TextStyle(color: accent, fontSize: 11, fontWeight: FontWeight.w600)),
            ],
            if (expires.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(expires, style: const TextStyle(color: muted, fontSize: 11)),
            ],
            const SizedBox(height: 10),
            Material(
              color: const Color(0xFF27272A),
              borderRadius: BorderRadius.circular(10),
              child: InkWell(
                onTap: onCopy,
                borderRadius: BorderRadius.circular(10),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          formatted,
                          style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.w700, letterSpacing: 1.5, color: Color(0xFFF4F4F5)),
                        ),
                      ),
                      Icon(copied ? Icons.check_circle_outline : Icons.content_copy_outlined, size: 16, color: copied ? accent : muted),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

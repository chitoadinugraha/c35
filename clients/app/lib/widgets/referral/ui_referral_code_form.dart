import 'package:alienai_c35/c/api/referral_conn.dart';
import 'package:alienai_c35/c/pb/c35/wire.pb.dart';
import 'package:alienai_c35/c/pb/c35/referral.pb.dart';
import 'package:alienai_c35/c/referral/referral_format.dart';
import 'package:alienai_c35/c/ui/ui_friendly_error.dart';
import 'package:alienai_c35/widgets/ui/ui_error.dart';
import 'package:alienai_c35/widgets/ui/ui_input_decoration.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

Future<ReferralCodeDoc?> referralCodeFormDialog(BuildContext context, {required ReferralConn conn, ReferralCodeDoc? existing}) =>
    showDialog<ReferralCodeDoc>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => _ReferralCodeFormDialog(conn: conn, existing: existing),
    );

class _ReferralCodeFormDialog extends StatefulWidget {
  const _ReferralCodeFormDialog({required this.conn, this.existing});

  final ReferralConn conn;
  final ReferralCodeDoc? existing;

  @override
  State<_ReferralCodeFormDialog> createState() => _ReferralCodeFormDialogState();
}

class _ReferralCodeFormDialogState extends State<_ReferralCodeFormDialog> {
  static const _bg = Color(0xFF18181B);
  static const _text = Color(0xFFF4F4F5);
  static const _muted = Color(0xFFA1A1AA);

  late final _editing = widget.existing != null;
  late final _codeCtrl = TextEditingController(text: widget.existing == null ? '' : referralCodeFormat(widget.existing!.code));
  late final _nameCtrl = TextEditingController(text: widget.existing?.name ?? '');
  late final _priceCtrl = TextEditingController(text: (widget.existing?.priceUsd ?? 0) > 0 ? '${widget.existing!.priceUsd}' : '');
  late final _durationCtrl = TextEditingController(text: (widget.existing?.durationMonths ?? 0) > 0 ? '${widget.existing!.durationMonths}' : '');
  late final _maxUsesCtrl = TextEditingController(text: (widget.existing?.maxUses ?? 0) > 0 ? '${widget.existing!.maxUses}' : '');
  late var _type = widget.existing?.type.trim().isNotEmpty == true ? widget.existing!.type : 'referral';
  var _saving = false;
  String? _error;

  @override
  void dispose() {
    _codeCtrl.dispose();
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    _durationCtrl.dispose();
    _maxUsesCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    final err = referralCodeFormValidate(_codeCtrl.text);
    if (err != null) {
      setState(() => _error = err);
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final doc = ReferralCodeDoc(
      code: referralCodeNorm(_codeCtrl.text),
      name: _nameCtrl.text.trim(),
      type: _type,
      priceUsd: double.tryParse(_priceCtrl.text.trim()) ?? 0,
      durationMonths: int.tryParse(_durationCtrl.text.trim()) ?? 0,
      maxUses: int.tryParse(_maxUsesCtrl.text.trim()) ?? 0,
      usedCount: widget.existing?.usedCount ?? 0,
      expiresAtMs: widget.existing?.expiresAtMs ?? Int64.ZERO,
      basePlanSlug: widget.existing?.basePlanSlug ?? '',
    );
    try {
      final res = await widget.conn.invoke(InvokeReq(reqId: const Uuid().v4(), referralCodePut: ReqReferralCodePut(code: doc)));
      if (!mounted) return;
      invokeResThrow(res, fallback: 'Failed to save code');
      Navigator.pop(context, res.hasReferralCodePut() ? res.referralCodePut : doc);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = uiReferralError(e, fallback: 'Failed to save code');
      });
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        backgroundColor: _bg,
        title: Text(_editing ? 'Edit referral code' : 'New referral code', style: const TextStyle(color: _text)),
        content: SizedBox(
          width: 360,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _codeCtrl,
                  readOnly: _editing,
                  autofocus: !_editing,
                  style: const TextStyle(color: _text, fontFamily: 'monospace', letterSpacing: 1.2),
                  textCapitalization: TextCapitalization.characters,
                  decoration: UiInputDecoration.of(context, labelText: 'Code', hintText: referralCodeHint),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _nameCtrl,
                  style: const TextStyle(color: _text),
                  decoration: UiInputDecoration.of(context, labelText: 'Name', hintText: 'Optional label'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _type,
                  dropdownColor: _bg,
                  style: const TextStyle(color: _text),
                  decoration: UiInputDecoration.of(context, labelText: 'Type'),
                  items: const [
                    DropdownMenuItem(value: 'referral', child: Text('Sign up')),
                    DropdownMenuItem(value: 'package', child: Text('Package')),
                  ],
                  onChanged: _saving ? null : (v) { if (v != null) setState(() => _type = v); },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _priceCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(color: _text),
                  decoration: UiInputDecoration.of(context, labelText: 'Price USD', hintText: '0'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _durationCtrl,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: _text),
                  decoration: UiInputDecoration.of(context, labelText: 'Duration months', hintText: '0'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _maxUsesCtrl,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: _text),
                  decoration: UiInputDecoration.of(context, labelText: 'Max uses', hintText: '0'),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  UIError(message: _error!, compact: true),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: _saving ? null : () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: _muted))),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF09090B)))
                : const Text('Save'),
          ),
        ],
      );
}

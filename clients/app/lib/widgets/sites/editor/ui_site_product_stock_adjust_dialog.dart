import 'package:alienai_c35/c/ui/money_format.dart';
import 'package:alienai_c35/widgets/io/in_money_idr.dart';
import 'package:alienai_c35/widgets/sites/editor/ui_site_editor_form.dart';
import 'package:flutter/material.dart';

Future<int?> showSiteProductStockAdjustDialog(
  BuildContext context, {
  required int current,
  required String unit,
}) =>
    showDialog<int>(
      context: context,
      builder: (ctx) => _SiteProductStockAdjustDialog(current: current, unit: unit),
    );

class _SiteProductStockAdjustDialog extends StatefulWidget {
  const _SiteProductStockAdjustDialog({required this.current, required this.unit});

  final int current;
  final String unit;

  @override
  State<_SiteProductStockAdjustDialog> createState() => _SiteProductStockAdjustDialogState();
}

class _SiteProductStockAdjustDialogState extends State<_SiteProductStockAdjustDialog> {
  late final _qtyCtrl = TextEditingController(
    text: widget.current > 0 ? moneyFmtIdrGrouped(widget.current) : '',
  );
  late final _noteCtrl = TextEditingController();
  var _saving = false;

  @override
  void dispose() {
    _qtyCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  void _save() {
    if (_saving) return;
    setState(() => _saving = true);
    final qty = moneyParseIdrInt(_qtyCtrl.text) ?? 0;
    Navigator.pop(context, qty);
  }

  @override
  Widget build(BuildContext context) {
    final unitSuffix = widget.unit.trim().isEmpty ? '' : ' ${widget.unit.trim()}';
    return AlertDialog(
      backgroundColor: const Color(0xFF18181B),
      title: const Text('Adjust stock', style: TextStyle(color: siteEditorFormText)),
      content: SizedBox(
        width: 320,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Current: ${moneyFmtIdrGrouped(widget.current)}$unitSuffix',
              style: const TextStyle(color: siteEditorFormMuted, fontSize: 13),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _qtyCtrl,
              autofocus: true,
              textAlign: TextAlign.end,
              keyboardType: TextInputType.number,
              inputFormatters: moneyIdrInputFormatters,
              style: const TextStyle(color: siteEditorFormText, fontSize: 13),
              decoration: siteEditorInputDecoration(hintText: 'New quantity'),
              onSubmitted: (_) => _save(),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _noteCtrl,
              style: const TextStyle(color: siteEditorFormText, fontSize: 13),
              decoration: siteEditorInputDecoration(hintText: 'Note (optional)'),
              maxLines: 2,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: _saving ? null : () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          onPressed: _saving ? null : _save,
          style: FilledButton.styleFrom(backgroundColor: siteEditorFormAccent, foregroundColor: Colors.black),
          child: const Text('Save'),
        ),
      ],
    );
  }
}

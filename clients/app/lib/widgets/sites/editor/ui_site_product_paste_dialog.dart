import 'package:alienai_c35/c/site/site_product_parse_paste.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const _border = Color(0xFF27272A);
const _muted = Color(0xFF71717A);
const _text = Color(0xFFF4F4F5);
const _accent = Color(0xFF34D399);

Future<List<SiteProductPasteRow>?> uiSiteProductPasteDialogShow(BuildContext context) async {
  var text = (await Clipboard.getData('text/plain'))?.text ?? '';
  if (!context.mounted) return null;
  return showDialog<List<SiteProductPasteRow>>(
    context: context,
    builder: (ctx) => _UiSiteProductPasteDialog(initial: text),
  );
}

class _UiSiteProductPasteDialog extends StatefulWidget {
  const _UiSiteProductPasteDialog({required this.initial});

  final String initial;

  @override
  State<_UiSiteProductPasteDialog> createState() => _UiSiteProductPasteDialogState();
}

class _UiSiteProductPasteDialogState extends State<_UiSiteProductPasteDialog> {
  late final _ctrl = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  List<SiteProductPasteRow> get _rows => siteProductParsePasteText(_ctrl.text);

  @override
  Widget build(BuildContext context) => AlertDialog(
        backgroundColor: const Color(0xFF18181B),
        title: const Text('Paste products', style: TextStyle(color: _text, fontSize: 16)),
        content: SizedBox(
          width: 480,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Tab/comma-separated rows or spreadsheet paste (name, price, description).',
                style: TextStyle(color: _muted, fontSize: 12),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _ctrl,
                onChanged: (_) => setState(() {}),
                minLines: 6,
                maxLines: 10,
                style: const TextStyle(color: _text, fontSize: 13, fontFamily: 'monospace'),
                decoration: const InputDecoration(
                  border: OutlineInputBorder(borderSide: BorderSide(color: _border)),
                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: _border)),
                  focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: _accent)),
                ),
              ),
              const SizedBox(height: 8),
              Text('${_rows.length} product(s) parsed', style: const TextStyle(color: _muted, fontSize: 11)),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: _rows.isEmpty ? null : () => Navigator.pop(context, _rows),
            style: FilledButton.styleFrom(backgroundColor: _accent, foregroundColor: Colors.black),
            child: const Text('Import'),
          ),
        ],
      );
}

import 'package:alienai_c35/c/pb/c35/site.pb.dart';
import 'package:alienai_c35/c/site/site_api.dart';
import 'package:alienai_c35/c/site/site_object_batch.dart';
import 'package:alienai_c35/c/ui/ui_friendly_error.dart';
import 'package:alienai_c35/widgets/ui/ui_img.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const _border = Color(0xFF27272A);
const _muted = Color(0xFF71717A);
const _text = Color(0xFFF4F4F5);
const _accent = Color(0xFF34D399);
const _dialogW = 420.0;

Future<int?> showSiteObjectBatchDialog(
  BuildContext context, {
  required SiteApi api,
  required int siteIid,
  required SiteProduct product,
}) =>
    showDialog<int>(
      context: context,
      builder: (ctx) => _UiSiteObjectBatchDialog(api: api, siteIid: siteIid, product: product),
    );

class _UiSiteObjectBatchDialog extends StatefulWidget {
  const _UiSiteObjectBatchDialog({required this.api, required this.siteIid, required this.product});

  final SiteApi api;
  final int siteIid;
  final SiteProduct product;

  @override
  State<_UiSiteObjectBatchDialog> createState() => _UiSiteObjectBatchDialogState();
}

class _UiSiteObjectBatchDialogState extends State<_UiSiteObjectBatchDialog> {
  late final _prefixCtrl = TextEditingController(
    text: widget.product.name.trim().isEmpty ? 'Unit ' : '${widget.product.name.trim()} ',
  );
  late final _startCtrl = TextEditingController(text: '1');
  late final _endCtrl = TextEditingController(text: '10');
  late final _digitsCtrl = TextEditingController(text: '2');
  var _kind = siteObjectKindRoom;
  var _saving = false;
  var _error = '';

  @override
  void dispose() {
    _prefixCtrl.dispose();
    _startCtrl.dispose();
    _endCtrl.dispose();
    _digitsCtrl.dispose();
    super.dispose();
  }

  int get _start => int.tryParse(_startCtrl.text.trim()) ?? 0;
  int get _end => int.tryParse(_endCtrl.text.trim()) ?? 0;
  int get _digits => int.tryParse(_digitsCtrl.text.trim()) ?? 0;

  List<({String name, String code})> get _preview => siteObjectBatchPreview(
        prefix: _prefixCtrl.text,
        start: _start,
        end: _end,
        digits: _digits.clamp(0, 6),
      );

  void _bump() => setState(() => _error = '');

  InputDecoration _fieldDecoration(String label) => InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: _muted, fontSize: 12),
        border: const OutlineInputBorder(borderSide: BorderSide(color: _border)),
        enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: _border)),
        focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: _accent)),
      );

  Future<void> _save() async {
    if (_saving) return;
    final items = _preview;
    if (items.isEmpty) {
      setState(() => _error = 'Invalid range (max $siteObjectBatchMaxCount units).');
      return;
    }
    setState(() {
      _saving = true;
      _error = '';
    });
    final productId = widget.product.productId;
    final kind = _kind;
    try {
      for (final item in items) {
        final o = widget.api.objectNew(widget.siteIid)
          ..name = item.name
          ..code = item.code
          ..kind = kind
          ..productId = productId
          ..canBeReserved = true
          ..isActive = true;
        await widget.api.objectPut(widget.siteIid, o);
      }
      if (!mounted) return;
      Navigator.pop(context, items.length);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = uiFriendlyError(e);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final preview = _preview;
    final pic = widget.product.pic;

    return AlertDialog(
      backgroundColor: const Color(0xFF18181B),
      title: const Text('Add reservation units', style: TextStyle(color: _text, fontSize: 16)),
      contentPadding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      content: SizedBox(
        width: _dialogW,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _prefixCtrl,
                    style: const TextStyle(color: _text, fontSize: 13),
                    decoration: _fieldDecoration('Prefix'),
                    onChanged: (_) => _bump(),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _kind,
                    isExpanded: true,
                    dropdownColor: const Color(0xFF27272A),
                    style: const TextStyle(color: _text, fontSize: 13),
                    decoration: _fieldDecoration('Kind'),
                    items: [
                      for (final k in siteObjectKindValues)
                        DropdownMenuItem(value: k, child: Text(siteObjectKindLabel(k))),
                    ],
                    onChanged: (v) {
                      if (v == null) return;
                      setState(() => _kind = v);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _startCtrl,
                    decoration: _fieldDecoration('Start'),
                    style: const TextStyle(color: _text, fontSize: 13),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: (_) => _bump(),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _endCtrl,
                    decoration: _fieldDecoration('End'),
                    style: const TextStyle(color: _text, fontSize: 13),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: (_) => _bump(),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _digitsCtrl,
                    decoration: _fieldDecoration('Digits'),
                    style: const TextStyle(color: _text, fontSize: 13),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(1)],
                    onChanged: (_) => _bump(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              preview.isEmpty
                  ? 'Set Start–End (max $siteObjectBatchMaxCount). Digits 0 = no zero-padding.'
                  : '${siteObjectKindLabel(_kind)} · ${preview.length} units: ${preview.first.name} – ${preview.last.name}',
              style: const TextStyle(color: _muted, fontSize: 12),
            ),
            if (_error.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(_error, style: const TextStyle(color: Color(0xFFF87171), fontSize: 13)),
            ],
            if (preview.isNotEmpty) ...[
              const SizedBox(height: 14),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 240),
                child: GridView.builder(
                  shrinkWrap: true,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    childAspectRatio: 0.62,
                  ),
                  itemCount: preview.length,
                  itemBuilder: (context, i) => _PreviewTile(pic: pic, name: preview[i].name, kind: _kind),
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: _saving ? null : () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          onPressed: _saving || preview.isEmpty ? null : _save,
          style: FilledButton.styleFrom(backgroundColor: _accent, foregroundColor: Colors.black),
          child: _saving
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
              : Text(preview.isEmpty ? 'Add' : 'Add ${preview.length}'),
        ),
      ],
    );
  }
}

class _PreviewTile extends StatelessWidget {
  const _PreviewTile({required this.pic, required this.name, required this.kind});

  final String pic;
  final String name;
  final String kind;

  IconData get _kindIcon => switch (kind) {
        siteObjectKindTable => Icons.table_restaurant_outlined,
        siteObjectKindRoom => Icons.meeting_room_outlined,
        _ => Icons.category_outlined,
      };

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFF27272A),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _border),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: ColoredBox(
                  color: const Color(0xFF3F3F46),
                  child: pic.isEmpty
                      ? Center(child: Icon(_kindIcon, color: _muted, size: 28))
                      : UiImg(src: pic, fit: BoxFit.cover, width: double.infinity, height: double.infinity, fallback: Icon(_kindIcon, color: _muted, size: 28)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 5, 4, 6),
                child: Text(
                  name,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: _text, fontSize: 10, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      );
}

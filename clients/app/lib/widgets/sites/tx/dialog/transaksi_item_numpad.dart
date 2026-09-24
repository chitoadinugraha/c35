import 'package:alienai_c35/c/pb/c35/tx.pb.dart';
import 'package:alienai_c35/c/ui/money_format.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flutter/material.dart';

const _border = Color(0xFF27272A);
const _muted = Color(0xFF71717A);
const _text = Color(0xFFF4F4F5);
const _accent = Color(0xFF34D399);

Future<TxItem?> showTransaksiItemNumpad({
  required BuildContext context,
  required TxItem item,
  String productName = '',
  bool allowPriceEdit = true,
}) =>
    showDialog<TxItem>(
      context: context,
      builder: (ctx) => _DialogItemNumpad(
        item: item,
        productName: productName,
        allowPriceEdit: allowPriceEdit,
      ),
    );

class _DialogItemNumpad extends StatefulWidget {
  const _DialogItemNumpad({
    required this.item,
    required this.productName,
    required this.allowPriceEdit,
  });

  final TxItem item;
  final String productName;
  final bool allowPriceEdit;

  @override
  State<_DialogItemNumpad> createState() => _DialogItemNumpadState();
}

class _DialogItemNumpadState extends State<_DialogItemNumpad> {
  late int _qty = widget.item.qty > 0 ? widget.item.qty : 1;
  late int _price = widget.item.price.toInt();
  late final TextEditingController _noteCtrl = TextEditingController(text: widget.item.note);
  late final TextEditingController _priceCtrl = TextEditingController(text: _price.toString());

  @override
  void dispose() {
    _noteCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  void _keyTap(String key) {
    setState(() {
      if (key == 'C') {
        _qty = 0;
      } else if (key == '⌫') {
        final s = _qty.toString();
        _qty = s.length > 1 ? int.parse(s.substring(0, s.length - 1)) : 0;
      } else {
        final s = _qty == 0 ? key : '$_qty$key';
        _qty = (int.tryParse(s) ?? _qty).clamp(0, 9999);
      }
    });
  }

  void _addQty(int delta) {
    setState(() {
      _qty = (_qty + delta).clamp(0, 9999);
    });
  }

  TxItem _build() {
    final next = widget.item.clone();
    next.qty = _qty;
    next.price = Int64(_price);
    next.note = _noteCtrl.text.trim();
    return next;
  }

  @override
  Widget build(BuildContext context) {
    final subtotal = _qty * _price;
    return AlertDialog(
      backgroundColor: const Color(0xFF121215),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: _border),
      ),
      titlePadding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      contentPadding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      title: Row(
        children: [
          Expanded(
            child: Text(
              widget.productName.isNotEmpty ? widget.productName : 'Item ${widget.item.productId}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: _text, fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
          Text(moneyFmtIdr(subtotal), style: const TextStyle(color: _accent, fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
      content: SizedBox(
        width: 320,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Display Qty
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF18181B),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _border),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Jumlah (Qty)', style: TextStyle(color: _muted, fontSize: 13)),
                    Text(
                      '$_qty',
                      style: const TextStyle(color: _text, fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // Quick increment chips
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  for (final n in [1, 2, 5, 10, 20])
                    InkWell(
                      onTap: () => _addQty(n),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF18181B),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: _border),
                        ),
                        child: Text('+$n', style: const TextStyle(color: _accent, fontSize: 12, fontWeight: FontWeight.w600)),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),

              // Touch Numpad Grid (3x4)
              _numpadGrid(),
              const SizedBox(height: 12),

              // Note field
              TextField(
                controller: _noteCtrl,
                style: const TextStyle(color: _text, fontSize: 13),
                decoration: InputDecoration(
                  labelText: 'Catatan Item (cth: kurang manis, meja 2)',
                  labelStyle: const TextStyle(color: _muted, fontSize: 12),
                  filled: true,
                  fillColor: const Color(0xFF18181B),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _border)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _accent)),
                ),
              ),

              // Price edit field (optional)
              if (widget.allowPriceEdit) ...[
                const SizedBox(height: 10),
                TextField(
                  controller: _priceCtrl,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: _text, fontSize: 13),
                  decoration: InputDecoration(
                    labelText: 'Ubah Harga Satuan (Price Override)',
                    labelStyle: const TextStyle(color: _muted, fontSize: 12),
                    prefixText: 'Rp ',
                    prefixStyle: const TextStyle(color: _accent, fontSize: 13),
                    filled: true,
                    fillColor: const Color(0xFF18181B),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _border)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _accent)),
                  ),
                  onChanged: (v) {
                    final parsed = int.tryParse(v.replaceAll(RegExp(r'[^0-9]'), '')) ?? _price;
                    setState(() => _price = parsed);
                  },
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Batal', style: TextStyle(color: _muted)),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: _accent, foregroundColor: const Color(0xFF052E1B)),
          onPressed: () => Navigator.of(context).pop(_build()),
          child: const Text('Terapkan', style: TextStyle(fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }

  Widget _numpadGrid() {
    const keys = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['C', '0', '⌫'],
    ];
    return Column(
      children: [
        for (final row in keys)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                for (final k in row)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          backgroundColor: k == 'C' || k == '⌫' ? const Color(0xFF27272A).withValues(alpha: 0.5) : const Color(0xFF18181B),
                          side: const BorderSide(color: _border),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: () => _keyTap(k),
                        child: Text(
                          k,
                          style: TextStyle(
                            color: k == 'C' ? Colors.redAccent : (k == '⌫' ? Colors.amberAccent : _text),
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

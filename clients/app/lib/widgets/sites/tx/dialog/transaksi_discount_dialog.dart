import 'package:alienai_c35/c/pb/c35/tx.pb.dart';
import 'package:alienai_c35/c/ui/money_format.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flutter/material.dart';
import 'package:alienai_c35/widgets/io/in_money_idr.dart';
import 'package:flutter/services.dart';

const _border = Color(0xFF27272A);
const _muted = Color(0xFF71717A);
const _text = Color(0xFFF4F4F5);
const _accent = Color(0xFF34D399);

Future<TxDiscount?> showTransaksiDiscountDialog({
  required BuildContext context,
  required Int64 originalAmount,
  TxDiscount? initialDiscount,
  String title = 'Diskon',
}) =>
    showDialog<TxDiscount>(
      context: context,
      builder: (ctx) => _DialogDiscount(
        originalAmount: originalAmount,
        initialDiscount: initialDiscount,
        title: title,
      ),
    );

class _DialogDiscount extends StatefulWidget {
  const _DialogDiscount({
    required this.originalAmount,
    this.initialDiscount,
    required this.title,
  });

  final Int64 originalAmount;
  final TxDiscount? initialDiscount;
  final String title;

  @override
  State<_DialogDiscount> createState() => _DialogDiscountState();
}

class _DialogDiscountState extends State<_DialogDiscount> {
  late String _discountType;
  late final TextEditingController _percentCtrl;
  late final TextEditingController _nominalCtrl;
  late final TextEditingController _noteCtrl;

  @override
  void initState() {
    super.initState();
    final init = widget.initialDiscount;
    if (init != null && init.discountType == 'percent') {
      _discountType = 'percent';
      final orig = widget.originalAmount.toInt();
      final p = orig > 0 ? ((init.amount.toInt() * 100) / orig).round() : 0;
      _percentCtrl = TextEditingController(text: p > 0 ? p.toString() : '');
      _nominalCtrl = TextEditingController();
    } else if (init != null && init.amount > Int64.ZERO) {
      _discountType = 'fixed';
      _percentCtrl = TextEditingController();
      _nominalCtrl = TextEditingController(text: moneyFmtIdrGrouped(init.amount.toInt()));
    } else {
      _discountType = 'percent';
      _percentCtrl = TextEditingController();
      _nominalCtrl = TextEditingController();
    }
    _noteCtrl = TextEditingController(text: init?.note ?? '');
  }

  @override
  void dispose() {
    _percentCtrl.dispose();
    _nominalCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  int get _calculatedDiscount {
    final orig = widget.originalAmount.toInt();
    if (orig <= 0) return 0;
    if (_discountType == 'percent') {
      final p = double.tryParse(_percentCtrl.text.trim()) ?? 0;
      final clampedP = p.clamp(0.0, 100.0);
      return ((orig * clampedP) / 100).round();
    } else {
      final n = moneyParseIdrInt(_nominalCtrl.text) ?? 0;
      return n.clamp(0, orig);
    }
  }

  void _applyPercentPreset(int percent) {
    setState(() {
      _discountType = 'percent';
      _percentCtrl.text = percent.toString();
    });
  }

  void _applyNominalPreset(int nominal) {
    setState(() {
      _discountType = 'fixed';
      _nominalCtrl.text = moneyFmtIdrGrouped(nominal);
    });
  }

  void _submit() {
    final discount = _calculatedDiscount;
    Navigator.of(context).pop(
      TxDiscount(
        discountType: _discountType,
        amount: Int64(discount),
        note: _noteCtrl.text.trim(),
      ),
    );
  }

  void _clearDiscount() {
    Navigator.of(context).pop(
      TxDiscount(
        discountType: 'fixed',
        amount: Int64.ZERO,
        note: '',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final orig = widget.originalAmount.toInt();
    final discountNominal = _calculatedDiscount;
    final finalAmount = (orig - discountNominal).clamp(0, orig);
    final hasInitialDiscount = widget.initialDiscount != null && widget.initialDiscount!.amount > Int64.ZERO;

    final percentPresets = [5, 10, 15, 20, 25, 50];
    final nominalPresets = [5000, 10000, 20000, 50000, 100000].where((n) => n <= orig).toList();

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
          const Icon(Icons.local_offer_outlined, color: _accent, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              widget.title,
              style: const TextStyle(color: _text, fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: _muted, size: 18),
            onPressed: () => Navigator.of(context).pop(),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 360,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Discount Type Switcher
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E24),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _border),
                ),
                padding: const EdgeInsets.all(3),
                child: Row(
                  children: [
                    Expanded(
                      child: _typeTab(
                        label: 'Persentase (%)',
                        isSelected: _discountType == 'percent',
                        onTap: () => setState(() => _discountType = 'percent'),
                      ),
                    ),
                    Expanded(
                      child: _typeTab(
                        label: 'Nominal (Rp)',
                        isSelected: _discountType == 'fixed',
                        onTap: () => setState(() => _discountType = 'fixed'),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Value Input Field
              if (_discountType == 'percent') ...[
                TextFormField(
                  controller: _percentCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(3),
                  ],
                  autofocus: true,
                  style: const TextStyle(color: _text, fontSize: 18, fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    labelText: 'Besar Diskon (%)',
                    labelStyle: const TextStyle(color: _muted),
                    suffixText: '%',
                    suffixStyle: const TextStyle(color: _accent, fontSize: 18, fontWeight: FontWeight.bold),
                    filled: true,
                    fillColor: const Color(0xFF18181B),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: _border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: _accent),
                    ),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: percentPresets.map((p) {
                    final selected = _percentCtrl.text == p.toString();
                    return ActionChip(
                      label: Text('$p%'),
                      labelStyle: TextStyle(
                        color: selected ? const Color(0xFF052E1B) : _text,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                      backgroundColor: selected ? _accent : const Color(0xFF18181B),
                      side: BorderSide(color: selected ? _accent : _border),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      onPressed: () => _applyPercentPreset(p),
                    );
                  }).toList(),
                ),
              ] else ...[
                TextFormField(
                  controller: _nominalCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: moneyIdrInputFormatters,
                  autofocus: true,
                  style: const TextStyle(color: _text, fontSize: 18, fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    labelText: 'Nominal Potongan (Rp)',
                    labelStyle: const TextStyle(color: _muted),
                    prefixText: 'Rp ',
                    prefixStyle: const TextStyle(color: _accent, fontSize: 16, fontWeight: FontWeight.bold),
                    filled: true,
                    fillColor: const Color(0xFF18181B),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: _border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: _accent),
                    ),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                if (nominalPresets.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: nominalPresets.map((n) {
                      final selected = _nominalCtrl.text == moneyFmtIdrGrouped(n);
                      return ActionChip(
                        label: Text(moneyFmtIdr(n)),
                        labelStyle: TextStyle(
                          color: selected ? const Color(0xFF052E1B) : _text,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                        backgroundColor: selected ? _accent : const Color(0xFF18181B),
                        side: BorderSide(color: selected ? _accent : _border),
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        onPressed: () => _applyNominalPreset(n),
                      );
                    }).toList(),
                  ),
                ],
              ],
              const SizedBox(height: 14),

              // Note / reason field
              TextFormField(
                controller: _noteCtrl,
                style: const TextStyle(color: _text, fontSize: 13),
                decoration: InputDecoration(
                  labelText: 'Alasan / Catatan (opsional)',
                  labelStyle: const TextStyle(color: _muted, fontSize: 12),
                  hintText: 'Contoh: Member VIP, Promo Weekend',
                  hintStyle: const TextStyle(color: _muted, fontSize: 12),
                  filled: true,
                  fillColor: const Color(0xFF18181B),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: _border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: _accent),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Calculation Summary Card
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF16161A),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _border),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Harga Asal', style: TextStyle(color: _muted, fontSize: 12)),
                        Text(moneyFmtIdr(orig), style: const TextStyle(color: _text, fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Potongan Diskon', style: TextStyle(color: Colors.redAccent, fontSize: 12)),
                        Text(
                          discountNominal > 0 ? '- ${moneyFmtIdr(discountNominal)}' : 'Rp 0',
                          style: const TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 6),
                      child: Divider(height: 1, color: _border),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total Setelah Diskon', style: TextStyle(color: _text, fontSize: 13, fontWeight: FontWeight.w600)),
                        Text(
                          moneyFmtIdr(finalAmount),
                          style: const TextStyle(color: _accent, fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        if (hasInitialDiscount)
          TextButton.icon(
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            onPressed: _clearDiscount,
            icon: const Icon(Icons.delete_outline, size: 16),
            label: const Text('Hapus Diskon'),
          ),
        TextButton(
          style: TextButton.styleFrom(foregroundColor: _muted),
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: _accent,
            foregroundColor: const Color(0xFF052E1B),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          onPressed: _submit,
          icon: const Icon(Icons.check, size: 16),
          label: const Text('Terapkan', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _typeTab({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) =>
      InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? _accent : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? const Color(0xFF052E1B) : _muted,
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      );
}

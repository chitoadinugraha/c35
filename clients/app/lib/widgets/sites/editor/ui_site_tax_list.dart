import 'package:alienai_c35/c/site/site_draft_meta.dart';
import 'package:flutter/material.dart';

const _border = Color(0xFF27272A);
const _muted = Color(0xFF71717A);
const _text = Color(0xFFF4F4F5);
const _accent = Color(0xFF34D399);

IconData siteTaxTypeIcon(String type) => switch (siteTaxTypeNormalize(type)) {
      kSiteTaxTypeServiceTax => Icons.room_service_outlined,
      kSiteTaxTypePph => Icons.account_balance_outlined,
      _ => Icons.receipt_long_outlined,
    };

class UiSiteTaxList extends StatelessWidget {
  const UiSiteTaxList({
    super.key,
    required this.taxes,
    required this.busy,
    required this.onChanged,
    required this.onAdd,
  });

  final List<SiteTaxDraft> taxes;
  final bool busy;
  final ValueChanged<List<SiteTaxDraft>> onChanged;
  final VoidCallback onAdd;

  void _update(int index, SiteTaxDraft tax) {
    final next = [...taxes];
    next[index] = tax;
    onChanged(next);
  }

  void _remove(int index) => onChanged([...taxes]..removeAt(index));

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text('Sales taxes', style: TextStyle(color: _text, fontSize: 16, fontWeight: FontWeight.w600)),
              ),
              TextButton.icon(
                onPressed: busy ? null : onAdd,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add tax'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Stored in site draft meta for POS / checkout.',
            style: TextStyle(color: _muted, fontSize: 12),
          ),
          const SizedBox(height: 16),
          if (taxes.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: Text('No taxes configured', style: TextStyle(color: _muted, fontSize: 13))),
            )
          else
            for (var i = 0; i < taxes.length; i++)
              _TaxRow(
                key: ValueKey(taxes[i].id),
                tax: taxes[i],
                busy: busy,
                onChanged: (t) => _update(i, t),
                onRemove: () => _remove(i),
              ),
          if (busy) const Padding(padding: EdgeInsets.only(top: 12), child: LinearProgressIndicator(minHeight: 2, color: _accent)),
        ],
      );
}

class _TaxRow extends StatelessWidget {
  const _TaxRow({super.key, required this.tax, required this.busy, required this.onChanged, required this.onRemove});

  final SiteTaxDraft tax;
  final bool busy;
  final ValueChanged<SiteTaxDraft> onChanged;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Material(
          color: const Color(0xFF18181B),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: const BorderSide(color: _border)),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(siteTaxTypeIcon(tax.type), size: 20, color: _accent),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: siteTaxTypeNormalize(tax.type),
                        decoration: const InputDecoration(
                          labelText: 'Type',
                          labelStyle: TextStyle(color: _muted, fontSize: 11),
                          isDense: true,
                        ),
                        dropdownColor: const Color(0xFF27272A),
                        style: const TextStyle(color: _text, fontSize: 13),
                        items: kSiteTaxTypes
                            .map(
                              (t) => DropdownMenuItem(
                                value: t,
                                child: Row(
                                  children: [
                                    Icon(siteTaxTypeIcon(t), size: 18, color: _text),
                                    const SizedBox(width: 8),
                                    Text(siteTaxDefaultName(t)),
                                  ],
                                ),
                              ),
                            )
                            .toList(growable: false),
                        onChanged: busy
                            ? null
                            : (v) {
                                if (v == null) return;
                                onChanged(tax.copyWith(type: v, name: siteTaxDefaultName(v)));
                              },
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(onPressed: busy ? null : onRemove, icon: const Icon(Icons.delete_outline, color: _muted, size: 20)),
                  ],
                ),
                const SizedBox(height: 8),
                TextFormField(
                  initialValue: tax.name,
                  enabled: !busy,
                  style: const TextStyle(color: _text, fontSize: 13),
                  decoration: const InputDecoration(
                    labelText: 'Label',
                    labelStyle: TextStyle(color: _muted, fontSize: 11),
                    isDense: true,
                  ),
                  onChanged: (v) => onChanged(tax.copyWith(name: v)),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        initialValue: tax.percent == tax.percent.roundToDouble() ? '${tax.percent.toInt()}' : '${tax.percent}',
                        enabled: !busy,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        style: const TextStyle(color: _text, fontSize: 13),
                        decoration: const InputDecoration(
                          labelText: 'Rate %',
                          labelStyle: TextStyle(color: _muted, fontSize: 11),
                          isDense: true,
                        ),
                        onChanged: (v) => onChanged(tax.copyWith(percent: double.tryParse(v.replaceAll(',', '.')) ?? 0)),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Active', style: TextStyle(color: _muted, fontSize: 11)),
                        Switch.adaptive(
                          value: tax.active,
                          onChanged: busy ? null : (v) => onChanged(tax.copyWith(active: v)),
                          activeTrackColor: _accent,
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
}

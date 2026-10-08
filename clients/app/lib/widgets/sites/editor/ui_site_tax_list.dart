import 'package:alienai_c35/c/site/site_draft_meta.dart';
import 'package:alienai_c35/widgets/sites/editor/ui_site_editor_form.dart';
import 'package:alienai_c35/widgets/ui/ui_empty_state.dart';
import 'package:flutter/material.dart';

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
          UiSiteEditorPaneHeader(
            title: 'Sales taxes',
            subtitle: 'Applied at POS and checkout. Saved with your site draft.',
            action: FilledButton.icon(
              onPressed: busy ? null : onAdd,
              style: FilledButton.styleFrom(
                backgroundColor: siteEditorFormAccent,
                foregroundColor: Colors.black,
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add tax'),
            ),
          ),
          if (taxes.isEmpty)
            const UiEmptyState(
              icon: Icons.percent_outlined,
              title: 'No taxes yet',
              subtitle: 'Add PPN, service charge, or other rates for checkout.',
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
          if (busy) const Padding(padding: EdgeInsets.only(top: 8), child: LinearProgressIndicator(minHeight: 2, color: siteEditorFormAccent)),
        ],
      );
}

class _TaxRow extends StatefulWidget {
  const _TaxRow({super.key, required this.tax, required this.busy, required this.onChanged, required this.onRemove});

  final SiteTaxDraft tax;
  final bool busy;
  final ValueChanged<SiteTaxDraft> onChanged;
  final VoidCallback onRemove;

  @override
  State<_TaxRow> createState() => _TaxRowState();
}

class _TaxRowState extends State<_TaxRow> {
  late final _nameCtrl = TextEditingController(text: widget.tax.name);
  late final _rateCtrl = TextEditingController(text: _rateText(widget.tax));

  static String _rateText(SiteTaxDraft tax) =>
      tax.percent == tax.percent.roundToDouble() ? '${tax.percent.toInt()}' : '${tax.percent}';

  @override
  void didUpdateWidget(covariant _TaxRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tax.id != widget.tax.id) {
      _nameCtrl.text = widget.tax.name;
      _rateCtrl.text = _rateText(widget.tax);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _rateCtrl.dispose();
    super.dispose();
  }

  void _setType(String type) => widget.onChanged(widget.tax.copyWith(type: type, name: siteTaxDefaultName(type)));

  @override
  Widget build(BuildContext context) {
    final tax = widget.tax;
    final type = siteTaxTypeNormalize(tax.type);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: UiSiteEditorFormSection(
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: siteEditorFieldFill,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: siteEditorFieldBorder),
                ),
                child: Icon(siteTaxTypeIcon(type), color: siteEditorFormAccent, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  tax.name.isEmpty ? siteTaxDefaultName(type) : tax.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: siteEditorFormText, fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ),
              IconButton(
                onPressed: widget.busy ? null : widget.onRemove,
                tooltip: 'Remove tax',
                icon: const Icon(Icons.delete_outline, size: 20, color: siteEditorFormMuted),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text('Tax type', style: TextStyle(color: siteEditorFormMuted, fontSize: 11, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: kSiteTaxTypes.map((t) {
              final selected = type == t;
              return Material(
                color: selected ? siteEditorFormAccent.withValues(alpha: 0.15) : siteEditorFieldFill,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: selected ? siteEditorFormAccent : siteEditorFieldBorder),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: widget.busy ? null : () => _setType(t),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(siteTaxTypeIcon(t), size: 16, color: selected ? siteEditorFormAccent : siteEditorFormMuted),
                        const SizedBox(width: 6),
                        Text(
                          siteTaxDefaultName(t),
                          style: TextStyle(
                            color: selected ? siteEditorFormText : siteEditorFormMuted,
                            fontSize: 12,
                            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(growable: false),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: UiSiteEditorLabeledField(
                  label: 'Label on receipt',
                  child: TextField(
                    controller: _nameCtrl,
                    enabled: !widget.busy,
                    style: const TextStyle(color: siteEditorFormText, fontSize: 13),
                    decoration: siteEditorInputDecoration(hintText: 'e.g. PPN 11%'),
                    onChanged: (v) => widget.onChanged(tax.copyWith(name: v)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 108,
                child: UiSiteEditorLabeledField(
                  label: 'Rate',
                  child: TextField(
                    controller: _rateCtrl,
                    enabled: !widget.busy,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: const TextStyle(color: siteEditorFormText, fontSize: 13),
                    decoration: siteEditorInputDecoration(suffixText: '%'),
                    onChanged: (v) => widget.onChanged(tax.copyWith(percent: double.tryParse(v.replaceAll(',', '.')) ?? 0)),
                  ),
                ),
              ),
            ],
          ),
          UiSiteEditorSwitchRow(
            label: 'Active',
            value: tax.active,
            onChanged: widget.busy ? null : (v) => widget.onChanged(tax.copyWith(active: v)),
          ),
        ],
      ),
    );
  }
}

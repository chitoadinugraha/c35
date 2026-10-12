import 'package:alienai_c35/c/site/site_draft_meta.dart';
import 'package:alienai_c35/widgets/sites/editor/ui_site_catalog_detail_header.dart';
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

  void _setType(String type) {
    final name = siteTaxDefaultName(type);
    _nameCtrl.text = name;
    widget.onChanged(widget.tax.copyWith(type: type, name: name));
  }

  InputDecoration _inlineFieldDecoration({String? hintText, String? suffixText}) => InputDecoration(
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        isDense: true,
        hintText: hintText,
        hintStyle: const TextStyle(color: siteEditorFormMuted, fontSize: 13),
        suffixText: suffixText,
        suffixStyle: const TextStyle(color: siteEditorFormMuted, fontSize: 12),
        contentPadding: EdgeInsets.zero,
      );

  @override
  Widget build(BuildContext context) {
    final tax = widget.tax;
    final type = siteTaxTypeNormalize(tax.type);
    final title = tax.name.isEmpty ? siteTaxDefaultName(type) : tax.name;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
        decoration: BoxDecoration(
          color: siteEditorCardBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: siteEditorFieldBorder.withValues(alpha: 0.85)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            UiSiteCatalogDetailHeader(
              icon: siteTaxTypeIcon(type),
              title: title,
              active: tax.active,
              onActiveChanged: widget.busy ? null : (v) => widget.onChanged(tax.copyWith(active: v)),
              onDelete: widget.busy ? null : widget.onRemove,
              deleteLabel: 'Remove tax',
              deleteConfirmTitle: 'Remove tax?',
              deleteConfirmBody: 'This tax will no longer apply at checkout.',
            ),
            const SizedBox(height: 8),
            DecoratedBox(
              decoration: BoxDecoration(
                color: siteEditorFieldFill,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: siteEditorFieldBorder),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Row(
                  children: [
                    for (var i = 0; i < kSiteTaxTypes.length; i++) ...[
                      if (i > 0) Container(width: 1, height: 34, color: siteEditorFieldBorder),
                      Expanded(
                        child: _TaxTypeSegment(
                          type: kSiteTaxTypes[i],
                          selected: type == kSiteTaxTypes[i],
                          busy: widget.busy,
                          onTap: () => _setType(kSiteTaxTypes[i]),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            DecoratedBox(
              decoration: BoxDecoration(
                color: siteEditorFieldFill,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: siteEditorFieldBorder),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Column(
                  children: [
                    _TaxInlineField(
                      label: 'Label on receipt',
                      child: TextField(
                        controller: _nameCtrl,
                        enabled: !widget.busy,
                        textAlign: TextAlign.end,
                        style: const TextStyle(color: siteEditorFormText, fontSize: 13),
                        decoration: _inlineFieldDecoration(hintText: 'e.g. PPN 11%'),
                        onChanged: (v) => widget.onChanged(tax.copyWith(name: v)),
                      ),
                    ),
                    Divider(height: 1, thickness: 1, color: siteEditorFieldBorder),
                    _TaxInlineField(
                      label: 'Rate',
                      child: SizedBox(
                        width: 88,
                        child: TextField(
                          controller: _rateCtrl,
                          enabled: !widget.busy,
                          textAlign: TextAlign.end,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          style: const TextStyle(color: siteEditorFormText, fontSize: 13),
                          decoration: _inlineFieldDecoration(suffixText: '%'),
                          onChanged: (v) =>
                              widget.onChanged(tax.copyWith(percent: double.tryParse(v.replaceAll(',', '.')) ?? 0)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TaxTypeSegment extends StatelessWidget {
  const _TaxTypeSegment({
    required this.type,
    required this.selected,
    required this.busy,
    required this.onTap,
  });

  final String type;
  final bool selected;
  final bool busy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final label = siteTaxDefaultName(type);
    return Material(
      color: selected ? siteEditorFormAccent.withValues(alpha: 0.14) : Colors.transparent,
      child: InkWell(
        onTap: busy ? null : onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(siteTaxTypeIcon(type), size: 14, color: selected ? siteEditorFormAccent : siteEditorFormMuted),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: selected ? siteEditorFormText : siteEditorFormMuted,
                    fontSize: 11,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TaxInlineField extends StatelessWidget {
  const _TaxInlineField({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(label, style: const TextStyle(color: siteEditorFormMuted, fontSize: 12)),
            const SizedBox(width: 12),
            Expanded(child: Align(alignment: Alignment.centerRight, child: child)),
          ],
        ),
      );
}

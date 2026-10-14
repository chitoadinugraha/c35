import 'package:alienai_c35/c/ui/money_format.dart';
import 'package:alienai_c35/widgets/io/in_money_idr.dart';
import 'package:alienai_c35/widgets/sites/editor/ui_site_editor_form.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

Widget siteProductSectionDivider(BuildContext context, String title) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          const Expanded(child: Divider(color: siteEditorFieldBorder)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              title,
              style: const TextStyle(color: siteEditorFormText, fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
          const Expanded(child: Divider(color: siteEditorFieldBorder)),
        ],
      ),
    );

Widget siteProductLabeledFieldRow({required String label, required Widget field}) => Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(color: siteEditorFormText, fontSize: 13))),
          SizedBox(width: 140, child: field),
        ],
      ),
    );

class SiteProductStockThresholdRow extends StatelessWidget {
  const SiteProductStockThresholdRow({
    super.key,
    required this.enabled,
    required this.label,
    required this.controller,
    required this.onEnabledChanged,
    required this.onQtyChanged,
    this.suffixText,
    this.busy = false,
  });

  final bool enabled;
  final String label;
  final TextEditingController controller;
  final ValueChanged<bool> onEnabledChanged;
  final ValueChanged<String> onQtyChanged;
  final String? suffixText;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final labelColor = enabled ? siteEditorFormText : siteEditorFormMuted;
    return Row(
      children: [
        Checkbox(
          value: enabled,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.compact,
          onChanged: busy ? null : (v) => onEnabledChanged(v ?? false),
        ),
        Expanded(child: Text(label, style: TextStyle(color: labelColor, fontSize: 13))),
        SizedBox(
          width: 140,
          child: TextField(
            controller: controller,
            enabled: enabled && !busy,
            textAlign: TextAlign.end,
            keyboardType: TextInputType.number,
            inputFormatters: moneyIdrInputFormatters,
            style: const TextStyle(color: siteEditorFormText, fontSize: 13),
            decoration: siteEditorInputDecoration(suffixText: suffixText),
            onChanged: enabled ? onQtyChanged : null,
          ),
        ),
      ],
    );
  }
}

class SiteProductStockShowToCustomerSection extends StatelessWidget {
  const SiteProductStockShowToCustomerSection({
    super.key,
    required this.showToCustomer,
    required this.maxQtyController,
    required this.suffixText,
    required this.onShowChanged,
    required this.onMaxChanged,
    this.busy = false,
  });

  final bool showToCustomer;
  final TextEditingController maxQtyController;
  final String? suffixText;
  final ValueChanged<bool> onShowChanged;
  final ValueChanged<String> onMaxChanged;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final maxLabel = (moneyParseIdrInt(maxQtyController.text) ?? 0) > 0
        ? maxQtyController.text.trim()
        : 'n';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Checkbox(
              value: showToCustomer,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
              onChanged: busy ? null : (v) => onShowChanged(v ?? false),
            ),
            const Expanded(
              child: Text('Show stock to customers', style: TextStyle(color: siteEditorFormText, fontSize: 13)),
            ),
          ],
        ),
        if (showToCustomer) ...[
          const SizedBox(height: 8),
          siteProductLabeledFieldRow(
            label: 'Max shown',
            field: TextField(
              controller: maxQtyController,
              enabled: !busy,
              textAlign: TextAlign.end,
              keyboardType: TextInputType.number,
              inputFormatters: moneyIdrInputFormatters,
              style: const TextStyle(color: siteEditorFormText, fontSize: 13),
              decoration: siteEditorInputDecoration(suffixText: suffixText),
              onChanged: onMaxChanged,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 4, top: 4),
            child: Text(
              'Cap displayed stock; above max shows as $maxLabel+',
              style: const TextStyle(color: siteEditorFormMuted, fontSize: 11),
            ),
          ),
        ],
      ],
    );
  }
}

const siteProductStockUnitFormatters = [LengthLimitingTextInputFormatter(6)];

int siteProductParseQty(String raw) => moneyParseIdrInt(raw) ?? 0;

String siteProductQtyDisplay(int qty) => qty > 0 ? moneyFmtIdrGrouped(qty) : '';

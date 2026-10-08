import 'package:flutter/material.dart';

const siteEditorFieldBorder = Color(0xFF3F3F46);
const siteEditorFieldFill = Color(0xFF18181B);
const siteEditorFormMuted = Color(0xFF71717A);
const siteEditorFormText = Color(0xFFF4F4F5);
const siteEditorFormAccent = Color(0xFF34D399);
const siteEditorCardBg = Color(0xFF0F0F12);

InputDecoration siteEditorInputDecoration({String? hintText, String? suffixText}) => InputDecoration(
      isDense: true,
      hintText: hintText,
      suffixText: suffixText,
      hintStyle: const TextStyle(color: siteEditorFormMuted, fontSize: 13),
      suffixStyle: const TextStyle(color: siteEditorFormMuted, fontSize: 12),
      filled: true,
      fillColor: siteEditorFieldFill,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: siteEditorFieldBorder)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: siteEditorFieldBorder)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: siteEditorFormAccent)),
    );

class UiSiteEditorFormSection extends StatelessWidget {
  const UiSiteEditorFormSection({super.key, this.title, required this.children});

  final String? title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: siteEditorCardBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: siteEditorFieldBorder.withValues(alpha: 0.85)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (title != null) ...[
              Text(title!, style: const TextStyle(color: siteEditorFormText, fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
            ],
            ...children,
          ],
        ),
      );
}

class UiSiteEditorLabeledField extends StatelessWidget {
  const UiSiteEditorLabeledField({super.key, required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(label, style: const TextStyle(color: siteEditorFormMuted, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.2)),
            const SizedBox(height: 6),
            child,
          ],
        ),
      );
}

class UiSiteEditorSwitchRow extends StatelessWidget {
  const UiSiteEditorSwitchRow({super.key, required this.label, required this.value, required this.onChanged});

  final String label;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Expanded(
              child: Text(label, style: const TextStyle(color: siteEditorFormText, fontSize: 13)),
            ),
            Switch(
              value: value,
              onChanged: onChanged,
              activeThumbColor: siteEditorFormAccent,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ],
        ),
      );
}

class UiSiteEditorPaneHeader extends StatelessWidget {
  const UiSiteEditorPaneHeader({super.key, required this.title, this.subtitle, this.action});

  final String title;
  final String? subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(title, style: const TextStyle(color: siteEditorFormText, fontSize: 17, fontWeight: FontWeight.w600)),
                  if (subtitle != null && subtitle!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(subtitle!, style: const TextStyle(color: siteEditorFormMuted, fontSize: 12, height: 1.35)),
                  ],
                ],
              ),
            ),
            if (action != null) action!,
          ],
        ),
      );
}

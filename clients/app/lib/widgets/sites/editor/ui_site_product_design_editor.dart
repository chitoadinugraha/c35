import 'package:alienai_c35/c/site/site_draft_meta.dart';
import 'package:flutter/material.dart';

const _border = Color(0xFF27272A);
const _muted = Color(0xFF71717A);
const _text = Color(0xFFF4F4F5);
const _accent = Color(0xFF34D399);

class UiSiteProductDesignEditor extends StatelessWidget {
  const UiSiteProductDesignEditor({
    super.key,
    required this.design,
    required this.busy,
    required this.onChanged,
  });

  final SiteProductDesignDraft design;
  final bool busy;
  final ValueChanged<SiteProductDesignDraft> onChanged;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Catalog card typography', style: TextStyle(color: _text, fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          const Text(
            'Default product card styling (title, subtitle, price). Saved in draft meta as product_design.',
            style: TextStyle(color: _muted, fontSize: 12),
          ),
          const SizedBox(height: 20),
          _section('Title', design.titleFontSize, design.titleItalic, design.titleUnderline, (size, italic, underline) => onChanged(
                design.copyWith(titleFontSize: size, titleItalic: italic, titleUnderline: underline),
              )),
          const SizedBox(height: 16),
          _section('Subtitle', design.subtitleFontSize, design.subtitleItalic, design.subtitleUnderline, (size, italic, underline) => onChanged(
                design.copyWith(subtitleFontSize: size, subtitleItalic: italic, subtitleUnderline: underline),
              )),
          const SizedBox(height: 16),
          _section('Price', design.priceFontSize, design.priceItalic, design.priceUnderline, (size, italic, underline) => onChanged(
                design.copyWith(priceFontSize: size, priceItalic: italic, priceUnderline: underline),
              )),
          if (busy) const Padding(padding: EdgeInsets.only(top: 16), child: LinearProgressIndicator(minHeight: 2, color: _accent)),
        ],
      );

  Widget _section(
    String label,
    double fontSize,
    bool italic,
    bool underline,
    void Function(double size, bool italic, bool underline) on,
  ) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(label, style: const TextStyle(color: _muted, fontSize: 11, fontWeight: FontWeight.w600)),
          Slider(
            value: fontSize.clamp(10, 24),
            min: 10,
            max: 24,
            divisions: 14,
            label: fontSize.round().toString(),
            activeColor: _accent,
            onChanged: busy ? null : (v) => on(v, italic, underline),
          ),
          Row(
            children: [
              FilterChip(
                label: const Text('Italic', style: TextStyle(fontSize: 11)),
                selected: italic,
                onSelected: busy ? null : (v) => on(fontSize, v, underline),
                selectedColor: _accent.withValues(alpha: 0.25),
                side: const BorderSide(color: _border),
              ),
              const SizedBox(width: 8),
              FilterChip(
                label: const Text('Underline', style: TextStyle(fontSize: 11)),
                selected: underline,
                onSelected: busy ? null : (v) => on(fontSize, italic, v),
                selectedColor: _accent.withValues(alpha: 0.25),
                side: const BorderSide(color: _border),
              ),
            ],
          ),
        ],
      );
}

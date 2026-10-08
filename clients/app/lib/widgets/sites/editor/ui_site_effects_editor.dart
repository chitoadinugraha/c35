import 'package:alienai_c35/widgets/sites/editor/ui_site_catalog_shared.dart';
import 'package:flutter/material.dart';

const _muted = Color(0xFF71717A);
const _text = Color(0xFFF4F4F5);

class UiSiteEffectsEditor extends StatelessWidget {
  const UiSiteEffectsEditor({super.key});

  @override
  Widget build(BuildContext context) => UiSiteEditorFormScroll(
        children: [
          const Text('Effects', style: TextStyle(color: _text, fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Icon(Icons.auto_awesome_outlined, size: 40, color: _muted.withValues(alpha: 0.6)),
          const SizedBox(height: 12),
          const Text(
            'Effects coming soon',
            textAlign: TextAlign.center,
            style: TextStyle(color: _muted, fontSize: 14),
          ),
          const SizedBox(height: 8),
          const Text(
            'Backdrop presets and block effect catalog will appear here when the design system ships.',
            textAlign: TextAlign.center,
            style: TextStyle(color: _muted, fontSize: 12, height: 1.4),
          ),
        ],
      );
}

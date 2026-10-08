import 'package:alienai_c35/c/pb/c35/site.pb.dart';
import 'package:alienai_c35/widgets/sites/editor/ui_site_catalog_shared.dart';
import 'package:flutter/material.dart';

const _muted = Color(0xFF71717A);
const _text = Color(0xFFF4F4F5);
const _accent = Color(0xFF34D399);

class UiSitePublishEditor extends StatelessWidget {
  const UiSitePublishEditor({
    super.key,
    required this.row,
    this.onPublish,
    this.publishing = false,
  });

  final SiteRow row;
  final VoidCallback? onPublish;
  final bool publishing;

  @override
  Widget build(BuildContext context) => UiSiteEditorFormScroll(
        children: [
          const Text('Publish', style: TextStyle(color: _text, fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          const Text(
            'Push the current draft to your live site. Visitors on custom domains see the published version.',
            style: TextStyle(color: _muted, fontSize: 12, height: 1.4),
          ),
          const SizedBox(height: 20),
          _infoRow('Published version', row.publishedVersionId.isEmpty ? 'Draft only (not live)' : row.publishedVersionId),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: publishing || onPublish == null ? null : onPublish,
            style: FilledButton.styleFrom(backgroundColor: _accent, foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(vertical: 14)),
            icon: publishing
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                : const Icon(Icons.rocket_launch_outlined, size: 20),
            label: Text(publishing ? 'Publishing…' : 'Publish site'),
          ),
        ],
      );

  Widget _infoRow(String label, String value) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: _muted, fontSize: 12)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(color: _text, fontSize: 14)),
        ],
      );
}

import 'package:alienai_c35/c/pb/c35/site.pb.dart';
import 'package:alienai_c35/c/site/site_api.dart';
import 'package:alienai_c35/widgets/sites/editor/site_domain_editor_panel.dart';
import 'package:alienai_c35/widgets/sites/editor/ui_site_catalog_shared.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

const _muted = Color(0xFF71717A);
const _text = Color(0xFFF4F4F5);
const _accent = Color(0xFF34D399);

class UiSitePublishEditor extends StatelessWidget {
  const UiSitePublishEditor({
    super.key,
    required this.row,
    required this.api,
    required this.siteIid,
    this.onPublish,
    this.publishing = false,
    this.publishPending = true,
  });

  final SiteRow row;
  final SiteApi api;
  final int siteIid;
  final VoidCallback? onPublish;
  final bool publishing;
  final bool publishPending;

  String get _publicUrl {
    final handle = row.alienId.trim();
    if (handle.isEmpty) return '';
    return 'https://alienai.id/$handle';
  }

  @override
  Widget build(BuildContext context) => UiSiteEditorFormScroll(
        children: [
          const Text('Publish', style: TextStyle(color: _text, fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text(
            'site.domain.publishIntro'.tr(),
            style: const TextStyle(color: _muted, fontSize: 12, height: 1.4),
          ),
          if (_publicUrl.isNotEmpty) ...[
            const SizedBox(height: 16),
            _infoRow('site.domain.publicUrl'.tr(), _publicUrl),
          ],
          const SizedBox(height: 20),
          _infoRow('Published version', row.publishedVersionId.isEmpty ? 'Draft only (not live)' : row.publishedVersionId),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: publishing || !publishPending || onPublish == null ? null : onPublish,
            style: FilledButton.styleFrom(backgroundColor: _accent, foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(vertical: 14)),
            icon: publishing
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                : Icon(publishPending ? Icons.rocket_launch_outlined : Icons.check_circle_outline, size: 20),
            label: Text(publishing ? 'Publishing…' : (publishPending ? 'Publish site' : 'Published')),
          ),
          const SizedBox(height: 32),
          Text('site.domain.sectionTitle'.tr(), style: const TextStyle(color: _text, fontSize: 15, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          UiSiteDomainPanel(api: api, siteIid: siteIid, showCnameHint: false),
        ],
      );

  Widget _infoRow(String label, String value) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: _muted, fontSize: 12)),
          const SizedBox(height: 4),
          SelectableText(value, style: const TextStyle(color: _text, fontSize: 14)),
        ],
      );
}

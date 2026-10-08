import 'package:alienai_c35/c/pb/c35/site.pb.dart';
import 'package:alienai_c35/c/site/site_api.dart';
import 'package:alienai_c35/c/ui/ui_friendly_error.dart';
import 'package:alienai_c35/widgets/sites/editor/ui_site_editor_shell.dart';
import 'package:alienai_c35/widgets/sites/ui_site_preview.dart';
import 'package:alienai_c35/widgets/ui/ui_safe_area.dart';
import 'package:alienai_c35/widgets/ui/ui_window_bar.dart';
import 'package:flutter/material.dart';

const _border = Color(0xFF27272A);
const _muted = Color(0xFF71717A);
const _text = Color(0xFFF4F4F5);
const _accent = Color(0xFF34D399);

class UiSiteDetail extends StatefulWidget {
  const UiSiteDetail({
    super.key,
    required this.row,
    required this.api,
    this.onBack,
    this.title,
    this.initialTabRoute,
    this.initialEditorSection = 'products',
  });

  final SiteRow row;
  final SiteApi api;
  final VoidCallback? onBack;
  final String? title;
  final String? initialTabRoute;
  final String initialEditorSection;

  @override
  State<UiSiteDetail> createState() => _UiSiteDetailState();
}

class _UiSiteDetailState extends State<UiSiteDetail> {
  late final _siteIid = widget.row.siteIid.toInt();
  var _publishing = false;
  var _previewMode = SitePreviewMode.draft;
  var _previewReloadNonce = 0;

  Future<void> _publish() async {
    if (_publishing) return;
    setState(() => _publishing = true);
    try {
      await widget.api.publish(_siteIid);
      if (mounted) {
        setState(() => _previewReloadNonce++);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Site published'), behavior: SnackBarBehavior.floating));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(uiFriendlyError(e)), behavior: SnackBarBehavior.floating));
    } finally {
      if (mounted) setState(() => _publishing = false);
    }
  }

  int _initialTabIndex() => switch (widget.initialTabRoute) {
        'site.product' || 'site.contact' || 'site.object' || 'site.settings' => 1,
        _ => 0,
      };

  String _editorInitialSection() => switch (widget.initialTabRoute) {
        'site.product' => 'products',
        'site.contact' => 'contacts',
        'site.object' => 'objects',
        'site.settings' => 'capabilities',
        _ => widget.initialEditorSection,
      };

  @override
  Widget build(BuildContext context) {
    const tabs = ['Preview', 'Edit'];
    return DefaultTabController(
      length: tabs.length,
      initialIndex: _initialTabIndex().clamp(0, tabs.length - 1),
      child: ColoredBox(
        color: const Color(0xFF08080A),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.onBack != null || widget.title != null) _navBarWrap(),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 4, 0),
              child: TabBar(
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                labelColor: _text,
                unselectedLabelColor: _muted,
                indicatorColor: _accent,
                dividerColor: _border,
                tabs: [for (final t in tabs) Tab(text: t)],
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _previewTab(),
                  UiSiteEditorShell(
                    row: widget.row,
                    api: widget.api,
                    initialSection: _editorInitialSection(),
                    onPublish: _publish,
                    publishing: _publishing,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _navBarWrap() => uiDesktopWindow ? _navBar() : uiMobileTopBar(context, _navBar());

  Widget _navBar() => Container(
        padding: const EdgeInsets.fromLTRB(4, 6, 8, 6),
        decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: _border))),
        child: Row(
          children: [
            if (widget.onBack != null)
              IconButton(onPressed: widget.onBack, icon: const Icon(Icons.arrow_back, color: _text)),
            Expanded(
              child: Text(widget.title ?? widget.row.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: _text, fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      );

  Widget _previewTab() => Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                SegmentedButton<SitePreviewMode>(
                  segments: const [
                    ButtonSegment(value: SitePreviewMode.draft, label: Text('Draft'), icon: Icon(Icons.edit_note, size: 16)),
                    ButtonSegment(value: SitePreviewMode.published, label: Text('Published'), icon: Icon(Icons.public, size: 16)),
                  ],
                  selected: {_previewMode},
                  onSelectionChanged: (s) => setState(() => _previewMode = s.first),
                  style: ButtonStyle(
                    visualDensity: VisualDensity.compact,
                    foregroundColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? _text : _muted),
                  ),
                ),
                const Spacer(),
                OutlinedButton.icon(
                  onPressed: _publishing ? null : _publish,
                  icon: _publishing ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.publish_outlined, size: 18),
                  label: Text(_publishing ? 'Publishing…' : 'Publish'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: UiSitePreview(
                row: widget.row,
                api: widget.api,
                mode: _previewMode,
                reloadNonce: _previewReloadNonce,
              ),
            ),
          ],
        ),
      );
}

import 'dart:async';

import 'package:alienai_c35/c/pb/c35/site.pb.dart';
import 'package:alienai_c35/c/site/site_link_platform.dart';
import 'package:alienai_c35/widgets/sites/editor/ui_site_catalog_detail_header.dart';
import 'package:alienai_c35/widgets/sites/editor/ui_site_editor_form.dart';
import 'package:alienai_c35/widgets/sites/io/in_site_link_platform_picker.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class UiSiteLinkDetail extends StatefulWidget {
  const UiSiteLinkDetail({
    super.key,
    required this.link,
    required this.busy,
    required this.onPatch,
    required this.onDelete,
  });

  final SiteLink link;
  final bool busy;
  final void Function(String id, void Function(SiteLink l) fn) onPatch;
  final VoidCallback onDelete;

  @override
  State<UiSiteLinkDetail> createState() => _UiSiteLinkDetailState();
}

class _UiSiteLinkDetailState extends State<UiSiteLinkDetail> {
  late final _labelCtrl = TextEditingController();
  late final _valueCtrl = TextEditingController();
  late String _icon;

  @override
  void initState() {
    super.initState();
    _syncFromLink();
  }

  void _syncFromLink() {
    _icon = siteLinkPlatformNormalize(widget.link.icon);
    _labelCtrl.text = widget.link.label;
    _valueCtrl.text = siteLinkValueDisplay(icon: _icon, stored: widget.link.url);
  }

  @override
  void didUpdateWidget(covariant UiSiteLinkDetail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if ('${oldWidget.link.linkId}' != '${widget.link.linkId}' ||
        oldWidget.link.url != widget.link.url ||
        oldWidget.link.icon != widget.link.icon ||
        oldWidget.link.label != widget.link.label) {
      _syncFromLink();
    }
  }

  @override
  void dispose() {
    _labelCtrl.dispose();
    _valueCtrl.dispose();
    super.dispose();
  }

  String get _id => '${widget.link.linkId}';

  String get _previewUrl => siteLinkUrlForSave(icon: _icon, raw: _valueCtrl.text);

  bool get _hasPreviewUrl => siteLinkHasPreviewValue(icon: _icon, raw: _valueCtrl.text);

  Future<void> _openPreview() async {
    final url = _previewUrl;
    if (siteLinkPreviewUrlEmpty(url)) return;
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  void _selectPlatform(String id) {
    final prev = _icon;
    final title = _labelCtrl.text.trim();
    final nextTitle = title.isEmpty || title == siteLinkDefaultTitle(prev) ? siteLinkDefaultTitle(id) : title;
    if (title.isEmpty || title == siteLinkDefaultTitle(prev)) _labelCtrl.text = nextTitle;
    final raw = _valueCtrl.text;
    final idNorm = siteLinkPlatformNormalize(id);
    final savedUrl = siteLinkUrlForSave(icon: idNorm, raw: raw);
    widget.onPatch(_id, (l) {
      l.icon = idNorm;
      l.label = nextTitle;
      l.url = savedUrl;
    });
    setState(() {
      _icon = idNorm;
      _valueCtrl.text = siteLinkValueDisplay(icon: idNorm, stored: savedUrl);
    });
  }

  @override
  Widget build(BuildContext context) {
    final link = widget.link;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
      children: [
        UiSiteCatalogDetailHeader(
          icon: Icons.link,
          title: 'Link',
          subtitle: 'Hub button on your storefront',
          active: link.active,
          onActiveChanged: widget.busy ? null : (v) => widget.onPatch(_id, (l) => l.active = v),
          onDelete: widget.busy ? null : widget.onDelete,
          deleteConfirmTitle: 'Delete link?',
          deleteConfirmBody: 'This removes the link from your site.',
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InSiteLinkPlatformButton(
              value: _icon,
              readOnly: widget.busy,
              onChanged: _selectPlatform,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  UiSiteEditorLabeledField(
                    label: 'Label',
                    child: TextField(
                      controller: _labelCtrl,
                      onChanged: widget.busy ? null : (v) => widget.onPatch(_id, (l) => l.label = v),
                      style: const TextStyle(fontSize: 13, color: siteEditorFormText),
                      decoration: siteEditorInputDecoration(hintText: siteLinkDefaultTitle(_icon)),
                    ),
                  ),
                  UiSiteEditorLabeledField(
                    label: siteLinkValueLabel(_icon),
                    child: TextField(
                      controller: _valueCtrl,
                      keyboardType: siteLinkValueKeyboardType(_icon),
                      onChanged: widget.busy
                          ? null
                          : (v) {
                              widget.onPatch(_id, (l) => l.url = siteLinkUrlForSave(icon: _icon, raw: v));
                              setState(() {});
                            },
                      style: const TextStyle(fontSize: 13, color: siteEditorFormText),
                      decoration: siteEditorInputDecoration(hintText: siteLinkValueHint(_icon)),
                    ),
                  ),
                  if (_hasPreviewUrl)
                    Padding(
                      padding: const EdgeInsets.only(left: 2, bottom: 8),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: InkWell(
                          onTap: widget.busy ? null : () => unawaited(_openPreview()),
                          borderRadius: BorderRadius.circular(4),
                          child: Text(
                            _previewUrl,
                            style: const TextStyle(fontSize: 11, color: siteEditorFormMuted, height: 1.35),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        UiSiteEditorSwitchRow(
          label: 'Pinned',
          value: link.isPinned,
          onChanged: widget.busy ? null : (v) => widget.onPatch(_id, (l) => l.isPinned = v),
        ),
      ],
    );
  }
}

import 'dart:async';

import 'package:alienai_c35/c/site/site_api.dart';
import 'package:alienai_c35/c/site/site_draft_meta.dart';
import 'package:alienai_c35/c/ui/ui_friendly_error.dart';
import 'package:alienai_c35/widgets/sites/editor/ui_site_catalog_shared.dart';
import 'package:alienai_c35/widgets/sites/editor/ui_site_product_design_editor.dart';
import 'package:flutter/material.dart';

const _border = Color(0xFF27272A);
const _muted = Color(0xFF71717A);
const _text = Color(0xFFF4F4F5);
const _accent = Color(0xFF34D399);

class UiSiteDesignEditor extends StatefulWidget {
  const UiSiteDesignEditor({super.key, required this.api, required this.siteIid});

  final SiteApi api;
  final int siteIid;

  @override
  State<UiSiteDesignEditor> createState() => _UiSiteDesignEditorState();
}

class _UiSiteDesignEditorState extends State<UiSiteDesignEditor> {
  late final _accentCtrl = TextEditingController();
  var _loading = true;
  var _busy = false;
  var _showProductDesign = false;
  var _design = const SiteProductDesignDraft();
  Timer? _accentTimer;
  Timer? _metaTimer;

  @override
  void initState() {
    super.initState();
    _accentCtrl.addListener(_scheduleAccentSave);
    unawaited(_load());
  }

  @override
  void dispose() {
    _accentTimer?.cancel();
    _metaTimer?.cancel();
    _accentCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final draft = await widget.api.draftGet(widget.siteIid);
      _accentCtrl.text = siteThemeAccentGet(draft.doc.themeJson);
      final meta = await widget.api.draftGetMeta(widget.siteIid);
      _design = meta.productDesign;
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(uiFriendlyError(e)), behavior: SnackBarBehavior.floating));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _scheduleAccentSave() {
    if (_loading || _busy) return;
    _accentTimer?.cancel();
    _accentTimer = Timer(const Duration(milliseconds: 500), () => unawaited(_saveAccent()));
  }

  Future<void> _saveAccent() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final draft = await widget.api.draftGet(widget.siteIid);
      final next = draft.clone();
      next.doc = siteDocWithThemeJson(next.doc, siteThemeMergeAccent(next.doc.themeJson, _accentCtrl.text));
      await widget.api.draftPut(next);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(uiFriendlyError(e)), behavior: SnackBarBehavior.floating));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _scheduleMetaSave() {
    _metaTimer?.cancel();
    _metaTimer = Timer(const Duration(milliseconds: 500), () => unawaited(_saveMeta()));
  }

  Future<void> _saveMeta() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await widget.api.draftPutMeta(widget.siteIid, productDesign: _design);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(uiFriendlyError(e)), behavior: SnackBarBehavior.floating));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _onDesignChanged(SiteProductDesignDraft design) {
    setState(() => _design = design);
    _scheduleMetaSave();
  }

  Color? _parseAccentPreview() {
    final raw = _accentCtrl.text.trim();
    if (raw.isEmpty) return null;
    final hex = raw.startsWith('#') ? raw.substring(1) : raw;
    if (hex.length == 6) {
      final v = int.tryParse(hex, radix: 16);
      if (v != null) return Color(0xFF000000 | v);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: _muted)));
    }
    final preview = _parseAccentPreview();
    return UiSiteEditorFormScroll(
      children: [
        const Text('Theme', style: TextStyle(color: _text, fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        const Text('Accent color used across guest site chrome and blocks.', style: TextStyle(color: _muted, fontSize: 12)),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: preview ?? _muted.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _border),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _accentCtrl,
                style: const TextStyle(color: _text, fontSize: 14),
                decoration: const InputDecoration(
                  labelText: 'Accent (hex)',
                  labelStyle: TextStyle(color: _muted, fontSize: 13),
                  hintText: '#2563eb',
                  hintStyle: TextStyle(color: _muted),
                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: _border)),
                  focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: _accent)),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 28),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _busy ? null : () => setState(() => _showProductDesign = !_showProductDesign),
                icon: Icon(_showProductDesign ? Icons.expand_less : Icons.style_outlined, size: 18),
                label: Text(_showProductDesign ? 'Hide product card design' : 'Product card design'),
              ),
            ),
          ],
        ),
        if (_showProductDesign) ...[
          const SizedBox(height: 16),
          UiSiteProductDesignEditor(design: _design, busy: _busy, onChanged: _onDesignChanged),
        ],
        if (_busy) const Padding(padding: EdgeInsets.only(top: 16), child: LinearProgressIndicator(minHeight: 2, color: _accent)),
      ],
    );
  }
}

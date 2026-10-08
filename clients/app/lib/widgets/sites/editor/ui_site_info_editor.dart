import 'dart:async';

import 'package:alienai_c35/c/pb/c35/site.pb.dart';
import 'package:alienai_c35/c/site/site_api.dart';
import 'package:alienai_c35/c/site/site_draft_meta.dart';
import 'package:alienai_c35/c/ui/ui_friendly_error.dart';
import 'package:alienai_c35/widgets/sites/editor/ui_site_catalog_shared.dart';
import 'package:flutter/material.dart';

const _border = Color(0xFF27272A);
const _muted = Color(0xFF71717A);
const _text = Color(0xFFF4F4F5);
const _accent = Color(0xFF34D399);

class UiSiteInfoEditor extends StatefulWidget {
  const UiSiteInfoEditor({super.key, required this.row, required this.api, required this.siteIid});

  final SiteRow row;
  final SiteApi api;
  final int siteIid;

  @override
  State<UiSiteInfoEditor> createState() => _UiSiteInfoEditorState();
}

class _UiSiteInfoEditorState extends State<UiSiteInfoEditor> {
  late final _taglineCtrl = TextEditingController();
  late final _seoCtrl = TextEditingController();
  var _loading = true;
  var _saving = false;
  Timer? _saveTimer;

  @override
  void initState() {
    super.initState();
    _taglineCtrl.addListener(_scheduleSave);
    _seoCtrl.addListener(_scheduleSave);
    unawaited(_load());
  }

  @override
  void dispose() {
    _saveTimer?.cancel();
    _taglineCtrl.dispose();
    _seoCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final draft = await widget.api.draftGet(widget.siteIid);
      final meta = draft.doc.metaJson;
      _taglineCtrl.text = siteMetaFieldGet(meta, 'tagline');
      _seoCtrl.text = siteMetaFieldGet(meta, 'seo_title');
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(uiFriendlyError(e)), behavior: SnackBarBehavior.floating));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _scheduleSave() {
    if (_loading || _saving) return;
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 500), () => unawaited(_save()));
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final draft = await widget.api.draftGet(widget.siteIid);
      final next = draft.clone();
      next.doc = siteDocWithMetaJson(
        next.doc,
        siteMetaMergeFields(
          next.doc.metaJson,
          tagline: _taglineCtrl.text,
          seoTitle: _seoCtrl.text,
        ),
      );
      await widget.api.draftPut(next);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(uiFriendlyError(e)), behavior: SnackBarBehavior.floating));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _readOnly(String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: _muted, fontSize: 12)),
            const SizedBox(height: 4),
            Text(value.isEmpty ? '—' : value, style: const TextStyle(color: _text, fontSize: 14)),
          ],
        ),
      );

  InputDecoration _fieldDecoration(String label) => InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: _muted, fontSize: 13),
        enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: _border)),
        focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: _accent)),
      );

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: _muted)));
    }
    return UiSiteEditorFormScroll(
      children: [
        const Text('Site info', style: TextStyle(color: _text, fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        const Text('Public name and handle are managed from the site list.', style: TextStyle(color: _muted, fontSize: 12)),
        const SizedBox(height: 20),
        _readOnly('Site name', widget.row.name),
        _readOnly('Alien ID', widget.row.alienId.isEmpty ? '—' : '@${widget.row.alienId}'),
        TextField(
          controller: _taglineCtrl,
          style: const TextStyle(color: _text, fontSize: 14),
          maxLength: 120,
          decoration: _fieldDecoration('Tagline'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _seoCtrl,
          style: const TextStyle(color: _text, fontSize: 14),
          maxLength: 120,
          decoration: _fieldDecoration('SEO title'),
        ),
        if (_saving) const Padding(padding: EdgeInsets.only(top: 12), child: LinearProgressIndicator(minHeight: 2, color: _accent)),
      ],
    );
  }
}

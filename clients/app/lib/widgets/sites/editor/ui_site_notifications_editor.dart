import 'dart:async';

import 'package:alienai_c35/c/site/site_api.dart';
import 'package:alienai_c35/c/site/site_draft_extras.dart';
import 'package:alienai_c35/c/ui/ui_friendly_error.dart';
import 'package:alienai_c35/widgets/sites/editor/site_editor_save_scope.dart';
import 'package:alienai_c35/widgets/sites/editor/ui_site_catalog_shared.dart';
import 'package:flutter/material.dart';

const _muted = Color(0xFF71717A);
const _text = Color(0xFFF4F4F5);

class UiSiteNotificationsEditor extends StatefulWidget {
  const UiSiteNotificationsEditor({super.key, required this.api, required this.siteIid, this.onDraftSaved});

  final SiteApi api;
  final int siteIid;
  final VoidCallback? onDraftSaved;

  @override
  State<UiSiteNotificationsEditor> createState() => _UiSiteNotificationsEditorState();
}

class _UiSiteNotificationsEditorState extends State<UiSiteNotificationsEditor> {
  var _loading = true;
  String? _error;
  var _orderRing = kSiteOrderRingUntilHandled;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  @override
  void didUpdateWidget(covariant UiSiteNotificationsEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.siteIid != widget.siteIid) unawaited(_load());
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final draft = await widget.api.draftGet(widget.siteIid);
      _orderRing = siteDraftExtrasParse(draft.doc.metaJson).orderRing;
    } catch (e) {
      _error = uiFriendlyError(e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _set(String value) async {
    if (value == _orderRing) return;
    setState(() => _orderRing = value);
    await SiteEditorSaveScope.run(context, () async {
      final draft = await widget.api.draftGet(widget.siteIid);
      final next = draft.clone();
      final doc = next.doc.clone();
      doc.metaJson = siteDraftExtrasMerge(doc.metaJson, orderRing: value);
      next.doc = doc;
      await widget.api.draftPut(next);
      widget.onDraftSaved?.call();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    return UiSiteEditorFormScroll(
      children: [
        const Text('New order', style: TextStyle(color: _text, fontSize: 15, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        const Text(
          'How long the staff order ring plays. Playback still uses the existing order push.',
          style: TextStyle(color: _muted, fontSize: 12, height: 1.35),
        ),
        if (_error != null) ...[
          const SizedBox(height: 8),
          Text(_error!, style: const TextStyle(color: Color(0xFFF87171), fontSize: 12)),
        ],
        const SizedBox(height: 8),
        RadioGroup<String>(
          groupValue: _orderRing,
          onChanged: (v) {
            if (v != null) unawaited(_set(v));
          },
          child: Column(
            children: [
        RadioListTile<String>(
          value: kSiteOrderRingOnce,
          secondary: const Icon(Icons.notifications_outlined, color: _muted),
          title: const Text('Ring once', style: TextStyle(color: _text, fontSize: 14)),
          subtitle: const Text('Play one time when an order arrives.', style: TextStyle(color: _muted, fontSize: 12)),
          contentPadding: EdgeInsets.zero,
          dense: true,
          activeColor: const Color(0xFF34D399),
        ),
        RadioListTile<String>(
          value: kSiteOrderRingUntilHandled,
          secondary: const Icon(Icons.notifications_active_outlined, color: _muted),
          title: const Text('Until handled', style: TextStyle(color: _text, fontSize: 14)),
          subtitle: const Text('Keep ringing until the order is handled.', style: TextStyle(color: _muted, fontSize: 12)),
          contentPadding: EdgeInsets.zero,
          dense: true,
          activeColor: const Color(0xFF34D399),
        ),
            ],
          ),
        ),
      ],
    );
  }
}

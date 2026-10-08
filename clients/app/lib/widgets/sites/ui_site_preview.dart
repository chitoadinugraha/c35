import 'dart:async';
import 'dart:convert';

import 'package:alienai_c35/c/config.dart';
import 'package:alienai_c35/c/pb/c35/site.pb.dart';
import 'package:alienai_c35/c/site/site_api.dart';
import 'package:alienai_c35/c/ui/ui_friendly_error.dart';
import 'package:alienai_c35/guest_site/guest_site_view.dart';
import 'package:alienai_c35/guest_site/site_preview_mode.dart';
import 'package:alienai_c35/widgets/ui/ui_tooltip.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

export 'package:alienai_c35/guest_site/site_preview_mode.dart';

const _muted = Color(0xFF71717A);
const _border = Color(0xFF27272A);

class UiSitePreview extends StatefulWidget {
  const UiSitePreview({
    super.key,
    required this.row,
    required this.api,
    this.mode = SitePreviewMode.draft,
    this.reloadNonce = 0,
    this.embedded = false,
  });

  final SiteRow row;
  final SiteApi api;
  final SitePreviewMode mode;
  final int reloadNonce;
  final bool embedded;

  @override
  State<UiSitePreview> createState() => _UiSitePreviewState();
}

class _UiSitePreviewState extends State<UiSitePreview> {
  Map<String, dynamic>? _boot;
  var _loading = true;
  String? _error;
  String? _url;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  @override
  void didUpdateWidget(covariant UiSitePreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.mode != widget.mode ||
        oldWidget.reloadNonce != widget.reloadNonce ||
        oldWidget.row.siteIid != widget.row.siteIid) {
      unawaited(_load());
    }
  }

  String get _slug => widget.row.alienId.isNotEmpty ? widget.row.alienId : widget.row.siteIid.toString();

  SiteBootMode get _bootMode => widget.mode == SitePreviewMode.draft
      ? SiteBootMode.SITE_BOOT_MODE_DRAFT
      : SiteBootMode.SITE_BOOT_MODE_PUBLISHED;

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
      _boot = null;
    });
    try {
      final res = await widget.api.bootGet(widget.row.siteIid.toInt(), mode: _bootMode);
      final raw = res.bootJson;
      if (raw.isEmpty) throw 'Site boot payload missing';
      final boot = jsonDecode(raw);
      if (boot is! Map<String, dynamic>) throw 'Invalid site boot payload';
      final url = await _previewUrlForExternal();
      if (!mounted) return;
      setState(() {
        _boot = boot;
        _url = url;
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = uiFriendlyError(e);
          _loading = false;
        });
      }
    }
  }

  Future<String> _previewUrlForExternal() async {
    final origin = C35Config.guestSiteOrigin.replaceAll(RegExp(r'/+$'), '');
    if (widget.mode == SitePreviewMode.published) return '$origin/$_slug';
    final res = await widget.api.sitePreviewToken(widget.row.siteIid.toInt());
    final token = res.token;
    if (token.isEmpty) throw 'Preview token missing';
    return '$origin/$_slug?draft=1&ptoken=${Uri.encodeComponent(token)}';
  }

  Future<void> _openExternal() async {
    final url = _url;
    if (url == null) return;
    if (!await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication) && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open URL')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: _muted, fontSize: 13)),
            const SizedBox(height: 12),
            TextButton(onPressed: _load, child: const Text('Retry')),
          ],
        ),
      );
    }
    if (_loading) {
      return const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: _muted)));
    }
    final boot = _boot;
    if (boot == null) {
      return const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: _muted)));
    }
    final guest = GuestSiteView.bootJson(bootJson: boot);
    if (widget.embedded) return _embeddedPreview(child: guest);
    return _previewChrome(child: guest);
  }

  Widget _embeddedPreview({required Widget child}) => Stack(
        children: [
          Positioned.fill(child: SingleChildScrollView(child: child)),
          Positioned(
            top: 4,
            right: 4,
            child: Material(
              color: const Color(0xCC18181B),
              borderRadius: BorderRadius.circular(6),
              child: uiIconButton(
                tooltip: 'Open in browser',
                onPressed: _openExternal,
                icon: const Icon(Icons.open_in_new, size: 16, color: _muted),
              ),
            ),
          ),
        ],
      );

  Widget _previewChrome({required Widget child}) => DecoratedBox(
        decoration: BoxDecoration(border: Border.all(color: _border), borderRadius: BorderRadius.circular(8)),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: _embeddedPreview(child: child),
        ),
      );
}

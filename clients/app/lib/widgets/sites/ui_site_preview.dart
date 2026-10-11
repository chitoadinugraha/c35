import 'dart:async';
import 'dart:convert';

import 'package:alienai_c35/c/pb/c35/site.pb.dart';
import 'package:alienai_c35/c/site/site_editor_preview_cache.dart';
import 'package:alienai_c35/c/site/site_api.dart';
import 'package:alienai_c35/c/site/site_preview_external_url.dart';
import 'package:alienai_c35/c/ui/ui_friendly_error.dart';
import 'package:alienai_c35/guest_site/guest_site_shell.dart';
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
    this.editorPreview,
    this.embedded = false,
    this.showVisitOverlay = true,
  });

  final SiteRow row;
  final SiteApi api;
  final SitePreviewMode mode;
  final int reloadNonce;
  /// When set (site editor), preview reads boot from cache for instant updates.
  final Listenable? editorPreview;
  final bool embedded;
  final bool showVisitOverlay;

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
    widget.editorPreview?.addListener(_onEditorPreviewChanged);
    if (widget.editorPreview != null) {
      final cache = widget.editorPreview as SiteEditorPreviewCache?;
      unawaited(cache?.ensureLoaded());
      unawaited(_refreshExternalUrl());
    } else {
      unawaited(_load());
    }
  }

  @override
  void dispose() {
    widget.editorPreview?.removeListener(_onEditorPreviewChanged);
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant UiSitePreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.editorPreview != null) {
      if (oldWidget.editorPreview != widget.editorPreview) {
        oldWidget.editorPreview?.removeListener(_onEditorPreviewChanged);
        widget.editorPreview?.addListener(_onEditorPreviewChanged);
      }
      if (oldWidget.mode != widget.mode || oldWidget.row.siteIid != widget.row.siteIid) {
        final cache = widget.editorPreview as SiteEditorPreviewCache?;
        cache?.setMode(widget.mode);
        cache?.updateRow(widget.row);
        unawaited(_refreshExternalUrl());
      }
      return;
    }
    if (oldWidget.mode != widget.mode ||
        oldWidget.reloadNonce != widget.reloadNonce ||
        oldWidget.row.siteIid != widget.row.siteIid) {
      unawaited(_load());
    }
  }

  void _onEditorPreviewChanged() {
    if (!mounted) return;
    setState(() {});
  }

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
      if (!mounted) return;
      setState(() {
        _boot = boot;
        _loading = false;
      });
      await _refreshExternalUrl();
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = uiFriendlyError(e);
          _loading = false;
        });
      }
    }
  }

  Future<void> _refreshExternalUrl() async {
    try {
      final url = await sitePreviewExternalUrl(api: widget.api, row: widget.row, mode: widget.mode);
      if (mounted) setState(() => _url = url);
    } catch (_) {
      if (mounted) setState(() => _url = null);
    }
  }

  Future<void> _openExternal() async {
    try {
      final url = _url ?? await sitePreviewExternalUrl(api: widget.api, row: widget.row, mode: widget.mode);
      if (!await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication) && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open URL')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(uiFriendlyError(e))));
      }
    }
  }

  Map<String, dynamic>? _bootFromEditorCache() {
    final cache = widget.editorPreview as SiteEditorPreviewCache?;
    return cache?.boot;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.editorPreview != null) {
      final cache = widget.editorPreview as SiteEditorPreviewCache?;
      final err = cache?.error;
      if (err != null && cache?.boot == null) {
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(err, textAlign: TextAlign.center, style: const TextStyle(color: _muted, fontSize: 13)),
              const SizedBox(height: 12),
              TextButton(onPressed: () => unawaited(cache?.reloadFromServer(keepVisible: false)), child: const Text('Retry')),
            ],
          ),
        );
      }
      if (cache?.loading == true && cache?.boot == null) {
        return const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: _muted)));
      }
      final boot = _bootFromEditorCache();
      if (boot == null) {
        return const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: _muted)));
      }
      final guest = GuestSiteShell.bootJson(bootJson: boot);
      if (widget.embedded) return _embeddedPreview(child: guest);
      return _previewChrome(child: guest);
    }
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
    final guest = GuestSiteShell.bootJson(bootJson: boot);
    if (widget.embedded) return _embeddedPreview(child: guest);
    return _previewChrome(child: guest);
  }

  Widget _embeddedPreview({required Widget child}) => Stack(
        children: [
          Positioned.fill(child: child),
          if (widget.showVisitOverlay)
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

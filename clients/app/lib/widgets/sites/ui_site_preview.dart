import 'package:alienai_c35/c/config.dart';
import 'package:alienai_c35/c/pb/c35/site.pb.dart';
import 'package:alienai_c35/c/site/site_api.dart';
import 'package:alienai_c35/c/ui/ui_friendly_error.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

const _muted = Color(0xFF71717A);
const _border = Color(0xFF27272A);

enum SitePreviewMode { draft, published }

class UiSitePreview extends StatefulWidget {
  const UiSitePreview({
    super.key,
    required this.row,
    required this.api,
    this.mode = SitePreviewMode.draft,
    this.reloadNonce = 0,
  });

  final SiteRow row;
  final SiteApi api;
  final SitePreviewMode mode;
  final int reloadNonce;

  @override
  State<UiSitePreview> createState() => _UiSitePreviewState();
}

class _UiSitePreviewState extends State<UiSitePreview> {
  WebViewController? _controller;
  var _loading = true;
  String? _error;
  String? _url;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant UiSitePreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.mode != widget.mode ||
        oldWidget.reloadNonce != widget.reloadNonce ||
        oldWidget.row.siteIid != widget.row.siteIid) {
      _load();
    }
  }

  String get _slug => widget.row.alienId.isNotEmpty ? widget.row.alienId : widget.row.siteIid.toString();

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
      _controller = null;
    });
    try {
      final origin = C35Config.guestSiteOrigin.replaceAll(RegExp(r'/+$'), '');
      late final String url;
      if (widget.mode == SitePreviewMode.draft) {
        final res = await widget.api.sitePreviewToken(widget.row.siteIid.toInt());
        final token = res.token;
        if (token.isEmpty) throw 'Preview token missing';
        url = '$origin/$_slug?draft=1&ptoken=${Uri.encodeComponent(token)}';
      } else {
        url = '$origin/$_slug';
      }
      if (!mounted) return;
      final ctrl = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageStarted: (_) {
              if (mounted) setState(() => _loading = true);
            },
            onPageFinished: (_) {
              if (mounted) setState(() => _loading = false);
            },
            onWebResourceError: (e) {
              if (mounted) {
                setState(() {
                  _error = e.description.isNotEmpty ? e.description : 'Failed to load preview';
                  _loading = false;
                });
              }
            },
          ),
        )
        ..loadRequest(Uri.parse(url));
      setState(() {
        _url = url;
        _controller = ctrl;
        _loading = true;
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
    final ctrl = _controller;
    if (ctrl == null) {
      return const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: _muted)));
    }
    return DecoratedBox(
      decoration: BoxDecoration(border: Border.all(color: _border), borderRadius: BorderRadius.circular(8)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          children: [
            WebViewWidget(controller: ctrl),
            if (_loading) const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: _muted))),
            Positioned(
              top: 4,
              right: 4,
              child: Material(
                color: const Color(0xCC18181B),
                borderRadius: BorderRadius.circular(6),
                child: IconButton(
                  tooltip: 'Open in browser',
                  onPressed: _openExternal,
                  icon: const Icon(Icons.open_in_new, size: 16, color: _muted),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'dart:async';

import 'package:alienai_c35/pages/mail/mail_external_link.dart';
import 'package:alienai_c35/pages/mail/mail_html_sanitize.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class MailHtmlBody extends StatefulWidget {
  const MailHtmlBody({super.key, required this.html});

  final String html;

  @override
  State<MailHtmlBody> createState() => _MailHtmlBodyState();
}

class _MailHtmlBodyState extends State<MailHtmlBody> {
  static const _maxBodyHeight = 480.0;
  WebViewController? _controller;
  String? _loadedHtml;

  String _wrappedHtml(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final fg = mailHtmlCssColor(cs.onSurface);
    final bg = mailHtmlCssColor(cs.surface);
    final link = mailHtmlCssColor(cs.primary);
    final body = sanitizeMailHtml(widget.html);
    return '''
<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<meta http-equiv="Content-Security-Policy" content="default-src 'none'; img-src https: http: data: cid:; style-src 'unsafe-inline'; font-src https: data:;">
<style>
  body { margin: 0; padding: 0; font-family: system-ui, -apple-system, sans-serif; font-size: 15px; line-height: 1.5; color: $fg; background: $bg; }
  img { max-width: 100%; height: auto; }
  a { color: $link; }
  blockquote { margin: 8px 0; padding-left: 12px; border-left: 3px solid rgba(127,127,127,0.35); }
</style>
</head>
<body>$body</body>
</html>
''';
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final html = _wrappedHtml(context);
    if (_loadedHtml == html && _controller != null) return;
    _loadedHtml = html;
    final ctrl = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.disabled)
      ..setBackgroundColor(Colors.transparent)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (request) {
            final uri = Uri.tryParse(request.url);
            if (uri != null && mailExternalUrlSchemeAllowed(uri)) {
              unawaited(confirmAndLaunchMailExternalUrl(context, uri));
            }
            return NavigationDecision.prevent;
          },
        ),
      )
      ..loadHtmlString(html);
    setState(() => _controller = ctrl);
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = _controller;
    if (ctrl == null) {
      return const SizedBox(
        height: 48,
        child: Center(child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))),
      );
    }
    return SizedBox(
      height: _maxBodyHeight,
      child: WebViewWidget(controller: ctrl),
    );
  }
}

import 'package:alienai_c35/pages/mail/mail_external_link.dart';
import 'package:alienai_c35/pages/mail/mail_html_sanitize.dart';
import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';

class MailHtmlBody extends StatelessWidget {
  const MailHtmlBody({super.key, required this.html});

  final String html;

  static const _maxBodyHeight = 480.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final textStyle = theme.textTheme.bodyMedium?.copyWith(
      fontSize: 15,
      height: 1.5,
      color: cs.onSurface,
    );
    final safe = sanitizeMailHtml(html);
    if (safe.trim().isEmpty) {
      return const SizedBox.shrink();
    }
    return SizedBox(
      height: _maxBodyHeight,
      child: SingleChildScrollView(
        child: HtmlWidget(
          safe,
          textStyle: textStyle,
          onTapUrl: (url) async {
            final uri = Uri.tryParse(url);
            if (uri != null && mailExternalUrlSchemeAllowed(uri)) {
              await confirmAndLaunchMailExternalUrl(context, uri);
            }
            return true;
          },
        ),
      ),
    );
  }
}

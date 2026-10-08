import 'package:alienai_c35/c/pb/c35/site.pb.dart';
import 'package:alienai_c35/c/site/site_api.dart';
import 'package:alienai_c35/widgets/sites/ui_site_preview.dart';
import 'package:flutter/material.dart';

/// Live guest preview for the site editor right column (CSA layout).
class UiSitePreviewPane extends StatelessWidget {
  const UiSitePreviewPane({
    super.key,
    required this.row,
    required this.api,
    required this.mode,
    required this.reloadNonce,
    this.padding = const EdgeInsets.fromLTRB(8, 8, 12, 12),
  });

  final SiteRow row;
  final SiteApi api;
  final SitePreviewMode mode;
  final int reloadNonce;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) => ColoredBox(
        color: const Color(0xFF08080A),
        child: Padding(
          padding: padding,
          child: UiSitePreview(
            row: row,
            api: api,
            mode: mode,
            reloadNonce: reloadNonce,
            embedded: true,
          ),
        ),
      );
}

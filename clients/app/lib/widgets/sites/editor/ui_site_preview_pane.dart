import 'package:alienai_c35/c/pb/c35/site.pb.dart';
import 'package:alienai_c35/c/site/site_api.dart';
import 'package:alienai_c35/widgets/sites/editor/ui_site_phone_preview_frame.dart';
import 'package:alienai_c35/widgets/sites/ui_site_preview.dart';
import 'package:flutter/material.dart';

const _muted = Color(0xFF71717A);

/// Live guest preview for the site editor right column (CSA layout).
class UiSitePreviewPane extends StatelessWidget {
  const UiSitePreviewPane({
    super.key,
    required this.row,
    required this.api,
    required this.mode,
    required this.reloadNonce,
    this.usePhoneFrame = true,
  });

  final SiteRow row;
  final SiteApi api;
  final SitePreviewMode mode;
  final int reloadNonce;
  final bool usePhoneFrame;

  @override
  Widget build(BuildContext context) => ColoredBox(
        color: const Color(0xFF08080A),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
              child: Text('Live preview', style: const TextStyle(color: _muted, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.4)),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 12, 12),
                child: usePhoneFrame
                    ? UiSitePhonePreviewFrame(
                        child: UiSitePreview(
                          row: row,
                          api: api,
                          mode: mode,
                          reloadNonce: reloadNonce,
                          embedded: true,
                        ),
                      )
                    : UiSitePreview(
                        row: row,
                        api: api,
                        mode: mode,
                        reloadNonce: reloadNonce,
                        embedded: true,
                      ),
              ),
            ),
          ],
        ),
      );
}

import 'package:alienai_c35/c/config.dart';
import 'package:alienai_c35/c/log.dart';
import 'package:alienai_c35/c/pb/c35/site.pb.dart';
import 'package:alienai_c35/c/ui/ui_friendly_error.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

Future<void> siteRowVisit(BuildContext context, SiteRow row) async {
  try {
    final origin = C35Config.guestSiteOrigin.replaceAll(RegExp(r'/+$'), '');
    final slug = row.alienId.isNotEmpty ? row.alienId : row.siteIid.toString();
    final url = row.publishedVersionId.isNotEmpty ? '$origin/$slug' : '$origin/$slug?draft=1';
    if (!await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication) && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open URL'), behavior: SnackBarBehavior.floating),
      );
    }
  } catch (e) {
    lError('site visit: $e');
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(uiFriendlyError(e)), behavior: SnackBarBehavior.floating),
      );
    }
  }
}

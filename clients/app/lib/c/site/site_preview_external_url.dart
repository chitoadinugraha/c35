import 'package:alienai_c35/c/config.dart';
import 'package:alienai_c35/c/pb/c35/site.pb.dart';
import 'package:alienai_c35/c/site/site_api.dart';
import 'package:alienai_c35/guest_site/site_preview_mode.dart';

/// External browser URL for site preview (draft uses `ptoken`, published uses live slug).
Future<String> sitePreviewExternalUrl({
  required SiteApi api,
  required SiteRow row,
  required SitePreviewMode mode,
}) async {
  final origin = C35Config.guestSiteOrigin.replaceAll(RegExp(r'/+$'), '');
  final slug = row.alienId.isNotEmpty ? row.alienId : row.siteIid.toString();
  if (mode == SitePreviewMode.published) return '$origin/$slug';
  final res = await api.sitePreviewToken(row.siteIid.toInt());
  final token = res.token;
  if (token.isEmpty) throw 'Preview token missing';
  return '$origin/$slug?draft=1&ptoken=${Uri.encodeComponent(token)}';
}

/// Order-track status line (matches `c35GuestOrder.poll` in site-guest.v1.js).
String guestOrderTrackPollLabel(Map<String, dynamic> tx) {
  final progress = tx['progress_label']?.toString().trim();
  if (progress != null && progress.isNotEmpty) return progress;
  final state = tx['state']?.toString().trim();
  if (state != null && state.isNotEmpty) return state;
  final status = tx['status']?.toString().trim();
  if (status != null && status.isNotEmpty) return status;
  return '—';
}

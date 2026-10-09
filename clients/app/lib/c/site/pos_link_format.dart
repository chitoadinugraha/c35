/// Deep links that open staff POS for a site (`id.alienai://pos/<site_iid>`).
String posAppSchemeUrl(String siteIid) => 'id.alienai://pos/${siteIid.trim()}';

String posAppWebUrl(String siteIid) =>
    'https://alienai.id/app/pos/${Uri.encodeComponent(siteIid.trim())}';

/// Numeric site iid from app scheme or `/app/pos/<id>` HTTPS path.
String? posSiteIidFromUri(Uri uri) {
  final host = uri.host.toLowerCase();
  if (uri.scheme == 'id.alienai' && host == 'pos') {
    return _posIdFromPath(uri);
  }
  final segs = uri.pathSegments.where((s) => s.isNotEmpty).toList();
  final i = segs.indexWhere((s) => s.toLowerCase() == 'pos');
  if (i >= 0 && i + 1 < segs.length) {
    return _normSiteIid(segs[i + 1]);
  }
  return null;
}

String? _posIdFromPath(Uri uri) {
  final segs = uri.pathSegments.where((s) => s.isNotEmpty).toList();
  if (segs.isEmpty) return null;
  return _normSiteIid(segs.first);
}

String? _normSiteIid(String raw) {
  final id = raw.trim();
  if (id.isEmpty || !RegExp(r'^\d+$').hasMatch(id)) return null;
  return id;
}

/// Desktop / launcher label: `<Site> - Alien AI POS`.
String posShortcutLabel(String siteName) {
  final base = siteName.trim().isEmpty ? 'Site' : siteName.trim();
  return '$base - Alien AI POS';
}

/// Safe file name stem for `.lnk` (no extension).
String posShortcutFileStem(String siteName) {
  var stem = posShortcutLabel(siteName);
  stem = stem.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
  stem = stem.replaceAll(RegExp(r'\s+'), ' ').trim();
  if (stem.isEmpty) stem = 'Site - Alien AI POS';
  const max = 120;
  if (stem.length > max) stem = '${stem.substring(0, max - 3)}...';
  return stem;
}

String posShortcutId(String siteIid) => 'pos_${siteIid.trim()}';
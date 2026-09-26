String fileStoragePath(String hash) => '/fs/$hash';

String? fileFsHash(String path) {
  final p = path.trim();
  if (p.isEmpty) return null;
  final m = RegExp(r'(?:^|/)([a-fA-F0-9]{64})$').firstMatch(p);
  if (m != null) return m.group(1)!.toLowerCase();
  final m2 = RegExp(r'/fs/([a-fA-F0-9]{64})').firstMatch(p);
  return m2?.group(1)?.toLowerCase();
}

String fileServeUrl(String path, {required String baseUrl}) {
  final p = path.trim();
  if (p.isEmpty) return p;
  if (p.startsWith('http://') || p.startsWith('https://') || p.startsWith('data:')) return p;
  if (p.startsWith('/fs/')) return '${baseUrl.replaceAll(RegExp(r'/+$'), '')}$p';
  final match = RegExp(r'/fs/([a-fA-F0-9]{64})').firstMatch(p);
  if (match != null) return '${baseUrl.replaceAll(RegExp(r'/+$'), '')}/fs/${match.group(1)}';
  return p.startsWith('/') ? '${baseUrl.replaceAll(RegExp(r'/+$'), '')}$p' : p;
}

String fileImageUrl(String path, {required String baseUrl}) {
  final url = fileServeUrl(path, baseUrl: baseUrl).trim();
  if (url.startsWith('http://') || url.startsWith('https://') || url.startsWith('data:')) return url;
  return '';
}

String fileFsPublicUrl(String hash, {required String baseUrl}) => '${baseUrl.replaceAll(RegExp(r'/+$'), '')}/fs/$hash';

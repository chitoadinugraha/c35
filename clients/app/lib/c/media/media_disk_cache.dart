import 'dart:convert';
import 'dart:io';

import 'package:alienai_c35/c/config.dart';
import 'package:alienai_c35/c/log.dart';
import 'package:alienai_c35/c/session.dart';
import 'package:blake3_dart/blake3_dart.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:alienai_c35/c/media/media_disk_cache_paths.dart'
    if (dart.library.html) 'package:alienai_c35/c/media/media_disk_cache_paths_web.dart';
import 'package:alienai_c35/c/media/media_disk_cache_platform.dart'
    if (dart.library.html) 'package:alienai_c35/c/media/media_disk_cache_platform_web.dart' as media_disk_cache_platform;
import 'package:path/path.dart' as p;

const _cacheVersion = 'v1';

Directory? _testCacheRoot;

@visibleForTesting
void mediaDiskCacheTestRoot(Directory? dir) => _testCacheRoot = dir;

String mediaUrlResolve(String src) {
  final cleaned = src.trim();
  if (cleaned.isEmpty) return '';
  if (cleaned.startsWith('http://') || cleaned.startsWith('https://')) return cleaned;
  if (cleaned.startsWith('/fs/') || cleaned.startsWith('fs/')) {
    final base = C35Config.authApiBase.replaceAll(RegExp(r'/+$'), '');
    final path = cleaned.startsWith('/') ? cleaned : '/$cleaned';
    return '$base$path';
  }
  final base = C35Config.authApiBase.replaceAll(RegExp(r'/+$'), '');
  return '$base${cleaned.startsWith('/') ? cleaned : '/$cleaned'}';
}

String mediaDiskCacheKey(String resolvedUrl) => blake3Hex(utf8.encode(resolvedUrl));

Map<String, String>? mediaDiskCacheAuthHeaders() {
  final token = sessionAuthToken();
  return token.isEmpty ? null : {'Authorization': 'Bearer $token'};
}

bool get mediaDiskCacheEnabled => media_disk_cache_platform.mediaDiskCachePlatformEnabled();

Future<Directory> mediaDiskCacheRoot() async {
  if (!mediaDiskCacheEnabled) {
    throw UnsupportedError('media disk cache is not available on web');
  }
  if (_testCacheRoot != null) return _testCacheRoot!;
  final basePath = await mediaDiskCacheApplicationDir();
  final dir = Directory(p.join(basePath, 'c35_media', _cacheVersion));
  if (!dir.existsSync()) dir.createSync(recursive: true);
  return dir;
}

Future<File?> mediaDiskCacheFileForUrl(String resolvedUrl) async {
  if (!mediaDiskCacheEnabled || resolvedUrl.isEmpty) return null;
  final root = await mediaDiskCacheRoot();
  final file = File(p.join(root.path, mediaDiskCacheKey(resolvedUrl)));
  return file.existsSync() ? file : null;
}

Future<File?> mediaDiskCacheFetch(String src, {Map<String, String>? headers, bool fetchIfMissing = true}) async {
  if (!mediaDiskCacheEnabled) return null;
  final url = mediaUrlResolve(src);
  if (url.isEmpty) return null;
  final existing = await mediaDiskCacheFileForUrl(url);
  if (existing != null) return existing;
  if (!fetchIfMissing) return null;
  try {
    final res = await http.get(Uri.parse(url), headers: headers ?? mediaDiskCacheAuthHeaders());
    if (res.statusCode < 200 || res.statusCode >= 300) return null;
    final bytes = res.bodyBytes;
    if (bytes.isEmpty) return null;
    final root = await mediaDiskCacheRoot();
    final file = File(p.join(root.path, mediaDiskCacheKey(url)));
    final tmp = File('${file.path}.part');
    await tmp.writeAsBytes(bytes, flush: true);
    if (file.existsSync()) await file.delete();
    await tmp.rename(file.path);
    return file;
  } catch (e) {
    lError('mediaDiskCacheFetch $url: $e');
    return null;
  }
}

Future<void> mediaDiskCachePrefetch(Iterable<String> srcs, {Map<String, String>? headers, int maxConcurrent = 6}) async {
  if (!mediaDiskCacheEnabled) return;
  final urls = srcs.map(mediaUrlResolve).where((u) => u.isNotEmpty).toSet();
  if (urls.isEmpty) return;
  final auth = headers ?? mediaDiskCacheAuthHeaders();
  var i = 0;
  final list = urls.toList(growable: false);
  while (i < list.length) {
    final batch = list.skip(i).take(maxConcurrent).toList(growable: false);
    i += batch.length;
    await Future.wait(batch.map((u) => mediaDiskCacheFetch(u, headers: auth, fetchIfMissing: true)));
  }
}

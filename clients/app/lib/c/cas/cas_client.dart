import 'dart:convert';

import 'package:alienai_c35/c/config.dart';
import 'package:alienai_c35/c/session.dart';
import 'package:alienai_c35/c/ui/ui_friendly_error.dart';
import 'package:http/http.dart' as http;

class CasUploadRes {
  const CasUploadRes({required this.hash, required this.url, required this.mimeType});
  final String hash;
  final String url;
  final String mimeType;
}

Future<CasUploadRes?> casUpload({required List<int> bytes, required String mime, String name = '', void Function(double progress)? onProgress}) async {
  final token = sessionAuthToken();
  if (token.isEmpty || bytes.isEmpty) return null;
  onProgress?.call(0.1);
  final base = C35Config.authApiBase.replaceAll(RegExp(r'/+$'), '');
  final res = await http.post(
    Uri.parse('$base/v1/file/upload'),
    headers: {
      'Content-Type': mime.isEmpty ? 'application/octet-stream' : mime,
      'Authorization': 'Bearer $token',
      if (name.isNotEmpty) 'x-file-name': Uri.encodeComponent(name),
    },
    body: bytes,
  );
  if (res.statusCode < 200 || res.statusCode >= 300) {
    final raw = res.body.trim();
    if (raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic>) {
          final msg = (decoded['error'] ?? decoded['message'] ?? '').toString().trim();
          if (msg.isNotEmpty) throw ApiException(msg);
        }
      } catch (e) {
        if (e is ApiException) rethrow;
      }
      if (raw.length <= 200) throw ApiException(raw);
    }
    throw ApiException('upload failed (${res.statusCode})');
  }
  final body = jsonDecode(res.body) as Map<String, dynamic>;
  onProgress?.call(1.0);
  return CasUploadRes(hash: body['hash'] as String? ?? '', url: body['url'] as String? ?? '', mimeType: body['mime_type'] as String? ?? mime);
}

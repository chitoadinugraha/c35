import 'package:alienai_c35/c/config.dart';
import 'package:alienai_c35/c/session.dart';
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
  if (res.statusCode < 200 || res.statusCode >= 300) return null;
  onProgress?.call(1.0);
  return null;
}

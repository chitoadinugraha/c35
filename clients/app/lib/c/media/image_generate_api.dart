import 'package:alienai_c35/c/chat/chat_conn.dart';

class ImageGenerateQuotaException implements Exception {
  @override
  String toString() => 'Not enough frontier quota';
}

class ImageGenerateResult {
  const ImageGenerateResult({required this.hash, required this.url, required this.mime});

  final String hash;
  final String url;
  final String mime;
}

Future<ImageGenerateResult> imageGenerate(
  ChatConn conn, {
  required String prompt,
  required String provider,
}) async {
  final res = await conn.imgGenerate(prompt: prompt, provider: provider);
  final quota = res.error == 'Not enough frontier quota';
  if (quota || (res.hash.isEmpty && quota)) {
    throw ImageGenerateQuotaException();
  }
  return ImageGenerateResult(hash: res.hash, url: res.url, mime: res.mime);
}

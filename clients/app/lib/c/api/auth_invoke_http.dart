import 'package:alienai_c35/c/api/wire.dart';
import 'package:alienai_c35/c/config.dart';
import 'package:alienai_c35/c/session.dart';
import 'package:http/http.dart' as http;

Future<AuthInvokeRes> authInvokeHttp({List<int> body = const [], String path = '', String method = 'POST'}) async {
  final token = sessionAuthToken();
  if (token.isEmpty) return const AuthInvokeRes(statusCode: 401, error: 'Not signed in');
  final base = C35Config.authApiBase.replaceAll(RegExp(r'/+$'), '');
  final uri = path.isNotEmpty ? Uri.parse('$base$path') : Uri.parse('$base/v1/auth/invoke');
  try {
    final res = await http
        .post(
          uri,
          headers: {
            'Authorization': 'Bearer $token',
            'X-Session-Token': token,
            'Content-Type': 'application/x-protobuf',
            if (method.isNotEmpty) 'X-HTTP-Method-Override': method,
          },
          body: body,
        )
        .timeout(const Duration(seconds: 30));
    if (res.statusCode == 404) {
      return AuthInvokeRes(statusCode: 503, error: 'This feature is not available on the server yet.');
    }
    return AuthInvokeRes(statusCode: res.statusCode, body: res.bodyBytes, error: res.statusCode >= 400 && res.bodyBytes.isEmpty ? 'Request failed' : '');
  } catch (e) {
    return AuthInvokeRes(statusCode: 0, error: e.toString());
  }
}

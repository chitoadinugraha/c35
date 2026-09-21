import 'package:alienai_c35/c/api/auth_invoke_http.dart';
import 'package:alienai_c35/c/api/wire.dart';

class SettingsConn {
  SettingsConn({AuthInvokeFn? invoke}) : _invoke = invoke ?? authInvokeHttp;

  final AuthInvokeFn _invoke;

  AuthInvokeFn get authInvoke => _invoke;

  Future<AuthInvokeRes> authInvokeCall({List<int> body = const [], String path = '', String method = 'POST'}) =>
      _invoke(body: body, path: path, method: method);
}

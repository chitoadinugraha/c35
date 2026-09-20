/// Minimal wire types for HTTP invoke (sidecar path unused in Phase 1).
class AuthInvokeRes {
  const AuthInvokeRes({this.requestId = '', this.statusCode = 0, this.error = '', this.body = const []});
  final String requestId;
  final int statusCode;
  final String error;
  final List<int> body;
}

typedef AuthInvokeFn = Future<AuthInvokeRes> Function({List<int> body, String path, String method});

Future<AuthInvokeRes> authInvokeUnavailable({List<int> body = const [], String path = '', String method = 'POST'}) async =>
    const AuthInvokeRes(statusCode: 503, error: 'Agent sidecar not available');

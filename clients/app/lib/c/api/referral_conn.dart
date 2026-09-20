import 'package:alienai_c35/c/api/wire.dart';
import 'package:alienai_c35/c/config.dart';
import 'package:alienai_c35/c/pb/c35/wire.pb.dart';
import 'package:alienai_c35/c/session.dart';
import 'package:fixnum/fixnum.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

String? invokeResError(InvokeRes res, {required String fallback}) {
  final msg = res.errorMessage.trim();
  if (msg.isNotEmpty) return msg;
  if (res.statusCode >= 400) return fallback;
  return null;
}

void invokeResThrow(InvokeRes res, {required String fallback}) {
  final err = invokeResError(res, fallback: fallback);
  if (err != null) throw err;
}

class ReferralConn {
  ReferralConn({AuthInvokeFn? invoke, int? uid}) : _invoke = invoke ?? authInvokeUnavailable, _uid = uid ?? Session.instance.uid;

  final AuthInvokeFn _invoke;
  final int _uid;

  Future<InvokeRes> invoke(InvokeReq req, {Duration timeout = const Duration(seconds: 30)}) async {
    if (req.reqId.isEmpty) req.reqId = const Uuid().v4();
    if (req.callerIid == Int64.ZERO) req.callerIid = Int64(_uid);
    final token = sessionAuthToken();
    if (token.isNotEmpty) return _invokeHttp(req, token, timeout);
    return _invokeAgent(req, timeout);
  }

  Future<InvokeRes> _invokeHttp(InvokeReq req, String token, Duration timeout) async {
    final base = C35Config.authApiBase.replaceAll(RegExp(r'/+$'), '');
    try {
      final res = await http
          .post(
            Uri.parse('$base/v1/invoke'),
            headers: {
              'Authorization': 'Bearer $token',
              'X-Session-Token': token,
              'Content-Type': 'application/x-protobuf',
            },
            body: req.writeToBuffer(),
          )
          .timeout(timeout);
      if (res.statusCode != 200 || res.bodyBytes.isEmpty) {
        if (res.bodyBytes.isNotEmpty) {
          try {
            final inv = InvokeRes.fromBuffer(res.bodyBytes);
            if (inv.errorMessage.isNotEmpty) {
              return InvokeRes(reqId: inv.reqId.isNotEmpty ? inv.reqId : req.reqId, statusCode: inv.statusCode == 0 ? (res.statusCode == 0 ? 503 : res.statusCode) : inv.statusCode, errorMessage: inv.errorMessage);
            }
          } catch (_) {}
        }
        return InvokeRes(reqId: req.reqId, statusCode: res.statusCode == 0 ? 503 : res.statusCode, errorMessage: res.body.isNotEmpty ? res.body : 'request failed');
      }
      return InvokeRes.fromBuffer(res.bodyBytes);
    } catch (e) {
      return InvokeRes(reqId: req.reqId, statusCode: 0, errorMessage: e.toString().contains('TimeoutException') ? 'Request timed out. Check your internet and try again.' : e.toString());
    }
  }

  Future<InvokeRes> _invokeAgent(InvokeReq req, Duration timeout) async {
    final res = await _invoke(body: req.writeToBuffer(), path: '/v1/invoke', method: 'POST').timeout(
      timeout,
      onTimeout: () => const AuthInvokeRes(statusCode: 0, error: 'Request timed out. Check your internet and try again.'),
    );
    if (res.statusCode != 200 || res.body.isEmpty) {
      return InvokeRes(reqId: req.reqId, statusCode: res.statusCode == 0 ? 503 : res.statusCode, errorMessage: res.error.isNotEmpty ? res.error : 'request failed');
    }
    return InvokeRes.fromBuffer(res.body);
  }
}

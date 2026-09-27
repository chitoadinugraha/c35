import 'dart:io';
import 'package:alienai_c35/c/pb/c35/device.pb.dart';
import 'package:alienai_c35/c/pb/c35/wire.pb.dart';
import 'package:fixnum/fixnum.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

Future<void> main(List<String> args) async {
  if (args.isEmpty) {
    stderr.writeln('usage: device_pair_claim.dart <code>');
    exit(2);
  }
  final token = Platform.environment['DEPLOY_AUTH_TOKEN'] ?? '';
  if (token.isEmpty) {
    stderr.writeln('DEPLOY_AUTH_TOKEN required');
    exit(2);
  }
  final code = args.first.replaceAll('-', '').trim();
  final req = InvokeReq(
    reqId: const Uuid().v4(),
    callerIid: Int64(99000),
    devicePair: ReqDevicePair(code: code),
  );
  final res = await http.post(
    Uri.parse('https://api.alienai.id/v1/invoke'),
    headers: {
      'Authorization': 'Bearer $token',
      'X-Session-Token': token,
      'Content-Type': 'application/x-protobuf',
    },
    body: req.writeToBuffer(),
  );
  if (res.statusCode != 200) {
    stderr.writeln('invoke ${res.statusCode}: ${res.body}');
    exit(1);
  }
  final out = InvokeRes.fromBuffer(res.bodyBytes);
  if (out.errorMessage.isNotEmpty) {
    stderr.writeln('error: ${out.errorMessage}');
    exit(1);
  }
  if (!out.hasDevicePair()) {
    stderr.writeln('no device_pair in response');
    exit(1);
  }
  final dev = out.devicePair.device;
  final iid = dev.hasIdentity() ? dev.identity.iid : Int64.ZERO;
  stdout.writeln('claimed device_iid=$iid name=${dev.hasIdentity() ? dev.identity.name : ""}');
}
// Invoke ReqAdminDiskClean (Yugabyte broom) via protobuf HTTP.
// Usage:
//   mint DEPLOY_AUTH_TOKEN first (mint_deploy_auth_token.ps1)
//   dart run _/scripts/dev/admin_yb_disk_clean_invoke.dart 10.0.85.142
//   dart run _/scripts/dev/admin_yb_disk_clean_invoke.dart 10.0.85.142 --full
import 'dart:io';

import 'package:alienai_c35/c/pb/c35/stats.pb.dart';
import 'package:alienai_c35/c/pb/c35/wire.pb.dart';
import 'package:fixnum/fixnum.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

Future<void> main(List<String> args) async {
  final full = args.contains('--full');
  final nodeArgs = args.where((a) => !a.startsWith('--')).toList();
  if (nodeArgs.isEmpty) {
    stderr.writeln('usage: admin_yb_disk_clean_invoke.dart <node_name> [--full]');
    exit(2);
  }
  final nodeName = nodeArgs.first;
  final token = Platform.environment['DEPLOY_AUTH_TOKEN'] ?? '';
  if (token.isEmpty) {
    stderr.writeln('DEPLOY_AUTH_TOKEN required');
    exit(2);
  }
  final base = (Platform.environment['C35_SERVER_URL'] ?? 'https://api.alienai.id').trim().replaceAll(RegExp(r'/+$'), '');
  final req = InvokeReq(
    reqId: const Uuid().v4(),
    callerIid: Int64(99000),
    adminDiskClean: ReqAdminDiskClean(
      nodeName: nodeName,
      kind: AdminDiskCleanKind.ADMIN_DISK_CLEAN_YUGABYTE,
      full: full,
    ),
  );
  stdout.writeln('POST $base/v1/invoke node=$nodeName full=$full');
  final res = await http.post(
    Uri.parse('$base/v1/invoke'),
    headers: {
      'Authorization': 'Bearer $token',
      'X-Session-Token': token,
      'Content-Type': 'application/x-protobuf',
    },
    body: req.writeToBuffer(),
  );
  final out = InvokeRes.fromBuffer(res.bodyBytes);
  if (res.statusCode != 200 || out.statusCode != 200) {
    stderr.writeln('invoke HTTP ${res.statusCode} status_code=${out.statusCode} error=${out.errorMessage}');
    exit(1);
  }
  stdout.writeln('status_code=${out.statusCode} error=${out.errorMessage}');
  if (!out.hasAdminDiskClean()) {
    stderr.writeln('no admin_disk_clean body');
    exit(1);
  }
  final dc = out.adminDiskClean;
  stdout.writeln('ok=${dc.ok} message=${dc.message}');
  for (final s in dc.steps) {
    final detail = s.detail.length > 400 ? '${s.detail.substring(0, 400)}...' : s.detail;
    stdout.writeln('  step ${s.name} ok=${s.ok}');
    if (detail.isNotEmpty) stdout.writeln('    $detail');
  }
  exit(dc.ok ? 0 : 1);
}

import 'dart:io';
import 'package:googleapis_auth/auth_io.dart';
import '../deploy_app/deploy_app_lib.dart';
import '../deploy_lib.dart';
Future<void> main() async {
  deployLoadEnvLocal();
  final creds = ServiceAccountCredentials.fromJson(await playStoreCredentialsJson());
  final c = await clientViaServiceAccount(creds, ['https://www.googleapis.com/auth/androidpublisher']);
  const pkg = 'id.alienai';
  final root = 'https://androidpublisher.googleapis.com/androidpublisher/v3/applications/$pkg';
  const id = 'id.alienai.credit.50000';
  for (final path in [
    '/oneTimeProducts?pageSize=10',
    '/onetimeproducts?pageSize=10',
    '/oneTimeProducts/$id',
    '/onetimeproducts/$id',
  ]) {
    final res = await c.get(Uri.parse('$root$path'));
    stdout.writeln('$path -> ${res.statusCode} len=${res.body.length}');
    if (res.statusCode == 200 && res.body.length < 500) stdout.writeln(res.body);
    else if (res.statusCode == 200) stdout.writeln(res.body.substring(0, 300));
  }
  c.close();
}
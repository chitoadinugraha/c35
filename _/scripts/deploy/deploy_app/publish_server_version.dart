import 'publish_app_version.dart';
import 'update_version.dart';
import '../deploy_lib.dart';

const serverLiveUrl = 'https://api.alienai.id/livez';

Future<void> main(List<String> args) async {
  final (_, build) = versionReadPubspec(repoRoot());
  if (build <= 0) throw StateError('Invalid pubspec build for server version publish');
  await publishPlatformAppVersion(platform: 'server', version: build, storeUrl: serverLiveUrl, min: 0);
}
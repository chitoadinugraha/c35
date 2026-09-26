import 'build_remote_windows.dart';
import '../deploy_lib.dart';

void main() async {
  deployLoadEnvLocal();
  await buildRemoteWindowsRelease();
}

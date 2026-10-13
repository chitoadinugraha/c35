import 'package:alienai_c35/c/parts/version_label.dart';
import 'package:alienai_c35/c/update/app_release.dart';

String appBarVersionSubtitle({required int localBuild, AppRelease? remote}) {
  if (remote != null && remote.version > 0 && appReleaseNeedsUpdate(local: localBuild, remote: remote)) {
    return 'New: ${remote.version}';
  }
  return 'Version ${csaiVersionBuild()}';
}

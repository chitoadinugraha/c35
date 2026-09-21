import 'dart:io';

String appUpdateRootDir() {
  final local = Platform.environment['LOCALAPPDATA'];
  if (local != null && local.isNotEmpty) return '$local${Platform.pathSeparator}AlienAI${Platform.pathSeparator}updates';
  return '${Directory.systemTemp.path}${Platform.pathSeparator}alienai-updates';
}

String appUpdateZipPath(int version) => '${appUpdateRootDir()}${Platform.pathSeparator}$version.zip';

String appUpdateStagingDir(int version) => '${appUpdateRootDir()}${Platform.pathSeparator}$version${Platform.pathSeparator}staging';

String appUpdateApplyScriptPath() => '${appUpdateRootDir()}${Platform.pathSeparator}apply.ps1';

String appInstallDir() => File(Platform.resolvedExecutable).parent.path;

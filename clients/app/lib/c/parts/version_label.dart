import 'package:alienai_c35/c/parts/csai__version.dart';

String csaiVersionBuild() {
  final parts = csaiVersion.split('.');
  if (parts.length >= 2 && parts[1].isNotEmpty) return parts[1];
  return csaiVersion;
}

String appVersionLabel() => 'v${csaiVersionBuild()}';

String appVersionDetailLabel() => 'Version: ${csaiVersionBuild()}';

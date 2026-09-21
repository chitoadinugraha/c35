import 'dart:io';

import 'package:alienai_c35/c/log.dart';
import 'package:alienai_c35/c/update/app_update_paths.dart';

Future<bool> appUpdateInstallStaged(int version) async {
  if (!Platform.isWindows) return false;
  final staging = appUpdateStagingDir(version);
  final install = appInstallDir();
  if (!File('$staging${Platform.pathSeparator}alienai.exe').existsSync()) return false;
  final script = appUpdateApplyScriptPath();
  File(script).parent.createSync(recursive: true);
  File(script).writeAsStringSync(_applyPs1(staging: staging, install: install));
  try {
    await Process.start('powershell', ['-NoProfile', '-ExecutionPolicy', 'Bypass', '-WindowStyle', 'Hidden', '-File', script], mode: ProcessStartMode.detached);
    exit(0);
  } catch (e) {
    lError(e);
    return false;
  }
}

String _applyPs1({required String staging, required String install}) => '''
\$staging = '$staging'
\$install = '$install'
\$exe = Join-Path \$install 'alienai.exe'
\$deadline = (Get-Date).AddSeconds(5)
while ((Get-Process -Name alienai -ErrorAction SilentlyContinue) -and ((Get-Date) -lt \$deadline)) {
  Start-Sleep -Milliseconds 200
}
Get-Process -Name alienai -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
Start-Sleep -Milliseconds 200
robocopy \$staging \$install /MIR /NFL /NDL /NJH /NJS /nc /ns /np | Out-Null
if (\$LASTEXITCODE -ge 8) { exit 1 }
Start-Process \$exe
exit 0
''';

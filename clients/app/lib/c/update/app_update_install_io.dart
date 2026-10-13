import 'dart:ffi';
import 'dart:io';

import 'package:alienai_c35/c/log.dart';
import 'package:alienai_c35/c/update/app_update_paths.dart';
import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';

const _createNoWindow = 0x08000000;
const _detachedProcess = 0x00000008;

Future<bool> _startHiddenPowerShellApply(String scriptPath) async {
  final args = '-NoProfile -NonInteractive -ExecutionPolicy Bypass -WindowStyle Hidden -File "$scriptPath"';
  final commandLine = 'powershell.exe $args'.toNativeUtf16();
  final si = calloc<STARTUPINFO>();
  si.ref.cb = sizeOf<STARTUPINFO>();
  si.ref.dwFlags = STARTF_USESHOWWINDOW;
  si.ref.wShowWindow = SW_HIDE;
  final pi = calloc<PROCESS_INFORMATION>();
  try {
    final ok = CreateProcess(
      nullptr,
      commandLine,
      nullptr,
      nullptr,
      FALSE,
      _createNoWindow | _detachedProcess,
      nullptr,
      nullptr,
      si,
      pi,
    );
    if (ok == FALSE) return false;
    CloseHandle(pi.ref.hProcess);
    CloseHandle(pi.ref.hThread);
    return true;
  } finally {
    calloc.free(commandLine);
    calloc.free(si);
    calloc.free(pi);
  }
}

Future<bool> appUpdateInstallStaged(int version) async {
  if (!Platform.isWindows) return false;
  final staging = appUpdateStagingDir(version);
  final install = appInstallDir();
  if (!File('$staging${Platform.pathSeparator}alienai.exe').existsSync()) return false;
  final script = appUpdateApplyScriptPath();
  File(script).parent.createSync(recursive: true);
  File(script).writeAsStringSync(_applyPs1(staging: staging, install: install));
  try {
    final started = await _startHiddenPowerShellApply(script);
    if (!started) {
      await Process.start(
        'powershell.exe',
        ['-NoProfile', '-NonInteractive', '-ExecutionPolicy', 'Bypass', '-WindowStyle', 'Hidden', '-File', script],
        mode: ProcessStartMode.detached,
        runInShell: false,
      );
    }
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
\$deadline = (Get-Date).AddSeconds(8)
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

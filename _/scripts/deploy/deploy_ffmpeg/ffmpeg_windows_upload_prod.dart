import '../deploy_lib.dart';
import 'build_ffmpeg_windows.dart';
import 'upload_ffmpeg_windows_release.dart';

int? _argInt(List<String> args, String flag) {
  final i = args.indexOf(flag);
  if (i < 0 || i + 1 >= args.length) return null;
  return int.tryParse(args[i + 1]);
}

String? _argStr(List<String> args, String flag) {
  final i = args.indexOf(flag);
  if (i < 0 || i + 1 >= args.length) return null;
  return args[i + 1].trim();
}

Future<void> main(List<String> args) async {
  try {
    deployStart();
    deployLoadEnvLocal();
    final skipNats = args.contains('--skip-nats');
    final ffmpegDir = _argStr(args, '--ffmpeg-dir') ?? deployEnv('FFMPEG_WINDOWS_DIR', '');
    if (ffmpegDir.isEmpty) {
      phaseFail('ffmpeg-windows publish', 'Pass --ffmpeg-dir <path> or set FFMPEG_WINDOWS_DIR (folder with ffmpeg.exe at root)');
    }
    final minAgentBuild = _argInt(args, '--min-agent-build') ?? int.tryParse(deployEnv('FFMPEG_MIN_AGENT_BUILD', '0')) ?? 0;
    final versionOverride = _argInt(args, '--version');
    final version = versionOverride ?? await ffmpegWindowsNextVersion();
    final build = await runStep('Zip ffmpeg-windows v$version', () => buildFfmpegWindowsZip(ffmpegDir: ffmpegDir, version: version));
    await uploadAndPublishFfmpegRelease(build, minAgentBuild: minAgentBuild, skipNats: skipNats);
    deployDone(
      version: 'ffmpeg-windows ${build.versionName}+${build.version}',
      detail: 'zip ${formatBytes(build.size)}',
      target: 'ffmpeg-windows',
    );
  } catch (e) {
    phaseFail('FFmpeg Windows upload failed', e.toString());
  }
}

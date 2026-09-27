const fs = require("fs");
const p = "D:/c35/clients/app/lib/c/remote/remote_fs_transfer.dart";
let t = fs.readFileSync(p, "utf8");
const uploadAnchor = "    unawaited(_pump());\n  }\n\n  void uploadLocalDirectory(String destDir, String localDir) {";
const uploadInsert = `    unawaited(_pump());
  }

  /// Stage [files] from \`file_picker\` (content URIs to temp) then enqueue uploads.
  Future<void> uploadPickerFiles(String destDir, List<PlatformFile> files) async {
    if (destDir.isEmpty || files.isEmpty) return;
    for (final file in files) {
      final staged = await remoteFsStagePickerFile(file);
      if (staged == null || staged.isEmpty) continue;
      final name = file.name.trim().isNotEmpty ? file.name.trim() : _basename(staged);
      jobs.add(RemoteFsJob.uploadLocal(
          label: name, destPath: _join(destDir, name), localPath: staged));
    }
    if (jobs.isEmpty) return;
    notifyListeners();
    unawaited(_pump());
  }

  void uploadLocalDirectory(String destDir, String localDir) {`;
if (!t.includes(uploadAnchor)) throw new Error("upload");
t = t.replace(uploadAnchor, uploadInsert);
const dlOld = `  /// Pick a local folder (desktop) and download remote file(s) or folder trees via [fsRead].
  Future<void> downloadRemote(List<String> remotePaths) async {
    if (remotePaths.isEmpty) return;
    if (kIsWeb) throw 'Download to disk is not supported on web';
    final fs = _session.fs;
    if (fs == null) throw 'File channel not open';
    final destDir = await FilePicker.platform.getDirectoryPath();
    if (destDir == null || destDir.isEmpty) return;
    for (final remote in remotePaths) {
      final name = _basename(remote);
      final localTarget = p.join(destDir, name);
      jobs.add(RemoteFsJob.downloadRemote(
          label: name, fromPath: remote, localPath: localTarget));
    }
    notifyListeners();
    unawaited(_pump());
  }`;
const dlNew = `  /// Pick save location (\`file_picker\`) and download remote file(s) or folder trees via [fsRead].
  Future<void> downloadRemote(List<String> remotePaths) async {
    if (remotePaths.isEmpty) return;
    if (kIsWeb) throw 'Download to disk is not supported on web';
    final fs = _session.fs;
    if (fs == null) throw 'File channel not open';

    if (!kIsWeb && Platform.isAndroid && remotePaths.length == 1) {
      final remote = remotePaths.single;
      final name = _basename(remote);
      if (!await _isRemoteDir(fs, remote)) {
        final savePath = await FilePicker.platform.saveFile(fileName: name);
        if (savePath == null || savePath.isEmpty) return;
        jobs.add(RemoteFsJob.downloadRemote(
            label: name, fromPath: remote, localPath: savePath));
        notifyListeners();
        unawaited(_pump());
        return;
      }
    }

    final destDir = await FilePicker.platform.getDirectoryPath();
    if (destDir == null || destDir.isEmpty) return;
    for (final remote in remotePaths) {
      final name = _basename(remote);
      final localTarget = p.join(destDir, name);
      jobs.add(RemoteFsJob.downloadRemote(
          label: name, fromPath: remote, localPath: localTarget));
    }
    notifyListeners();
    unawaited(_pump());
  }`;
if (!t.includes(dlOld)) throw new Error("dl");
t = t.replace(dlOld, dlNew);
const runOld = `  Future<void> _runUploadLocal(RemoteFsApi fs, RemoteFsJob job) async {
    final localPath = job.localPath;
    if (localPath == null) throw 'missing local path';
    await _uploadLocalFile(fs, job, localPath, job.destPath);
  }`;
const runNew = `  Future<void> _runUploadLocal(RemoteFsApi fs, RemoteFsJob job) async {
    final localPath = job.localPath;
    if (localPath == null) throw 'missing local path';
    try {
      await _uploadLocalFile(fs, job, localPath, job.destPath);
    } finally {
      if (await remoteFsIsStagedTempPath(localPath)) {
        try {
          await File(localPath).delete();
        } catch (_) {}
      }
    }
  }`;
if (!t.includes(runOld)) throw new Error("run");
t = t.replace(runOld, runNew);
fs.writeFileSync(p, t);
console.log("ok2");

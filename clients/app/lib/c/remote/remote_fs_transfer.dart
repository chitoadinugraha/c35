import 'dart:async';
import 'dart:io';
import 'package:alienai_c35/c/log.dart';
import 'package:alienai_c35/c/remote/remote_fs_api.dart';
import 'package:alienai_c35/c/remote/remote_session.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:ulid/ulid.dart';

const _chunkSize = 262144;

enum RemoteFsJobKind {
  uploadLocal,
  remoteCopy,
  createEmpty,
  downloadRemote,
  uploadLocalTree,
  remoteCopyTree,
}

enum RemoteFsJobStatus { queued, running, done, failed }

class RemoteFsJob {
  RemoteFsJob._({
    required this.id,
    required this.kind,
    required this.label,
    required this.destPath,
    this.localPath,
    this.fromPath,
    this.totalBytes,
  });

  factory RemoteFsJob.uploadLocal(
          {required String label,
          required String destPath,
          required String localPath,
          int? totalBytes}) =>
      RemoteFsJob._(
        id: Ulid().toString(),
        kind: RemoteFsJobKind.uploadLocal,
        label: label,
        destPath: destPath,
        localPath: localPath,
        totalBytes: totalBytes,
      );

  factory RemoteFsJob.remoteCopy(
          {required String label,
          required String fromPath,
          required String destPath,
          int? totalBytes}) =>
      RemoteFsJob._(
        id: Ulid().toString(),
        kind: RemoteFsJobKind.remoteCopy,
        label: label,
        fromPath: fromPath,
        destPath: destPath,
        totalBytes: totalBytes,
      );

  factory RemoteFsJob.createEmpty(
          {required String label, required String destPath}) =>
      RemoteFsJob._(
        id: Ulid().toString(),
        kind: RemoteFsJobKind.createEmpty,
        label: label,
        destPath: destPath,
        totalBytes: 0,
      );

  factory RemoteFsJob.downloadRemote({
    required String label,
    required String fromPath,
    required String localPath,
    int? totalBytes,
  }) =>
      RemoteFsJob._(
        id: Ulid().toString(),
        kind: RemoteFsJobKind.downloadRemote,
        label: label,
        fromPath: fromPath,
        localPath: localPath,
        destPath: localPath,
        totalBytes: totalBytes,
      );

  factory RemoteFsJob.uploadLocalTree({
    required String label,
    required String localDir,
    required String destPath,
    int? totalBytes,
  }) =>
      RemoteFsJob._(
        id: Ulid().toString(),
        kind: RemoteFsJobKind.uploadLocalTree,
        label: label,
        localPath: localDir,
        destPath: destPath,
        totalBytes: totalBytes,
      );

  factory RemoteFsJob.remoteCopyTree({
    required String label,
    required String fromPath,
    required String destPath,
    int? totalBytes,
  }) =>
      RemoteFsJob._(
        id: Ulid().toString(),
        kind: RemoteFsJobKind.remoteCopyTree,
        label: label,
        fromPath: fromPath,
        destPath: destPath,
        totalBytes: totalBytes,
      );

  final String id;
  final RemoteFsJobKind kind;
  final String label;
  String destPath;
  final String? localPath;
  final String? fromPath;
  int? totalBytes;
  var bytesDone = 0;
  var status = RemoteFsJobStatus.queued;
  String? error;

  double get progress {
    final total = totalBytes;
    if (total == null || total <= 0) {
      if (status == RemoteFsJobStatus.done) return 1;
      return 0;
    }
    return (bytesDone / total).clamp(0.0, 1.0);
  }
}

class RemoteFsTransfer extends ChangeNotifier {
  RemoteFsTransfer(this._session);

  final RemoteSession _session;
  final jobs = <RemoteFsJob>[];
  List<String> clipboardPaths = const [];
  var clipboardCut = false;

  static final _byDevice = <int, RemoteFsTransfer>{};

  static RemoteFsTransfer of(RemoteSession session) =>
      _byDevice.putIfAbsent(session.deviceIid, () => RemoteFsTransfer(session));

  int get activeCount => jobs
      .where((j) =>
          j.status == RemoteFsJobStatus.queued ||
          j.status == RemoteFsJobStatus.running)
      .length;

  List<RemoteFsJob> get panelJobs => jobs
      .where((j) =>
          j.status == RemoteFsJobStatus.queued ||
          j.status == RemoteFsJobStatus.running ||
          j.status == RemoteFsJobStatus.failed)
      .toList();

  bool get hasClipboard => clipboardPaths.isNotEmpty;

  void copyRemote(List<String> paths, {bool cut = false}) {
    clipboardPaths = List.unmodifiable(paths);
    clipboardCut = cut;
    notifyListeners();
  }

  void clearClipboard() {
    clipboardPaths = const [];
    clipboardCut = false;
    notifyListeners();
  }

  void uploadLocalFiles(String destDir, List<String> localPaths) {
    if (localPaths.isEmpty) return;
    for (final path in localPaths) {
      final name = _basename(path);
      jobs.add(RemoteFsJob.uploadLocal(
          label: name, destPath: _join(destDir, name), localPath: path));
    }
    notifyListeners();
    unawaited(_pump());
  }

  void uploadLocalDirectory(String destDir, String localDir) {
    if (localDir.isEmpty) return;
    final name = _basename(localDir);
    jobs.add(RemoteFsJob.uploadLocalTree(
        label: name, localDir: localDir, destPath: _join(destDir, name)));
    notifyListeners();
    unawaited(_pump());
  }

  /// Pick a local folder (desktop) and download remote file(s) or folder trees via [fsRead].
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
  }

  void pasteRemote(String destDir) {
    if (clipboardPaths.isEmpty) return;
    unawaited(_pasteRemote(destDir));
  }

  Future<void> _pasteRemote(String destDir) async {
    final fs = _session.fs;
    if (fs == null) return;
    for (final from in clipboardPaths) {
      final name = _basename(from);
      final dest = _join(destDir, name);
      if (await _isRemoteDir(fs, from)) {
        jobs.add(RemoteFsJob.remoteCopyTree(
            label: name, fromPath: from, destPath: dest));
      } else {
        jobs.add(RemoteFsJob.remoteCopy(
            label: name, fromPath: from, destPath: dest));
      }
    }
    notifyListeners();
    unawaited(_pump());
  }

  void createEmptyFile(String destDir, String fileName) {
    jobs.add(RemoteFsJob.createEmpty(
        label: fileName, destPath: _join(destDir, fileName)));
    notifyListeners();
    unawaited(_pump());
  }

  void dismissJob(String id) {
    jobs.removeWhere((j) => j.id == id);
    notifyListeners();
  }

  void clearFinished() {
    jobs.removeWhere((j) => j.status == RemoteFsJobStatus.done);
    notifyListeners();
  }

  var _pumping = false;

  Future<void> _pump() async {
    if (_pumping) return;
    _pumping = true;
    try {
      while (true) {
        RemoteFsJob? job;
        for (final j in jobs) {
          if (j.status == RemoteFsJobStatus.queued) {
            job = j;
            break;
          }
        }
        if (job == null) break;
        job.status = RemoteFsJobStatus.running;
        notifyListeners();
        try {
          await _run(job);
          job.status = RemoteFsJobStatus.done;
          job.bytesDone = job.totalBytes ?? job.bytesDone;
        } catch (e, st) {
          lError('remote fs job ${job.label}: $e\n$st');
          job.status = RemoteFsJobStatus.failed;
          job.error = '$e';
        }
        notifyListeners();
        if (job.status == RemoteFsJobStatus.done) {
          final doneJob = job;
          unawaited(Future.delayed(const Duration(seconds: 4), () {
            jobs.remove(doneJob);
            notifyListeners();
          }));
        }
      }
    } finally {
      _pumping = false;
    }
  }

  Future<void> _run(RemoteFsJob job) async {
    final fs = _session.fs;
    if (fs == null) throw 'File channel not open';
    switch (job.kind) {
      case RemoteFsJobKind.uploadLocal:
        await _runUploadLocal(fs, job);
      case RemoteFsJobKind.remoteCopy:
        await _runRemoteCopy(fs, job);
      case RemoteFsJobKind.createEmpty:
        await _runCreateEmpty(fs, job);
      case RemoteFsJobKind.downloadRemote:
        await _runDownloadRemote(fs, job);
      case RemoteFsJobKind.uploadLocalTree:
        await _runUploadLocalTree(fs, job);
      case RemoteFsJobKind.remoteCopyTree:
        await _runRemoteCopyTree(fs, job);
    }
  }

  Future<void> _runCreateEmpty(RemoteFsApi fs, RemoteFsJob job) async {
    job.destPath = await _uniquePath(fs, job.destPath);
    final res =
        await fs.fsWrite(job.destPath, Uint8List(0), offset: 0, finalize: true);
    if (res.error.isNotEmpty) throw res.error;
    job.bytesDone = 0;
    job.totalBytes = 0;
  }

  Future<void> _runUploadLocal(RemoteFsApi fs, RemoteFsJob job) async {
    final localPath = job.localPath;
    if (localPath == null) throw 'missing local path';
    await _uploadLocalFile(fs, job, localPath, job.destPath);
  }

  Future<void> _runUploadLocalTree(RemoteFsApi fs, RemoteFsJob job) async {
    final localRoot = job.localPath;
    if (localRoot == null) throw 'missing local directory';
    if (kIsWeb) throw 'Upload from disk is not supported on web';
    final dir = Directory(localRoot);
    if (!await dir.exists()) throw 'Directory not found';
    final remoteRoot = await _uniquePath(fs, job.destPath);
    job.destPath = remoteRoot;

    final files = <File>[];
    await for (final entity in dir.list(recursive: true, followLinks: false)) {
      if (entity is File) files.add(entity);
    }
    var total = 0;
    for (final f in files) {
      total += await f.length();
    }
    job.totalBytes = total;
    notifyListeners();

    for (final file in files) {
      final rel = p.relative(file.path, from: localRoot);
      final remotePath = _join(remoteRoot, rel.replaceAll('/', '\\'));
      await _uploadLocalFile(fs, job, file.path, remotePath, uniqueDest: false);
    }
  }

  Future<void> _uploadLocalFile(
    RemoteFsApi fs,
    RemoteFsJob job,
    String localPath,
    String destPath, {
    bool uniqueDest = true,
  }) async {
    if (kIsWeb) throw 'Upload from disk is not supported on web';
    final file = File(localPath);
    if (!await file.exists()) throw 'File not found';
    final total = await file.length();
    job.totalBytes ??= total;
    final remotePath = uniqueDest ? await _uniquePath(fs, destPath) : destPath;
    if (uniqueDest) job.destPath = remotePath;
    notifyListeners();

    final raf = await file.open();
    try {
      var offset = 0;
      while (offset < total) {
        final chunk = await raf.read(_chunkSize);
        if (chunk.isEmpty) break;
        final data = Uint8List.fromList(chunk);
        final finalize = offset + data.length >= total;
        final res = await fs.fsWrite(remotePath, data,
            offset: offset, finalize: finalize);
        if (res.error.isNotEmpty) throw res.error;
        offset += data.length;
        job.bytesDone += data.length;
        notifyListeners();
      }
    } finally {
      await raf.close();
    }
  }

  Future<void> _runRemoteCopy(RemoteFsApi fs, RemoteFsJob job) async {
    final from = job.fromPath;
    if (from == null) throw 'missing source path';
    job.destPath = await _uniquePath(fs, job.destPath);
    await _copyRemoteFile(fs, job, from, job.destPath);
  }

  Future<void> _runRemoteCopyTree(RemoteFsApi fs, RemoteFsJob job) async {
    final from = job.fromPath;
    if (from == null) throw 'missing source path';
    job.destPath = await _uniquePath(fs, job.destPath);
    await _copyRemoteTree(fs, job, from, job.destPath);
  }

  Future<void> _copyRemoteTree(
      RemoteFsApi fs, RemoteFsJob job, String fromRoot, String destRoot) async {
    await _mkdirRemoteIfSupported(fs, destRoot);
    final files = await _listRemoteFiles(fs, fromRoot);
    if (files.isEmpty && !await _isRemoteDir(fs, fromRoot)) {
      await _copyRemoteFile(fs, job, fromRoot, destRoot);
      return;
    }
    job.totalBytes = files.fold<int>(0, (s, e) => s + e.size.toInt());
    notifyListeners();
    for (final e in files) {
      final rel = _relativeRemote(fromRoot, e.path);
      final dest = _join(destRoot, rel);
      await _copyRemoteFile(fs, job, e.path, dest);
    }
  }

  Future<void> _copyRemoteFile(
      RemoteFsApi fs, RemoteFsJob job, String from, String dest) async {
    var offset = 0;
    while (true) {
      final res = await fs.fsRead(from, offset: offset, len: _chunkSize);
      if (res.error.isNotEmpty) throw res.error;
      if (res.data.isEmpty && res.eof) break;
      final finalize = res.eof;
      final write = await fs.fsWrite(dest, Uint8List.fromList(res.data),
          offset: offset, finalize: finalize);
      if (write.error.isNotEmpty) throw write.error;
      offset += res.data.length;
      job.bytesDone += res.data.length;
      if (job.totalBytes == null && res.eof) job.totalBytes = offset;
      notifyListeners();
      if (res.eof) break;
    }
    job.totalBytes ??= offset;
  }

  Future<void> _runDownloadRemote(RemoteFsApi fs, RemoteFsJob job) async {
    final from = job.fromPath;
    final localPath = job.localPath;
    if (from == null || localPath == null) throw 'missing download paths';
    if (kIsWeb) throw 'Download to disk is not supported on web';

    if (await _isRemoteDir(fs, from)) {
      final files = await _listRemoteFiles(fs, from);
      job.totalBytes = files.fold<int>(0, (s, e) => s + e.size.toInt());
      notifyListeners();
      for (final e in files) {
        final rel = _relativeRemote(from, e.path);
        final localFile =
            File(p.join(localPath, rel.replaceAll('\\', p.separator)));
        await localFile.parent.create(recursive: true);
        await _downloadRemoteFile(fs, job, e.path, localFile);
      }
      if (files.isEmpty) {
        await Directory(localPath).create(recursive: true);
      }
      return;
    }

    final file = File(localPath);
    await file.parent.create(recursive: true);
    await _downloadRemoteFile(fs, job, from, file);
  }

  Future<void> _downloadRemoteFile(RemoteFsApi fs, RemoteFsJob job,
      String remotePath, File localFile) async {
    final sink = localFile.openWrite();
    try {
      await for (final res in fs.streamFile(remotePath)) {
        if (res.error.isNotEmpty) throw res.error;
        if (res.data.isNotEmpty) {
          sink.add(res.data);
          job.bytesDone += res.data.length;
          notifyListeners();
        }
      }
    } finally {
      await sink.close();
    }
    if (job.totalBytes == null) {
      job.totalBytes = await localFile.length();
      job.bytesDone = job.totalBytes!;
    }
  }

  Future<List<_RemoteFileRef>> _listRemoteFiles(
      RemoteFsApi fs, String root) async {
    final out = <_RemoteFileRef>[];
    if (!await _isRemoteDir(fs, root)) {
      return out;
    }
    await _walkRemoteDir(fs, root, root, out);
    return out;
  }

  Future<void> _walkRemoteDir(RemoteFsApi fs, String dirPath, String root,
      List<_RemoteFileRef> out) async {
    final res = await fs.fsList(dirPath);
    if (res.error.isNotEmpty) throw res.error;
    for (final e in res.entries) {
      if (e.isDir) {
        await _walkRemoteDir(fs, e.path, root, out);
      } else {
        out.add(_RemoteFileRef(e.path, e.size.toInt()));
      }
    }
  }

  Future<void> _mkdirRemoteIfSupported(RemoteFsApi fs, String path) async {
    try {
      final res = await fs.fsMkdir(path);
      if (res.error.isEmpty) return;
    } catch (_) {}
  }

  Future<String> _uniquePath(RemoteFsApi fs, String destPath) async {
    final parent = _parentDir(destPath);
    final base = _basename(destPath);
    final dot = base.lastIndexOf('.');
    final stem = dot > 0 ? base.substring(0, dot) : base;
    final ext = dot > 0 ? base.substring(dot) : '';
    var candidate = destPath;
    var n = 1;
    while (await _exists(fs, candidate)) {
      candidate = _join(parent, '$stem ($n)$ext');
      n++;
    }
    return candidate;
  }

  Future<bool> _exists(RemoteFsApi fs, String path) async {
    final parent = _parentDir(path);
    final name = _basename(path);
    final res = await fs.fsList(parent);
    if (res.error.isNotEmpty) return false;
    return res.entries.any((e) => e.name.toLowerCase() == name.toLowerCase());
  }

  Future<bool> _isRemoteDir(RemoteFsApi fs, String path) async {
    final parent = _parentDir(path);
    final name = _basename(path);
    final res = await fs.fsList(parent);
    if (res.error.isNotEmpty) return false;
    for (final e in res.entries) {
      if (e.name.toLowerCase() == name.toLowerCase()) return e.isDir;
    }
    return false;
  }
}

class _RemoteFileRef {
  const _RemoteFileRef(this.path, this.size);
  final String path;
  final int size;
}

String _relativeRemote(String root, String full) {
  final r = root.replaceAll('/', '\\');
  final f = full.replaceAll('/', '\\');
  if (f.length > r.length && f.toLowerCase().startsWith(r.toLowerCase())) {
    var rest = f.substring(r.length);
    if (rest.startsWith(r'\\')) rest = rest.substring(1);
    return rest;
  }
  return _basename(full);
}

String _join(String dir, String name) {
  if (dir.isEmpty) return name;
  final d = dir.replaceAll('/', '\\');
  if (d.endsWith(r'\') || d.endsWith(':')) return '$d$name';
  return '$d\\$name';
}

String _parentDir(String path) {
  final pth = path.replaceAll('/', '\\');
  final i = pth.lastIndexOf(r'\');
  if (i <= 0) return pth;
  if (i == 2 && pth[1] == ':') return pth.substring(0, 3);
  return pth.substring(0, i);
}

String _basename(String path) {
  final pth = path.replaceAll('/', '\\');
  final i = pth.lastIndexOf(r'\');
  return i < 0 ? pth : pth.substring(i + 1);
}

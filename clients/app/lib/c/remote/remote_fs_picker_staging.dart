import 'dart:io';

import 'package:alienai_c35/c/media/ask_media.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:ulid/ulid.dart';

/// Returns a readable local path for [file] (copies content URIs / streams to temp when needed).
Future<String?> remoteFsStagePickerFile(PlatformFile file) async {
  if (kIsWeb) return null;
  final name = file.name.trim().isNotEmpty ? file.name.trim() : 'upload';
  final path = file.path;
  if (path != null && path.isNotEmpty && !path.startsWith('content:')) {
    final f = File(path);
    if (await f.exists()) return path;
  }
  final tmpRoot = (await getTemporaryDirectory()).path;
  final dest = p.join(tmpRoot, 'remote_fs_${Ulid()}_$name');
  final out = File(dest);
  final stream = file.readStream;
  if (stream != null) {
    final sink = out.openWrite();
    try {
      await stream.pipe(sink);
    } finally {
      await sink.close();
    }
    return dest;
  }
  final bytes = file.bytes ?? await platformFileBytes(file);
  if (bytes == null || bytes.isEmpty) return null;
  await out.writeAsBytes(bytes, flush: true);
  return dest;
}

Future<bool> remoteFsIsStagedTempPath(String localPath) async {
  if (kIsWeb) return false;
  final tmpRoot = (await getTemporaryDirectory()).path;
  return p.isWithin(tmpRoot, p.normalize(localPath));
}

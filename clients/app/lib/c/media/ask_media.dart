import 'dart:io';

import 'package:alienai_c35/c/media/media_types.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

const defaultMaxMediaFiles = 10;
const defaultMaxFileBytes = 100 * 1024 * 1024;

Future<List<StagedMedia>?> askMedia({
  List<MediaType> types = const [MediaType.image, MediaType.document],
  bool allowMultiple = true,
  int maxCount = defaultMaxMediaFiles,
  int maxBytesPerFile = defaultMaxFileBytes,
}) async {
  try {
    FileType pickType = FileType.any;
    List<String>? allowedExtensions;
    final onlyImages = types.length == 1 && types.first == MediaType.image;
    final onlyDocs = types.length == 1 && types.first == MediaType.document;
    if (onlyImages) {
      pickType = FileType.custom;
      allowedExtensions = ['jpg', 'jpeg', 'png', 'webp', 'gif', 'heic', 'avif'];
    } else if (onlyDocs) {
      pickType = FileType.custom;
      allowedExtensions = ['pdf', 'txt', 'md', 'doc', 'docx', 'xls', 'xlsx', 'csv', 'json', 'zip'];
    } else if (!types.contains(MediaType.any)) {
      pickType = FileType.custom;
      allowedExtensions = ['jpg', 'jpeg', 'png', 'webp', 'gif', 'heic', 'avif', 'pdf', 'txt', 'md', 'doc', 'docx', 'xls', 'xlsx', 'csv', 'zip'];
    }
    final files = await FilePicker.platform.pickFiles(type: pickType, allowedExtensions: allowedExtensions, withData: true);
    if (files == null || files.files.isEmpty) return null;
    final staged = <StagedMedia>[];
    for (final pf in files.files) {
      if (staged.length >= maxCount) break;
      var raw = pf.bytes;
      if ((raw == null || raw.isEmpty) && pf.path != null && pf.path!.isNotEmpty && !kIsWeb) {
        raw = await File(pf.path!).readAsBytes();
      }
      if (raw == null || raw.isEmpty || raw.length > maxBytesPerFile) continue;
      final mime = mimeForFilename(pf.name);
      staged.add(StagedMedia(name: pf.name, bytes: raw, mime: mime, type: mediaTypeForMime(mime), size: raw.length));
    }
    return staged.isEmpty ? null : staged;
  } catch (e) {
    debugPrint('askMedia error: $e');
    return null;
  }
}

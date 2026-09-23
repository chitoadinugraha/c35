import 'dart:io';

import 'package:alienai_c35/c/media/media_types.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

const defaultMaxMediaFiles = 10;
const defaultMaxFileBytes = 100 * 1024 * 1024;

const _imagePickExtensions = ['jpg', 'jpeg', 'png', 'gif', 'webp', 'heic', 'bmp', 'avif'];

bool get _mobileCameraGallery =>
    !kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS);

/// Read picked file bytes without Binder `withData` on mobile (TransactionTooLarge / OOM).
Future<Uint8List?> platformFileBytes(PlatformFile file) async {
  if (kIsWeb) {
    final bytes = file.bytes;
    if (bytes == null || bytes.isEmpty) return null;
    return bytes;
  }
  final inline = file.bytes;
  if (inline != null && inline.isNotEmpty) return inline;
  final path = file.path;
  if (path == null || path.isEmpty) return null;
  return File(path).readAsBytes();
}

Future<ImageSource?> _askImageSource(BuildContext context) => showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Camera'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Gallery'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

Future<List<StagedMedia>> _stagedFromXFiles(List<XFile> files, {required int maxCount, required int maxBytesPerFile}) async {
  final staged = <StagedMedia>[];
  for (final x in files) {
    if (staged.length >= maxCount) break;
    final bytes = await x.readAsBytes();
    if (bytes.isEmpty || bytes.length > maxBytesPerFile) continue;
    final name = x.name.trim().isNotEmpty ? x.name : 'image.jpg';
    final mime = mimeForFilename(name);
    staged.add(StagedMedia(name: name, bytes: bytes, mime: mime, type: mediaTypeForMime(mime), size: bytes.length));
  }
  return staged;
}

Future<List<StagedMedia>?> _pickImagesMobile({
  BuildContext? context,
  required bool allowMultiple,
  required int maxCount,
  required int maxBytesPerFile,
}) async {
  final picker = ImagePicker();
  if (_mobileCameraGallery && context != null && context.mounted) {
    final source = await _askImageSource(context);
    if (source == null) return null;
    if (allowMultiple && source == ImageSource.gallery) {
      final files = await picker.pickMultiImage(imageQuality: 88);
      if (files.isEmpty) return null;
      final staged = await _stagedFromXFiles(files, maxCount: maxCount, maxBytesPerFile: maxBytesPerFile);
      return staged.isEmpty ? null : staged;
    }
    final file = await picker.pickImage(source: source, imageQuality: 88);
    if (file == null) return null;
    final staged = await _stagedFromXFiles([file], maxCount: maxCount, maxBytesPerFile: maxBytesPerFile);
    return staged.isEmpty ? null : staged;
  }
  if (_mobileCameraGallery) {
    if (allowMultiple) {
      final files = await picker.pickMultiImage(imageQuality: 88);
      if (files.isEmpty) return null;
      final staged = await _stagedFromXFiles(files, maxCount: maxCount, maxBytesPerFile: maxBytesPerFile);
      return staged.isEmpty ? null : staged;
    }
    final file = await picker.pickImage(source: ImageSource.gallery, imageQuality: 88);
    if (file == null) return null;
    final staged = await _stagedFromXFiles([file], maxCount: maxCount, maxBytesPerFile: maxBytesPerFile);
    return staged.isEmpty ? null : staged;
  }
  return _pickFiles(
    pickType: FileType.custom,
    allowedExtensions: _imagePickExtensions,
    allowMultiple: allowMultiple,
    maxCount: maxCount,
    maxBytesPerFile: maxBytesPerFile,
  );
}

Future<List<StagedMedia>?> _pickFiles({
  required FileType pickType,
  List<String>? allowedExtensions,
  required bool allowMultiple,
  required int maxCount,
  required int maxBytesPerFile,
}) async {
  final result = await FilePicker.platform.pickFiles(
    type: pickType,
    allowedExtensions: allowedExtensions,
    allowMultiple: allowMultiple,
    lockParentWindow: !kIsWeb,
    withData: kIsWeb,
  );
  if (result == null || result.files.isEmpty) return null;
  final staged = <StagedMedia>[];
  for (final pf in result.files) {
    if (staged.length >= maxCount) break;
    final raw = await platformFileBytes(pf);
    if (raw == null || raw.isEmpty || raw.length > maxBytesPerFile) continue;
    final mime = mimeForFilename(pf.name);
    staged.add(StagedMedia(name: pf.name, bytes: raw, mime: mime, type: mediaTypeForMime(mime), size: raw.length));
  }
  return staged.isEmpty ? null : staged;
}

Future<List<StagedMedia>?> askMedia({
  BuildContext? context,
  List<MediaType> types = const [MediaType.image, MediaType.document],
  bool allowMultiple = true,
  int maxCount = defaultMaxMediaFiles,
  int maxBytesPerFile = defaultMaxFileBytes,
}) async {
  try {
    final onlyImages = types.length == 1 && types.first == MediaType.image;
    final onlyDocs = types.length == 1 && types.first == MediaType.document;
    if (onlyImages) {
      return await _pickImagesMobile(context: context, allowMultiple: allowMultiple, maxCount: maxCount, maxBytesPerFile: maxBytesPerFile);
    }
    FileType pickType = FileType.any;
    List<String>? allowedExtensions;
    if (onlyDocs) {
      pickType = FileType.custom;
      allowedExtensions = ['pdf', 'txt', 'md', 'doc', 'docx', 'xls', 'xlsx', 'csv', 'json', 'zip'];
    } else if (!types.contains(MediaType.any)) {
      pickType = FileType.custom;
      allowedExtensions = [..._imagePickExtensions, 'pdf', 'txt', 'md', 'doc', 'docx', 'xls', 'xlsx', 'csv', 'zip'];
    }
    return await _pickFiles(
      pickType: pickType,
      allowedExtensions: allowedExtensions,
      allowMultiple: allowMultiple,
      maxCount: maxCount,
      maxBytesPerFile: maxBytesPerFile,
    );
  } catch (e) {
    debugPrint('askMedia error: $e');
    return null;
  }
}

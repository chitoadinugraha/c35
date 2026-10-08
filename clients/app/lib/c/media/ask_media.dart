import 'dart:io';

import 'package:alienai_c35/c/chat/chat_conn.dart';
import 'package:alienai_c35/c/media/image_generate_prompt.dart';
import 'package:alienai_c35/c/media/media_types.dart';
import 'package:alienai_c35/widgets/ai/ui_alien_icon.dart';
import 'package:alienai_c35/widgets/media/ui_ask_image_generate.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

const defaultMaxMediaFiles = 10;
const defaultMaxFileBytes = 100 * 1024 * 1024;

const _imagePickExtensions = ['jpg', 'jpeg', 'png', 'gif', 'webp', 'heic', 'bmp', 'avif'];

bool get _mobileCameraGallery =>
    !kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS);

enum _AskImageChoice { camera, gallery, generate }

enum _AskDesktopImageChoice { files, generate }

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

Color _sheetIconColor(BuildContext context) =>
    IconTheme.of(context).color ?? Theme.of(context).colorScheme.onSurface;

Future<_AskImageChoice?> _askImageSource(BuildContext context, {bool includeGenerate = false}) =>
    showModalBottomSheet<_AskImageChoice>(
      context: context,
      showDragHandle: true,
      useSafeArea: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Camera'),
              onTap: () => Navigator.pop(ctx, _AskImageChoice.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Gallery'),
              onTap: () => Navigator.pop(ctx, _AskImageChoice.gallery),
            ),
            if (includeGenerate)
              ListTile(
                leading: UiAlienIcon(size: 24, color: _sheetIconColor(ctx)),
                title: const Text('Generate'),
                onTap: () => Navigator.pop(ctx, _AskImageChoice.generate),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

Future<_AskDesktopImageChoice?> _askDesktopImageSource(BuildContext context) =>
    showModalBottomSheet<_AskDesktopImageChoice>(
      context: context,
      showDragHandle: true,
      useSafeArea: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.folder_outlined),
              title: const Text('Files'),
              onTap: () => Navigator.pop(ctx, _AskDesktopImageChoice.files),
            ),
            ListTile(
              leading: UiAlienIcon(size: 24, color: _sheetIconColor(ctx)),
              title: const Text('Generate'),
              onTap: () => Navigator.pop(ctx, _AskDesktopImageChoice.generate),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

List<StagedMedia> _stagedFromGenerated(GeneratedImage result) => [
      StagedMedia(
        name: 'generated.png',
        bytes: Uint8List(0),
        mime: 'image/png',
        type: MediaType.image,
        size: 0,
        hash: result.hash,
      ),
    ];

Future<List<StagedMedia>?> _generateStaged(
  BuildContext context, {
  required ChatConn conn,
  required ImageGenerateSlot slot,
  required String name,
  required String desc,
}) async {
  final result = await askImageGenerate(context, conn: conn, slot: slot, name: name, desc: desc);
  if (result == null) return null;
  return _stagedFromGenerated(result);
}

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
  bool canGenerate = false,
  ChatConn? conn,
  ImageGenerateSlot generateSlot = ImageGenerateSlot.productExtra,
  String generateName = '',
  String generateDesc = '',
}) async {
  final picker = ImagePicker();
  if (_mobileCameraGallery && context != null && context.mounted) {
    final choice = await _askImageSource(context, includeGenerate: canGenerate);
    if (choice == null) return null;
    if (choice == _AskImageChoice.generate) {
      if (!context.mounted || conn == null) return null;
      return _generateStaged(context, conn: conn, slot: generateSlot, name: generateName, desc: generateDesc);
    }
    final source = choice == _AskImageChoice.camera ? ImageSource.camera : ImageSource.gallery;
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
  if (canGenerate && context != null && context.mounted && conn != null) {
    final choice = await _askDesktopImageSource(context);
    if (choice == null) return null;
    if (choice == _AskDesktopImageChoice.generate) {
      if (!context.mounted) return null;
      return _generateStaged(context, conn: conn, slot: generateSlot, name: generateName, desc: generateDesc);
    }
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
  bool allowGenerate = false,
  ChatConn? conn,
  ImageGenerateSlot generateSlot = ImageGenerateSlot.productExtra,
  String generateName = '',
  String generateDesc = '',
}) async {
  try {
    final onlyImages = types.length == 1 && types.first == MediaType.image;
    final onlyDocs = types.length == 1 && types.first == MediaType.document;
    final canGenerate = allowGenerate && conn != null && context != null && context.mounted && onlyImages;
    if (onlyImages) {
      return await _pickImagesMobile(
        context: context,
        allowMultiple: allowMultiple,
        maxCount: maxCount,
        maxBytesPerFile: maxBytesPerFile,
        canGenerate: canGenerate,
        conn: conn,
        generateSlot: generateSlot,
        generateName: generateName,
        generateDesc: generateDesc,
      );
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

import 'dart:typed_data';

enum MediaType { image, video, audio, document, any }

class StagedMedia {
  StagedMedia({
    String? id,
    required this.name,
    required this.bytes,
    required this.mime,
    required this.type,
    required this.size,
    this.hash,
    this.previewUrl,
    this.uploadProgress,
  }) : id = id ?? '${DateTime.now().microsecondsSinceEpoch}_${name.hashCode}';

  final String id;
  final String name;
  final Uint8List bytes;
  final String mime;
  final MediaType type;
  final int size;
  final String? hash;
  final String? previewUrl;
  final double? uploadProgress;

  bool get isUploading => uploadProgress != null && uploadProgress! < 1.0;
  bool get isImage => type == MediaType.image || mime.startsWith('image/');
  bool get isDocument => type == MediaType.document || mime == 'application/pdf' || mime.startsWith('text/') || mime.contains('document') || mime.contains('sheet') || mime.contains('zip');

  String get formattedSize {
    if (size <= 0) return '';
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  StagedMedia copyWith({String? hash, double? uploadProgress, Uint8List? bytes, int? size, String? mime, String? name}) => StagedMedia(
        id: id,
        name: name ?? this.name,
        bytes: bytes ?? this.bytes,
        mime: mime ?? this.mime,
        type: type,
        size: size ?? this.size,
        hash: hash ?? this.hash,
        previewUrl: previewUrl,
        uploadProgress: uploadProgress ?? this.uploadProgress,
      );
}

String mimeForFilename(String filename) {
  final ext = filename.split('.').last.toLowerCase();
  return switch (ext) {
    'jpg' || 'jpeg' => 'image/jpeg',
    'png' => 'image/png',
    'webp' => 'image/webp',
    'gif' => 'image/gif',
    'heic' => 'image/heic',
    'avif' => 'image/avif',
    'svg' => 'image/svg+xml',
    'pdf' => 'application/pdf',
    'txt' => 'text/plain',
    'md' => 'text/markdown',
    'json' => 'application/json',
    'csv' => 'text/csv',
    'doc' => 'application/msword',
    'docx' => 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    'xls' => 'application/vnd.ms-excel',
    'xlsx' => 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    'zip' => 'application/zip',
    _ => 'application/octet-stream',
  };
}

MediaType mediaTypeForMime(String mime) {
  if (mime.startsWith('image/')) return MediaType.image;
  if (mime.startsWith('video/')) return MediaType.video;
  if (mime.startsWith('audio/')) return MediaType.audio;
  if (mime == 'application/pdf' || mime.startsWith('text/') || mime.contains('document') || mime.contains('sheet') || mime.contains('zip')) return MediaType.document;
  return MediaType.any;
}

/// Kind of a shared inbound file.
enum ShareInboundKind { image, video, other }

/// One file path from an OS share sheet.
class ShareInboundFile {
  const ShareInboundFile({
    required this.path,
    required this.kind,
    this.mime = '',
  });

  final String path;
  final ShareInboundKind kind;
  final String mime;

  bool get isImage => kind == ShareInboundKind.image;
  bool get isVideo => kind == ShareInboundKind.video;
}

/// Normalized inbound share payload (text + local file paths).
class ShareInboundPayload {
  const ShareInboundPayload({this.text = '', this.files = const []});

  final String text;
  final List<ShareInboundFile> files;

  bool get isEmpty => text.trim().isEmpty && files.isEmpty;
  bool get hasVideo => files.any((f) => f.isVideo);
  bool get hasImage => files.any((f) => f.isImage);
}

ShareInboundKind shareInboundKindFromPath(String path, {String mime = ''}) {
  final m = mime.toLowerCase();
  if (m.startsWith('image/')) return ShareInboundKind.image;
  if (m.startsWith('video/')) return ShareInboundKind.video;
  final lower = path.toLowerCase();
  const imageExt = ['.jpg', '.jpeg', '.png', '.gif', '.webp', '.bmp', '.heic', '.avif'];
  const videoExt = ['.mp4', '.mov', '.webm', '.m4v', '.avi', '.mkv', '.mpeg', '.wmv', '.flv'];
  for (final e in imageExt) {
    if (lower.endsWith(e)) return ShareInboundKind.image;
  }
  for (final e in videoExt) {
    if (lower.endsWith(e)) return ShareInboundKind.video;
  }
  return ShareInboundKind.other;
}

import 'dart:io';

import 'package:alienai_c35/c/media/media_types.dart';
import 'package:alienai_c35/c/share/share_inbound_limits.dart';
import 'package:alienai_c35/c/share/share_inbound_payload.dart';

class ShareInboundStageResult {
  const ShareInboundStageResult({
    required this.staged,
    this.skippedOversize = 0,
    this.skippedUnsupported = 0,
    this.skippedCapacity = 0,
  });

  final List<StagedMedia> staged;
  final int skippedOversize;
  final int skippedUnsupported;
  final int skippedCapacity;

  int get skippedTotal => skippedOversize + skippedUnsupported + skippedCapacity;
}

int _maxBytesForKind(ShareInboundKind kind) =>
    kind == ShareInboundKind.video ? shareInboundMaxVideoBytes : shareInboundMaxFileBytes;

/// Read share paths into [StagedMedia] for composer staging (no upload).
Future<ShareInboundStageResult> stagedMediaFromShareInbound(
  ShareInboundPayload payload, {
  int alreadyStaged = 0,
}) async {
  final out = <StagedMedia>[];
  var skippedOversize = 0;
  var skippedUnsupported = 0;
  var skippedCapacity = 0;

  for (final f in payload.files) {
    if (out.length + alreadyStaged >= shareInboundMaxFiles) {
      skippedCapacity++;
      continue;
    }
    if (f.kind == ShareInboundKind.other) {
      skippedUnsupported++;
      continue;
    }

    final path = f.path.trim();
    if (path.isEmpty) continue;
    final file = File(path);
    if (!await file.exists()) continue;

    final length = await file.length();
    final maxBytes = _maxBytesForKind(f.kind);
    if (length <= 0 || length > maxBytes) {
      skippedOversize++;
      continue;
    }

    final bytes = await file.readAsBytes();
    if (bytes.isEmpty || bytes.length > maxBytes) {
      skippedOversize++;
      continue;
    }

    final name = path.split(RegExp(r'[\\/]')).last;
    var mime = f.mime.trim().isNotEmpty ? f.mime.trim() : mimeForFilename(name);
    if (f.kind == ShareInboundKind.image && !mime.startsWith('image/')) {
      skippedUnsupported++;
      continue;
    }
    if (f.kind == ShareInboundKind.video && !mime.startsWith('video/')) {
      mime = 'video/mp4';
    }
    final type = f.kind == ShareInboundKind.video ? MediaType.video : mediaTypeForMime(mime);

    out.add(
      StagedMedia(
        name: name,
        bytes: bytes,
        mime: mime,
        type: type,
        size: bytes.length,
        uploadProgress: 0.05,
      ),
    );
  }

  return ShareInboundStageResult(
    staged: out,
    skippedOversize: skippedOversize,
    skippedUnsupported: skippedUnsupported,
    skippedCapacity: skippedCapacity,
  );
}
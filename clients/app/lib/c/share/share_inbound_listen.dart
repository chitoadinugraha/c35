import 'dart:async';

import 'package:alienai_c35/c/log.dart';
import 'package:alienai_c35/c/share/share_inbound_payload.dart';
import 'package:flutter/foundation.dart';
import 'package:share_handler/share_handler.dart';

typedef ShareInboundHandler = void Function(ShareInboundPayload payload);

/// Listens for OS inbound shares on Android / iOS ([share_handler]).
class ShareInbound {
  ShareInbound._();
  static final instance = ShareInbound._();

  ShareInboundHandler? onPayload;
  ShareInboundPayload? _pending;
  var _started = false;
  StreamSubscription<SharedMedia>? _sub;

  ShareInboundPayload? get pending => _pending;

  void clearPending() => _pending = null;

  Future<void> start() async {
    if (_started || kIsWeb) return;
    if (defaultTargetPlatform != TargetPlatform.android && defaultTargetPlatform != TargetPlatform.iOS) {
      return;
    }
    _started = true;
    try {
      final handler = ShareHandler.instance;
      final initial = await handler.getInitialSharedMedia();
      if (initial != null) {
        _emit(_fromSharedMedia(initial));
        await handler.resetInitialSharedMedia();
      }
      _sub = handler.sharedMediaStream.listen(
        (media) {
          _emit(_fromSharedMedia(media));
          unawaited(handler.resetInitialSharedMedia());
        },
        onError: (Object e) => lError('share inbound: $e'),
      );
    } catch (e) {
      lError('share inbound start: $e');
    }
  }

  void stop() {
    _sub?.cancel();
    _sub = null;
    _started = false;
  }

  void _emit(ShareInboundPayload payload) {
    if (payload.isEmpty) return;
    _pending = payload;
    onPayload?.call(payload);
  }

  ShareInboundPayload _fromSharedMedia(SharedMedia media) {
    final text = (media.content ?? '').trim();
    final files = <ShareInboundFile>[];
    for (final a in media.attachments ?? const <SharedAttachment?>[]) {
      if (a == null) continue;
      final path = a.path.trim();
      if (path.isEmpty) continue;
      final kind = switch (a.type) {
        SharedAttachmentType.image => ShareInboundKind.image,
        SharedAttachmentType.video => ShareInboundKind.video,
        _ => shareInboundKindFromPath(path),
      };
      files.add(ShareInboundFile(path: path, kind: kind));
    }
    return ShareInboundPayload(text: text, files: files);
  }
}

Future<void> shareInboundStart() => ShareInbound.instance.start();

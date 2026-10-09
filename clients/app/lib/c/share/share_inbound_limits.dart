import 'package:alienai_c35/c/media/ask_media.dart';

/// Max attachments in composer (shared with gallery pick).
const shareInboundMaxFiles = defaultMaxMediaFiles;

/// Non-video files (images, documents).
const shareInboundMaxFileBytes = defaultMaxFileBytes;

/// Stricter cap for shared video (gallery pick uses [defaultMaxFileBytes]).
const shareInboundMaxVideoBytes = 50 * 1024 * 1024;

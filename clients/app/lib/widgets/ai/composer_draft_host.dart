import 'package:alienai_c35/c/media/media_types.dart';
import 'package:flutter/foundation.dart';

/// Read/write staged attachments on [InComposer] for per-chat draft persistence.
class ComposerDraftHost {
  List<StagedMedia> Function()? _read;
  void Function(List<StagedMedia>)? _restore;
  VoidCallback? _clear;

  void attach({
    required List<StagedMedia> Function() readAttachments,
    required void Function(List<StagedMedia> items) restoreAttachments,
    required VoidCallback clearAttachments,
  }) {
    _read = readAttachments;
    _restore = restoreAttachments;
    _clear = clearAttachments;
  }

  void detach() {
    _read = null;
    _restore = null;
    _clear = null;
  }

  List<StagedMedia> readAttachments() => _read?.call() ?? const [];

  void restoreAttachments(List<StagedMedia> items) => _restore?.call(items);

  void clearAttachments() => _clear?.call();
}

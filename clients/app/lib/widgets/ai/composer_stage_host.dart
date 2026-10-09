import 'package:alienai_c35/c/media/media_types.dart';

/// Lets [PageAIHome] stage attachments on [InComposer] without a [GlobalKey].
class ComposerStageHost {
  void Function(List<StagedMedia> items)? _stage;

  void attach(void Function(List<StagedMedia> items) stage) => _stage = stage;

  void detach() => _stage = null;

  bool stage(List<StagedMedia> items) {
    if (_stage == null || items.isEmpty) return false;
    _stage!(items);
    return true;
  }
}

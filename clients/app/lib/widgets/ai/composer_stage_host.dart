import 'package:alienai_c35/c/media/media_types.dart';
import 'package:flutter/widgets.dart';

/// Lets [PageAIHome] stage attachments on [InComposer] without a [GlobalKey].
class ComposerStageHost {
  void Function(List<StagedMedia> items)? _stage;
  void Function(String id, StagedMedia item)? _replace;

  void attach(
    void Function(List<StagedMedia> items) stage, {
    void Function(String id, StagedMedia item)? replace,
  }) {
    _stage = stage;
    _replace = replace;
  }

  void detach() {
    _stage = null;
    _replace = null;
  }

  bool stage(List<StagedMedia> items) {
    if (_stage == null || items.isEmpty) return false;
    _stage!(items);
    return true;
  }

  bool replaceStaged(String id, StagedMedia item) {
    if (_replace == null || id.isEmpty) return false;
    _replace!(id, item);
    return true;
  }
}

/// Exposes [ComposerStageHost] to image preview / chat bubbles under Home.
class ComposerStage extends InheritedWidget {
  const ComposerStage({super.key, required this.host, required super.child});

  final ComposerStageHost host;

  static ComposerStageHost? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<ComposerStage>()?.host;
  }

  @override
  bool updateShouldNotify(ComposerStage oldWidget) => oldWidget.host != host;
}

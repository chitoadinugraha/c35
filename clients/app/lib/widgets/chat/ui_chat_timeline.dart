import 'dart:async';

import 'package:flutter/material.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

/// Scroll controller for [UiChatTimeline] — reversed list, index 0 = newest at visual bottom.
class UiChatTimelineController {
  final itemScroll = ItemScrollController();
  final itemPositions = ItemPositionsListener.create();
  final scrollOffset = ScrollOffsetListener.create();

  var stickToBottom = true;
  var _scrollOffset = 0.0;
  StreamSubscription<double>? _offsetSub;

  void attach() => _offsetSub = scrollOffset.changes.listen((delta) {
        _scrollOffset += delta;
        if (_scrollOffset < 0) _scrollOffset = 0;
        stickToBottom = _scrollOffset < 120;
      });

  void dispose() => _offsetSub?.cancel();

  void scrollToBottom({bool force = false, bool animate = false}) {
    if (force) stickToBottom = true;
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom(force: force, animate: animate));
  }

  void scrollToChronologicalIndex(int index, {required int itemCount, double alignment = 0.78}) {
    final displayIndex = itemCount - 1 - index;
    if (displayIndex < 0 || displayIndex >= itemCount) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!itemScroll.isAttached) return;
      unawaited(
        itemScroll.scrollTo(
          index: displayIndex,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          alignment: alignment,
        ),
      );
    });
  }

  void _scrollToBottom({required bool force, required bool animate}) {
    if (!itemScroll.isAttached) return;
    if (!force && !stickToBottom && _scrollOffset > 96) return;
    if (!animate) {
      itemScroll.jumpTo(index: 0, alignment: 0);
      if (!force) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (itemScroll.isAttached) itemScroll.jumpTo(index: 0, alignment: 0);
      });
      return;
    }
    unawaited(
      itemScroll.scrollTo(
        index: 0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        alignment: 0,
      ),
    );
  }
}

/// Chronological chat message list (0 = oldest). Newest sits at the visual bottom.
class UiChatTimeline extends StatelessWidget {
  const UiChatTimeline({
    super.key,
    required this.controller,
    required this.itemCount,
    required this.itemBuilder,
    this.padding = EdgeInsets.zero,
    this.separatorBuilder,
  });

  final UiChatTimelineController controller;
  final int itemCount;
  final Widget Function(BuildContext context, int chronologicalIndex) itemBuilder;
  final EdgeInsets padding;
  final IndexedWidgetBuilder? separatorBuilder;

  @override
  Widget build(BuildContext context) => ScrollablePositionedList.separated(
        itemScrollController: controller.itemScroll,
        itemPositionsListener: controller.itemPositions,
        scrollOffsetListener: controller.scrollOffset,
        reverse: true,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: padding,
        itemCount: itemCount,
        separatorBuilder: separatorBuilder ?? (_c, _i) => const SizedBox.shrink(),
        itemBuilder: (context, i) => itemBuilder(context, itemCount - 1 - i),
      );
}

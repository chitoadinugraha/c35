import 'package:alienai_c35/guest_site/guest_site_scroll_behavior.dart';
import 'package:flutter/material.dart';

/// Editor site preview stage: pan the floorplan when guest scroll cannot absorb drag.
class SitePreviewViewportHandoff extends InheritedWidget {
  const SitePreviewViewportHandoff({super.key, required this.onPan, required super.child});

  final void Function(Offset delta) onPan;

  static SitePreviewViewportHandoff? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<SitePreviewViewportHandoff>();
  }

  @override
  bool updateShouldNotify(SitePreviewViewportHandoff oldWidget) => onPan != oldWidget.onPan;
}

/// Forwards orthogonal drag on the guest scroll view to the stage pan (not scroll-edge overscroll).
class SitePreviewScrollHandoffListener extends StatelessWidget {
  const SitePreviewScrollHandoffListener({super.key, required this.child});

  final Widget child;

  /// Orthogonal drag while the primary axis is scrolling (e.g. horizontal stage pan on a vertical list).
  static void _handoffOrthogonalDrag(SitePreviewViewportHandoff handoff, ScrollUpdateNotification notification) {
    final drag = notification.dragDetails;
    if (drag == null) return;
    final metrics = notification.metrics;
    if (metrics.axis == Axis.vertical && drag.delta.dx != 0) {
      handoff.onPan(Offset(drag.delta.dx, 0));
    } else if (metrics.axis == Axis.horizontal && drag.delta.dy != 0) {
      handoff.onPan(Offset(0, drag.delta.dy));
    }
  }

  @override
  Widget build(BuildContext context) {
    final handoff = SitePreviewViewportHandoff.maybeOf(context);
    if (handoff == null) return child;

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification is ScrollUpdateNotification) {
          _handoffOrthogonalDrag(handoff, notification);
        }
        return false;
      },
      child: child,
    );
  }
}

/// Mouse / touch drag devices for guest preview (same as [GuestSitePreviewScrollBehavior]).
class SitePreviewHandoffScrollBehavior extends GuestSitePreviewScrollBehavior {
  const SitePreviewHandoffScrollBehavior();
}

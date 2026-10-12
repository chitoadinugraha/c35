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

/// Forwards scroll the guest view could not absorb (clamping overscroll) to the stage pan.
class SitePreviewScrollHandoffListener extends StatelessWidget {
  const SitePreviewScrollHandoffListener({super.key, required this.child});

  final Widget child;

  static Offset _viewportPanForScrollSurplus(ScrollMetrics metrics, double scrollSurplus) {
    if (metrics.axis == Axis.vertical) {
      return Offset(0, scrollSurplus);
    }
    return Offset(scrollSurplus, 0);
  }

  static void _handoffOverscroll(SitePreviewViewportHandoff handoff, OverscrollNotification notification) {
    final metrics = notification.metrics;
    var pan = _viewportPanForScrollSurplus(metrics, notification.overscroll);
    final drag = notification.dragDetails;
    if (drag != null) {
      if (metrics.axis == Axis.vertical) {
        pan += Offset(drag.delta.dx, 0);
      } else {
        pan += Offset(0, drag.delta.dy);
      }
    }
    if (pan != Offset.zero) {
      handoff.onPan(pan);
    }
  }

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
        if (notification is OverscrollNotification) {
          _handoffOverscroll(handoff, notification);
        } else if (notification is ScrollUpdateNotification) {
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

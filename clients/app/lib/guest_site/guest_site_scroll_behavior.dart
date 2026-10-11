import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// Guest site preview: click-drag scroll with mouse (editor phone + standalone preview).
class GuestSitePreviewScrollBehavior extends MaterialScrollBehavior {
  const GuestSitePreviewScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => const {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
        PointerDeviceKind.stylus,
      };
}

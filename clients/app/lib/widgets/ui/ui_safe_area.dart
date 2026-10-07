import 'dart:math' as math;

import 'package:alienai_c35/widgets/ui/ui_window_bar.dart';
import 'package:flutter/material.dart';

double uiStatusBarInset(BuildContext context) {
  if (uiDesktopWindow) return 0;
  final m = MediaQuery.of(context);
  return math.max(m.padding.top, m.viewPadding.top);
}

double uiSafeBottomInset(BuildContext context, [double base = 0]) {
  if (uiDesktopWindow) return base;
  final m = MediaQuery.of(context);
  final keyboard = m.viewInsets.bottom;
  // Scaffold resizeToAvoidBottomInset already lifts content for the IME. On some
  // Android builds viewPadding.bottom includes the keyboard — adding it here
  // double-offsets the composer above the keys.
  final deviceBottom = math.max(m.padding.bottom, math.max(0, m.viewPadding.bottom - keyboard));
  return base + deviceBottom;
}

Widget uiMobileTopBar(BuildContext context, Widget child) {
  final top = uiStatusBarInset(context);
  if (top <= 0) return child;
  return Padding(padding: EdgeInsets.only(top: top), child: child);
}
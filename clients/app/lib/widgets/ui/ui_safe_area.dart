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
  return base + math.max(m.padding.bottom, m.viewPadding.bottom);
}

Widget uiMobileTopBar(BuildContext context, Widget child) {
  final top = uiStatusBarInset(context);
  if (top <= 0) return child;
  return Padding(padding: EdgeInsets.only(top: top), child: child);
}
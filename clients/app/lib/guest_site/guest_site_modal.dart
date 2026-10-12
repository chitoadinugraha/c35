import 'package:flutter/material.dart';

/// Modal routes for guest site UI — stay on the preview / shell navigator (CSA `useRootNavigator: false`).
Future<T?> guestSiteShowModalBottomSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  Color? backgroundColor,
  bool isScrollControlled = false,
  bool useSafeArea = false,
  ShapeBorder? shape,
}) =>
    showModalBottomSheet<T>(
      context: context,
      useRootNavigator: false,
      builder: builder,
      backgroundColor: backgroundColor,
      isScrollControlled: isScrollControlled,
      useSafeArea: useSafeArea,
      shape: shape,
    );

Future<T?> guestSiteShowDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
}) =>
    showDialog<T>(
      context: context,
      useRootNavigator: false,
      barrierDismissible: barrierDismissible,
      builder: builder,
    );

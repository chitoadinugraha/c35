import 'package:alienai_c35/widgets/ui/ui_menu_position.dart';
import 'package:flutter/material.dart';

const uiBotMenuBg = Color(0xFF18181B);
const _uiBotMenuIcon = Color(0xFFA1A1AA);
const _uiBotMenuText = Color(0xFFF4F4F5);
const _uiBotMenuDestructive = Color(0xFFEF4444);

const double _uiBotMenuItemHeight = 40;

PopupMenuItem<T> uiBotMenuItem<T>({
  required T value,
  required IconData icon,
  required String label,
  bool destructive = false,
}) {
  final iconColor = destructive ? _uiBotMenuDestructive : _uiBotMenuIcon;
  final textStyle = TextStyle(
    color: destructive ? _uiBotMenuDestructive : _uiBotMenuText,
    fontSize: 13,
    fontWeight: FontWeight.w500,
  );
  return PopupMenuItem<T>(
    value: value,
    height: _uiBotMenuItemHeight,
    child: Row(
      children: [
        Icon(icon, size: 18, color: iconColor),
        const SizedBox(width: 10),
        Text(label, style: textStyle),
      ],
    ),
  );
}

const PopupMenuDivider uiBotMenuDivider = PopupMenuDivider(height: 8);

Future<T?> uiBotMenuShow<T>({
  required BuildContext context,
  required RelativeRect position,
  required List<PopupMenuEntry<T>> items,
}) =>
    showMenu<T>(context: context, position: position, color: uiBotMenuBg, items: items);

Future<T?> uiBotMenuShowAt<T>({
  required BuildContext context,
  required Offset global,
  required List<PopupMenuEntry<T>> items,
}) =>
    uiBotMenuShow<T>(context: context, position: uiMenuPositionAt(context, global), items: items);

Future<T?> uiBotMenuShowBelow<T>({
  required BuildContext context,
  required RenderBox anchor,
  required List<PopupMenuEntry<T>> items,
  double gap = 4,
}) =>
    uiBotMenuShow<T>(context: context, position: uiMenuPositionBelow(context, anchor, gap: gap), items: items);
import 'package:alienai_c35/c/conn/server_host.dart';
import 'package:alienai_c35/c/nav.dart';
import 'package:alienai_c35/widgets/ui/ui_menu_position.dart';
import 'package:flutter/material.dart';

Future<String?> uiServerHostMenuPick({
  required RenderBox anchor,
  required String activeHost,
}) async {
  final nav = c35NavigatorKey.currentState;
  if (nav == null || !nav.mounted || nav.overlay == null || !nav.overlay!.mounted) return null;
  final menuCtx = nav.context;
  return showMenu<String>(
    context: menuCtx,
    color: const Color(0xFF18181B),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
      side: const BorderSide(color: Color(0xFF27272A)),
    ),
    position: uiMenuPositionBelow(menuCtx, anchor, gap: -8),
    items: serverHostOptions
        .map(
          (o) => PopupMenuItem(
            value: o,
            height: 32,
            child: Row(
              children: [
                SizedBox(
                  width: 16,
                  child: serverHostNormalize(o) == serverHostNormalize(activeHost)
                      ? const Icon(Icons.check, size: 14, color: Color(0xFFA1A1AA))
                      : null,
                ),
                const SizedBox(width: 6),
                Text(serverHostLabelFromUrl(o), style: const TextStyle(fontSize: 12, color: Color(0xFFE4E4E7))),
              ],
            ),
          ),
        )
        .toList(),
  );
}

import 'dart:async';

import 'package:alienai_c35/c/nav.dart';
import 'package:flutter/material.dart';

/// In-app banner shown only while the app is resumed.
class UiNotifyBanner {
  static OverlayEntry? _entry;
  static Timer? _hideTimer;

  static void show({required String title, required String body, required String routeJson, VoidCallback? onTap}) {
    final overlay = c35NavigatorKey.currentState?.overlay;
    if (overlay == null) return;
    hide();
    _entry = OverlayEntry(
      builder: (context) {
        final top = MediaQuery.paddingOf(context).top + 8;
        return Positioned(
          top: top,
          left: 12,
          right: 12,
          child: Material(
            key: ValueKey<String>(routeJson),
            color: const Color(0xFF18181B),
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: Color(0xFF27272A)),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                hide();
                onTap?.call();
              },
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title.isEmpty ? 'Notification' : title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Color(0xFFF4F4F5), fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    if (body.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        body,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Color(0xFFA1A1AA), fontSize: 13),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
    overlay.insert(_entry!);
    _hideTimer = Timer(const Duration(seconds: 5), hide);
  }

  static void hide() {
    _hideTimer?.cancel();
    _hideTimer = null;
    _entry?.remove();
    _entry = null;
  }
}

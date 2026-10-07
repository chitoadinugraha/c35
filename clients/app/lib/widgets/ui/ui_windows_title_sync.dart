import 'dart:async';

import 'package:alienai_c35/c/conn/server_host.dart';
import 'package:alienai_c35/c/parts/desktop_window_title.dart';
import 'package:alienai_c35/c/session.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

/// Keeps the native Windows caption in sync (hidden custom title bar is avoided on Windows — screen capture flicker).
class UiWindowsTitleSync extends StatefulWidget {
  const UiWindowsTitleSync({super.key, required this.child});
  final Widget child;

  @override
  State<UiWindowsTitleSync> createState() => _UiWindowsTitleSyncState();
}

class _UiWindowsTitleSyncState extends State<UiWindowsTitleSync> {
  @override
  void initState() {
    super.initState();
    if (defaultTargetPlatform != TargetPlatform.windows) return;
    sessionTick.addListener(_pushTitle);
    serverHostTick.addListener(_pushTitle);
    unawaited(_pushTitle());
  }

  @override
  void dispose() {
    if (defaultTargetPlatform == TargetPlatform.windows) {
      sessionTick.removeListener(_pushTitle);
      serverHostTick.removeListener(_pushTitle);
    }
    super.dispose();
  }

  Future<void> _pushTitle() async {
    try {
      await windowManager.setTitle(await desktopWindowTitle());
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

import 'dart:io' as io;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class CsaWebView {
  WebViewEnvironment? environment;
  var _ready = false;
  var needsNativeRebuild = false;

  Future<void> ensureReady() async {
    if (_ready) return;
    if (kIsWeb || !io.Platform.isWindows) {
      _ready = true;
      return;
    }
    try {
      final version = await WebViewEnvironment.getAvailableVersion();
      if (version == null) throw StateError('WebView2 runtime required');
      environment = await WebViewEnvironment.create();
      needsNativeRebuild = false;
      _ready = true;
    } on MissingPluginException {
      needsNativeRebuild = true;
      rethrow;
    }
  }
}

final csaWebview = CsaWebView();

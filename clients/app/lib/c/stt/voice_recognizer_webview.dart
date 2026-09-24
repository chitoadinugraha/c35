import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:permission_handler/permission_handler.dart';

import 'csa_webview.dart';
import 'voice_env.dart';
import 'voice_recognizer.dart';
import 'voice_transcript.dart';

class VoiceRecognizerWebView extends VoiceRecognizer {
  VoiceRecognizerWebView({
    super.onStart,
    super.onEnd,
    super.onInit,
    super.onTranscript,
    super.onTranscriptFinal,
    super.onError,
  });

  final _loadedCompleter = Completer<void>();
  HeadlessInAppWebView? _webview;

  @override
  Future<void> get ready => _loadedCompleter.future;

  HeadlessInAppWebView _buildWebView() => HeadlessInAppWebView(
        webViewEnvironment: !kIsWeb && Platform.isWindows ? csaWebview.environment : null,
        initialUrlRequest: URLRequest(url: WebUri(kTtsHost)),
        initialSettings: InAppWebViewSettings(
          javaScriptEnabled: true,
          domStorageEnabled: true,
          databaseEnabled: true,
          mediaPlaybackRequiresUserGesture: false,
        ),
        onPermissionRequest: (_, request) async => PermissionResponse(
          resources: request.resources,
          action: PermissionResponseAction.GRANT,
        ),
        onReceivedError: (_, __, error) => onError?.call(error),
        onWebViewCreated: (controller) {
          controller.addJavaScriptHandler(
            handlerName: 'i',
            callback: (segments) {
              try {
                final cmd = segments.isNotEmpty ? segments.first as String : '';
                var payload = segments.length > 1 ? segments[1] : null;
                if (payload is String && payload.isNotEmpty) {
                  try {
                    payload = jsonDecode(payload);
                  } catch (_) {}
                }
                switch (cmd) {
                  case 'tts_transcript':
                    if (payload is Map) {
                      final transcript = VoiceTranscript.fromMap(
                        Map<String, dynamic>.from(payload),
                      );
                      onTranscript?.call(transcript);
                      if (transcript.isFinal) onTranscriptFinal?.call(transcript);
                    }
                  case 'tts_start':
                    isListening = true;
                    onStart?.call();
                  case 'tts_end':
                    isListening = false;
                    onEnd?.call();
                  case 'tts_init':
                    onInit?.call();
                    if (!_loadedCompleter.isCompleted) _loadedCompleter.complete();
                  case 'tts_error':
                    onError?.call(payload);
                }
              } catch (e) {
                onError?.call(e);
              }
            },
          );
        },
      );

  Future<void> _invoke(String fn, List<dynamic> args) async {
    await ready;
    final controller = _webview?.webViewController;
    if (controller == null) return;
    final argsJson = args.map((e) => jsonEncode(e)).join(',');
    await controller.evaluateJavascript(source: '$fn($argsJson)');
  }

  @override
  Future<void> init() async {
    if (isInitialized) return;
    isInitialized = true;
    await csaWebview.ensureReady();
    _webview ??= _buildWebView();
    await _webview!.run();
    final permissionStatus = await Permission.microphone.request();
    if (!permissionStatus.isGranted) {
      throw Exception('Microphone permission not granted');
    }
    await ready;
    await Future.delayed(const Duration(milliseconds: 200));
    await _invoke('tts_ensure_mic', []);
  }

  @override
  Future<void> start(String lang) async {
    await init();
    await Future.delayed(const Duration(milliseconds: 300));
    await _invoke('tts_start', [lang]);
  }

  @override
  Future<void> stop() async => _invoke('tts_stop', []);

  @override
  void dispose() {
    isListening = false;
    final webview = _webview;
    _webview = null;
    unawaited(() async {
      try {
        await webview?.webViewController?.evaluateJavascript(source: 'tts_stop()');
      } catch (_) {}
      try {
        await webview?.dispose();
      } catch (_) {}
    }());
    super.dispose();
  }
}

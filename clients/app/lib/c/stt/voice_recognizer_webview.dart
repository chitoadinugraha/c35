import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:permission_handler/permission_handler.dart';

import 'csa_webview.dart';

const kTtsHost = 'https://alienai.id/tts.html';

class VoiceTranscript {
  const VoiceTranscript({
    required this.lang,
    required this.txt,
    required this.confidence,
    required this.isFinal,
    this.interim = '',
  });

  final String lang;
  final String txt;
  final String interim;
  final double confidence;
  final bool isFinal;

  factory VoiceTranscript.fromMap(Map<String, dynamic> map) => VoiceTranscript(
        lang: '${map['lang'] ?? ''}',
        txt: '${map['txt'] ?? ''}',
        interim: '${map['interim'] ?? ''}',
        confidence: (map['confidence'] as num?)?.toDouble() ?? 0,
        isFinal: map['isFinal'] == true,
      );
}

class VoiceRecognizerWebView {
  VoiceRecognizerWebView({
    this.onStart,
    this.onEnd,
    this.onInit,
    this.onTranscript,
    this.onTranscriptFinal,
    this.onError,
    String? ttsHost,
  }) : _ttsHost = ttsHost ?? kTtsHost;

  final String _ttsHost;
  final VoidCallback? onStart;
  final VoidCallback? onEnd;
  final VoidCallback? onInit;
  final ValueChanged<VoiceTranscript>? onTranscript;
  final ValueChanged<VoiceTranscript>? onTranscriptFinal;
  final ValueChanged<dynamic>? onError;

  final _loadedCompleter = Completer<void>();
  HeadlessInAppWebView? _webview;
  bool isInitialized = false;
  bool isListening = false;

  Future<void> get ready => _loadedCompleter.future;

  HeadlessInAppWebView _buildWebView() => HeadlessInAppWebView(
        webViewEnvironment: !kIsWeb && Platform.isWindows ? csaWebview.environment : null,
        initialUrlRequest: URLRequest(url: WebUri(_ttsHost)),
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
    final argsJson = args.map((e) => jsonEncode(e)).join(',');
    await _webview!.webViewController!.evaluateJavascript(
      source: '$fn($argsJson)',
    );
  }

  Future<void> init() async {
    if (isInitialized) return;
    isInitialized = true;
    await csaWebview.ensureReady();
    _webview ??= _buildWebView();
    await _webview!.run();
    if (!kIsWeb) {
      final permissionStatus = await Permission.microphone.request();
      if (!permissionStatus.isGranted) {
        throw Exception('Microphone permission not granted');
      }
    }
    await ready;
    await Future.delayed(const Duration(milliseconds: 200));
    await _invoke('tts_ensure_mic', []);
  }

  Future<void> start(String lang) async {
    await init();
    await Future.delayed(const Duration(milliseconds: 300));
    await _invoke('tts_start', [lang]);
  }

  Future<void> stop() async => _invoke('tts_stop', []);

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
  }
}

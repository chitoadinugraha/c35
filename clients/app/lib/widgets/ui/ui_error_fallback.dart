import 'package:alienai_c35/c/chat/chat_inbox.dart';
import 'package:alienai_c35/c/log.dart';
import 'package:alienai_c35/c/ui/ui_friendly_error.dart';
import 'package:alienai_c35/widgets/ui/ui_root_error_detail.dart';
import 'package:alienai_c35/widgets/ui/ui_window_bar.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

void uiErrorLog(Object error, [StackTrace? stack]) => lError(stack == null ? error : '$error\n$stack');

final uiError = ValueNotifier<Object?>(null);
void uiErrorPut(Object error) {
  if (uiIsConnectionError(uiErrorDetailText(error))) {
    uiErrorLog(error);
    return;
  }
  uiError.value = error;
}
void uiErrorClear() => uiError.value = null;

String uiErrorDetailText(Object error) {
  var s = error.toString();
  if (s.startsWith('Exception: ')) s = s.substring('Exception: '.length);
  return s.trim();
}

void uiErrorHook() {
  final prev = FlutterError.onError;
  FlutterError.onError = (details) {
    uiErrorLog(details.exception, details.stack);
    prev?.call(details);
  };
  ErrorWidget.builder = (details) {
    uiErrorLog(details.exception, details.stack);
    return Directionality(textDirection: TextDirection.ltr, child: UiErrorFallback(error: details.exception));
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    uiErrorLog(error, stack);
    uiErrorPut(error);
    return true;
  };
}

class UiErrorHost extends StatelessWidget {
  const UiErrorHost({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => ValueListenableBuilder<Object?>(
        valueListenable: uiError,
        builder: (_, err, child) => err == null
            ? child!
            : Stack(
                fit: StackFit.expand,
                children: [
                  child!,
                  UiErrorFallback(showChrome: true, error: err, onRetry: uiErrorClear),
                ],
              ),
        child: child,
      );
}

class UiErrorFallback extends StatelessWidget {
  const UiErrorFallback({super.key, this.error, this.onRetry, this.showChrome = false});

  final Object? error;
  final VoidCallback? onRetry;
  final bool showChrome;

  String get _title {
    if (error == null) return 'Something went wrong';
    final raw = uiErrorDetailText(error!);
    if (uiIsConnectionError(raw)) return uiCannotConnectToAlienAi;
    final friendly = uiFriendlyError(error!, fallback: 'Something went wrong');
    return friendly == raw ? 'Something went wrong' : friendly;
  }

  String get _subtitle {
    if (error != null && uiIsConnectionError(uiErrorDetailText(error!))) {
      return 'Check your connection and try again. If this keeps happening, restart the app.';
    }
    return 'Please try again. If this keeps happening, restart the app.';
  }

  Widget _body() => Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline_rounded, size: 28, color: Color(0xFFA1A1AA)),
                const SizedBox(height: 12),
                Text(_title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFFF4F4F5))),
                const SizedBox(height: 8),
                Text(_subtitle, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, height: 1.4, color: Color(0xFFA1A1AA))),
                if (error != null && sessionViewerIsRoot()) ...[
                  const SizedBox(height: 12),
                  UiRootErrorDetail(detail: uiErrorDetailText(error!)),
                ],
                if (onRetry != null) ...[
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: onRetry,
                    style: FilledButton.styleFrom(backgroundColor: const Color(0xFF34D399), foregroundColor: const Color(0xFF052E1C)),
                    child: const Text('Retry'),
                  ),
                ],
              ],
            ),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) => Material(
        color: const Color(0xFF08080A),
        child: showChrome ? UiDesktopChrome(child: _body()) : _body(),
      );
}

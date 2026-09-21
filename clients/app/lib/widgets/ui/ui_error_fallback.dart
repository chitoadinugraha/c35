import 'package:alienai_c35/c/log.dart';
import 'package:alienai_c35/widgets/ui/ui_window_bar.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

void uiErrorLog(Object error, [StackTrace? stack]) => lError(stack == null ? error : '$error\n$stack');

final uiError = ValueNotifier<Object?>(null);
void uiErrorPut(Object error) => uiError.value = error;
void uiErrorClear() => uiError.value = null;

void uiErrorHook() {
  final prev = FlutterError.onError;
  FlutterError.onError = (details) {
    uiErrorLog(details.exception, details.stack);
    prev?.call(details);
  };
  ErrorWidget.builder = (details) {
    uiErrorLog(details.exception, details.stack);
    return const Directionality(textDirection: TextDirection.ltr, child: UiErrorFallback());
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
        builder: (_, err, child) => err == null ? child! : Stack(fit: StackFit.expand, children: [child!, UiErrorFallback(showChrome: true, onRetry: uiErrorClear)]),
        child: child,
      );
}

class UiErrorFallback extends StatelessWidget {
  const UiErrorFallback({super.key, this.onRetry, this.showChrome = false});
  final VoidCallback? onRetry;
  final bool showChrome;

  Widget _body() => Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline_rounded, size: 28, color: Color(0xFFA1A1AA)),
                const SizedBox(height: 12),
                const Text('Something went wrong', textAlign: TextAlign.center, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFFF4F4F5))),
                const SizedBox(height: 8),
                const Text('Please try again. If this keeps happening, restart the app.', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, height: 1.4, color: Color(0xFFA1A1AA))),
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

import 'package:alienai_c35/widgets/ui/ui_error_fallback.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('fallback shows friendly copy not technical terms', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: UiErrorFallback()));
    expect(find.text('Something went wrong'), findsOneWidget);
    expect(find.text('Please try again. If this keeps happening, restart the app.'), findsOneWidget);
    expect(find.text('Retry'), findsNothing);
    expect(find.textContaining('Null check'), findsNothing);
    expect(find.textContaining('https://docs.flutter.dev'), findsNothing);
  });

  testWidgets('platform error is marked handled so the window can stay open', (tester) async {
    final prevBuilder = ErrorWidget.builder;
    final prevOnError = FlutterError.onError;
    final prevPlatform = PlatformDispatcher.instance.onError;
    uiErrorClear();
    try {
      uiErrorHook();
      expect(PlatformDispatcher.instance.onError!(StateError('boom'), StackTrace.empty), isTrue);
      expect(uiError.value, isA<StateError>());
    } finally {
      ErrorWidget.builder = prevBuilder;
      FlutterError.onError = prevOnError;
      PlatformDispatcher.instance.onError = prevPlatform;
      uiErrorClear();
    }
  });

  testWidgets('retry clears platform error overlay', (tester) async {
    uiErrorClear();
    addTearDown(uiErrorClear);
    await tester.pumpWidget(const MaterialApp(home: UiErrorHost(child: Text('alive'))));
    uiErrorPut(StateError('boom'));
    await tester.pump();
    expect(find.text('Something went wrong'), findsOneWidget);
    await tester.tap(find.text('Retry'));
    await tester.pump();
    expect(find.text('Something went wrong'), findsNothing);
    expect(find.text('alive'), findsOneWidget);
  });

  testWidgets('error host overlays fallback without removing the app', (tester) async {
    uiErrorClear();
    addTearDown(uiErrorClear);
    await tester.pumpWidget(const MaterialApp(home: UiErrorHost(child: Text('alive'))));
    expect(find.text('alive'), findsOneWidget);
    uiErrorPut(StateError('boom'));
    await tester.pump();
    expect(find.text('alive'), findsOneWidget);
    expect(find.text('Something went wrong'), findsOneWidget);
  });
}

import 'package:alienai_c35/widgets/devices/ui_remote_device.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('UiRemoteBottomSessionControl renders Shared clipboard toggle and responds to tap', (tester) async {
    bool? currentVal = true;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: UiRemoteBottomSessionControl(
              mode: RemoteInteractMode.trackpad,
              sharedClipboard: true,
              onSharedClipboardChanged: (val) {
                currentVal = val;
              },
              onModeChanged: (_) {},
              onPanReset: () {},
              onTeach: () {},
              onFullscreen: () {},
            ),
          ),
        ),
      ),
    );

    // Find the dropdown anchor button and tap it to open the menu
    final button = find.byType(InkWell);
    expect(button, findsOneWidget);
    await tester.tap(button);
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    // Verify 'Shared clipboard' option exists in the menu with leading icon
    expect(find.text('Shared clipboard'), findsOneWidget);
    expect(find.byIcon(Icons.assignment_outlined), findsOneWidget);
    expect(find.byIcon(Icons.check_box_outlined), findsOneWidget);

    // Tap 'Shared clipboard'
    await tester.tap(find.text('Shared clipboard'));
    await tester.pumpAndSettle();

    // Verify callback was invoked with false (toggled off)
    expect(currentVal, isFalse);
  });
}

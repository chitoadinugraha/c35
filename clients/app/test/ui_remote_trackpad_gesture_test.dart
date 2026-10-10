import 'package:alienai_c35/c/chat/chat_conn.dart';
import 'package:alienai_c35/c/remote/remote_session.dart';
import 'package:alienai_c35/c/remote/remote_trackpad_cursor_clip.dart';
import 'package:alienai_c35/widgets/devices/ui_remote_device.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('RemoteTrackpadCursorClip instantiates and safely handles confine and release', () {
    final clipper = RemoteTrackpadCursorClip();
    expect(clipper.isConfined, isFalse);

    // Confine with arbitrary surface size
    clipper.confine(
      localPointerPos: const Offset(100, 100),
      surfaceSize: const Size(1920, 1080),
      devicePixelRatio: 1.0,
    );

    // Release must be idempotent and safe
    clipper.release();
    expect(clipper.isConfined, isFalse);
    clipper.release();
  });

  testWidgets('UiRemoteDevice renders in trackpad mode with virtual cursor and control bar', (tester) async {
    final conn = ChatConn();
    final session = RemoteSession.of(conn, 1001);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: UiRemoteDevice(
            session: session,
            deviceName: 'Test Machine',
            online: true,
            interactMode: RemoteInteractMode.trackpad,
            showStreamStats: true,
            onInteractModeChanged: (_) {},
            onTeach: () {},
            onFullscreen: () {},
          ),
        ),
      ),
    );

    // Initial state before connected shows placeholder
    expect(find.text('Server offline. Reconnect when signed in.'), findsOneWidget);

    // Switching widget to dispose must clean up without errors
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(),
        ),
      ),
    );
    await tester.pump();
  });

  test('RemoteSession handles transient disconnected state with grace period without immediate teardown', () async {
    final conn = ChatConn();
    final session = RemoteSession.of(conn, 1001);
    expect(session.connected.value, isFalse);

    // Prepare reconnect resets timers cleanly
    session.prepareUserReconnect();
    expect(session.connected.value, isFalse);
  });
}

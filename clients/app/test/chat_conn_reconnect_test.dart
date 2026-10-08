import 'dart:async';

import 'package:alienai_c35/c/chat/chat_conn.dart';
import 'package:alienai_c35/widgets/ui/ui_conn_wifi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ChatConn connection state', () {
    test('connected getter is false when socket is null or status is not connected', () {
      final conn = ChatConn();
      expect(conn.connected, isFalse);
      expect(conn.status.value, ChatConnStatus.disconnected);
    });

    test('status.value updates synchronously', () {
      final conn = ChatConn();
      expect(conn.status.value, ChatConnStatus.disconnected);
      conn.status.value = ChatConnStatus.connecting;
      expect(conn.status.value, ChatConnStatus.connecting);
      conn.status.value = ChatConnStatus.connected;
      expect(conn.status.value, ChatConnStatus.connected);
      conn.status.value = ChatConnStatus.reconnecting;
      expect(conn.status.value, ChatConnStatus.reconnecting);
    });
  });

  group('UiConnWifi widget', () {
    testWidgets('shows wifi icon and triggers onReconnect when tapped', (tester) async {
      final conn = ChatConn();
      conn.status.value = ChatConnStatus.connecting;
      var reconnected = false;

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: UiConnWifi(
            conn: conn,
            onReconnect: () async {
              reconnected = true;
            },
          ),
        ),
      ));

      expect(find.byIcon(Icons.wifi_rounded), findsOneWidget);
      await tester.tap(find.byType(GestureDetector));
      await tester.pump();
      expect(reconnected, isTrue);
    });

    testWidgets('resets reconnect busy state even if onReconnect throws', (tester) async {
      final conn = ChatConn();
      conn.status.value = ChatConnStatus.reconnecting;
      var callCount = 0;

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: UiConnWifi(
            conn: conn,
            onReconnect: () async {
              callCount++;
              throw StateError('connection error');
            },
          ),
        ),
      ));

      // First tap throws
      await tester.tap(find.byType(GestureDetector));
      await tester.pump();
      expect(callCount, 1);

      // Second tap must still be accepted because busy was reset in finally block
      await tester.tap(find.byType(GestureDetector));
      await tester.pump();
      expect(callCount, 2);
    });
  });
}

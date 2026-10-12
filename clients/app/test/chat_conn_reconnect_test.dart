import 'dart:async';

import 'package:alienai_c35/c/chat/chat_conn.dart';
import 'package:alienai_c35/c/session.dart';
import 'package:alienai_c35/widgets/ui/ui_conn_wifi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
// Transitive via web_socket_channel; the fake socket needs StreamChannelMixin.
// ignore: depend_on_referenced_packages
import 'package:stream_channel/stream_channel.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

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

  group('ChatConn reconnect after a failed handshake', () {
    test('does not stay on connecting when socket close never finishes', () async {
      var opened = 0;
      final conn = ChatConn(openSocket: (_) {
        opened++;
        if (opened == 1) return _ScriptedSocket.refused();
        return _ScriptedSocket.ready();
      });
      final previousToken = Session.instance.token;
      Session.instance.token = 'test-token';
      addTearDown(() async {
        Session.instance.token = previousToken;
        await conn.disconnect();
      });

      await expectLater(conn.connect(), throwsA(isA<StateError>()));
      expect(conn.status.value, ChatConnStatus.reconnecting);

      await conn.connect().timeout(const Duration(seconds: 2));
      expect(conn.status.value, ChatConnStatus.connected);
      expect(conn.connected, isTrue);
      expect(opened, 2);
    }, timeout: const Timeout(Duration(seconds: 3)));

    test('ready timeout leaves reconnecting so a later connect can finish', () async {
      final conn = ChatConn(openSocket: (_) => _ScriptedSocket.pending())..readyTimeout = const Duration(milliseconds: 40);
      final previousToken = Session.instance.token;
      Session.instance.token = 'test-token';
      addTearDown(() async {
        Session.instance.token = previousToken;
        await conn.disconnect();
      });

      await expectLater(conn.connect(), throwsA(isA<StateError>()));
      expect(conn.status.value, ChatConnStatus.reconnecting);
      expect(conn.connected, isFalse);
    }, timeout: const Timeout(Duration(seconds: 3)));
  });
}

/// Handshake failed, and [sink.close] never completes — the web_socket_channel
/// behavior when the connect future errors before a stream listener exists.
class _ScriptedSocket extends StreamChannelMixin<dynamic> implements WebSocketChannel {
  _ScriptedSocket.refused() : _failReady = true, _pendingReady = false, _close = Completer<void>().future;
  _ScriptedSocket.ready() : _failReady = false, _pendingReady = false, _close = Future<void>.value();
  _ScriptedSocket.pending() : _failReady = false, _pendingReady = true, _close = Completer<void>().future;

  final bool _failReady;
  final bool _pendingReady;
  final Future<void> _close;
  final _events = StreamController<dynamic>();
  late final WebSocketSink _sink = _ScriptedSink(_close);

  @override
  Future<void> get ready {
    if (_failReady) return Future<void>.error(StateError('refused'));
    if (_pendingReady) return Completer<void>().future;
    return Future<void>.value();
  }

  @override
  Stream<dynamic> get stream => _events.stream;

  @override
  WebSocketSink get sink => _sink;

  @override
  String? get protocol => null;

  @override
  int? get closeCode => null;

  @override
  String? get closeReason => null;
}

class _ScriptedSink implements WebSocketSink {
  _ScriptedSink(this._close);

  final Future<void> _close;

  @override
  Future<void> close([int? closeCode, String? closeReason]) => _close;

  @override
  void add(event) {}

  @override
  void addError(Object error, [StackTrace? stackTrace]) {}

  @override
  Future<void> addStream(Stream<dynamic> stream) async {}

  @override
  Future<void> get done => _close;
}

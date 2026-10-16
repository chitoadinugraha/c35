import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:alienai_c35/c/log.dart';
import 'package:alienai_c35/core/notify/notify_desktop_spawn.dart';
import 'package:flutter/foundation.dart';

/// Desktop notify helper IPC (`alienai_notify.exe` on Windows).
class NotifyDesktopClient {
  NotifyDesktopClient._();

  static final NotifyDesktopClient instance = NotifyDesktopClient._();

  static const host = '127.0.0.1';
  static const port = 19831;

  /// True after a successful `hello` on the current IPC session.
  bool helperOk = false;

  void Function(String title, String body, String routeJson, int? id)? onNotifyPush;

  Socket? _socket;
  StreamSubscription<String>? _lineSub;
  var _startInflight = false;
  var _stopped = false;
  Timer? _reconnectTimer;
  final _pendingLine = StreamController<String>.broadcast();

  @visibleForTesting
  Future<Socket> Function(String host, int port)? connectOverride;

  /// Attach to the helper (spawn if needed). Safe to call repeatedly.
  Future<void> start() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.windows) return;
    if (_stopped) return;
    if (_startInflight) return;
    _startInflight = true;
    try {
      await ensureNotifyDesktopHelperRunning();
      await _attach();
    } finally {
      _startInflight = false;
    }
  }

  void stop() {
    _stopped = true;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    helperOk = false;
    unawaited(_detach());
  }

  /// Tell the helper whether Flutter is in the foreground (`set_focus` IPC).
  Future<void> setFocus(bool resumed) async {
    if (!helperOk || _socket == null) return;
    try {
      await _sendLine('set_focus');
    } catch (e) {
      lError('notify ipc set_focus: $e');
    }
  }

  Future<void> _attach() async {
    if (_stopped) return;
    await _detach();
    Socket socket;
    try {
      final connect = connectOverride ?? Socket.connect;
      socket = await connect(host, port).timeout(const Duration(seconds: 3));
    } catch (e) {
      _scheduleReconnect();
      return;
    }
    _socket = socket;
    helperOk = false;
    final buffer = StringBuffer();
    _lineSub = socket.map(utf8.decode).listen(
      (chunk) {
        buffer.write(chunk);
        while (true) {
          final text = buffer.toString();
          final nl = text.indexOf('\n');
          if (nl < 0) break;
          final line = text.substring(0, nl).trim();
          buffer.clear();
          buffer.write(text.substring(nl + 1));
          if (line.isEmpty) continue;
          _handleLine(line);
        }
      },
      onError: (e) {
        lError('notify ipc read: $e');
        _onSocketLost();
      },
      onDone: _onSocketLost,
      cancelOnError: true,
    );
    try {
      final ok = await _handshakeHello();
      helperOk = ok;
      if (!ok) {
        await _detach();
        _scheduleReconnect();
      }
    } catch (e) {
      lError('notify ipc hello: $e');
      await _detach();
      _scheduleReconnect();
    }
  }

  Future<bool> _handshakeHello() async {
    final line = await _sendLineAndWait('hello', const Duration(seconds: 5));
    return line != null && line.startsWith('ok');
  }

  Future<void> _sendLine(String line) async {
    final s = _socket;
    if (s == null) throw StateError('notify ipc not connected');
    s.add(utf8.encode('$line\n'));
    await s.flush();
  }

  Future<String?> _sendLineAndWait(String line, Duration timeout) async {
    final next = _pendingLine.stream.first;
    await _sendLine(line);
    try {
      return await next.timeout(timeout);
    } on TimeoutException {
      return null;
    }
  }

  void _handleLine(String line) {
    if (line.startsWith('ok')) {
      _pendingLine.add(line);
      if (line.contains('helper=')) {
        helperOk = true;
      }
      return;
    }
    if (line.startsWith('notify_push ')) {
      final payload = parseNotifyPushPayload(line);
      if (payload == null) {
        lError('notify ipc bad notify_push line');
        return;
      }
      onNotifyPush?.call(
        payload.title,
        payload.body,
        payload.routeJson,
        payload.id,
      );
      return;
    }
    if (line.startsWith('err ')) {
      lError('notify ipc: $line');
    }
  }

  void _onSocketLost() {
    helperOk = false;
    unawaited(_detach());
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    if (_stopped) return;
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 5), () {
      unawaited(start());
    });
  }

  Future<void> _detach() async {
    helperOk = false;
    await _lineSub?.cancel();
    _lineSub = null;
    try {
      await _socket?.close();
    } catch (_) {}
    _socket = null;
  }
}

class NotifyPushIpcPayload {
  const NotifyPushIpcPayload({
    required this.title,
    required this.body,
    required this.routeJson,
    this.id,
  });

  final String title;
  final String body;
  final String routeJson;
  final int? id;
}

/// Parse `notify_push {"id":1,"title":"…",…}` from the helper.
NotifyPushIpcPayload? parseNotifyPushPayload(String line) {
  const prefix = 'notify_push ';
  if (!line.startsWith(prefix)) return null;
  final raw = line.substring(prefix.length).trim();
  if (raw.isEmpty) return null;
  try {
    final map = jsonDecode(raw);
    if (map is! Map) return null;
    final idVal = map['id'];
    final id = idVal is int ? idVal : int.tryParse('$idVal');
    return NotifyPushIpcPayload(
      title: '${map['title'] ?? ''}',
      body: '${map['body'] ?? ''}',
      routeJson: '${map['route_json'] ?? map['routeJson'] ?? ''}',
      id: id,
    );
  } catch (_) {
    return null;
  }
}

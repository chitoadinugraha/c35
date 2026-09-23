import 'dart:async';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:alienai_c35/c/log.dart';
import 'package:alienai_c35/widgets/ui/ui_tooltip.dart';
import 'package:alienai_c35/c/pb/c35/remote.pb.dart';
import 'package:alienai_c35/c/remote/remote_session.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

const _border = Color(0xFF27272A);
const _panel = Color(0xFF111114);
const _zinc100 = Color(0xFFF4F4F5);
const _zinc400 = Color(0xFFA1A1AA);
const _zinc500 = Color(0xFF71717A);
const _emerald = Color(0xFF10B981);
const _amber = Color(0xFFF59E0B);
const _red = Color(0xFFEF4444);

class UiRemoteDevice extends StatefulWidget {
  const UiRemoteDevice({
    super.key,
    this.session,
    this.deviceName = 'Remote Device',
    this.online = false,
    this.compact = false,
    this.trackpad = false,
    this.softKeyboard = false,
  });

  final RemoteSession? session;
  final String deviceName;
  final bool online;
  final bool compact;
  final bool trackpad;
  final bool softKeyboard;

  @override
  State<UiRemoteDevice> createState() => _UiRemoteDeviceState();
}

class _UiRemoteDeviceState extends State<UiRemoteDevice> {
  final _focusNode = FocusNode();
  var _connecting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _connect();
  }

  @override
  void didUpdateWidget(UiRemoteDevice oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.session != widget.session) {
      _connect();
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _connect() async {
    final sess = widget.session;
    if (sess == null) return;
    if (!sess.conn.connected) return;
    if (sess.connected.value || _connecting) return;
    setState(() {
      _connecting = true;
      _error = null;
    });
    try {
      await sess.start();
    } catch (e) {
      lError('remote start failed: $e');
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _connecting = false);
    }
  }

  void _sendPointer(String eventType, Offset local, Size size, {int button = 0, int deltaY = 0}) {
    final sess = widget.session;
    if (sess == null) return;
    sess.userActivityPing();
    if (!sess.isControlEnabled.value) return;
    if (size.width <= 0 || size.height <= 0) return;

    final nx = (local.dx / size.width).clamp(0.0, 1.0);
    final ny = (local.dy / size.height).clamp(0.0, 1.0);

    sess.sendInput(RemoteInputEvent(
      eventType: eventType,
      x: nx,
      y: ny,
      button: button,
      deltaY: deltaY,
    ));
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    final sess = widget.session;
    if (sess == null) return KeyEventResult.ignored;
    sess.userActivityPing();
    if (!sess.isControlEnabled.value) return KeyEventResult.ignored;

    final vk = _windowsVkForLogicalKey(event.logicalKey);
    if (vk == 0) return KeyEventResult.ignored;

    final isDown = event is KeyDownEvent || event is KeyRepeatEvent;
    sess.sendInput(RemoteInputEvent(
      eventType: isDown ? 'key_down' : 'key_up',
      keyCode: vk,
    ));

    return KeyEventResult.handled;
  }

  void _showSendTextDialog() {
    final textCtrl = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF18181B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: _border)),
        title: const Text('Send Text to Remote', style: TextStyle(color: _zinc100, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Text will be injected directly as Unicode keystrokes on the remote machine.',
              style: TextStyle(color: _zinc400, fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: textCtrl,
              autofocus: true,
              style: const TextStyle(color: _zinc100, fontSize: 14),
              decoration: const InputDecoration(
                hintText: 'Type text here…',
                hintStyle: TextStyle(color: _zinc500),
                filled: true,
                fillColor: Color(0xFF27272A),
                border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(8)), borderSide: BorderSide.none),
              ),
              onSubmitted: (val) {
                if (val.isNotEmpty) {
                  widget.session?.sendInput(RemoteInputEvent(eventType: 'type_text', text: val));
                  Navigator.pop(ctx);
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: _zinc400)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: _emerald),
            onPressed: () {
              final val = textCtrl.text;
              if (val.isNotEmpty) {
                widget.session?.sendInput(RemoteInputEvent(eventType: 'type_text', text: val));
                Navigator.pop(ctx);
              }
            },
            child: const Text('Send', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  void _sendSpecialKey(int vk, String name) {
    final sess = widget.session;
    if (sess == null || !sess.isControlEnabled.value) return;
    sess.sendInput(RemoteInputEvent(eventType: 'key_down', keyCode: vk));
    Future.delayed(const Duration(milliseconds: 60), () {
      sess.sendInput(RemoteInputEvent(eventType: 'key_up', keyCode: vk));
    });
  }

  void _sendShortcut(String combo) {
    final sess = widget.session;
    if (sess == null || !sess.isControlEnabled.value) return;
    sess.userActivityPing();
    sess.sendInput(RemoteInputEvent(eventType: 'shortcut', text: combo));
  }

  @override
  Widget build(BuildContext context) {
    final sess = widget.session;
    if (sess == null) {
      return const Center(child: Text('No active session', style: TextStyle(color: _zinc500)));
    }

    return ValueListenableBuilder<bool>(
      valueListenable: sess.connected,
      builder: (context, connected, _) => ValueListenableBuilder<bool>(
        valueListenable: sess.isControlEnabled,
        builder: (context, controlEnabled, _) => Column(
          children: [
            if (!widget.compact || connected) _buildToolbar(sess, connected, controlEnabled),
            if (!controlEnabled && connected) _buildViewOnlyNotice(sess),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: _buildCanvasArea(sess, connected, controlEnabled),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToolbar(RemoteSession sess, bool connected, bool controlEnabled) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: const BoxDecoration(
        color: _panel,
        border: Border(bottom: BorderSide(color: _border)),
      ),
      child: Row(
        children: [
          // Resolution / FPS
          ValueListenableBuilder<RemoteScreenFrame?>(
            valueListenable: sess.screenFrame,
            builder: (context, frame, _) => ValueListenableBuilder<int>(
              valueListenable: sess.fps,
              builder: (context, fps, _) {
                if (!connected || frame == null) return const SizedBox.shrink();
                return Text(
                  '${frame.width}×${frame.height} • ${fps}fps',
                  style: const TextStyle(fontSize: 11, color: _zinc500),
                );
              },
            ),
          ),

          const Spacer(),

          // Staged update action (prominent update button on remote display appbar)
          ValueListenableBuilder<bool>(
            valueListenable: sess.updateReady,
            builder: (context, ready, _) {
              if (!ready) return const SizedBox.shrink();
              return ValueListenableBuilder<int?>(
                valueListenable: sess.updateVersion,
                builder: (context, version, _) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: uiTooltip(
                      message: version != null
                          ? 'Agent update v$version ready. Click to restart and apply now.'
                          : 'Update ready. Click to restart and apply.',
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.system_update_rounded, size: 14),
                        label: Text(
                          version != null ? 'Update (v$version)' : 'Update Agent',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _emerald,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: () {
                          sess.triggerUpdate();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Agent update triggered. It will reconnect once restarted.'),
                              duration: Duration(seconds: 4),
                            ),
                          );
                        },
                      ),
                    ),
                  );
                },
              );
            },
          ),

          // Safety mode toggle (View Only vs Remote Control)
          if (connected) ...[
            InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () {
                sess.isControlEnabled.value = !sess.isControlEnabled.value;
                if (sess.isControlEnabled.value) {
                  _focusNode.requestFocus();
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: controlEnabled ? _amber.withValues(alpha: 0.15) : const Color(0xFF27272A),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: controlEnabled ? _amber : _border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      controlEnabled ? Icons.gamepad_outlined : Icons.lock_outline_rounded,
                      size: 14,
                      color: controlEnabled ? _amber : _zinc400,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      controlEnabled ? 'Control Active' : 'View Only',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: controlEnabled ? _amber : _zinc100,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Send text action
            if (controlEnabled) ...[
              uiIconButton(
                tooltip: 'Send Text',
                icon: const Icon(Icons.keyboard_outlined, size: 18, color: _zinc400),
                onPressed: _showSendTextDialog,
                visualDensity: VisualDensity.compact,
              ),
              PopupMenuButton<String>(
                tooltip: uiPopupMenuTooltipText('Special Keys & Shortcuts'),
                color: const Color(0xFF18181B),
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'vk:13', child: Text('Enter (↵)', style: TextStyle(color: _zinc100, fontSize: 13))),
                  const PopupMenuItem(value: 'vk:9', child: Text('Tab (⇥)', style: TextStyle(color: _zinc100, fontSize: 13))),
                  const PopupMenuItem(value: 'vk:27', child: Text('Escape (Esc)', style: TextStyle(color: _zinc100, fontSize: 13))),
                  const PopupMenuItem(value: 'vk:8', child: Text('Backspace (⌫)', style: TextStyle(color: _zinc100, fontSize: 13))),
                  const PopupMenuItem(value: 'vk:91', child: Text('Windows Key (⊞)', style: TextStyle(color: _zinc100, fontSize: 13))),
                  const PopupMenuDivider(),
                  const PopupMenuItem(value: 'combo:ctrl+c', child: Text('Copy (Ctrl+C)', style: TextStyle(color: _zinc100, fontSize: 13))),
                  const PopupMenuItem(value: 'combo:ctrl+v', child: Text('Paste (Ctrl+V)', style: TextStyle(color: _zinc100, fontSize: 13))),
                  const PopupMenuItem(value: 'combo:ctrl+a', child: Text('Select All (Ctrl+A)', style: TextStyle(color: _zinc100, fontSize: 13))),
                  const PopupMenuItem(value: 'combo:win+r', child: Text('Run (Win+R)', style: TextStyle(color: _zinc100, fontSize: 13))),
                  const PopupMenuItem(value: 'combo:alt+tab', child: Text('Switch App (Alt+Tab)', style: TextStyle(color: _zinc100, fontSize: 13))),
                  const PopupMenuItem(value: 'combo:ctrl+shift+esc', child: Text('Task Manager', style: TextStyle(color: _zinc100, fontSize: 13))),
                ],
                onSelected: (val) {
                  if (val.startsWith('vk:')) {
                    final vk = int.tryParse(val.substring(3)) ?? 0;
                    if (vk > 0) _sendSpecialKey(vk, 'key');
                  } else if (val.startsWith('combo:')) {
                    _sendShortcut(val.substring(6));
                  }
                },
                child: uiPopupMenuChild(
                  tooltip: 'Special Keys & Shortcuts',
                  child: const Icon(Icons.more_horiz_rounded, size: 18, color: _zinc400),
                ),
              ),
            ],
          ],

          // Reconnect / Stop button
          uiIconButton(
            tooltip: connected ? 'Stop Session' : 'Reconnect',
            icon: Icon(
              connected ? Icons.stop_circle_outlined : Icons.refresh_rounded,
              size: 18,
              color: connected ? _red : _zinc400,
            ),
            onPressed: connected ? () => sess.stop() : _connect,
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }

  Widget _buildViewOnlyNotice(RemoteSession sess) {
    return Container(
      width: double.infinity,
      color: const Color(0xFF18181B),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          const Icon(Icons.shield_outlined, size: 14, color: _zinc400),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'View-Only mode active. Remote mouse and keyboard input are disabled for safety.',
              style: TextStyle(fontSize: 12, color: _zinc400),
            ),
          ),
          TextButton(
            style: TextButton.styleFrom(
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 8),
            ),
            onPressed: () {
              sess.isControlEnabled.value = true;
              _focusNode.requestFocus();
            },
            child: const Text('Enable Control', style: TextStyle(color: _amber, fontSize: 12, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _buildCanvasArea(RemoteSession sess, bool connected, bool controlEnabled) {
    final border = controlEnabled ? _amber.withValues(alpha: 0.6) : _border;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: _panel,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border, width: controlEnabled ? 1.5 : 1.0),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(11),
        child: ValueListenableBuilder<RemoteSessionStatus>(
          valueListenable: sess.status,
          builder: (context, status, _) {
            if (status == RemoteSessionStatus.pausedIdle) {
              return Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 380),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF18181B),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _border),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.pause_circle_outline_rounded, size: 54, color: _amber),
                      const SizedBox(height: 14),
                      const Text(
                        'Session Paused',
                        style: TextStyle(color: _zinc100, fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Direct connection disconnected after 1 minute of inactivity to save network bandwidth and battery.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: _zinc400, fontSize: 13, height: 1.4),
                      ),
                      const SizedBox(height: 18),
                      FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: _emerald,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        ),
                        icon: const Icon(Icons.play_arrow_rounded, size: 20),
                        label: const Text('Resume Session', style: TextStyle(fontWeight: FontWeight.w600)),
                        onPressed: _connect,
                      ),
                    ],
                  ),
                ),
              );
            }

            return ValueListenableBuilder<bool>(
              valueListenable: sess.hasVideoTrack,
              builder: (context, hasVideoTrack, _) => ValueListenableBuilder<RemoteScreenFrame?>(
                valueListenable: sess.screenFrame,
                builder: (context, frame, _) {
                  if (!connected || (!hasVideoTrack && frame == null)) {
                    final linking = sess.conn.connected && (sess.isLinking || _connecting);
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.desktop_windows_outlined,
                            size: 56,
                            color: linking ? _amber : const Color(0xFF3F3F46),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _error != null
                                ? 'Connection Error: $_error'
                                : (!sess.conn.connected
                                    ? 'Server offline. Reconnect when signed in.'
                                    : linking
                                        ? 'Connecting to ${widget.deviceName}…'
                                        : widget.compact
                                            ? 'Screen stream idle. Tap Reconnect beside the status badge.'
                                            : 'Screen stream idle. Click Reconnect above to start.'),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              color: _error != null ? _red : _zinc400,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  final aspectRatio = frame != null && frame.width > 0 && frame.height > 0
                      ? frame.width / frame.height
                      : 16 / 9;

                  return Center(
                    child: AspectRatio(
                      aspectRatio: aspectRatio,
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final renderSize = Size(constraints.maxWidth, constraints.maxHeight);

                          return Focus(
                            focusNode: _focusNode,
                            onKeyEvent: _handleKeyEvent,
                            child: Listener(
                              onPointerDown: (e) {
                                if (controlEnabled) _focusNode.requestFocus();
                                final btn = e.buttons == kSecondaryMouseButton
                                    ? 2
                                    : (e.buttons == kMiddleMouseButton ? 1 : 0);
                                _sendPointer('mouse_down', e.localPosition, renderSize, button: btn);
                              },
                              onPointerUp: (e) {
                                final btn = e.buttons == kSecondaryMouseButton
                                    ? 2
                                    : (e.buttons == kMiddleMouseButton ? 1 : 0);
                                _sendPointer('mouse_up', e.localPosition, renderSize, button: btn);
                              },
                              onPointerMove: (e) {
                                _sendPointer('mouse_move', e.localPosition, renderSize);
                              },
                              onPointerHover: (e) {
                                _sendPointer('mouse_move', e.localPosition, renderSize);
                              },
                              onPointerSignal: (e) {
                                if (e is PointerScrollEvent) {
                                  final delta = (e.scrollDelta.dy / 20).round();
                                  _sendPointer('wheel', e.localPosition, renderSize, deltaY: delta);
                                }
                              },
                              child: MouseRegion(
                                cursor: controlEnabled ? SystemMouseCursors.precise : SystemMouseCursors.basic,
                                child: hasVideoTrack
                                    ? RTCVideoView(
                                        sess.videoRenderer,
                                        objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitContain,
                                      )
                                    : Image.memory(
                                        frame!.jpegBytes,
                                        gaplessPlayback: true,
                                        fit: BoxFit.contain,
                                      ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }

  int _windowsVkForLogicalKey(LogicalKeyboardKey key) {
    if (key == LogicalKeyboardKey.enter || key == LogicalKeyboardKey.numpadEnter) return 0x0D;
    if (key == LogicalKeyboardKey.tab) return 0x09;
    if (key == LogicalKeyboardKey.escape) return 0x1B;
    if (key == LogicalKeyboardKey.backspace) return 0x08;
    if (key == LogicalKeyboardKey.delete) return 0x2E;
    if (key == LogicalKeyboardKey.space) return 0x20;
    if (key == LogicalKeyboardKey.arrowLeft) return 0x25;
    if (key == LogicalKeyboardKey.arrowUp) return 0x26;
    if (key == LogicalKeyboardKey.arrowRight) return 0x27;
    if (key == LogicalKeyboardKey.arrowDown) return 0x28;
    if (key == LogicalKeyboardKey.controlLeft || key == LogicalKeyboardKey.controlRight) return 0x11;
    if (key == LogicalKeyboardKey.shiftLeft || key == LogicalKeyboardKey.shiftRight) return 0x10;
    if (key == LogicalKeyboardKey.altLeft || key == LogicalKeyboardKey.altRight) return 0x12;
    if (key == LogicalKeyboardKey.metaLeft || key == LogicalKeyboardKey.metaRight) return 0x5B;

    final id = key.keyId;
    // 'a'..'z' (0x61..0x7A) -> 0x41..0x5A
    if (id >= 0x61 && id <= 0x7A) return (id - 0x20).toInt();
    // '0'..'9' (0x30..0x39)
    if (id >= 0x30 && id <= 0x39) return id.toInt();

    return 0;
  }
}

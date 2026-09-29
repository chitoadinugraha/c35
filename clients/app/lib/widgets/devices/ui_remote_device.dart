import 'dart:async';
import 'dart:math' show min;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:alienai_c35/c/log.dart';
import 'package:alienai_c35/widgets/ui/ui_tooltip.dart';
import 'package:alienai_c35/c/pb/c35/remote.pb.dart';
import 'package:alienai_c35/c/remote/device_prompt_context.dart';
import 'package:alienai_c35/c/remote/remote_cursor.dart';
import 'package:alienai_c35/c/remote/remote_trackpad_cursor_lock.dart';
import 'package:alienai_c35/c/remote/remote_virtual_cursor.dart';
import 'package:alienai_c35/c/remote/remote_session.dart';
import 'package:alienai_c35/widgets/devices/in_device_prompt_composer.dart';
import 'package:alienai_c35/widgets/devices/ui_device_prompt_sheet.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

const _border = Color(0xFF27272A);
const _panel = Color(0xFF111114);
const _zinc100 = Color(0xFFF4F4F5);
const _zinc400 = Color(0xFFA1A1AA);
const _zinc500 = Color(0xFF71717A);
const _emerald = Color(0xFF10B981);
const _amber = Color(0xFFF59E0B);

const _trackpadSingleClickDelay = Duration(milliseconds: 180);
const _trackpadDoubleTapWindowMs = 280;

enum RemoteInteractMode { view, mouse, trackpad }

extension RemoteInteractModeUi on RemoteInteractMode {
  String get label => switch (this) {
        RemoteInteractMode.view => 'Pan (view only)',
        RemoteInteractMode.mouse => 'Mouse',
        RemoteInteractMode.trackpad => 'Trackpad',
      };

  IconData get icon => switch (this) {
        RemoteInteractMode.view => Icons.open_with_rounded,
        RemoteInteractMode.mouse => Icons.mouse_outlined,
        RemoteInteractMode.trackpad => Icons.touch_app_outlined,
      };
}

class UiRemoteBottomSessionControl extends StatelessWidget {
  const UiRemoteBottomSessionControl({
    super.key,
    required this.mode,
    required this.onModeChanged,
    required this.onPanReset,
    required this.onTeach,
    required this.onFullscreen,
    this.immersive = false,
    this.updateReady = false,
    this.updateVersion,
    this.onApplyUpdate,
  });

  final RemoteInteractMode mode;
  final ValueChanged<RemoteInteractMode> onModeChanged;
  final VoidCallback onPanReset;
  final VoidCallback onTeach;
  final VoidCallback onFullscreen;
  final bool immersive;
  final bool updateReady;
  final int? updateVersion;
  final VoidCallback? onApplyUpdate;

  void _onMenuSelected(String id) {
    switch (id) {
      case 'view':
        onModeChanged(RemoteInteractMode.view);
      case 'mouse':
        onModeChanged(RemoteInteractMode.mouse);
      case 'trackpad':
        onModeChanged(RemoteInteractMode.trackpad);
      case 'teach':
        onTeach();
      case 'fullscreen':
        onFullscreen();
      case 'update':
        onApplyUpdate?.call();
    }
  }


  @override
  Widget build(BuildContext context) {
    final modeAccent = mode == RemoteInteractMode.view ? _zinc400 : _amber;

    return MenuAnchor(
      style: MenuStyle(
        backgroundColor: const WidgetStatePropertyAll(Color(0xFF18181B)),
        surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
        padding:
            const WidgetStatePropertyAll(EdgeInsets.symmetric(vertical: 6)),
        shape: WidgetStatePropertyAll(RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: const BorderSide(color: _border))),
      ),
      menuChildren: [
        for (final m in RemoteInteractMode.values)
          MenuItemButton(
            leadingIcon:
                Icon(m.icon, size: 16, color: m == mode ? _amber : _zinc400),
            trailingIcon: m == mode
                ? const Icon(Icons.check_rounded, size: 16, color: _amber)
                : null,
            onPressed: () => _onMenuSelected(m.name),
            child: Text(m.label,
                style: TextStyle(
                    color: _zinc100,
                    fontSize: 13,
                    fontWeight: m == mode ? FontWeight.w600 : FontWeight.w400)),
          ),
        const Divider(height: 1, color: _border),
        MenuItemButton(
          leadingIcon: const Icon(Icons.auto_awesome_outlined,
              size: 16, color: _zinc400),
          onPressed: () => _onMenuSelected('teach'),
          child: const Text('Teach skill',
              style: TextStyle(color: _zinc100, fontSize: 13)),
        ),
        if (updateReady) ...[
          const Divider(height: 1, color: _border),
          MenuItemButton(
            leadingIcon: const Icon(Icons.system_update_rounded,
                size: 16, color: _emerald),
            onPressed: () => _onMenuSelected('update'),
            child: Text(
              updateVersion != null
                  ? 'Update agent (v$updateVersion)'
                  : 'Update agent',
              style: const TextStyle(
                  color: _zinc100, fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ],
        const Divider(height: 1, color: _border),
        MenuItemButton(
          leadingIcon: Icon(
              immersive ? Icons.fullscreen_exit_outlined : Icons.fullscreen_outlined,
              size: 16,
              color: _zinc400),
          onPressed: () => _onMenuSelected('fullscreen'),
          child: Text(immersive ? 'Exit full screen' : 'Full screen',
              style: const TextStyle(color: _zinc100, fontSize: 13)),
        ),
      ],
      builder: (context, controller, child) {
        final tip = mode == RemoteInteractMode.view
            ? 'Pan (view only) — drag & pinch zoom; no remote input'
            : mode == RemoteInteractMode.trackpad
                ? 'Trackpad — touch on stream; virtual pointer; pinch to zoom view'
                : '${mode.label} — Ctrl+drag or middle-click to pan when zoomed';
        return Tooltip(
          message: uiPopupMenuTooltipText(tip),
          child: Material(
            color: const Color(0xFF18181B),
            borderRadius: BorderRadius.circular(8),
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => controller.isOpen ? controller.close() : controller.open(),
              onDoubleTap: onPanReset,
              child: SizedBox(
                width: 40,
                height: 40,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(mode.icon, size: 17, color: modeAccent),
                    Icon(Icons.arrow_drop_down, size: 18, color: modeAccent),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class UiRemoteDevice extends StatefulWidget {
  const UiRemoteDevice({
    super.key,
    this.session,
    this.deviceName = 'Remote Device',
    this.online = false,
    this.compact = false,
    required this.interactMode,
    required this.showStreamStats,
    required this.onInteractModeChanged,
    required this.onTeach,
    required this.onFullscreen,
    this.immersive = false,
    this.updateReady = false,
    this.updateVersion,
    this.onApplyUpdate,
    this.promptStore,
    this.browserDevice = false,
  });

  final RemoteSession? session;
  final DevicePromptContextStore? promptStore;
  final String deviceName;
  final bool online;
  final bool compact;
  final RemoteInteractMode interactMode;
  final bool showStreamStats;
  final ValueChanged<RemoteInteractMode> onInteractModeChanged;
  final VoidCallback onTeach;
  final VoidCallback onFullscreen;
  final bool immersive;
  final bool updateReady;
  final int? updateVersion;
  final VoidCallback? onApplyUpdate;
  final bool browserDevice;

  @override
  State<UiRemoteDevice> createState() => _UiRemoteDeviceState();
}

class _UiRemoteDeviceState extends State<UiRemoteDevice> {
  final _focusNode = FocusNode();
  final _vkbCtrl = TextEditingController();
  final _vkbFocus = FocusNode();
  var _connecting = false;
  var _vkbOpen = false;
  var _vkbPrevLen = 0;
  var _modCtrlLocked = false;
  var _modAltLocked = false;
  var _modWinLocked = false;
  String? _error;
  int _heldButtons = 0;
  int _lastDownButtons = 0;
  int _maxPointersInGesture = 0;
  bool _tapClickDispatched = false;
  var _scale = 1.0;
  var _panOffset = Offset.zero;
  Offset? _touchStart;
  var _touchMoved = false;
  final Map<int, Offset> _activePointers = {};
  double? _initialPinchDistance;
  double _initialScaleOnPinch = 1.0;
  Offset _virtualCursorNorm = const Offset(0.5, 0.5);
  Offset _twoFingerPrevPos = Offset.zero;
  var _physicalCtrlPressed = false;
  var _physicalAltPressed = false;
  var _physicalWinPressed = false;
  Timer? _edgeScrollTimer;
  Offset _edgeScrollVelocity = Offset.zero;
  Timer? _trackpadPendingClickTimer;
  int? _trackpadLastTapMs;
  var _trackpadDragLock = false;
  var _trackpadSuppressClickUp = false;
  final RemoteTrackpadCursorLock _trackpadCursorLock =
      createRemoteTrackpadCursorLock();

  bool get _controlInputEnabled =>
      widget.interactMode != RemoteInteractMode.view;
  bool get _keyboardInputEnabled =>
      widget.interactMode != RemoteInteractMode.view;
  bool get _viewPanMode => widget.interactMode == RemoteInteractMode.view;
  bool get _trackpadMode =>
      widget.interactMode == RemoteInteractMode.trackpad;
  bool _canvasDragPans({required bool ctrl, required bool middle}) =>
      _viewPanMode || (!_trackpadMode && (ctrl || middle));
  bool _trackpadGesturePointer(PointerEvent e) =>
      !_trackpadMode ||
      e.kind == PointerDeviceKind.touch ||
      e.kind == PointerDeviceKind.mouse;

  void _trackpadReleaseCursorLock() => _trackpadCursorLock.release();

  void _trackpadSyncCursorLock(PointerEvent e) {
    if (!_trackpadMode || e.kind != PointerDeviceKind.mouse) return;
    if (e.buttons == 0 || (!_touchMoved && !_trackpadDragLock)) return;
    _trackpadCursorLock.engage(e.position);
    _trackpadCursorLock.sustain();
  }

  bool _agentOfflineError(String? err) {
    if (err == null) return false;
    final lower = err.toLowerCase();
    return lower.contains('agent offline') ||
        lower.contains('agent unreachable') ||
        lower.contains('no response from agent');
  }

  bool _showDeviceOffline(RemoteSession sess, bool linking) =>
      !linking && (!widget.online || _agentOfflineError(_error));

  String _placeholderMessage(RemoteSession sess, bool linking) {
    if (!sess.conn.connected) {
      return 'Server offline. Reconnect when signed in.';
    }
    if (_showDeviceOffline(sess, linking)) {
      return '${widget.deviceName} is offline';
    }
    if (linking) return 'Connecting to ${widget.deviceName}…';
    if (sess.stoppedByUser) return 'Remote session stopped.';
    if (_error != null) return '${widget.deviceName} is offline';
    if (widget.browserDevice && sess.connected.value) return 'Starting video stream…';
    return 'Screen stream idle.';
  }

  bool _waitingBrowserVideo(RemoteSession sess, bool connected, bool hasVideoTrack, RemoteScreenFrame? frame) =>
      widget.browserDevice && connected && !hasVideoTrack && frame == null && !sess.stoppedByUser;

  void _syncSessionControl() {
    final sess = widget.session;
    if (sess != null) {
      sess.isControlEnabled.value = _controlInputEnabled;
    }
  }

  bool _onHardwareKeyEvent(KeyEvent event) {
    final ctrl = HardwareKeyboard.instance.isControlPressed;
    final alt = HardwareKeyboard.instance.isAltPressed;
    final win = HardwareKeyboard.instance.isMetaPressed;
    if (_physicalCtrlPressed != ctrl ||
        _physicalAltPressed != alt ||
        _physicalWinPressed != win) {
      if (mounted) {
        setState(() {
          _physicalCtrlPressed = ctrl;
          _physicalAltPressed = alt;
          _physicalWinPressed = win;
        });
      }
    }
    return false;
  }

  void _applyInteractMode(RemoteInteractMode mode) {
    widget.onInteractModeChanged(mode);
    final sess = widget.session;
    if (sess == null) return;
    sess.isControlEnabled.value = mode != RemoteInteractMode.view;
    if (mode != RemoteInteractMode.view) _focusNode.requestFocus();
  }

  Offset _toDesktopCoords(Offset local, Size size) {
    if (_scale <= 1.0) return local;
    final actualX = (local.dx - _panOffset.dx) / _scale;
    final actualY = (local.dy - _panOffset.dy) / _scale;
    return Offset(
        actualX.clamp(0.0, size.width), actualY.clamp(0.0, size.height));
  }

  Size _lastStreamContentSize = Size.zero;

  Size _streamContentSize(RemoteSession sess, bool hasVideoTrack, RemoteScreenFrame? frame) {
    if (hasVideoTrack && sess.videoRenderer.videoWidth > 0 && sess.videoRenderer.videoHeight > 0) {
      return Size(sess.videoRenderer.videoWidth.toDouble(), sess.videoRenderer.videoHeight.toDouble());
    }
    if (frame != null && frame.width > 0 && frame.height > 0) {
      return Size(frame.width.toDouble(), frame.height.toDouble());
    }
    return Size.zero;
  }

  (double scale, Offset offset) _coverLayout(Size viewport, Size content) {
    if (content.width <= 0 || content.height <= 0) return (1, Offset.zero);
    final s = min(viewport.width / content.width, viewport.height / content.height);
    final dw = content.width * s;
    final dh = content.height * s;
    return (s, Offset((viewport.width - dw) / 2, (viewport.height - dh) / 2));
  }

  Offset _viewportLocalToNorm(Offset local, Size viewport, Size content) {
    if (content.width <= 0 || content.height <= 0) return Offset.zero;
    final unzoomed = _toDesktopCoords(local, viewport);
    final (coverScale, coverOffset) = _coverLayout(viewport, content);
    final dw = content.width * coverScale;
    final dh = content.height * coverScale;
    return Offset(
      ((unzoomed.dx - coverOffset.dx) / dw).clamp(0.0, 1.0),
      ((unzoomed.dy - coverOffset.dy) / dh).clamp(0.0, 1.0),
    );
  }

  Offset _normToViewportLocal(Offset norm, Size viewport, Size content) {
    final (coverScale, coverOffset) = _coverLayout(viewport, content);
    final dw = content.width * coverScale;
    final dh = content.height * coverScale;
    return Offset(
      coverOffset.dx + norm.dx * dw * _scale + _panOffset.dx,
      coverOffset.dy + norm.dy * dh * _scale + _panOffset.dy,
    );
  }

  void _clampPan(Size renderSize) {
    if (_scale <= 1.0) {
      _scale = 1.0;
      _panOffset = Offset.zero;
      return;
    }
    final minX = -renderSize.width * (_scale - 1.0);
    final minY = -renderSize.height * (_scale - 1.0);
    _panOffset = Offset(
      _panOffset.dx.clamp(minX, 0.0),
      _panOffset.dy.clamp(minY, 0.0),
    );
  }

  void _zoomAt(Offset focal, double factor, Size renderSize) {
    final newScale = (_scale * factor).clamp(1.0, 4.0);
    if (newScale == _scale) return;
    final scaleRatio = newScale / _scale;
    _panOffset = focal - (focal - _panOffset) * scaleRatio;
    _scale = newScale;
    _clampPan(renderSize);
    setState(() {});
  }

  void _updateEdgeScrolling(Offset localPos, Size renderSize) {
    if (_scale <= 1.0) {
      _stopEdgeScrolling();
      return;
    }

    const margin = 48.0;
    const maxSpeed = 16.0;

    double vx = 0;
    double vy = 0;

    final cx = localPos.dx.clamp(0.0, renderSize.width);
    final cy = localPos.dy.clamp(0.0, renderSize.height);

    if (cx < margin) {
      final r = (margin - cx) / margin;
      vx = maxSpeed * r * r;
    } else if (cx > renderSize.width - margin) {
      final r = (cx - (renderSize.width - margin)) / margin;
      vx = -maxSpeed * r * r;
    }

    if (cy < margin) {
      final r = (margin - cy) / margin;
      vy = maxSpeed * r * r;
    } else if (cy > renderSize.height - margin) {
      final r = (cy - (renderSize.height - margin)) / margin;
      vy = -maxSpeed * r * r;
    }

    if (vx == 0 && vy == 0) {
      _stopEdgeScrolling();
      return;
    }

    _edgeScrollVelocity = Offset(vx, vy);
    _edgeScrollTimer ??= Timer.periodic(const Duration(milliseconds: 16), (_) {
      if (!mounted || _scale <= 1.0) {
        _stopEdgeScrolling();
        return;
      }
      final oldPan = _panOffset;
      _panOffset += _edgeScrollVelocity;
      _clampPan(renderSize);
      if (_panOffset != oldPan) {
        setState(() {});
      }
    });
  }

  void _stopEdgeScrolling() {
    _edgeScrollTimer?.cancel();
    _edgeScrollTimer = null;
    _edgeScrollVelocity = Offset.zero;
  }

  String _formatBytesPerSec(int bps) {
    if (bps < 1024) return '$bps B/s';
    if (bps < 1024 * 1024) {
      final k = bps / 1024;
      return '${k >= 100 ? k.round() : k.toStringAsFixed(1)} KB/s';
    }
    return '${(bps / (1024 * 1024)).toStringAsFixed(1)} MB/s';
  }

  String? _streamStatsLabel(
      RemoteSession sess, bool hasVideo, RemoteScreenFrame? frame, int fps, int? latencyMs, int bytesIn, int bytesOut) {
    final w = hasVideo && sess.videoRenderer.videoWidth > 0
        ? sess.videoRenderer.videoWidth
        : (frame?.width ?? 0);
    final h = hasVideo && sess.videoRenderer.videoHeight > 0
        ? sess.videoRenderer.videoHeight
        : (frame?.height ?? 0);
    if (w <= 0 || h <= 0) return null;
    final codec = hasVideo
        ? 'H.264'
        : 'MJPEG ${sess.streamQuality.value}%';
    final lat = latencyMs != null ? ' · $latencyMs ms' : '';
    final bw = ' · ↓${_formatBytesPerSec(bytesIn)} · ↑${_formatBytesPerSec(bytesOut)}';
    return '$w×$h · $fps fps · $codec$lat$bw';
  }

  Widget _buildStreamStatsOverlay(String label) => Positioned(
        left: 0,
        bottom: 0,
        child: IgnorePointer(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.5),
              borderRadius:
                  const BorderRadius.only(topRight: Radius.circular(6)),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 10, 5),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withValues(alpha: 0.92),
                  letterSpacing: 0.1,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ),
        ),
      );

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_onHardwareKeyEvent);
    _syncSessionControl();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _controlInputEnabled) _focusNode.requestFocus();
    });
    if (widget.session?.stoppedByUser != true) _connect();
  }

  @override
  void didUpdateWidget(UiRemoteDevice oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.session != widget.session) {
      _syncSessionControl();
      if (widget.session?.stoppedByUser != true) _connect();
    }
    if (oldWidget.interactMode != widget.interactMode) {
      _syncSessionControl();
      if (widget.interactMode != RemoteInteractMode.view) {
        _focusNode.requestFocus();
      }
      if (widget.interactMode == RemoteInteractMode.view) {
        _releaseAllModifiers(silent: true);
        if (mounted) setState(() {});
      }
    }
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_onHardwareKeyEvent);
    _stopEdgeScrolling();
    _trackpadCancelPendingClick();
    _trackpadReleaseCursorLock();
    _releaseAllModifiers(silent: true);
    _focusNode.dispose();
    _vkbCtrl.dispose();
    _vkbFocus.dispose();
    super.dispose();
  }

  void _toggleVirtualKeyboard() {
    setState(() {
      _vkbOpen = !_vkbOpen;
      if (_vkbOpen) {
        if (widget.promptStore?.isDisposed != true) widget.promptStore?.composerOpenPut(false);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _vkbFocus.requestFocus();
        });
      } else {
        _vkbFocus.unfocus();
        _vkbCtrl.clear();
        _vkbPrevLen = 0;
      }
    });
  }

  void _togglePromptComposer() {
    final store = widget.promptStore;
    if (store == null || store.isDisposed) return;
    if (store.composerOpen) {
      store.composerOpenPut(false);
      return;
    }
    setState(() {
      _vkbOpen = false;
      _vkbFocus.unfocus();
      _vkbCtrl.clear();
      _vkbPrevLen = 0;
    });
    store.composerOpenPut(true);
  }

  void _openPromptHistory() {
    final store = widget.promptStore;
    if (store == null || store.isDisposed) return;
    unawaited(
        showDevicePromptSheet(context, store, deviceName: widget.deviceName));
  }

  void _onVirtualKeyboardChanged(String value) {
    final sess = widget.session;
    if (sess == null || !_controlInputEnabled) return;
    if (value.length > _vkbPrevLen) {
      final added = value.substring(_vkbPrevLen);
      sess.userActivityPing();
      sess.sendInput(RemoteInputEvent(eventType: 'type_text', text: added));
    } else if (value.length < _vkbPrevLen) {
      final removed = _vkbPrevLen - value.length;
      for (var i = 0; i < removed; i++) {
        _sendKeyTap(0x08);
      }
    }
    _vkbPrevLen = value.length;
  }

  void _sendKeyDown(int vk) {
    final sess = widget.session;
    if (sess == null || !_controlInputEnabled) return;
    sess.userActivityPing();
    sess.sendInput(RemoteInputEvent(eventType: 'key_down', keyCode: vk));
  }

  void _sendKeyUp(int vk) {
    final sess = widget.session;
    if (sess == null) return;
    sess.sendInput(RemoteInputEvent(eventType: 'key_up', keyCode: vk));
  }

  void _sendKeyTap(int vk) {
    _sendKeyDown(vk);
    Future.delayed(const Duration(milliseconds: 60), () => _sendKeyUp(vk));
  }

  bool _modifierLocked(int vk) => switch (vk) {
        0x11 => _modCtrlLocked,
        0x12 => _modAltLocked,
        0x5B => _modWinLocked,
        _ => false,
      };

  void _setModifierLocked(int vk, bool locked) {
    switch (vk) {
      case 0x11:
        _modCtrlLocked = locked;
      case 0x12:
        _modAltLocked = locked;
      case 0x5B:
        _modWinLocked = locked;
    }
  }

  void _toggleModifierLock(int vk) {
    if (!_controlInputEnabled) return;
    final locked = _modifierLocked(vk);
    setState(() => _setModifierLocked(vk, !locked));
    if (locked) {
      _sendKeyUp(vk);
    } else {
      _sendKeyDown(vk);
    }
  }

  void _releaseAllModifiers({bool silent = false}) {
    final ups = <int>[];
    if (_modCtrlLocked) ups.add(0x11);
    if (_modAltLocked) ups.add(0x12);
    if (_modWinLocked) ups.add(0x5B);
    if (ups.isEmpty) return;
    for (final vk in ups) {
      _sendKeyUp(vk);
    }
    if (!silent && mounted) {
      setState(() {
        _modCtrlLocked = false;
        _modAltLocked = false;
        _modWinLocked = false;
      });
    } else {
      _modCtrlLocked = false;
      _modAltLocked = false;
      _modWinLocked = false;
    }
  }

  Future<void> _connect({bool forceRestart = false}) async {
    final sess = widget.session;
    if (sess == null) return;
    if (!sess.conn.connected) return;
    if (_connecting) return;
    if (!forceRestart) {
      if (sess.connected.value) {
        if (mounted) setState(() => _error = null);
        return;
      }
      if (sess.isLinking) return;
    }
    setState(() {
      _connecting = true;
      _error = null;
    });
    try {
      sess.prepareUserReconnect();
      if (forceRestart || sess.connected.value || sess.isLinking) {
        await sess.stop(userInitiated: false);
      }
      await sess.start();
    } catch (e) {
      lError('remote start failed: $e');
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _connecting = false);
    }
  }

  void _sendPointerNorm(String eventType, Offset norm,
      {int button = 0, int deltaY = 0}) {
    final sess = widget.session;
    if (sess == null || !_controlInputEnabled) return;
    sess.userActivityPing();
    sess.sendInput(RemoteInputEvent(
      eventType: eventType,
      x: norm.dx.clamp(0.0, 1.0),
      y: norm.dy.clamp(0.0, 1.0),
      button: button,
      deltaY: deltaY,
    ));
  }

  void _sendPointer(String eventType, Offset local, Size size,
      {int button = 0, int deltaY = 0}) {
    if (size.width <= 0 || size.height <= 0) return;
    final content = _lastStreamContentSize;
    final norm = content == Size.zero ? Offset(
      (_toDesktopCoords(local, size).dx / size.width).clamp(0.0, 1.0),
      (_toDesktopCoords(local, size).dy / size.height).clamp(0.0, 1.0),
    ) : _viewportLocalToNorm(local, size, content);
    _virtualCursorNorm = norm;
    _sendPointerNorm(eventType, _virtualCursorNorm,
        button: button, deltaY: deltaY);
  }

  void _trackpadCancelPendingClick() {
    _trackpadPendingClickTimer?.cancel();
    _trackpadPendingClickTimer = null;
  }

  Offset _virtualCursorViewportLocal(Size renderSize) {
    final content = _lastStreamContentSize;
    return _normToViewportLocal(
      _virtualCursorNorm,
      renderSize,
      content == Size.zero ? renderSize : content,
    );
  }

  void _trackpadSyncEdgeScroll(Size renderSize) {
    if (!_trackpadMode || _scale <= 1.0) return;
    _updateEdgeScrolling(_virtualCursorViewportLocal(renderSize), renderSize);
  }

  void _trackpadApplyDelta(Offset delta, Size renderSize) {
    if (delta.dx == 0 && delta.dy == 0) return;
    final content = _lastStreamContentSize;
    final (coverScale, _) = _coverLayout(renderSize, content == Size.zero ? renderSize : content);
    final dw = (content == Size.zero ? renderSize.width : content.width * coverScale) * _scale;
    final dh = (content == Size.zero ? renderSize.height : content.height * coverScale) * _scale;
    final dNormX = delta.dx / dw;
    final dNormY = delta.dy / dh;
    _virtualCursorNorm = Offset(
      (_virtualCursorNorm.dx + dNormX).clamp(0.0, 1.0),
      (_virtualCursorNorm.dy + dNormY).clamp(0.0, 1.0),
    );
    _sendPointerNorm('mouse_move', _virtualCursorNorm);
    _trackpadSyncEdgeScroll(renderSize);
    setState(() {});
  }

  void _trackpadTapUp({required int button}) {
    if (button == 2) {
      _trackpadCancelPendingClick();
      _trackpadLastTapMs = null;
      _sendPointerNorm('right_click', _virtualCursorNorm);
      return;
    }
    final now = DateTime.now().millisecondsSinceEpoch;
    if (_trackpadLastTapMs != null &&
        now - _trackpadLastTapMs! < _trackpadDoubleTapWindowMs) {
      _trackpadCancelPendingClick();
      _trackpadLastTapMs = null;
      _sendPointerNorm('double_click', _virtualCursorNorm, button: 0);
      return;
    }
    _trackpadCancelPendingClick();
    _trackpadLastTapMs = now;
    _trackpadPendingClickTimer = Timer(_trackpadSingleClickDelay, () {
      _trackpadPendingClickTimer = null;
      _trackpadLastTapMs = null;
      _sendPointerNorm('mouse_down', _virtualCursorNorm, button: 0);
      _sendPointerNorm('mouse_up', _virtualCursorNorm, button: 0);
    });
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    final sess = widget.session;
    if (sess == null) return KeyEventResult.ignored;
    sess.userActivityPing();
    if (!_keyboardInputEnabled) return KeyEventResult.ignored;

    final vk = _windowsVkForLogicalKey(event.logicalKey);
    if (vk == 0) return KeyEventResult.ignored;

    final isDown = event is KeyDownEvent || event is KeyRepeatEvent;
    sess.sendInput(RemoteInputEvent(
      eventType: isDown ? 'key_down' : 'key_up',
      keyCode: vk,
    ));

    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    final sess = widget.session;
    if (sess == null) {
      return const Center(
          child: Text('No active session', style: TextStyle(color: _zinc500)));
    }

    final controlInput = _controlInputEnabled;

    return ValueListenableBuilder<bool>(
      valueListenable: sess.connected,
      builder: (context, connected, _) => Column(
        children: [
          if (!controlInput && connected) _buildViewOnlyNotice(),
          Expanded(
            child: _buildCanvasArea(sess, connected, controlInput),
          ),
          if (connected) _buildBottomInputBar(),
        ],
      ),
    );
  }

  Widget _bottomKeyChip(
          {required String label,
          required bool locked,
          required VoidCallback onTap}) =>
      Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Material(
            color: locked
                ? _amber.withValues(alpha: 0.12)
                : const Color(0xFF18181B),
            borderRadius: BorderRadius.circular(8),
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: onTap,
              child: SizedBox(
                height: 40,
                child: Column(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 120),
                      height: locked ? 3 : 0,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: _amber,
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(8)),
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: Text(
                          label,
                          style: TextStyle(
                            color: locked ? _amber : _zinc100,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

  Widget _panSessionControl() => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: UiRemoteBottomSessionControl(
        mode: widget.interactMode,
        immersive: widget.immersive,
        onModeChanged: _applyInteractMode,
        onPanReset: () => setState(() {
          _scale = 1.0;
          _panOffset = Offset.zero;
        }),
        onTeach: widget.onTeach,
        onFullscreen: widget.onFullscreen,
        updateReady: widget.updateReady,
        updateVersion: widget.updateVersion,
        onApplyUpdate: widget.onApplyUpdate,
      ),
    );

  Widget _promptChatButton() {
    final store = widget.promptStore;
    if (store == null) return const SizedBox.shrink();
    final open = store.composerOpen;
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: Material(
        color: open ? _amber.withValues(alpha: 0.18) : const Color(0xFF18181B),
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: _togglePromptComposer,
          onLongPress: _openPromptHistory,
          child: SizedBox(
            width: 36,
            height: 40,
            child: Column(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 120),
                  height: open ? 3 : 0,
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: _amber,
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(8)),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Icon(Icons.chat_bubble_outline_rounded,
                        size: 18, color: open ? _amber : _zinc400),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomInputBar() {
    final store = widget.promptStore;
    final control = _controlInputEnabled;

    Widget body() => ColoredBox(
          color: _panel,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Divider(height: 1, color: _border),
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
                child: Row(
                  children: [
                    if (control) _promptChatButton(),
                    _panSessionControl(),
                    if (control) ...[
                      _bottomKeyChip(
                          label: 'Ctrl',
                          locked: _modCtrlLocked || _physicalCtrlPressed,
                          onTap: () => _toggleModifierLock(0x11)),
                      _bottomKeyChip(
                          label: 'Alt',
                          locked: _modAltLocked || _physicalAltPressed,
                          onTap: () => _toggleModifierLock(0x12)),
                      _bottomKeyChip(
                          label: 'Win',
                          locked: _modWinLocked || _physicalWinPressed,
                          onTap: () => _toggleModifierLock(0x5B)),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Material(
                            color: _vkbOpen
                                ? _amber.withValues(alpha: 0.15)
                                : const Color(0xFF18181B),
                            borderRadius: BorderRadius.circular(8),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(8),
                              onTap: _toggleVirtualKeyboard,
                              child: SizedBox(
                                height: 40,
                                child: Icon(
                                  Icons.keyboard_outlined,
                                  size: 22,
                                  color: _vkbOpen ? _amber : _zinc100,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ] else
                      const Spacer(),
                  ],
                ),
              ),
              if (control && _vkbOpen) _buildVirtualKeyboardField(),
              if (control && store != null && store.composerOpen)
                InDevicePromptComposer(
                    store: store, deviceName: widget.deviceName),
            ],
          ),
        );
    if (store == null) return body();
    return ListenableBuilder(listenable: store, builder: (_, __) => body());
  }

  Widget _buildVirtualKeyboardField() => Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
        child: TextField(
          controller: _vkbCtrl,
          focusNode: _vkbFocus,
          autofocus: true,
          keyboardType: TextInputType.multiline,
          textInputAction: TextInputAction.newline,
          style: const TextStyle(color: _zinc100, fontSize: 15),
          decoration: InputDecoration(
            hintText: 'Type to send to remote…',
            hintStyle: const TextStyle(color: _zinc500, fontSize: 14),
            filled: true,
            fillColor: const Color(0xFF27272A),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none),
          ),
          onChanged: _onVirtualKeyboardChanged,
        ),
      );

  Widget _buildViewOnlyNotice() {
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
              'Pan (view only) — local pan/zoom only. Remote mouse and keyboard are disabled.',
              style: TextStyle(fontSize: 12, color: _zinc400),
            ),
          ),
          TextButton(
            style: TextButton.styleFrom(
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 8),
            ),
            onPressed: () => _applyInteractMode(RemoteInteractMode.mouse),
            child: const Text('Enable Mouse',
                style: TextStyle(
                    color: _amber, fontSize: 12, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _buildCanvasArea(
      RemoteSession sess, bool connected, bool controlEnabled) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Color(0xFF09090B),
      ),
      child: ClipRect(
        child: SizedBox.expand(
          child: ValueListenableBuilder<bool>(
          valueListenable: sess.hasVideoTrack,
          builder: (context, hasVideoTrack, _) =>
              ValueListenableBuilder<RemoteScreenFrame?>(
            valueListenable: sess.screenFrame,
            builder: (context, frame, _) {
              if (sess.stoppedByUser || !connected || (!hasVideoTrack && frame == null)) {
                final linking =
                    sess.conn.connected && (sess.isLinking || _connecting);
                return Center(
                  child: SingleChildScrollView(
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
                          _placeholderMessage(sess, linking),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 13,
                            color: _zinc400,
                          ),
                        ),
                        if (_waitingBrowserVideo(sess, connected, hasVideoTrack, frame)) ...[
                          const SizedBox(height: 12),
                          const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2, color: _amber),
                          ),
                        ],
                        if (sess.conn.connected &&
                            !_waitingBrowserVideo(sess, connected, hasVideoTrack, frame)) ...[
                          const SizedBox(height: 16),
                          FilledButton.icon(
                            onPressed: linking
                                ? null
                                : () => _connect(
                                      forceRestart:
                                          _error != null || !widget.online,
                                    ),
                            style: FilledButton.styleFrom(
                              backgroundColor: _amber,
                              foregroundColor: const Color(0xFF09090B),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            icon: linking
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Color(0xFF09090B),
                                    ),
                                  )
                                : const Icon(Icons.play_arrow_rounded, size: 18),
                            label: Text(
                              linking
                                  ? 'Connecting…'
                                  : (_error != null ||
                                          !widget.online ||
                                          sess.stoppedByUser
                                      ? 'Retry'
                                      : 'Connect'),
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }

              return LayoutBuilder(
                builder: (context, constraints) {
                  final renderSize =
                      Size(constraints.maxWidth, constraints.maxHeight);
                  _lastStreamContentSize =
                      _streamContentSize(sess, hasVideoTrack, frame);

                      MouseCursor canvasCursor(String remoteShape) =>
                          (_viewPanMode ||
                                  _physicalCtrlPressed ||
                                  _modCtrlLocked)
                              ? SystemMouseCursors.grab
                              : (widget.interactMode ==
                                      RemoteInteractMode.trackpad
                                  ? SystemMouseCursors.basic
                                  : (controlEnabled
                                      ? remoteCursorFromShape(remoteShape)
                                      : SystemMouseCursors.basic));

                      return Focus(
                        focusNode: _focusNode,
                        autofocus: controlEnabled,
                        onKeyEvent: _handleKeyEvent,
                        child: ValueListenableBuilder<String>(
                          valueListenable: sess.remoteCursorShape,
                          builder: (context, remoteShape, _) => MouseRegion(
                            cursor: canvasCursor(remoteShape),
                            onExit: (_) => _stopEdgeScrolling(),
                            child: Listener(
                              onPointerDown: (e) {
                                if (controlEnabled) _focusNode.requestFocus();
                                if (!_trackpadGesturePointer(e)) return;
                                _activePointers[e.pointer] = e.localPosition;
                                if (_activePointers.length == 1) {
                                  _touchStart = e.localPosition;
                                  _touchMoved = false;
                                  _maxPointersInGesture = 1;
                                  _tapClickDispatched = false;
                                } else if (_activePointers.length >
                                    _maxPointersInGesture) {
                                  _maxPointersInGesture =
                                      _activePointers.length;
                                }
                                _lastDownButtons = e.buttons;

                                if (_activePointers.length == 2) {
                                  final pts = _activePointers.values.toList();
                                  _initialPinchDistance =
                                      (pts[0] - pts[1]).distance;
                                  _initialScaleOnPinch = _scale;
                                  _twoFingerPrevPos = (pts[0] + pts[1]) / 2;
                                  return;
                                }

                                final isDesktopCtrl = HardwareKeyboard
                                        .instance.isControlPressed ||
                                    _modCtrlLocked;
                                final isMiddleClick =
                                    (e.buttons & kMiddleMouseButton != 0);
                                if (_canvasDragPans(
                                    ctrl: isDesktopCtrl,
                                    middle: isMiddleClick)) {
                                  return;
                                }

                                if (widget.interactMode ==
                                    RemoteInteractMode.trackpad) {
                                  _trackpadCancelPendingClick();
                                  final now =
                                      DateTime.now().millisecondsSinceEpoch;
                                  final isQuickDouble =
                                      _trackpadLastTapMs != null &&
                                          (now - _trackpadLastTapMs! <
                                              _trackpadDoubleTapWindowMs);

                                  if (isQuickDouble &&
                                      _activePointers.length == 1 &&
                                      (e.buttons & kSecondaryMouseButton == 0)) {
                                    if (e.kind == PointerDeviceKind.mouse) {
                                      _trackpadCancelPendingClick();
                                      _trackpadLastTapMs = null;
                                      _trackpadSuppressClickUp = true;
                                      _sendPointerNorm('double_click',
                                          _virtualCursorNorm,
                                          button: 0);
                                    } else {
                                      _trackpadDragLock = true;
                                      _sendPointerNorm(
                                          'mouse_down', _virtualCursorNorm,
                                          button: 0);
                                    }
                                  } else {
                                    _trackpadDragLock = false;
                                  }
                                  _heldButtons = e.buttons;
                                  return;
                                }

                                final btn =
                                    (e.buttons & kSecondaryMouseButton != 0)
                                        ? 2
                                        : ((e.buttons & kMiddleMouseButton != 0)
                                            ? 1
                                            : 0);
                                _heldButtons = e.buttons;
                                _sendPointer(
                                    'mouse_down', e.localPosition, renderSize,
                                    button: btn);
                              },
                              onPointerMove: (e) {
                                if (!_trackpadGesturePointer(e)) return;
                                _activePointers[e.pointer] = e.localPosition;

                                if (_activePointers.length >= 2) {
                                  final pts = _activePointers.values.toList();
                                  final currentDist =
                                      (pts[0] - pts[1]).distance;
                                  final isPinching = _initialPinchDistance !=
                                          null &&
                                      (_initialPinchDistance! - currentDist)
                                              .abs() >
                                          12;

                                  if (_initialPinchDistance != null &&
                                      _initialPinchDistance! > 10 &&
                                      (widget.interactMode !=
                                              RemoteInteractMode.trackpad ||
                                          isPinching)) {
                                    final focal = (pts[0] + pts[1]) / 2;
                                    final scaleRatio =
                                        currentDist / _initialPinchDistance!;
                                    final targetScale =
                                        (_initialScaleOnPinch * scaleRatio)
                                            .clamp(1.0, 4.0);
                                    _zoomAt(focal, targetScale / _scale,
                                        renderSize);
                                    _touchMoved = true;
                                    return;
                                  }

                                  if (widget.interactMode ==
                                      RemoteInteractMode.trackpad) {
                                    final currentCenter =
                                        (pts[0] + pts[1]) / 2;
                                    final dy = currentCenter.dy -
                                        _twoFingerPrevPos.dy;
                                    _twoFingerPrevPos = currentCenter;
                                    if (dy.abs() > 1.0) {
                                      _touchMoved = true;
                                      final delta = (dy / 5.0).round();
                                      if (delta != 0) {
                                        _sendPointerNorm(
                                            'wheel', _virtualCursorNorm,
                                            deltaY: delta);
                                      }
                                    }
                                    return;
                                  }
                                }

                                final isDesktopCtrl = HardwareKeyboard
                                        .instance.isControlPressed ||
                                    _modCtrlLocked;
                                final isMiddleClick =
                                    (e.buttons & kMiddleMouseButton != 0);

                                if (_canvasDragPans(
                                    ctrl: isDesktopCtrl,
                                    middle: isMiddleClick)) {
                                  if (_touchStart != null &&
                                      (e.localPosition - _touchStart!)
                                              .distance >
                                          14.0) {
                                    _touchMoved = true;
                                  }
                                  _panOffset += e.delta;
                                  _clampPan(renderSize);
                                  setState(() {});
                                  return;
                                }

                                if (widget.interactMode ==
                                    RemoteInteractMode.trackpad) {
                                  if (e.kind == PointerDeviceKind.mouse &&
                                      e.buttons == 0) {
                                    return;
                                  }
                                  if (_touchStart != null &&
                                      (e.localPosition - _touchStart!)
                                              .distance >
                                          5.0) {
                                    _touchMoved = true;
                                    _trackpadCancelPendingClick();
                                  }
                                  _trackpadApplyDelta(e.delta, renderSize);
                                  _trackpadSyncCursorLock(e);
                                  return;
                                }

                                _updateEdgeScrolling(
                                    e.localPosition, renderSize);
                                _sendPointer(
                                    'mouse_move', e.localPosition, renderSize);
                              },
                              onPointerHover: (e) {
                                if (widget.interactMode ==
                                    RemoteInteractMode.trackpad) {
                                  // In trackpad mode, hover is ignored so that the virtual cursor
                                  // only navigates via deliberate gestures on the trackpad surface.
                                  return;
                                }
                                _updateEdgeScrolling(
                                    e.localPosition, renderSize);
                                _sendPointer(
                                    'mouse_move', e.localPosition, renderSize);
                              },
                              onPointerUp: (e) {
                                _stopEdgeScrolling();
                                if (!_trackpadGesturePointer(e)) return;
                                final hadTwoOrMorePointers =
                                    _maxPointersInGesture >= 2;
                                _activePointers.remove(e.pointer);
                                if (_activePointers.length < 2) {
                                  _initialPinchDistance = null;
                                }

                                final isDesktopCtrl = HardwareKeyboard
                                        .instance.isControlPressed ||
                                    _modCtrlLocked;
                                final wasMiddleClick =
                                    (_heldButtons & kMiddleMouseButton != 0);
                                if (isDesktopCtrl || wasMiddleClick) {
                                  _heldButtons = e.buttons;
                                  return;
                                }

                                if (widget.interactMode ==
                                    RemoteInteractMode.trackpad) {
                                  _trackpadReleaseCursorLock();
                                  if (_trackpadSuppressClickUp) {
                                    _trackpadSuppressClickUp = false;
                                    _heldButtons = e.buttons;
                                    return;
                                  }
                                  if (_trackpadDragLock) {
                                    _trackpadDragLock = false;
                                    _sendPointerNorm(
                                        'mouse_up', _virtualCursorNorm,
                                        button: 0);
                                    _trackpadLastTapMs = null;
                                    _heldButtons = e.buttons;
                                    return;
                                  }

                                  if (!_touchMoved && !_tapClickDispatched) {
                                    _tapClickDispatched = true;
                                    final btn = (hadTwoOrMorePointers ||
                                            (_lastDownButtons &
                                                    kSecondaryMouseButton !=
                                                0))
                                        ? 2
                                        : 0;
                                    _trackpadTapUp(button: btn);
                                  }
                                  _heldButtons = e.buttons;
                                  return;
                                }

                                final released = _heldButtons & ~e.buttons;
                                final btn =
                                    (released & kSecondaryMouseButton != 0)
                                        ? 2
                                        : ((released & kMiddleMouseButton != 0)
                                            ? 1
                                            : 0);
                                _heldButtons = e.buttons;
                                _sendPointer(
                                    'mouse_up', e.localPosition, renderSize,
                                    button: btn);
                              },
                              onPointerCancel: (e) {
                                _stopEdgeScrolling();
                                _trackpadReleaseCursorLock();
                                if (!_trackpadGesturePointer(e)) return;
                                _activePointers.remove(e.pointer);
                                if (_activePointers.length < 2) {
                                  _initialPinchDistance = null;
                                }
                              },
                              onPointerSignal: (e) {
                                if (e is PointerScrollEvent) {
                                  final isDesktopCtrl = HardwareKeyboard
                                          .instance.isControlPressed ||
                                      _modCtrlLocked;
                                  if (isDesktopCtrl &&
                                      widget.interactMode !=
                                          RemoteInteractMode.trackpad) {
                                    final factor =
                                        e.scrollDelta.dy < 0 ? 1.15 : 0.87;
                                    _zoomAt(
                                        e.localPosition, factor, renderSize);
                                    return;
                                  }

                                  // Invert dy: Flutter scroll-down is positive dy, Win32 WHEEL_DELTA requires negative for down
                                  final delta =
                                      (-e.scrollDelta.dy / 20).round();
                                  if (delta != 0) {
                                    if (widget.interactMode ==
                                        RemoteInteractMode.trackpad) {
                                      _sendPointerNorm(
                                          'wheel', _virtualCursorNorm,
                                          deltaY: delta);
                                    } else {
                                      _sendPointer(
                                          'wheel', e.localPosition, renderSize,
                                          deltaY: delta);
                                    }
                                  }
                                }
                              },
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  RepaintBoundary(
                                    child: ClipRect(
                                      child: Transform(
                                        // ignore: deprecated_member_use
                                        transform: Matrix4.identity()
                                          // ignore: deprecated_member_use
                                          ..translate(
                                              _panOffset.dx, _panOffset.dy)
                                          // ignore: deprecated_member_use
                                          ..scale(_scale),
                                        alignment: Alignment.topLeft,
                                        child: hasVideoTrack
                                            ? RTCVideoView(
                                                sess.videoRenderer,
                                                objectFit: RTCVideoViewObjectFit
                                                    .RTCVideoViewObjectFitContain,
                                              )
                                            : (frame != null
                                                ? Image.memory(
                                                    frame.jpegBytes,
                                                    gaplessPlayback: true,
                                                    fit: BoxFit.contain,
                                                    width: renderSize.width,
                                                    height: renderSize.height,
                                                    filterQuality:
                                                        FilterQuality.high,
                                                    isAntiAlias: true,
                                                )
                                                : const SizedBox.shrink()),
                                      ),
                                    ),
                                  ),
                                  if (widget.interactMode ==
                                          RemoteInteractMode.trackpad &&
                                      connected)
                                    Positioned(
                                      left: _normToViewportLocal(
                                              _virtualCursorNorm,
                                              renderSize,
                                              _lastStreamContentSize)
                                          .dx
                                          .clamp(-20.0, renderSize.width),
                                      top: _normToViewportLocal(
                                              _virtualCursorNorm,
                                              renderSize,
                                              _lastStreamContentSize)
                                          .dy
                                          .clamp(-24.0, renderSize.height),
                                      child: UiRemoteVirtualCursor(
                                          shape: remoteShape),
                                    ),
                                  ListenableBuilder(
                                    listenable: Listenable.merge([
                                      sess.fps,
                                      sess.latencyMs,
                                      sess.bytesInPerSec,
                                      sess.bytesOutPerSec,
                                      sess.streamQuality,
                                    ]),
                                    builder: (context, _) {
                                      final statsLabel = widget.showStreamStats
                                          ? _streamStatsLabel(
                                              sess,
                                              hasVideoTrack,
                                              frame,
                                              sess.fps.value,
                                              sess.latencyMs.value,
                                              sess.bytesInPerSec.value,
                                              sess.bytesOutPerSec.value,
                                            )
                                          : null;
                                      if (statsLabel == null) {
                                        return const SizedBox.shrink();
                                      }
                                      return _buildStreamStatsOverlay(
                                          statsLabel);
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                },
              );
            },
          ),
        ),
        ),
      ),
    );
  }

  int _windowsVkForLogicalKey(LogicalKeyboardKey key) {
    if (key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter) {
      return 0x0D;
    }
    if (key == LogicalKeyboardKey.tab) return 0x09;
    if (key == LogicalKeyboardKey.escape) return 0x1B;
    if (key == LogicalKeyboardKey.backspace) return 0x08;
    if (key == LogicalKeyboardKey.delete) return 0x2E;
    if (key == LogicalKeyboardKey.space) return 0x20;
    if (key == LogicalKeyboardKey.arrowLeft) return 0x25;
    if (key == LogicalKeyboardKey.arrowUp) return 0x26;
    if (key == LogicalKeyboardKey.arrowRight) return 0x27;
    if (key == LogicalKeyboardKey.arrowDown) return 0x28;
    if (key == LogicalKeyboardKey.controlLeft ||
        key == LogicalKeyboardKey.controlRight) {
      return 0x11;
    }
    if (key == LogicalKeyboardKey.shiftLeft ||
        key == LogicalKeyboardKey.shiftRight) {
      return 0x10;
    }
    if (key == LogicalKeyboardKey.altLeft || key == LogicalKeyboardKey.altRight) {
      return 0x12;
    }
    if (key == LogicalKeyboardKey.metaLeft ||
        key == LogicalKeyboardKey.metaRight) {
      return 0x5B;
    }

    // Navigation & editing keys
    if (key == LogicalKeyboardKey.home) return 0x24;
    if (key == LogicalKeyboardKey.end) return 0x23;
    if (key == LogicalKeyboardKey.pageUp) return 0x21;
    if (key == LogicalKeyboardKey.pageDown) return 0x22;
    if (key == LogicalKeyboardKey.insert) return 0x2D;
    if (key == LogicalKeyboardKey.capsLock) return 0x14;
    if (key == LogicalKeyboardKey.numLock) return 0x90;
    if (key == LogicalKeyboardKey.scrollLock) return 0x91;
    if (key == LogicalKeyboardKey.printScreen) return 0x2C;
    if (key == LogicalKeyboardKey.pause) return 0x13;

    // Function keys (F1 - F12)
    if (key == LogicalKeyboardKey.f1) return 0x70;
    if (key == LogicalKeyboardKey.f2) return 0x71;
    if (key == LogicalKeyboardKey.f3) return 0x72;
    if (key == LogicalKeyboardKey.f4) return 0x73;
    if (key == LogicalKeyboardKey.f5) return 0x74;
    if (key == LogicalKeyboardKey.f6) return 0x75;
    if (key == LogicalKeyboardKey.f7) return 0x76;
    if (key == LogicalKeyboardKey.f8) return 0x77;
    if (key == LogicalKeyboardKey.f9) return 0x78;
    if (key == LogicalKeyboardKey.f10) return 0x79;
    if (key == LogicalKeyboardKey.f11) return 0x7A;
    if (key == LogicalKeyboardKey.f12) return 0x7B;

    // Punctuation and symbols
    if (key == LogicalKeyboardKey.semicolon) return 0xBA;
    if (key == LogicalKeyboardKey.equal) return 0xBB;
    if (key == LogicalKeyboardKey.comma) return 0xBC;
    if (key == LogicalKeyboardKey.minus) return 0xBD;
    if (key == LogicalKeyboardKey.period) return 0xBE;
    if (key == LogicalKeyboardKey.slash) return 0xBF;
    if (key == LogicalKeyboardKey.backquote) return 0xC0;
    if (key == LogicalKeyboardKey.bracketLeft) return 0xDB;
    if (key == LogicalKeyboardKey.backslash) return 0xDC;
    if (key == LogicalKeyboardKey.bracketRight) return 0xDD;
    if (key == LogicalKeyboardKey.quote) return 0xDE;

    // Numpad keys
    if (key == LogicalKeyboardKey.numpad0) return 0x60;
    if (key == LogicalKeyboardKey.numpad1) return 0x61;
    if (key == LogicalKeyboardKey.numpad2) return 0x62;
    if (key == LogicalKeyboardKey.numpad3) return 0x63;
    if (key == LogicalKeyboardKey.numpad4) return 0x64;
    if (key == LogicalKeyboardKey.numpad5) return 0x65;
    if (key == LogicalKeyboardKey.numpad6) return 0x66;
    if (key == LogicalKeyboardKey.numpad7) return 0x67;
    if (key == LogicalKeyboardKey.numpad8) return 0x68;
    if (key == LogicalKeyboardKey.numpad9) return 0x69;
    if (key == LogicalKeyboardKey.numpadMultiply) return 0x6A;
    if (key == LogicalKeyboardKey.numpadAdd) return 0x6B;
    if (key == LogicalKeyboardKey.numpadSubtract) return 0x6D;
    if (key == LogicalKeyboardKey.numpadDecimal) return 0x6E;
    if (key == LogicalKeyboardKey.numpadDivide) return 0x6F;

    final id = key.keyId;
    // 'a'..'z' (0x61..0x7A) -> 0x41..0x5A
    if (id >= 0x61 && id <= 0x7A) return (id - 0x20).toInt();
    // '0'..'9' (0x30..0x39)
    if (id >= 0x30 && id <= 0x39) return id.toInt();

    return 0;
  }
}


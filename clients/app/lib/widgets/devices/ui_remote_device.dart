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

enum RemoteInteractMode { view, control, mouse }

extension RemoteInteractModeUi on RemoteInteractMode {
  String get label => switch (this) {
        RemoteInteractMode.view => 'View',
        RemoteInteractMode.control => 'Control',
        RemoteInteractMode.mouse => 'Mouse',
      };

  IconData get icon => switch (this) {
        RemoteInteractMode.view => Icons.visibility_outlined,
        RemoteInteractMode.control => Icons.gamepad_outlined,
        RemoteInteractMode.mouse => Icons.mouse_outlined,
      };
}

class UiRemoteSessionMenu extends StatelessWidget {
  const UiRemoteSessionMenu({
    super.key,
    required this.mode,
    required this.showStreamStats,
    required this.onModeChanged,
    required this.onShowStreamStatsChanged,
    required this.onTeach,
    required this.onFullscreen,
    this.updateReady = false,
    this.updateVersion,
    this.onApplyUpdate,
  });

  final RemoteInteractMode mode;
  final bool showStreamStats;
  final ValueChanged<RemoteInteractMode> onModeChanged;
  final ValueChanged<bool> onShowStreamStatsChanged;
  final VoidCallback onTeach;
  final VoidCallback onFullscreen;
  final bool updateReady;
  final int? updateVersion;
  final VoidCallback? onApplyUpdate;

  @override
  Widget build(BuildContext context) {
    final accent = mode == RemoteInteractMode.view ? _zinc400 : _amber;

    return PopupMenuButton<String>(
      tooltip: uiPopupMenuTooltipText('Remote session'),
      color: const Color(0xFF18181B),
      onSelected: (id) {
        switch (id) {
          case 'view':
            onModeChanged(RemoteInteractMode.view);
          case 'control':
            onModeChanged(RemoteInteractMode.control);
          case 'mouse':
            onModeChanged(RemoteInteractMode.mouse);
          case 'teach':
            onTeach();
          case 'fullscreen':
            onFullscreen();
          case 'update':
            onApplyUpdate?.call();
        }
      },
      itemBuilder: (_) => [
        for (final m in RemoteInteractMode.values)
          CheckedPopupMenuItem<String>(
            value: m.name,
            checked: m == mode,
            child: Row(
              children: [
                Icon(m.icon, size: 16, color: m == mode ? _amber : _zinc400),
                const SizedBox(width: 10),
                Text(m.label, style: TextStyle(color: _zinc100, fontSize: 13, fontWeight: m == mode ? FontWeight.w600 : FontWeight.w400)),
              ],
            ),
          ),
        const PopupMenuDivider(),
        PopupMenuItem<String>(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          onTap: () {},
          child: Row(
            children: [
              const Icon(Icons.insights_outlined, size: 16, color: _zinc400),
              const SizedBox(width: 10),
              const Expanded(child: Text('Show stats', style: TextStyle(color: _zinc100, fontSize: 13))),
              Switch.adaptive(
                value: showStreamStats,
                activeThumbColor: _amber,
                activeTrackColor: _amber.withValues(alpha: 0.45),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                onChanged: (v) {
                  onShowStreamStatsChanged(v);
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        ),
        if (updateReady) ...[
          const PopupMenuDivider(),
          PopupMenuItem(
            value: 'update',
            child: Row(
              children: [
                const Icon(Icons.system_update_rounded, size: 16, color: _emerald),
                const SizedBox(width: 10),
                Text(
                  updateVersion != null ? 'Update agent (v$updateVersion)' : 'Update agent',
                  style: const TextStyle(color: _zinc100, fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: 'teach',
          child: Row(
            children: [
              Icon(Icons.school_outlined, size: 16, color: _zinc400),
              SizedBox(width: 10),
              Text('Teach', style: TextStyle(color: _zinc100, fontSize: 13)),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'fullscreen',
          child: Row(
            children: [
              Icon(Icons.fullscreen_outlined, size: 16, color: _zinc400),
              SizedBox(width: 10),
              Text('Fullscreen', style: TextStyle(color: _zinc100, fontSize: 13)),
            ],
          ),
        ),
      ],
      child: uiPopupMenuChild(
        tooltip: 'Remote session',
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          decoration: BoxDecoration(
            color: const Color(0xFF111114),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(mode.icon, size: 14, color: accent),
              const SizedBox(width: 4),
              Text(mode.label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: mode == RemoteInteractMode.view ? _zinc100 : _amber)),
              const SizedBox(width: 2),
              Icon(Icons.arrow_drop_down, size: 18, color: accent),
            ],
          ),
        ),
      ),
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
    required this.onShowStreamStatsChanged,
  });

  final RemoteSession? session;
  final String deviceName;
  final bool online;
  final bool compact;
  final RemoteInteractMode interactMode;
  final bool showStreamStats;
  final ValueChanged<RemoteInteractMode> onInteractModeChanged;
  final ValueChanged<bool> onShowStreamStatsChanged;

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
  var _panZoomActive = false;
  var _scale = 1.0;
  var _panOffset = Offset.zero;
  Offset? _touchStart;
  var _touchMoved = false;
  final Map<int, Offset> _activePointers = {};
  double? _initialPinchDistance;
  double _initialScaleOnPinch = 1.0;
  var _physicalCtrlPressed = false;
  var _physicalAltPressed = false;
  var _physicalWinPressed = false;
  Timer? _edgeScrollTimer;
  Offset _edgeScrollVelocity = Offset.zero;

  bool get _controlInputEnabled => widget.interactMode != RemoteInteractMode.view;
  bool get _keyboardInputEnabled => widget.interactMode == RemoteInteractMode.control;

  bool _onHardwareKeyEvent(KeyEvent event) {
    final ctrl = HardwareKeyboard.instance.isControlPressed;
    final alt = HardwareKeyboard.instance.isAltPressed;
    final win = HardwareKeyboard.instance.isMetaPressed;
    if (_physicalCtrlPressed != ctrl || _physicalAltPressed != alt || _physicalWinPressed != win) {
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
    if (mode == RemoteInteractMode.control) _focusNode.requestFocus();
  }

  Offset _toDesktopCoords(Offset local, Size size) {
    if (_scale <= 1.0) return local;
    final actualX = (local.dx - _panOffset.dx) / _scale;
    final actualY = (local.dy - _panOffset.dy) / _scale;
    return Offset(actualX.clamp(0.0, size.width), actualY.clamp(0.0, size.height));
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

  String? _streamStatsLabel(RemoteSession sess, bool hasVideo, RemoteScreenFrame? frame, int fps) {
    final w = hasVideo && sess.videoRenderer.videoWidth > 0
        ? sess.videoRenderer.videoWidth
        : (frame?.width ?? 0);
    final h = hasVideo && sess.videoRenderer.videoHeight > 0
        ? sess.videoRenderer.videoHeight
        : (frame?.height ?? 0);
    if (w <= 0 || h <= 0) return null;
    final codec = hasVideo ? 'H.264' : 'MJPEG';
    return '$w×$h · $fps fps · $codec';
  }

  Widget _buildStreamStatsOverlay(String label) => Positioned(
        right: 12,
        bottom: 12,
        child: IgnorePointer(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.38),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.hd_outlined, size: 12, color: _emerald.withValues(alpha: 0.85)),
                  const SizedBox(width: 5),
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: Color(0xDDFFFFFF),
                      letterSpacing: 0.1,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_onHardwareKeyEvent);
    widget.session?.isControlEnabled.value = _controlInputEnabled;
    _connect();
  }

  @override
  void didUpdateWidget(UiRemoteDevice oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.session != widget.session) {
      _connect();
    }
    if (oldWidget.interactMode != widget.interactMode) {
      widget.session?.isControlEnabled.value = _controlInputEnabled;
      if (widget.interactMode == RemoteInteractMode.control) {
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
    if (!_controlInputEnabled) return;
    if (size.width <= 0 || size.height <= 0) return;

    final unzoomed = _toDesktopCoords(local, size);
    final nx = (unzoomed.dx / size.width).clamp(0.0, 1.0);
    final ny = (unzoomed.dy / size.height).clamp(0.0, 1.0);

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
      return const Center(child: Text('No active session', style: TextStyle(color: _zinc500)));
    }

    final controlInput = _controlInputEnabled;

    return ValueListenableBuilder<bool>(
      valueListenable: sess.connected,
      builder: (context, connected, _) => Column(
        children: [
          if (!controlInput && connected) _buildViewOnlyNotice(),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: _buildCanvasArea(sess, connected, controlInput),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bottomKeyChip({required String label, required bool locked, required VoidCallback onTap}) => Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Material(
            color: locked ? _amber.withValues(alpha: 0.12) : const Color(0xFF18181B),
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
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
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

  Widget _panZoomButton() {
    final isZoomed = _scale > 1.05;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Tooltip(
        message: uiPopupMenuTooltipText('Pan & Zoom (tap to toggle, double-tap to reset)'),
        child: Material(
          color: _panZoomActive
              ? _amber.withValues(alpha: 0.18)
              : (isZoomed ? const Color(0xFF242018) : const Color(0xFF18181B)),
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () {
              setState(() => _panZoomActive = !_panZoomActive);
            },
            onDoubleTap: () {
              setState(() {
                _scale = 1.0;
                _panOffset = Offset.zero;
                _panZoomActive = false;
              });
            },
            child: SizedBox(
              width: 36,
              height: 40,
              child: Column(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 120),
                    height: _panZoomActive ? 3 : 0,
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: _amber,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Icon(
                        Icons.open_with_rounded,
                        size: 16,
                        color: _panZoomActive
                            ? _amber
                            : (isZoomed ? _amber.withValues(alpha: 0.8) : _zinc400),
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
  }

  Widget _buildBottomInputBar() {
    if (!_controlInputEnabled) return const SizedBox.shrink();

    return ColoredBox(
      color: _panel,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Divider(height: 1, color: _border),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
            child: Row(
              children: [
                _panZoomButton(),
                _bottomKeyChip(label: 'Ctrl', locked: _modCtrlLocked || _physicalCtrlPressed, onTap: () => _toggleModifierLock(0x11)),
                _bottomKeyChip(label: 'Alt', locked: _modAltLocked || _physicalAltPressed, onTap: () => _toggleModifierLock(0x12)),
                _bottomKeyChip(label: 'Win', locked: _modWinLocked || _physicalWinPressed, onTap: () => _toggleModifierLock(0x5B)),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Material(
                      color: _vkbOpen ? _amber.withValues(alpha: 0.15) : const Color(0xFF18181B),
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
              ],
            ),
          ),
          if (_vkbOpen) _buildVirtualKeyboardField(),
        ],
      ),
    );
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
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
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
              'View-Only mode active. Remote mouse and keyboard input are disabled for safety.',
              style: TextStyle(fontSize: 12, color: _zinc400),
            ),
          ),
          TextButton(
            style: TextButton.styleFrom(
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 8),
            ),
            onPressed: () => _applyInteractMode(RemoteInteractMode.control),
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
        child: Column(
          children: [
            Expanded(
              child: ValueListenableBuilder<bool>(
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

                  final double aspectRatio;
                  if (hasVideoTrack && sess.videoRenderer.videoWidth > 0 && sess.videoRenderer.videoHeight > 0) {
                    aspectRatio = sess.videoRenderer.videoWidth / sess.videoRenderer.videoHeight;
                  } else if (frame != null && frame.width > 0 && frame.height > 0) {
                    aspectRatio = frame.width / frame.height;
                  } else {
                    aspectRatio = 16 / 9;
                  }

                  return Center(
                    child: AspectRatio(
                      aspectRatio: aspectRatio,
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final renderSize = Size(constraints.maxWidth, constraints.maxHeight);

                          return Focus(
                            focusNode: _focusNode,
                            onKeyEvent: _handleKeyEvent,
                            child: MouseRegion(
                              cursor: (_panZoomActive || _physicalCtrlPressed || _modCtrlLocked)
                                  ? SystemMouseCursors.grab
                                  : (controlEnabled ? SystemMouseCursors.precise : SystemMouseCursors.basic),
                              onExit: (_) => _stopEdgeScrolling(),
                              child: Listener(
                                onPointerDown: (e) {
                                  if (controlEnabled) _focusNode.requestFocus();
                                  _activePointers[e.pointer] = e.localPosition;
                                  if (_activePointers.length == 1) {
                                    _touchStart = e.localPosition;
                                    _touchMoved = false;
                                    _maxPointersInGesture = 1;
                                    _tapClickDispatched = false;
                                  } else if (_activePointers.length > _maxPointersInGesture) {
                                    _maxPointersInGesture = _activePointers.length;
                                  }
                                  _lastDownButtons = e.buttons;

                                  if (_activePointers.length == 2) {
                                    final pts = _activePointers.values.toList();
                                    _initialPinchDistance = (pts[0] - pts[1]).distance;
                                    _initialScaleOnPinch = _scale;
                                    return;
                                  }

                                  final isDesktopCtrl = HardwareKeyboard.instance.isControlPressed || _modCtrlLocked;
                                  final isMiddleClick = (e.buttons & kMiddleMouseButton != 0);
                                  if (isDesktopCtrl || isMiddleClick || _panZoomActive) {
                                    return;
                                  }

                                  final btn = (e.buttons & kSecondaryMouseButton != 0)
                                      ? 2
                                      : ((e.buttons & kMiddleMouseButton != 0) ? 1 : 0);
                                  _heldButtons = e.buttons;
                                  _sendPointer('mouse_down', e.localPosition, renderSize, button: btn);
                                },
                                onPointerMove: (e) {
                                  _activePointers[e.pointer] = e.localPosition;
                                  _updateEdgeScrolling(e.localPosition, renderSize);

                                  if (_activePointers.length >= 2 && _initialPinchDistance != null && _initialPinchDistance! > 10) {
                                    final pts = _activePointers.values.toList();
                                    final currentDist = (pts[0] - pts[1]).distance;
                                    final focal = (pts[0] + pts[1]) / 2;
                                    final scaleRatio = currentDist / _initialPinchDistance!;
                                    final targetScale = (_initialScaleOnPinch * scaleRatio).clamp(1.0, 4.0);
                                    _zoomAt(focal, targetScale / _scale, renderSize);
                                    _touchMoved = true;
                                    return;
                                  }

                                  final isDesktopCtrl = HardwareKeyboard.instance.isControlPressed || _modCtrlLocked;
                                  final isMiddleClick = (e.buttons & kMiddleMouseButton != 0);

                                  if (isDesktopCtrl || isMiddleClick || _panZoomActive) {
                                    if (_touchStart != null && (e.localPosition - _touchStart!).distance > 14.0) {
                                      _touchMoved = true;
                                    }
                                    _panOffset += e.delta;
                                    _clampPan(renderSize);
                                    setState(() {});
                                    return;
                                  }

                                  _sendPointer('mouse_move', e.localPosition, renderSize);
                                },
                                onPointerHover: (e) {
                                  _updateEdgeScrolling(e.localPosition, renderSize);
                                  _sendPointer('mouse_move', e.localPosition, renderSize);
                                },
                                onPointerUp: (e) {
                                  _stopEdgeScrolling();
                                  final hadTwoOrMorePointers = _maxPointersInGesture >= 2;
                                  _activePointers.remove(e.pointer);
                                  if (_activePointers.length < 2) {
                                    _initialPinchDistance = null;
                                  }

                                  final isDesktopCtrl = HardwareKeyboard.instance.isControlPressed || _modCtrlLocked;
                                  final wasMiddleClick = (_heldButtons & kMiddleMouseButton != 0);
                                  if (isDesktopCtrl || wasMiddleClick) {
                                    _heldButtons = e.buttons;
                                    return;
                                  }

                                  if (_panZoomActive) {
                                    if (!_touchMoved && !_tapClickDispatched && _touchStart != null) {
                                      _tapClickDispatched = true;
                                      final btn = (hadTwoOrMorePointers || (_lastDownButtons & kSecondaryMouseButton != 0)) ? 2 : 0;
                                      _sendPointer('mouse_down', _touchStart!, renderSize, button: btn);
                                      _sendPointer('mouse_up', _touchStart!, renderSize, button: btn);
                                    }
                                    _heldButtons = e.buttons;
                                    return;
                                  }

                                  final released = _heldButtons & ~e.buttons;
                                  final btn = (released & kSecondaryMouseButton != 0)
                                      ? 2
                                      : ((released & kMiddleMouseButton != 0) ? 1 : 0);
                                  _heldButtons = e.buttons;
                                  _sendPointer('mouse_up', e.localPosition, renderSize, button: btn);
                                },
                                onPointerCancel: (e) {
                                  _stopEdgeScrolling();
                                  _activePointers.remove(e.pointer);
                                  if (_activePointers.length < 2) {
                                    _initialPinchDistance = null;
                                  }
                                },
                                onPointerSignal: (e) {
                                  if (e is PointerScrollEvent) {
                                    final isDesktopCtrl = HardwareKeyboard.instance.isControlPressed || _modCtrlLocked;
                                    if (isDesktopCtrl) {
                                      final factor = e.scrollDelta.dy < 0 ? 1.15 : 0.87;
                                      _zoomAt(e.localPosition, factor, renderSize);
                                      return;
                                    }

                                    // Invert dy: Flutter scroll-down is positive dy, Win32 WHEEL_DELTA requires negative for down
                                    final delta = (-e.scrollDelta.dy / 20).round();
                                    if (delta != 0) {
                                      _sendPointer('wheel', e.localPosition, renderSize, deltaY: delta);
                                    }
                                  }
                                },
                                child: ValueListenableBuilder<int>(
                                  valueListenable: sess.fps,
                                  builder: (context, fps, _) {
                                    final statsLabel = widget.showStreamStats ? _streamStatsLabel(sess, hasVideoTrack, frame, fps) : null;

                                    return Stack(
                                      fit: StackFit.expand,
                                      children: [
                                        ClipRect(
                                          child: Transform(
                                            // ignore: deprecated_member_use
                                            transform: Matrix4.identity()..translate(_panOffset.dx, _panOffset.dy)..scale(_scale),
                                            alignment: Alignment.topLeft,
                                            child: hasVideoTrack
                                                ? RTCVideoView(
                                                    sess.videoRenderer,
                                                    objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitContain,
                                                  )
                                                : (frame != null
                                                    ? Image.memory(
                                                        frame.jpegBytes,
                                                        gaplessPlayback: true,
                                                        fit: BoxFit.contain,
                                                      )
                                                    : const SizedBox.shrink()),
                                          ),
                                        ),
                                        if (statsLabel != null) _buildStreamStatsOverlay(statsLabel),
                                      ],
                                    );
                                  },
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
            ),
            ),
            if (connected) _buildBottomInputBar(),
          ],
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

import 'package:alienai_c35/c/chat/chat_conn.dart';
import 'package:alienai_c35/c/device/device_store.dart';
import 'package:alienai_c35/c/log.dart';
import 'package:alienai_c35/c/pb/c35/identity.pb.dart';
import 'package:alienai_c35/c/pb/c35/remote.pbenum.dart';
import 'package:alienai_c35/c/pb/c35/skill.pb.dart';
import 'package:alienai_c35/c/remote/remote_session.dart';
import 'package:alienai_c35/c/settings/remote_prefs.dart';
import 'dart:async';
import 'package:alienai_c35/c/session.dart';
import 'package:alienai_c35/widgets/devices/ui_device_files.dart';
import 'package:alienai_c35/widgets/devices/ui_remote_device.dart';
import 'package:alienai_c35/widgets/skill/ui_skill_master_detail.dart';
import 'package:alienai_c35/widgets/ui/ui_tooltip.dart';
import 'package:alienai_c35/widgets/ui/ui_safe_area.dart';
import 'package:alienai_c35/widgets/ui/ui_window_bar.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

const _border = Color(0xFF27272A);
const _muted = Color(0xFF71717A);
const _text = Color(0xFFF4F4F5);
const _panel = Color(0xFF111114);
const _accent = Color(0xFF34D399);
const _toolIcon = Color(0xFF52525B);

bool _isMobile(BuildContext context) {
  if (kIsWeb) return false;
  final platform = Theme.of(context).platform;
  return platform == TargetPlatform.android || platform == TargetPlatform.iOS;
}

class UiDeviceDetail extends StatefulWidget {
  const UiDeviceDetail({super.key, required this.row, required this.chatConn, this.onBack, this.title});

  final IdentityListRow row;
  final ChatConn chatConn;
  final VoidCallback? onBack;
  final String? title;

  @override
  State<UiDeviceDetail> createState() => _UiDeviceDetailState();
}

class _UiDeviceDetailState extends State<UiDeviceDetail> {
  var _remoteInteractMode = RemoteInteractMode.control;
  var _remoteShowStats = false;
  final _skillKey = GlobalKey<UiSkillMasterDetailState>();
  late final RemoteSession _session;

  @override
  void initState() {
    super.initState();
    _session = RemoteSession.of(widget.chatConn, widget.row.identity.iid.toInt());
    if (widget.row.identity.kind.toLowerCase() == 'remote' && widget.chatConn.connected && !_session.connected.value) {
      _session.start().catchError((e) {
        lError('device detail auto-connect failed: $e');
      });
    }
    unawaited(
      RemotePrefs.instance.load().then((_) {
        if (mounted) {
          final modeName = RemotePrefs.instance.interactMode;
          final mode = RemoteInteractMode.values.firstWhere(
            (m) => m.name == modeName,
            orElse: () => RemoteInteractMode.control,
          );
          setState(() {
            _remoteShowStats = RemotePrefs.instance.showStreamStats;
            _remoteInteractMode = mode;
          });
          _session.isControlEnabled.value = mode != RemoteInteractMode.view;
        }
      }),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final id = widget.row.identity;
    final kind = id.kind.toLowerCase();
    final online = deviceOnlineFromMeta(id.metaJson);
    final tabs = kind == 'iot' ? const ['Control', 'Wiring'] : const ['Remote', 'Files', 'Task', 'Skill', 'Settings'];
    final mobile = _isMobile(context);
    return DefaultTabController(
      length: tabs.length,
      child: ColoredBox(
        color: const Color(0xFF08080A),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.onBack != null || widget.title != null) _navBarWrap(),
            Builder(
              builder: (context) {
                final controller = DefaultTabController.of(context);
                return AnimatedBuilder(
                  animation: controller,
                  builder: (context, _) {
                    final isRemote = kind == 'remote' && controller.index == 0;
                    final isSkill = kind == 'remote' && controller.index == 3;
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(8, 0, 4, 0),
                      child: Row(
                        children: [
                          Expanded(
                            child: TabBar(
                              controller: controller,
                              isScrollable: true,
                              tabAlignment: TabAlignment.start,
                              labelColor: _text,
                              unselectedLabelColor: _muted,
                              indicatorColor: _accent,
                              dividerColor: _border,
                              tabs: [for (final t in tabs) Tab(text: t)],
                            ),
                          ),
                          if (isSkill)
                            Builder(
                              builder: (ctx) => _toolBtn(
                                icon: Icons.add,
                                tooltip: 'Add skill',
                                onPressed: () {
                                  final box = ctx.findRenderObject() as RenderBox?;
                                  if (box == null) return;
                                  final anchor = box.localToGlobal(Offset(box.size.width, box.size.height));
                                  _skillKey.currentState?.showAddMenu(ctx, anchor: anchor);
                                },
                              ),
                            ),
                          if (isRemote) ...[
                            ListenableBuilder(
                              listenable: Listenable.merge([_session.connected, _session.mode, _session.status]),
                              builder: (context, _) {
                                final badge = _remoteBadge(online, _session);
                                if (mobile && !_session.connected.value && widget.chatConn.connected) {
                                  return Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      badge,
                                      const SizedBox(width: 6),
                                      _toolBtn(
                                        icon: Icons.refresh_rounded,
                                        tooltip: 'Reconnect',
                                        onPressed: () => _session.start().catchError((e) => lError('device reconnect: $e')),
                                      ),
                                    ],
                                  );
                                }
                                return badge;
                              },
                            ),
                            const SizedBox(width: 8),
                            ListenableBuilder(
                              listenable: Listenable.merge([_session.updateReady, _session.updateVersion]),
                              builder: (context, _) => UiRemoteSessionMenu(
                                mode: _remoteInteractMode,
                                showStreamStats: _remoteShowStats,
                                onModeChanged: (m) {
                                  setState(() => _remoteInteractMode = m);
                                  _session.isControlEnabled.value = m != RemoteInteractMode.view;
                                },
                                onShowStreamStatsChanged: (v) {
                                  setState(() => _remoteShowStats = v);
                                  unawaited(RemotePrefs.instance.setShowStreamStats(v));
                                },
                                onTeach: () => _remoteTeach(context),
                                onFullscreen: _remoteFullscreen,
                                updateReady: _session.updateReady.value,
                                updateVersion: _session.updateVersion.value,
                                onApplyUpdate: () {
                                  _session.triggerUpdate();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Agent update triggered. It will reconnect once restarted.'),
                                      duration: Duration(seconds: 4),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                );
              },
            ),
            Expanded(
              child: TabBarView(
                children: [
                  for (final t in tabs) _tabBody(kind, t, online),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _navBarWrap() {
    final bar = _navBar();
    if (widget.onBack != null && !uiDesktopWindow) return uiMobileTopBar(context, bar);
    return bar;
  }

  Widget _navBar() => Padding(
        padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
        child: SizedBox(
          height: 40,
          child: Row(
            children: [
              if (widget.onBack != null) ...[
                uiIconButton(
                  tooltip: 'Back',
                  onPressed: widget.onBack,
                  icon: const Icon(Icons.arrow_back, size: 18, color: Color(0xFFA1A1AA)),
                  style: const ButtonStyle(
                    visualDensity: VisualDensity.compact,
                    padding: WidgetStatePropertyAll(EdgeInsets.zero),
                    minimumSize: WidgetStatePropertyAll(Size(32, 32)),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
                const SizedBox(width: 8),
              ],
              if (widget.title != null)
                Expanded(
                  child: Text(widget.title!, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: _text)),
                ),
            ],
          ),
        ),
      );
  Widget _tabBody(String kind, String tab, bool online) {
    if (kind == 'remote' && tab == 'Remote') {
      return UiRemoteDevice(
        session: _session,
        deviceName: widget.row.identity.name,
        online: online,
        compact: _isMobile(context),
        interactMode: _remoteInteractMode,
        showStreamStats: _remoteShowStats,
        onInteractModeChanged: (m) {
          setState(() => _remoteInteractMode = m);
          _session.isControlEnabled.value = m != RemoteInteractMode.view;
          unawaited(RemotePrefs.instance.setInteractMode(m.name));
        },
        onShowStreamStatsChanged: (v) {
          setState(() => _remoteShowStats = v);
          unawaited(RemotePrefs.instance.setShowStreamStats(v));
        },
      );
    }
    if (kind == 'remote' && tab == 'Files') return UiDeviceFiles(session: _session);
    if (kind == 'remote' && tab == 'Skill') {
      return UiSkillMasterDetail(
        key: _skillKey,
        conn: widget.chatConn,
        ownerIid: Session.instance.uid,
        scope: SkillScope.SKILL_SCOPE_DEVICE,
        deviceIid: widget.row.identity.iid.toInt(),
        showTeach: true,
        hideBarActions: true,
      );
    }
    return Center(
      child: Text(
        '$tab — coming soon',
        style: const TextStyle(color: _muted, fontSize: 14),
      ),
    );
  }

  void _remoteTeach(BuildContext context) {
    final controller = DefaultTabController.of(context);
    controller.animateTo(3);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _skillKey.currentState?.teach();
    });
  }

  Future<void> _remoteFullscreen() async {
    if (kIsWeb || !uiDesktopWindow) return;
    try {
      final full = await windowManager.isFullScreen();
      await windowManager.setFullScreen(!full);
    } catch (e) {
      lError('remote fullscreen: $e');
    }
  }

  Widget _remoteBadge(bool clusterOnline, RemoteSession session) {
    if (!widget.chatConn.connected) {
      return _pillBadge('Offline', fg: _muted, bg: const Color(0xFF27272A), border: const Color(0xFF3F3F46));
    }
    if (session.connected.value) {
      final relay = session.mode.value == RemoteConnectionMode.REMOTE_CONNECTION_MODE_RELAY;
      final label = relay ? 'Relay' : 'Direct';
      final fg = relay ? const Color(0xFFFDE68A) : const Color(0xFF86EFAC);
      final bg = relay ? const Color(0xFF422006) : const Color(0xFF14532D);
      final border = relay ? const Color(0xFFF59E0B) : const Color(0xFF22C55E);
      return _pillBadge(label, fg: fg, bg: bg, border: border);
    }
    if (session.isLinking) {
      return _pillBadge('Connecting…', fg: const Color(0xFFFDE68A), bg: const Color(0xFF422006), border: const Color(0xFFF59E0B));
    }
    return _pillBadge(
      clusterOnline ? 'Alien AI Cloud' : 'Cloud offline',
      fg: clusterOnline ? const Color(0xFF86EFAC) : _muted,
      bg: clusterOnline ? const Color(0xFF14532D) : const Color(0xFF27272A),
      border: clusterOnline ? const Color(0xFF22C55E) : const Color(0xFF3F3F46),
    );
  }

  Widget _pillBadge(String label, {required Color fg, required Color bg, required Color border}) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: border),
        ),
        child: Text(label, style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.w500)),
      );

  Widget _toolBtn({required IconData icon, required String tooltip, required VoidCallback? onPressed}) => uiIconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        icon: Icon(icon, size: 18, color: _toolIcon),
        style: IconButton.styleFrom(
          backgroundColor: _panel,
          disabledBackgroundColor: _panel,
          minimumSize: const Size(34, 34),
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: const BorderSide(color: _border)),
        ),
      );
}

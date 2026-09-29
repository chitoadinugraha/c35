import 'package:alienai_c35/c/chat/chat_conn.dart';
import 'package:alienai_c35/c/device/device_store.dart';
import 'package:alienai_c35/c/log.dart';
import 'package:alienai_c35/c/pb/c35/identity.pb.dart';
import 'package:alienai_c35/c/pb/c35/remote.pbenum.dart';
import 'package:alienai_c35/c/pb/c35/skill.pb.dart';
import 'package:alienai_c35/c/remote/device_prompt_context.dart';
import 'package:alienai_c35/c/remote/remote_session.dart';
import 'package:alienai_c35/c/settings/remote_prefs.dart';
import 'package:alienai_c35/c/skill/skill_api.dart';
import 'package:alienai_c35/c/skill/skill_md.dart';
import 'package:alienai_c35/c/ui/ui_friendly_error.dart';
import 'package:alienai_c35/widgets/devices/ui_remote_teach_hud.dart';
import 'package:alienai_c35/widgets/skill/io_skill_review.dart';
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
import 'package:flutter/services.dart';

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

class _UiDeviceDetailState extends State<UiDeviceDetail> with SingleTickerProviderStateMixin {
  var _remoteInteractMode = RemoteInteractMode.mouse;
  var _remoteShowStats = false;
  var _remoteImmersive = false;
  final _skillKey = GlobalKey<UiSkillMasterDetailState>();
  late final RemoteSession _session;
  DevicePromptContextStore? _promptStore;
  late final TabController _tabController;
  late final List<String> _tabs;

  @override
  void initState() {
    super.initState();
    final deviceIid = widget.row.identity.iid.toInt();
    final kind = widget.row.identity.kind.toLowerCase();
    _tabs = kind == 'iot' ? const ['Control', 'Wiring'] : const ['Remote', 'Files', 'Task', 'Skill', 'Settings'];
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) return;
      setState(() {});
    });
    _session = RemoteSession.of(widget.chatConn, deviceIid);
    if (widget.row.identity.kind.toLowerCase() == 'remote') {
      _promptStore = DevicePromptContextStore(
        deviceIid: deviceIid,
        deviceName: widget.row.identity.name,
        chatConn: widget.chatConn,
      );
      unawaited(_promptStore!.init());
    }
    if (widget.row.identity.kind.toLowerCase() == 'remote' &&
        widget.chatConn.connected &&
        !_session.connected.value &&
        !_session.stoppedByUser) {
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
            orElse: () => RemoteInteractMode.mouse,
          );
          setState(() {
            _remoteShowStats = RemotePrefs.instance.showStreamStats;
            _remoteInteractMode = mode;
          });
          _session.streamQuality.value = RemotePrefs.instance.streamQuality;
          _session.sendStreamQuality(RemotePrefs.instance.streamQuality);
          _session.isControlEnabled.value = mode != RemoteInteractMode.view;
        }
      }),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _promptStore?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final id = widget.row.identity;
    final kind = id.kind.toLowerCase();
    final online = deviceOnlineFromMeta(id.metaJson);
    final mobile = _isMobile(context);
    final tabIndex = _tabController.index;
    final activeTab = _tabs[tabIndex];
    final isRemote = kind == 'remote' && activeTab == 'Remote';
    final isSkill = kind == 'remote' && activeTab == 'Skill';
    final immersiveRemote = _remoteImmersive && kind == 'remote';
    return CallbackShortcuts(
      bindings: immersiveRemote
          ? {const SingleActivator(LogicalKeyboardKey.escape): () => _setRemoteImmersive(false)}
          : const {},
      child: Focus(
        autofocus: immersiveRemote,
        child: ColoredBox(
          color: const Color(0xFF08080A),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!immersiveRemote && (widget.onBack != null || widget.title != null)) _navBarWrap(),
              if (!immersiveRemote)
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 0, 12, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: TabBar(
                          controller: _tabController,
                          isScrollable: true,
                          tabAlignment: TabAlignment.start,
                          labelColor: _text,
                          unselectedLabelColor: _muted,
                          indicatorColor: _accent,
                          dividerColor: _border,
                          tabs: [for (final t in _tabs) Tab(text: t)],
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
                            final showStop = _session.connected.value || _session.isLinking;
                            if (mobile && !_session.connected.value && widget.chatConn.connected && !_session.isLinking) {
                              return _toolBtn(
                                icon: Icons.refresh_rounded,
                                tooltip: 'Reconnect',
                                onPressed: () {
                                  _session.prepareUserReconnect();
                                  _session.start().catchError((e) => lError('device reconnect: $e'));
                                },
                              );
                            }
                            return Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _remoteBadge(_session),
                                if (showStop) ...[
                                  const SizedBox(width: 10),
                                  _remoteStopBtn(
                                    onPressed: () {
                                      unawaited(_session.stop().catchError((e) => lError('remote stop: $e')));
                                    },
                                  ),
                                ],
                              ],
                            );
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              Expanded(
                child: immersiveRemote
                    ? Stack(
                        fit: StackFit.expand,
                        children: [
                          _tabBody(kind, 'Remote', online),
                          Positioned(
                            left: 8,
                            top: 8,
                            child: Material(
                              color: Colors.black.withValues(alpha: 0.55),
                              borderRadius: BorderRadius.circular(8),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(8),
                                onTap: () => _setRemoteImmersive(false),
                                child: const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.fullscreen_exit_outlined, size: 16, color: _text),
                                      SizedBox(width: 6),
                                      Text('Exit full screen (Esc)', style: TextStyle(color: _text, fontSize: 12)),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      )
                    : _tabBody(kind, activeTab, online),
              ),
            ],
          ),
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
      final deviceIid = widget.row.identity.iid.toInt();
      return ListenableBuilder(
        listenable: Listenable.merge([_session.updateReady, _session.updateVersion]),
        builder: (context, _) => Stack(
          fit: StackFit.expand,
          children: [
            UiRemoteDevice(
              session: _session,
              promptStore: _promptStore,
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
              onTeach: () => unawaited(_startRemoteTeach(context)),
              onFullscreen: _toggleRemoteImmersive,
              immersive: _remoteImmersive,
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
            UiRemoteTeachHud(
              session: _session,
              deviceIid: deviceIid,
              onStop: () => unawaited(_stopRemoteTeach(context)),
            ),
          ],
        ),
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
        onTeachRemote: () {
          _tabController.animateTo(0);
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) unawaited(_startRemoteTeach(context));
          });
        },
        onDevicePrompt: (text) async {
          await _promptStore?.promptSend(text);
          _promptStore?.composerOpenPut(true);
        },
      );
    }
    return Center(
      child: Text(
        '$tab — coming soon',
        style: const TextStyle(color: _muted, fontSize: 14),
      ),
    );
  }

  Future<String?> _askTeachTitle(BuildContext context) async {
    final ctrl = TextEditingController();
    final title = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF18181B),
        title: const Text('Teach skill', style: TextStyle(color: _text, fontSize: 16, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          style: const TextStyle(color: _text),
          decoration: const InputDecoration(
            labelText: 'Skill title',
            labelStyle: TextStyle(color: _muted),
            hintText: 'e.g. Export report in Excel',
            hintStyle: TextStyle(color: _muted, fontSize: 12),
          ),
          onSubmitted: (v) => Navigator.pop(ctx, v.trim()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            style: FilledButton.styleFrom(backgroundColor: _accent, foregroundColor: Colors.black),
            child: const Text('Start recording'),
          ),
        ],
      ),
    );
    ctrl.dispose();
    return title != null && title.isNotEmpty ? title : null;
  }

  Future<void> _startRemoteTeach(BuildContext context) async {
    if (!_session.connected.value) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Connect Remote first, then start teach mode.'), behavior: SnackBarBehavior.floating),
      );
      return;
    }
    final title = await _askTeachTitle(context);
    if (title == null || !mounted) return;
    try {
      await _session.remoteTeachStart(title);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Recording "$title" — use Stop on the HUD or F9 on the PC.'), behavior: SnackBarBehavior.floating),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(uiFriendlyError(e)), behavior: SnackBarBehavior.floating));
      }
    }
  }

  Future<void> _stopRemoteTeach(BuildContext context) async {
    try {
      final steps = await _session.remoteTeachStop();
      final title = _session.teach?.title.value ?? 'Taught skill';
      if (!mounted) return;
      final review = await ioSkillReviewShow(context, title: title, steps: steps);
      if (review == null || !mounted) return;
      final skill = skillFromTeachReview(
        ownerIid: Session.instance.uid,
        scope: SkillScope.SKILL_SCOPE_DEVICE,
        deviceIid: widget.row.identity.iid.toInt(),
        title: review.title,
        bodyMd: review.bodyMd,
        steps: review.steps,
        autoSubmit: review.autoSubmit,
      );
      final api = SkillApi(widget.chatConn);
      final saved = await api.put(skill);
      _skillKey.currentState?.absorbSkill(saved);
      if (!mounted) return;
      _tabController.animateTo(3);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _skillKey.currentState?.selectSkill('${saved.id}');
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Saved skill "${saved.title}"'), behavior: SnackBarBehavior.floating),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(uiFriendlyError(e)), behavior: SnackBarBehavior.floating));
      }
    }
  }

  void _toggleStreamStats() {
    final v = !_remoteShowStats;
    setState(() => _remoteShowStats = v);
    unawaited(RemotePrefs.instance.setShowStreamStats(v));
  }

  void _toggleRemoteImmersive() => _setRemoteImmersive(!_remoteImmersive);

  void _setRemoteImmersive(bool v) {
    if (_remoteImmersive == v) return;
    setState(() => _remoteImmersive = v);
    if (v && _tabController.index != 0) _tabController.index = 0;
  }

  void _setStreamQuality(RemoteSession session, int quality) {
    session.sendStreamQuality(quality);
    unawaited(RemotePrefs.instance.setStreamQuality(quality));
    setState(() {});
  }

  Widget _remoteBadge(RemoteSession session) {
    if (!widget.chatConn.connected) {
      return _connectionMenu(session, label: 'Offline', fg: _muted, bg: const Color(0xFF27272A), border: const Color(0xFF3F3F46));
    }
    if (session.connected.value) {
      final relay = session.mode.value == RemoteConnectionMode.REMOTE_CONNECTION_MODE_RELAY;
      if (relay) {
        return _connectionMenu(
          session,
          label: 'Relay',
          fg: const Color(0xFFFDE68A),
          bg: const Color(0xFF422006),
          border: const Color(0xFFF59E0B),
        );
      }
      return _connectionMenu(
        session,
        label: 'Direct',
        fg: const Color(0xFF86EFAC),
        bg: const Color(0xFF14532D),
        border: const Color(0xFF22C55E),
      );
    }
    if (session.isLinking) {
      return _connectionMenu(
        session,
        label: 'Connecting…',
        fg: const Color(0xFFFDE68A),
        bg: const Color(0xFF422006),
        border: const Color(0xFFF59E0B),
      );
    }
    return const SizedBox.shrink();
  }

  static const _qualityPresets = [95, 80, 65, 50];

  Widget _connectionMenu(
    RemoteSession session, {
    required String label,
    required Color fg,
    required Color bg,
    required Color border,
  }) =>
      ListenableBuilder(
        listenable: session.streamQuality,
        builder: (context, _) {
          final q = session.streamQuality.value;
          return MenuAnchor(
            style: MenuStyle(
              backgroundColor: const WidgetStatePropertyAll(Color(0xFF18181B)),
              surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
              padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(vertical: 6)),
              shape: WidgetStatePropertyAll(RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: const BorderSide(color: _border),
              )),
            ),
            menuChildren: [
              MenuItemButton(
                trailingIcon: _remoteShowStats
                    ? const Icon(Icons.check_rounded, size: 16, color: Color(0xFFF59E0B))
                    : null,
                onPressed: _toggleStreamStats,
                child: const Text('Show stats', style: TextStyle(color: _text, fontSize: 13)),
              ),
              SubmenuButton(
                menuStyle: MenuStyle(
                  backgroundColor: const WidgetStatePropertyAll(Color(0xFF18181B)),
                  surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
                  shape: WidgetStatePropertyAll(RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: const BorderSide(color: _border),
                  )),
                ),
                menuChildren: [
                  for (final preset in _qualityPresets)
                    MenuItemButton(
                      trailingIcon: q == preset
                          ? const Icon(Icons.check_rounded, size: 16, color: Color(0xFFF59E0B))
                          : null,
                      onPressed: () => _setStreamQuality(session, preset),
                      child: Text('Quality $preset%', style: const TextStyle(color: _text, fontSize: 13)),
                    ),
                ],
                child: Text('Quality ($q%)', style: const TextStyle(color: _text, fontSize: 13)),
              ),
            ],
            builder: (context, controller, child) {
              final pill = Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(label, style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.w500)),
                    Icon(Icons.arrow_drop_down, size: 16, color: fg),
                  ],
                ),
              );
              return Tooltip(
                message: uiPopupMenuTooltipText('Connection — stats & MJPEG quality'),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(999),
                    onTap: () => controller.isOpen ? controller.close() : controller.open(),
                    child: pill,
                  ),
                ),
              );
            },
          );
        },
      );

  static const _stopRed = Color(0xFFEF4444);

  Widget _remoteStopBtn({required VoidCallback? onPressed}) => uiIconButton(
        tooltip: 'Stop remote session',
        onPressed: onPressed,
        icon: const Icon(Icons.stop_rounded, size: 20, color: _stopRed),
        style: IconButton.styleFrom(
          backgroundColor: Colors.transparent,
          disabledBackgroundColor: Colors.transparent,
          foregroundColor: _stopRed,
          minimumSize: const Size(32, 32),
          padding: EdgeInsets.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          shape: const RoundedRectangleBorder(),
        ),
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

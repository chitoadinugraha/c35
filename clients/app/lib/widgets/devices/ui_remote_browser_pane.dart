import 'package:alienai_c35/c/remote/device_prompt_context.dart';
import 'package:alienai_c35/c/remote/remote_session.dart';
import 'package:alienai_c35/widgets/devices/ui_browser_tab_strip.dart';
import 'package:alienai_c35/widgets/devices/ui_remote_device.dart';
import 'package:alienai_c35/widgets/devices/ui_remote_teach_hud.dart';
import 'package:flutter/material.dart';

const _muted = Color(0xFF71717A);

/// Browser Remote tab: tab strip + stream with one full-pane loading overlay.
class UiRemoteBrowserPane extends StatefulWidget {
  const UiRemoteBrowserPane({
    super.key,
    required this.session,
    required this.deviceIid,
    required this.deviceName,
    required this.online,
    required this.compact,
    required this.interactMode,
    required this.showStreamStats,
    required this.onInteractModeChanged,
    required this.onTeach,
    required this.onFullscreen,
    required this.immersive,
    required this.updateReady,
    required this.updateVersion,
    required this.onApplyUpdate,
    this.promptStore,
    required this.onStopTeach,
    this.androidRemote = false,
    this.onPresenceRefresh,
  });

  final RemoteSession session;
  final int deviceIid;
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
  final VoidCallback onApplyUpdate;
  final DevicePromptContextStore? promptStore;
  final VoidCallback onStopTeach;
  final bool androidRemote;
  final Future<void> Function()? onPresenceRefresh;

  @override
  State<UiRemoteBrowserPane> createState() => _UiRemoteBrowserPaneState();
}

class _UiRemoteBrowserPaneState extends State<UiRemoteBrowserPane> {
  var _tabsLoading = false;
  var _remoteShellBusy = false;
  String _remoteShellMessage = 'Loading...';

  bool get _showOverlay => _tabsLoading || _remoteShellBusy;

  @override
  Widget build(BuildContext context) => Stack(
        fit: StackFit.expand,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              UiBrowserTabStrip(
                session: widget.session,
                compact: widget.compact,
                onLoadingChanged: (loading) {
                  if (_tabsLoading == loading) return;
                  setState(() => _tabsLoading = loading);
                },
              ),
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    UiRemoteDevice(
                      session: widget.session,
                      promptStore: widget.promptStore,
                      deviceName: widget.deviceName,
                      online: widget.online,
                      browserDevice: true,
                      compact: widget.compact,
                      interactMode: widget.interactMode,
                      showStreamStats: widget.showStreamStats,
                      onInteractModeChanged: widget.onInteractModeChanged,
                      onTeach: widget.onTeach,
                      onFullscreen: widget.onFullscreen,
                      immersive: widget.immersive,
                      updateReady: widget.updateReady,
                      updateVersion: widget.updateVersion,
                      onApplyUpdate: widget.onApplyUpdate,
                      deferInlineLoading: true,
                      onPresenceRefresh: widget.onPresenceRefresh,
                      onShellBusyChanged: (busy, message) {
                        if (_remoteShellBusy == busy && _remoteShellMessage == message) return;
                        setState(() {
                          _remoteShellBusy = busy;
                          _remoteShellMessage = message;
                        });
                      },
                    ),
                    UiRemoteTeachHud(
                      session: widget.session,
                      deviceIid: widget.deviceIid,
                      onStop: widget.onStopTeach,
                      androidRemote: widget.androidRemote,
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_showOverlay)
            Positioned.fill(
              child: ColoredBox(
                color: const Color(0xE609090B),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(
                        width: 28,
                        height: 28,
                        child: CircularProgressIndicator(strokeWidth: 2.5, color: _muted),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        _tabsLoading && !_remoteShellBusy ? 'Loading browser tabs...' : _remoteShellMessage,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: _muted, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      );
}

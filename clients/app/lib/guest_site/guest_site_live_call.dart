import 'dart:async';

import 'package:alienai_c35/c/live/live_call_session.dart';
import 'package:alienai_c35/c/site/guest_assistant_api.dart';
import 'package:alienai_c35/c/stt/stt_mic_permission.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

enum GuestSiteLiveCallState {
  idle,
  connecting,
  active,
  error,
}

class GuestSiteLiveCallController extends ChangeNotifier {
  GuestSiteLiveCallController({LiveCallSession? session})
      : _session = session ?? LiveCallSession(),
        _ownsSession = session == null {
    _session.speakerOn.addListener(_onSessionStateChanged);
    _session.micMuted.addListener(_onSessionStateChanged);
    _session.caption.addListener(_onSessionStateChanged);
  }

  final LiveCallSession _session;
  final bool _ownsSession;
  LiveCallSession get session => _session;

  GuestSiteLiveCallState _state = GuestSiteLiveCallState.idle;
  GuestSiteLiveCallState get state => _state;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  int _callSeconds = 0;
  int get callSeconds => _callSeconds;

  Timer? _timer;
  VoidCallback? _errorListener;
  VoidCallback? _connectedListener;

  bool get isSpeakerOn => _session.speakerOn.value;
  bool get isMuted => _session.micMuted.value;
  LiveCaption? get caption => _session.caption.value;

  void _onSessionStateChanged() {
    notifyListeners();
  }

  void _hookSessionListeners() {
    _unhookSessionListeners();
    _errorListener = () {
      final err = _session.error.value;
      if (err != null && _state == GuestSiteLiveCallState.active) {
        _state = GuestSiteLiveCallState.error;
        _errorMessage = err;
        _timer?.cancel();
        notifyListeners();
      }
    };
    _connectedListener = () {
      if (!_session.connected.value && _state == GuestSiteLiveCallState.active) {
        final err = _session.error.value;
        _errorMessage = err ?? LiveCallSession.disconnectedError;
        _state = GuestSiteLiveCallState.error;
        _timer?.cancel();
        notifyListeners();
      }
    };
    _session.error.addListener(_errorListener!);
    _session.connected.addListener(_connectedListener!);
  }

  void _unhookSessionListeners() {
    if (_errorListener != null) {
      _session.error.removeListener(_errorListener!);
      _errorListener = null;
    }
    if (_connectedListener != null) {
      _session.connected.removeListener(_connectedListener!);
      _connectedListener = null;
    }
  }

  Future<void> start({
    required int siteIid,
    required String bootMode,
    http.Client? client,
  }) async {
    if (_state == GuestSiteLiveCallState.connecting || _state == GuestSiteLiveCallState.active) {
      return;
    }
    _state = GuestSiteLiveCallState.connecting;
    _errorMessage = null;
    _callSeconds = 0;
    notifyListeners();

    try {
      final micGranted = await sttMicPermissionEnsure();
      if (!micGranted) {
        throw StateError(sttMicErrorMessage());
      }

      if (kIsWeb) {
        await _session.unlockWebAudioPlayback();
      }

      final visitorId = await GuestAssistantApi.visitorIdForSite(siteIid);
      final setup = await GuestAssistantApi.liveSetup(
        siteIid: siteIid,
        visitorId: visitorId,
        bootMode: bootMode,
        client: client,
      );

      _hookSessionListeners();
      await _session.connectGuest(setup.wsPath);

      _state = GuestSiteLiveCallState.active;
      _timer?.cancel();
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        _callSeconds++;
        notifyListeners();
      });
      notifyListeners();
    } catch (e) {
      _state = GuestSiteLiveCallState.error;
      if (e is StateError) {
        _errorMessage = e.message;
      } else {
        _errorMessage = e.toString().replaceFirst(RegExp(r'^(Exception|StateError|Bad state):\s*'), '');
      }
      _timer?.cancel();
      try {
        await _session.disconnect();
      } catch (_) {}
      notifyListeners();
    }

  }

  Future<void> endCall() async {
    _timer?.cancel();
    _unhookSessionListeners();
    try {
      await _session.hangup();
    } catch (_) {}
    _state = GuestSiteLiveCallState.idle;
    _errorMessage = null;
    _callSeconds = 0;
    notifyListeners();
  }

  void dismissError() {
    _timer?.cancel();
    _unhookSessionListeners();
    _state = GuestSiteLiveCallState.idle;
    _errorMessage = null;
    _callSeconds = 0;
    notifyListeners();
  }

  Future<void> toggleSpeaker() async {
    await _session.toggleSpeaker();
    notifyListeners();
  }

  void toggleMute() {
    _session.toggleMicMute();
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _unhookSessionListeners();
    _session.speakerOn.removeListener(_onSessionStateChanged);
    _session.micMuted.removeListener(_onSessionStateChanged);
    _session.caption.removeListener(_onSessionStateChanged);
    if (_ownsSession) {
      _session.dispose();
    }
    super.dispose();
  }
}

class GuestSiteLiveCallOverlay extends StatelessWidget {
  const GuestSiteLiveCallOverlay({
    super.key,
    required this.controller,
    required this.intro,
  });

  final GuestSiteLiveCallController controller;
  final String intro;

  static String formatDuration(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        if (controller.state == GuestSiteLiveCallState.idle) {
          return const SizedBox.shrink();
        }

        final title = intro.trim().isEmpty ? 'Alien AI call' : intro.trim();

        Widget content;
        switch (controller.state) {
          case GuestSiteLiveCallState.connecting:
            content = Column(
              key: const Key('guest-live-call-connecting'),
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 48,
                  height: 48,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Connecting...',
                  style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 32),
                FilledButton(
                  key: const Key('guest-live-call-cancel'),
                  style: FilledButton.styleFrom(backgroundColor: Colors.white24),
                  onPressed: controller.endCall,
                  child: const Text('Cancel'),
                ),
              ],
            );
            break;

          case GuestSiteLiveCallState.active:
            final cap = controller.caption?.text.trim();
            content = Column(
              key: const Key('guest-live-call-active'),
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.volume_up, size: 48, color: Colors.white),
                const SizedBox(height: 16),
                Text(
                  formatDuration(controller.callSeconds),
                  style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Text(
                  (cap != null && cap.isNotEmpty) ? cap : title,
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton.filledTonal(
                      key: const Key('guest-live-call-speaker'),
                      icon: Icon(controller.isSpeakerOn ? Icons.volume_up : Icons.volume_off),
                      onPressed: controller.toggleSpeaker,
                      tooltip: controller.isSpeakerOn ? 'Speaker on' : 'Speaker off',
                    ),
                    const SizedBox(width: 24),
                    IconButton.filledTonal(
                      key: const Key('guest-live-call-mute'),
                      icon: Icon(controller.isMuted ? Icons.mic_off : Icons.mic),
                      onPressed: controller.toggleMute,
                      tooltip: controller.isMuted ? 'Unmute' : 'Mute',
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                FilledButton(
                  key: const Key('guest-live-call-end'),
                  style: FilledButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
                  onPressed: controller.endCall,
                  child: const Text('End call'),
                ),
              ],
            );
            break;

          case GuestSiteLiveCallState.error:
            content = Column(
              key: const Key('guest-live-call-error'),
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Color(0xFFEF4444)),
                const SizedBox(height: 16),
                const Text(
                  'Call Error',
                  style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Text(
                  controller.errorMessage ?? 'Call disconnected',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 32),
                FilledButton(
                  key: const Key('guest-live-call-dismiss'),
                  style: FilledButton.styleFrom(backgroundColor: Colors.white24),
                  onPressed: controller.dismissError,
                  child: const Text('Close'),
                ),
              ],
            );
            break;

          case GuestSiteLiveCallState.idle:
            return const SizedBox.shrink();
        }

        return Positioned.fill(
          child: Material(
            color: Colors.black87,
            child: SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: content,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Lightweight busy flags for app update gating without importing WebRTC / live sessions.
class SessionBusyRegistry {
  SessionBusyRegistry._();

  static bool liveCallActive = false;
  static bool remoteControlActive = false;

  static bool get anyHeavySessionActive => liveCallActive || remoteControlActive;
}

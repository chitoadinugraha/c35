# Remote browser - stabilize WebRTC + Chrome-like UI

> For agents: Dispatch one Task per track (model inherit).
> Spec: _/docs/browser-remote.md, _/docs/remote.md

**Goal:** Devices -> Chito Browser -> Remote shows compact Chrome-style tabs + address bar and a live stream when presence dots are green.

## Symptoms

- Both dots green but Screen stream idle + Connect: often `connected` true but `hasVideoTrack` false (ui_remote_device.dart ~1078).
- Tab UI: Tabs header + tall chips; user wants inline Chrome tabs with + and refresh.
- No address bar; worker has navigate but Rust/app do not expose it.

## Waves

| Wave | Tracks | Criterion |
|------|--------|-----------|
| RB-SW1 Diagnose | D | Root cause matrix filled |
| RB-SW2 Stream | E, F | Video within 10s of Remote tab |
| RB-SW3 Chrome UI | G, H, I | Inline tabs + address bar navigates |
| RB-SW4 Verify | J | flutter analyze + manual checklist |

## Track D - Diagnose (first)

1. dev_server + dev_browser + app 127.0.0.1:8080
2. Log: RemoteSession connected/hasVideoTrack; agent WEBRTC CONNECTED, screencast resumed, H.264 logs
3. MCP device_log_tail 99000 / Chito Browser iid
4. Matrix: ICE vs idle screencast vs encoder failure

## Track E - Agent video

- browser_idle.rs: screencast on session create or on PC connected
- browser_video.rs: MF failure -> SCTP fallback or clear warn
- cargo build -p c_remote_browser

## Track F - App + dev

- dev_browser -SctpScreen fallback doc
- Placeholder: Waiting for video when connected && !hasVideoTrack
- Audit duplicate start() in ui_device_detail.dart

## Track G - Tab strip UI

- Remove Remote browser info banner (ui_device_detail.dart)
- Remove Tabs header; 32px horizontal strip; + and refresh inline end
- ui_browser_tab_strip.dart

## Track H - navigate RPC

- browser_command.rs method navigate -> worker navigate

## Track I - Address bar Flutter

- TextField + submit -> browserInvoke navigate; sync URL from active tab

## Track J - Verify

- Login persists slots/default; optional publish_server for browser.* tools

## Order

D -> (E parallel F) -> G -> H -> I -> J
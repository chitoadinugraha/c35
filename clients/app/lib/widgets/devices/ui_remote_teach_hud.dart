import 'dart:async';

import 'package:alienai_c35/c/remote/remote_session.dart';
import 'package:alienai_c35/c/settings/remote_prefs.dart';
import 'package:flutter/material.dart';

const _border = Color(0xFF27272A);
const _text = Color(0xFFF4F4F5);
const _muted = Color(0xFF71717A);
const _rec = Color(0xFFEF4444);

bool remoteDeviceTypeIsAndroid(String deviceType) => deviceType.toLowerCase() == 'android';

/// Snackbar after teach starts (viewer app).
String remoteTeachRecordingSnackMessage(String title, {required bool androidRemote}) {
  if (androidRemote) {
    return 'Recording "$title" — tap Stop when you are done. On the phone, use the notification or volume keys (no F9).';
  }
  return 'Recording "$title" — use Stop on the HUD or F9 on the PC.';
}

/// Short hint shown on the in-session teach HUD while recording.
String remoteTeachHudStopHint({required bool androidRemote}) {
  if (androidRemote) {
    return 'On the phone: notification or volume keys also stop recording.';
  }
  return 'F9 on the PC also stops recording.';
}

class UiRemoteTeachHud extends StatefulWidget {
  const UiRemoteTeachHud({
    super.key,
    required this.session,
    required this.deviceIid,
    required this.onStop,
    this.androidRemote = false,
  });

  final RemoteSession session;
  final int deviceIid;
  final VoidCallback onStop;
  final bool androidRemote;

  @override
  State<UiRemoteTeachHud> createState() => _UiRemoteTeachHudState();
}

class _UiRemoteTeachHudState extends State<UiRemoteTeachHud> {
  Offset? _pos;
  var _prefsLoaded = false;
  var _expanded = false;

  @override
  void initState() {
    super.initState();
    unawaited(_loadPos());
  }

  Future<void> _loadPos() async {
    await RemotePrefs.instance.load();
    final saved = RemotePrefs.instance.teachHudOffset(widget.deviceIid);
    if (mounted) {
      setState(() {
        _pos = saved;
        _prefsLoaded = true;
      });
    }
  }

  String _formatDuration(int sec) {
    final m = sec ~/ 60;
    final s = sec % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    if (!_prefsLoaded) return const SizedBox.shrink();
    final size = MediaQuery.sizeOf(context);
    final resolved = _pos ?? Offset((size.width - 280).clamp(8.0, size.width - 8), 12);
    final listenable = widget.session.teachListenable;
    if (listenable == null) return const SizedBox.shrink();
    return ListenableBuilder(
      listenable: listenable,
      builder: (context, _) {
        final recording = widget.session.teachRecording?.value ?? false;
        if (!recording) return const SizedBox.shrink();
        final steps = widget.session.teachSteps?.value ?? const [];
        final last = widget.session.teachLastLabel?.value ?? '';
        final dur = widget.session.teach?.durationSec.value ?? 0;
        final lastPreview = last.isEmpty ? '-' : (last.length > 36 ? '${last.substring(0, 36)}...' : last);
        return Positioned(
          left: resolved.dx,
          top: resolved.dy,
          child: GestureDetector(
            onPanUpdate: (d) {
              final next = Offset(
                (resolved.dx + d.delta.dx).clamp(0.0, size.width - 40),
                (resolved.dy + d.delta.dy).clamp(0.0, size.height - 40),
              );
              setState(() => _pos = next);
              unawaited(RemotePrefs.instance.setTeachHudOffset(widget.deviceIid, next));
            },
            child: Material(
              elevation: 8,
              color: const Color(0xE6111114),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 280,
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(color: _rec, shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'REC ${_formatDuration(dur)} · ${steps.length} steps',
                            style: const TextStyle(color: _text, fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ),
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                          onPressed: () => setState(() => _expanded = !_expanded),
                          icon: Icon(_expanded ? Icons.expand_less : Icons.expand_more, size: 18, color: _muted),
                        ),
                      ],
                    ),
                    Text(lastPreview, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: _muted, fontSize: 11)),
                    if (_expanded && steps.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 140),
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: steps.length,
                          itemBuilder: (_, i) {
                            final s = steps[i];
                            final label = s.label.isNotEmpty ? s.label : s.kind;
                            return Text('${s.ord}. $label', style: const TextStyle(color: Color(0xFFE4E4E7), fontSize: 11));
                          },
                        ),
                      ),
                    ],
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        remoteTeachHudStopHint(androidRemote: widget.androidRemote),
                        style: const TextStyle(color: _muted, fontSize: 10, height: 1.35),
                      ),
                    ),
                    const SizedBox(height: 10),
                    FilledButton(
                      onPressed: widget.onStop,
                      style: FilledButton.styleFrom(backgroundColor: _rec, foregroundColor: Colors.white, minimumSize: const Size.fromHeight(36)),
                      child: const Text('Stop'),
                    ),
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
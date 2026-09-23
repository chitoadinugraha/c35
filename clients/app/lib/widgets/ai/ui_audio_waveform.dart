import 'dart:math';
import 'package:alienai_c35/widgets/ui/ui_tooltip.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class UiAudioWaveform extends StatefulWidget {
  const UiAudioWaveform({
    super.key,
    required this.recordingSeconds,
    required this.amplitude,
    required this.onCancel,
    required this.onCommit,
  });

  final ValueListenable<int> recordingSeconds;
  final ValueListenable<double> amplitude;
  final VoidCallback onCancel;
  final VoidCallback onCommit;

  @override
  State<UiAudioWaveform> createState() => _UiAudioWaveformState();
}

class _UiAudioWaveformState extends State<UiAudioWaveform> with SingleTickerProviderStateMixin {
  static const _accent = Color(0xFF06B6D4);
  static const _red = Color(0xFFEF4444);

  late final AnimationController _animCtrl;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  String _formatDuration(int sec) {
    final m = (sec ~/ 60).toString().padLeft(2, '0');
    final s = (sec % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF0284C7).withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          // Cancel button
          uiIconButton(
            tooltip: 'Cancel recording',
            icon: const Icon(Icons.close_rounded, size: 16, color: _red),
            onPressed: widget.onCancel,
          ),
          const SizedBox(width: 8),
          // Timer & Pulsing Dot
          ValueListenableBuilder<int>(
            valueListenable: widget.recordingSeconds,
            builder: (ctx, sec, _) => Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: _red,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  _formatDuration(sec),
                  style: const TextStyle(
                    fontFamily: 'Consolas',
                    color: Color(0xFFF4F4F5),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Waveform
          Expanded(
            child: AnimatedBuilder(
              animation: _animCtrl,
              builder: (ctx, _) {
                final amp = widget.amplitude.value;
                final t = _animCtrl.value * 2 * pi;

                return SizedBox(
                  height: 28,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(24, (i) {
                      final wave = (sin(t + i * 0.4) + 1) / 2;
                      final h = (6 + (amp * 20) * (0.3 + 0.7 * wave)).clamp(4.0, 26.0);

                      return Container(
                        width: 3,
                        height: h,
                        decoration: BoxDecoration(
                          color: _accent.withValues(alpha: 0.6 + 0.4 * wave),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      );
                    }),
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 12),
          // Commit / Stop button
          ElevatedButton(
            onPressed: widget.onCommit,
            style: ElevatedButton.styleFrom(
              backgroundColor: _accent,
              foregroundColor: Colors.black,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              minimumSize: Size.zero,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_rounded, size: 15),
                SizedBox(width: 4),
                Text('Done', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

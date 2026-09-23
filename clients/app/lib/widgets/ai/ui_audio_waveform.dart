import 'dart:math';

import 'package:alienai_c35/c/settings/voice_prefs.dart';
import 'package:alienai_c35/widgets/ui/ui_tooltip.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class UiAudioWaveform extends StatefulWidget {
  const UiAudioWaveform({
    super.key,
    required this.recordingSeconds,
    required this.amplitude,
    this.amplitudeHistory,
    this.liveTranscript,
    this.isTranscribing,
    this.engine,
    required this.onCancel,
    required this.onCommit,
  });

  final ValueListenable<int> recordingSeconds;
  final ValueListenable<double> amplitude;
  final ValueListenable<List<double>>? amplitudeHistory;
  final ValueListenable<String>? liveTranscript;
  final ValueListenable<bool>? isTranscribing;
  final String? engine;
  final VoidCallback onCancel;
  final VoidCallback onCommit;

  @override
  State<UiAudioWaveform> createState() => _UiAudioWaveformState();
}

class _UiAudioWaveformState extends State<UiAudioWaveform> with SingleTickerProviderStateMixin {
  static const _red = Color(0xFFEF4444);
  static const _zinc100 = Color(0xFFF4F4F5);
  static const _zinc400 = Color(0xFFA1A1AA);
  static const _zinc500 = Color(0xFF71717A);

  late final AnimationController _animCtrl;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
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
    final engine = widget.engine ?? VoicePrefs.instance.sttEngine;
    final engineIcon = switch (engine) {
      'cloud' => Icons.cloud_outlined,
      'local' => Icons.devices_outlined,
      _ => Icons.language_outlined,
    };

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Live transcript or recognizing status preview row
        if (widget.liveTranscript != null || widget.isTranscribing != null)
          ValueListenableBuilder<bool>(
            valueListenable: widget.isTranscribing ?? ValueNotifier(false),
            builder: (ctx, transcribing, _) {
              return ValueListenableBuilder<String>(
                valueListenable: widget.liveTranscript ?? ValueNotifier(''),
                builder: (ctx, transcript, _) {
                  if (!transcribing && transcript.trim().isEmpty) {
                    return const SizedBox.shrink();
                  }
                  return Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF27272A).withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        if (transcribing) ...[
                          const SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(strokeWidth: 1.5, color: _zinc400),
                          ),
                          const SizedBox(width: 8),
                          Icon(engineIcon, size: 14, color: _zinc400),
                          const SizedBox(width: 5),
                          const Text(
                            'Recognizing…',
                            style: TextStyle(color: _zinc400, fontSize: 12, fontStyle: FontStyle.italic),
                          ),
                        ] else ...[
                          const Icon(Icons.record_voice_over_rounded, size: 13, color: _zinc400),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              transcript,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: _zinc100,
                                fontSize: 13,
                                height: 1.25,
                              ),
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

        // Main recording row
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF18181B),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              // Cancel / Delete button
              uiIconButton(
                tooltip: 'Cancel recording',
                icon: const Icon(Icons.close_rounded, size: 18, color: _red),
                onPressed: widget.onCancel,
              ),
              const SizedBox(width: 8),

              // Pulsing recording dot & Monospace timer (00:03 / 00:30)
              ValueListenableBuilder<int>(
                valueListenable: widget.recordingSeconds,
                builder: (ctx, sec, _) => Row(
                  children: [
                    FadeTransition(
                      opacity: Tween<double>(begin: 0.35, end: 1.0).animate(_animCtrl),
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: _red,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _formatDuration(sec),
                      style: const TextStyle(
                        fontFamily: 'Consolas',
                        color: _zinc100,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 2),
                    const Text(
                      '/ 00:30',
                      style: TextStyle(
                        fontFamily: 'Consolas',
                        color: _zinc500,
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),

              // Dynamic animated scrolling waveform (WhatsApp / Telegram style)
              Expanded(
                child: SizedBox(
                  height: 28,
                  child: AnimatedBuilder(
                    animation: _animCtrl,
                    builder: (ctx, _) {
                      return ValueListenableBuilder<List<double>>(
                        valueListenable: widget.amplitudeHistory ?? ValueNotifier(const []),
                        builder: (ctx, history, _) {
                          return CustomPaint(
                            painter: _TelegramWaveformPainter(
                              samples: history,
                              currentAmplitude: widget.amplitude.value,
                              animValue: _animCtrl.value,
                            ),
                            size: Size.infinite,
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Stop & Send action button (matching chat send button)
              ValueListenableBuilder<bool>(
                valueListenable: widget.isTranscribing ?? ValueNotifier(false),
                builder: (ctx, transcribing, _) {
                  if (transcribing) {
                    return Container(
                      width: 32,
                      height: 32,
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Color(0xFF27272A),
                        shape: BoxShape.circle,
                      ),
                      child: const CircularProgressIndicator(strokeWidth: 2, color: _zinc400),
                    );
                  }
                  return uiTooltip(
                    message: 'Finish recording',
                    child: Material(
                      color: _zinc100,
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: widget.onCommit,
                        child: const Padding(
                          padding: EdgeInsets.all(7),
                          child: Icon(Icons.arrow_upward_rounded, size: 17, color: Color(0xFF18181B)),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Dynamic scrolling waveform painter modeled after WhatsApp & Telegram voice messages.
class _TelegramWaveformPainter extends CustomPainter {
  _TelegramWaveformPainter({
    required this.samples,
    required this.currentAmplitude,
    required this.animValue,
  });

  final List<double> samples;
  final double currentAmplitude;
  final double animValue;

  static const double barWidth = 3.0;
  static const double barGap = 2.0;
  static const double minBarHeight = 4.0;
  static const double maxBarHeight = 24.0;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final centerY = size.height / 2;
    final totalBarStep = barWidth + barGap;
    final maxBars = (size.width / totalBarStep).floor();
    if (maxBars <= 0) return;

    final displaySamples = List<double>.from(samples);
    while (displaySamples.length < maxBars) {
      displaySamples.insert(0, 0.0);
    }
    final activeSlice = displaySamples.sublist(displaySamples.length - maxBars);

    final paint = Paint()
      ..style = PaintingStyle.fill
      ..strokeCap = StrokeCap.round;

    for (var i = 0; i < maxBars; i++) {
      var amp = activeSlice[i].clamp(0.0, 1.0);
      // If audio is quiet or silence, generate subtle breathing wave so bars are always visibly moving
      if (amp < 0.1) {
        final wave = sin((i * 0.35) + (animValue * 2 * pi)) * 0.5 + 0.5;
        amp = (wave * 0.18).clamp(0.04, 0.22);
      }
      final h = (minBarHeight + (amp * (maxBarHeight - minBarHeight))).clamp(minBarHeight, maxBarHeight);
      final x = i * totalBarStep;
      final top = centerY - (h / 2);

      final progressFromLeft = i / maxBars;
      final alpha = (progressFromLeft < 0.15 ? (progressFromLeft / 0.15) : 1.0).clamp(0.25, 1.0);

      final colorVal = Color.lerp(const Color(0xFFA1A1AA), const Color(0xFFF4F4F5), amp)!;
      paint.color = colorVal.withValues(alpha: alpha);

      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, top, barWidth, h),
        const Radius.circular(barWidth / 2),
      );
      canvas.drawRRect(rect, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _TelegramWaveformPainter oldDelegate) => true;
}

import 'dart:math';

import 'package:alienai_c35/c/settings/voice_prefs.dart';
import 'package:alienai_c35/c/stt/stt_service.dart';
import 'package:alienai_c35/widgets/ui/ui_tooltip.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class UiAudioWaveform extends StatefulWidget {
  const UiAudioWaveform({
    super.key,
    required this.recordingSeconds,
    required this.amplitude,
    this.amplitudeHistory,
    this.liveTranscript,
    this.isLiveInterim,
    this.isTranscribing,
    this.isPreparing,
    this.engine,
    required this.onCancel,
    required this.onCommit,
  });

  final ValueListenable<int> recordingSeconds;
  final ValueListenable<double> amplitude;
  final ValueListenable<List<double>>? amplitudeHistory;
  final ValueListenable<String>? liveTranscript;
  final ValueListenable<bool>? isLiveInterim;
  final ValueListenable<bool>? isTranscribing;
  final ValueListenable<bool>? isPreparing;
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

  bool get _useDecorativeWave {
    final engine = widget.engine ?? VoicePrefs.instance.sttEngine;
    return engine == 'web';
  }

  @override
  Widget build(BuildContext context) {
    final engine = widget.engine ?? VoicePrefs.instance.sttEngine;
    final engineIcon = switch (engine) {
      'cloud' => Icons.cloud_outlined,
      'local' => Icons.devices_outlined,
      _ => Icons.language_outlined,
    };

    final transcribingListenable = widget.isTranscribing ?? ValueNotifier(false);
    final preparingListenable = widget.isPreparing ?? ValueNotifier(false);

    return ValueListenableBuilder<bool>(
      valueListenable: preparingListenable,
      builder: (ctx, preparing, _) {
        if (preparing) {
          return _preparingPanel(engineIcon);
        }
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.liveTranscript != null || widget.isTranscribing != null)
              ValueListenableBuilder<bool>(
                valueListenable: transcribingListenable,
                builder: (ctx, transcribing, _) {
                  return ValueListenableBuilder<bool>(
                    valueListenable: widget.isLiveInterim ?? SttService.instance.isLiveInterim,
                    builder: (ctx, isInterim, _) {
                      return ValueListenableBuilder<String>(
                        valueListenable: widget.liveTranscript ?? ValueNotifier(''),
                        builder: (ctx, transcript, _) {
                          final hasText = transcript.trim().isNotEmpty;
                          if (!transcribing && !hasText) {
                            return Container(
                              margin: const EdgeInsets.only(bottom: 6),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF18181B),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: const Color(0xFF27272A)),
                              ),
                              child: Row(
                                children: [
                                  Icon(engineIcon, size: 14, color: _zinc400),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'composer.listening'.tr(),
                                      style: const TextStyle(color: _zinc400, fontSize: 13, fontStyle: FontStyle.italic),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }
                          final isConfirmed = !isInterim && !transcribing;
                          return Container(
                            margin: const EdgeInsets.only(bottom: 6),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: const Color(0xFF18181B),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: const Color(0xFF27272A),
                              ),
                            ),
                            child: Text(
                              hasText
                                  ? (isConfirmed ? transcript : '$transcript…')
                                  : 'composer.listening'.tr(),
                              maxLines: 4,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: isConfirmed ? _zinc100 : _zinc400,
                                fontSize: 13.5,
                                fontStyle: isConfirmed ? FontStyle.normal : FontStyle.italic,
                                fontWeight: isConfirmed ? FontWeight.w500 : FontWeight.w400,
                                height: 1.35,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            _recordingRow(transcribingListenable),
          ],
        );
      },
    );
  }

  Widget _preparingPanel(IconData engineIcon) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF18181B),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            uiIconButton(
              tooltip: 'Cancel',
              icon: const Icon(Icons.close_rounded, size: 18, color: _red),
              onPressed: widget.onCancel,
            ),
            const SizedBox(width: 10),
            Icon(engineIcon, size: 16, color: _zinc400),
            const SizedBox(width: 8),
            const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2, color: _zinc400),
            ),
            const SizedBox(width: 8),
            Text(
              'composer.preparing'.tr(),
              style: const TextStyle(color: _zinc400, fontSize: 13, fontStyle: FontStyle.italic),
            ),
          ],
        ),
      );

  Widget _recordingRow(ValueListenable<bool> transcribingListenable) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF18181B),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            ValueListenableBuilder<bool>(
              valueListenable: transcribingListenable,
              builder: (ctx, transcribing, _) {
                if (transcribing) return const SizedBox.shrink();
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    uiIconButton(
                      tooltip: 'Cancel recording',
                      icon: const Icon(Icons.close_rounded, size: 18, color: _red),
                      onPressed: widget.onCancel,
                    ),
                    const SizedBox(width: 8),
                  ],
                );
              },
            ),
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
            Expanded(
              child: SizedBox(
                height: 28,
                child: _useDecorativeWave
                    ? _DecorativeWave(anim: _animCtrl)
                    : AnimatedBuilder(
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
            const SizedBox(width: 6),
            ListenableBuilder(
              listenable: VoicePrefs.instance,
              builder: (ctx, _) {
                return ValueListenableBuilder<bool>(
                  valueListenable: transcribingListenable,
                  builder: (ctx, transcribing, _) {
                    if (transcribing) return const SizedBox.shrink();
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: Checkbox(
                            value: VoicePrefs.instance.sttAutoSend,
                            onChanged: (v) => VoicePrefs.instance.setSttAutoSend(v ?? false),
                            activeColor: const Color(0xFF34D399),
                            side: const BorderSide(color: _zinc500),
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => VoicePrefs.instance.setSttAutoSend(!VoicePrefs.instance.sttAutoSend),
                          child: Padding(
                            padding: const EdgeInsets.only(left: 2, right: 4),
                            child: Text(
                              'composer.autoSend'.tr(),
                              style: const TextStyle(color: _zinc400, fontSize: 11, fontWeight: FontWeight.w500),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
            const SizedBox(width: 4),
            ValueListenableBuilder<bool>(
              valueListenable: transcribingListenable,
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
                  message: 'composer.finishRecording'.tr(),
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
      );
}

/// CSA-style decorative bars — not tied to mic amplitude (Web Speech has no level API).
class _DecorativeWave extends StatelessWidget {
  const _DecorativeWave({required this.anim});

  final Animation<double> anim;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: anim,
        builder: (ctx, _) => Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: List.generate(12, (i) {
            final t = (sin((i * 0.55) + (anim.value * 2 * pi)) * 0.5 + 0.5);
            final h = 4 + t * 16;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 1.5),
              child: Container(
                width: 3,
                height: h,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  color: Color.lerp(const Color(0xFFA1A1AA), const Color(0xFFF4F4F5), t),
                ),
              ),
            );
          }),
        ),
      );
}

/// Dynamic scrolling waveform with perceptual dynamic range and idle breathing.
class _TelegramWaveformPainter extends CustomPainter {
  _TelegramWaveformPainter({
    required this.samples,
    required this.currentAmplitude,
    required this.animValue,
  });

  final List<double> samples;
  final double currentAmplitude;
  final double animValue;

  static const double barWidth = 2.5;
  static const double barGap = 2.0;
  static const double minBarHeight = 3.5;
  static const double maxBarHeight = 22.0;

  static double _shapeAmplitude(double amp) {
    if (amp < 0.012) return 0.0;
    // Compress conversational audio levels (0.02 - 0.28) into vibrant, responsive heights
    final normalized = ((amp - 0.012) / 0.28).clamp(0.0, 1.0);
    return pow(normalized, 0.55).toDouble();
  }

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
      final amp = _shapeAmplitude(activeSlice[i]);
      // Idle harmonic wave so silent bars gently breathe instead of looking like dead dots
      final idleWave = sin((i * 0.35) + (animValue * 2 * pi)) * 0.5 + 0.5;
      final h = amp <= 0
          ? (minBarHeight + idleWave * 1.5)
          : (minBarHeight + (amp * (maxBarHeight - minBarHeight))).clamp(minBarHeight, maxBarHeight);
      final x = i * totalBarStep;
      final top = centerY - (h / 2);

      // Smooth opacity fade on the leftmost edge
      final progressFromLeft = i / maxBars;
      final alpha = (progressFromLeft < 0.12 ? (progressFromLeft / 0.12) : 1.0).clamp(0.25, 1.0);

      final Color colorVal;
      if (amp <= 0) {
        colorVal = Color.lerp(const Color(0xFF3F3F46), const Color(0xFF52525B), idleWave)!;
      } else if (amp > 0.65) {
        colorVal = Color.lerp(const Color(0xFFF4F4F5), const Color(0xFF34D399), (amp - 0.65) / 0.35)!;
      } else {
        colorVal = Color.lerp(const Color(0xFFA1A1AA), const Color(0xFFF4F4F5), amp)!;
      }
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

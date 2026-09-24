import 'package:alienai_c35/c/tts/speech_lang.dart';
import 'package:alienai_c35/c/tts/tts_service.dart';
import 'package:alienai_c35/widgets/ui/ui_tooltip.dart';
import 'package:flutter/material.dart';

/// Pulsing speak control — visible only while TTS is playing. Tap to stop.
class UiSpeakIndicator extends StatelessWidget {
  const UiSpeakIndicator({super.key});

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<bool>(
        valueListenable: TtsService.instance.isSpeaking,
        builder: (context, speaking, _) {
          if (!speaking) return const SizedBox.shrink();
          return ValueListenableBuilder<String>(
            valueListenable: TtsService.instance.speakingLang,
            builder: (context, lang, _) => _SpeakPulse(lang: lang),
          );
        },
      );
}

class _SpeakPulse extends StatefulWidget {
  const _SpeakPulse({required this.lang});
  final String lang;
  @override
  State<_SpeakPulse> createState() => _SpeakPulseState();
}

class _SpeakPulseState extends State<_SpeakPulse> with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 700))..repeat(reverse: true);

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => uiTooltip(
        message: 'Tap to stop',
        child: GestureDetector(
          onTap: TtsService.instance.stop,
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: FadeTransition(
              opacity: Tween<double>(begin: 0.45, end: 1).animate(_pulse),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.graphic_eq_rounded, size: 14, color: Color(0xFF22C55E)),
                const SizedBox(width: 4),
                Text('Speaking in ${speechLangLabel(widget.lang)}...', style: const TextStyle(color: Color(0xFF22C55E), fontSize: 11, fontWeight: FontWeight.w600, height: 1, letterSpacing: 0.2)),
              ]),
            ),
          ),
        ),
      );
}

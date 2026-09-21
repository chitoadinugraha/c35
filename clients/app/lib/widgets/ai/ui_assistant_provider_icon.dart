import 'package:alienai_c35/widgets/ai/ui_alien_icon.dart';
import 'package:alienai_c35/widgets/ui/ui_icon.dart';
import 'package:flutter/material.dart';

String? assistantProviderIconifyId(String provider) => switch (provider) {
      'google' => 'simple-icons:googlegemini',
      'xai' => 'logos:grok-icon',
      'openai' => 'logos:openai-icon',
      'anthropic' => 'logos:claude-icon',
      'deepseek' => 'logos:deepseek-icon',
      'ollama' => 'simple-icons:ollama',
      'cloudflare' => 'simple-icons:cloudflare',
      'openrouter' => 'simple-icons:openrouter',
      _ => null,
    };

bool assistantProviderUsesLightTile(String provider) => provider == 'xai' || provider == 'openai';

bool assistantProviderRecolor(String provider) => switch (provider) {
      'google' || 'ollama' || 'cloudflare' || 'openrouter' || 'xai' => true,
      _ => false,
    };

Color? assistantProviderIconColor(String provider) => switch (provider) {
      'google' => const Color(0xFF38BDF8),
      'ollama' => const Color(0xFF34D399),
      'cloudflare' => const Color(0xFFF38020),
      'openrouter' => const Color(0xFFF4F4F5),
      'xai' => const Color(0xFF18181B),
      _ => null,
    };

class UiAssistantProviderIcon extends StatelessWidget {
  const UiAssistantProviderIcon({super.key, required this.provider, this.size = 18, this.dimmed = false, this.accent});

  final String provider;
  final double size;
  final bool dimmed;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    if (provider == 'alienai') {
      final color = dimmed ? Colors.white.withValues(alpha: 0.42) : Colors.white;
      return UiAlienIcon(size: size, color: color);
    }
    final iconId = assistantProviderIconifyId(provider);
    if (iconId == null) return Icon(Icons.memory, size: size * 0.9, color: accent ?? const Color(0xFFA1A1AA));
    final light = assistantProviderUsesLightTile(provider);
    final inner = size * (light ? 0.72 : 0.88);
    Widget icon = UiIcon(iconId, size: inner, recolor: assistantProviderRecolor(provider), color: assistantProviderIconColor(provider) ?? accent);
    if (light) {
      icon = Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: const Color(0xFFFAFAFA), borderRadius: BorderRadius.circular(size * 0.24)),
        child: icon,
      );
    } else {
      icon = SizedBox(width: size, height: size, child: Center(child: icon));
    }
    return Opacity(opacity: dimmed ? 0.42 : 1, child: icon);
  }
}

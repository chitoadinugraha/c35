import 'package:alienai_c35/c/generation/media_provider_labels.dart';
import 'package:alienai_c35/widgets/ai/ui_assistant_provider_icon.dart';
import 'package:flutter/material.dart';

class UiMediaProviderChip extends StatelessWidget {
  const UiMediaProviderChip({super.key, required this.kind, required this.providerId, this.onTap});

  final String kind;
  final String providerId;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    if (providerId.trim().isEmpty) return const SizedBox.shrink();
    final opt = mediaProviderOptionFind(kind, providerId);
    final iconProvider = opt?.iconProvider ?? '';
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (iconProvider.isNotEmpty)
                UiAssistantProviderIcon(provider: iconProvider, size: 14, accent: const Color(0xFF34D399))
              else
                Icon(Icons.auto_awesome_outlined, size: 14, color: Colors.white.withValues(alpha: 0.55)),
              const SizedBox(width: 5),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 200),
                child: Text(
                  mediaGeneratedWithLabel(kind, providerId),
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Color(0xFF34D399), fontSize: 12, fontWeight: FontWeight.w500),
                ),
              ),
              if (onTap != null) ...[
                const SizedBox(width: 3),
                Icon(Icons.keyboard_arrow_down_rounded, size: 14, color: const Color(0xFF34D399).withValues(alpha: 0.7)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

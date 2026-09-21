import 'package:alienai_c35/c/llm/agent_model.dart';
import 'package:alienai_c35/widgets/ai/ui_assistant_provider_icon.dart';
import 'package:flutter/material.dart';

export 'package:alienai_c35/widgets/ai/ui_assistant_model_sheet.dart' show agentModelPick, UiAssistantModelSheet;

class UiAssistantModelChip extends StatelessWidget {
  const UiAssistantModelChip({super.key, required this.model, this.onTap});

  final AgentModel model;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Material(
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
                UiAssistantProviderIcon(provider: model.provider, size: 14, accent: model.accent),
                const SizedBox(width: 5),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 140),
                  child: Text(
                    model.canThink ? '${model.chip} · ${model.thinking.label}' : model.chip,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: model.accent, fontSize: 12, fontWeight: FontWeight.w500, letterSpacing: 0.1),
                  ),
                ),
                const SizedBox(width: 3),
                Icon(Icons.keyboard_arrow_down_rounded, size: 14, color: model.accent.withValues(alpha: 0.7)),
              ],
            ),
          ),
        ),
      );
}

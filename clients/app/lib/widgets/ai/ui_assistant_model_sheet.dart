import 'package:alienai_c35/c/llm/agent_model.dart';
import 'package:alienai_c35/widgets/ai/ui_assistant_provider_icon.dart';
import 'package:alienai_c35/widgets/ui/ui_input_decoration.dart';
import 'package:alienai_c35/widgets/ui/ui_tooltip.dart';
import 'package:flutter/material.dart';

Future<AgentModel?> agentModelPick(BuildContext context, AgentModel current, List<AgentModel> models) {
  final rows = models.isEmpty ? AgentModel.fallback : models;
  return showModalBottomSheet<AgentModel>(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFF18181B),
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
    builder: (ctx) => UiAssistantModelSheet(current: current, models: rows),
  );
}

class UiAssistantModelSheet extends StatefulWidget {
  const UiAssistantModelSheet({super.key, required this.current, required this.models});

  final AgentModel current;
  final List<AgentModel> models;

  @override
  State<UiAssistantModelSheet> createState() => _UiAssistantModelSheetState();
}

class _UiAssistantModelSheetState extends State<UiAssistantModelSheet> {
  late final _searchCtrl = TextEditingController()..addListener(_onSearch);
  var _query = '';

  void _onSearch() => setState(() => _query = _searchCtrl.text);
  void _pick(AgentModel m, [AgentThinking? thinking]) => Navigator.of(context).pop(thinking == null ? m : m.copyWith(thinking: thinking));

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final items = agentModelFilter(widget.models, _query);
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.72),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(child: Container(width: 36, height: 4, decoration: BoxDecoration(color: const Color(0xFF3F3F46), borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: TextField(
                    controller: _searchCtrl,
                    autofocus: true,
                    style: const TextStyle(color: Color(0xFFF4F4F5), fontSize: 14),
                    decoration: UiInputDecoration.of(context, hintText: 'Search models…', prefixIcon: const Icon(Icons.search_rounded, size: 20)).copyWith(counter: null),
                  ),
                ),
                const SizedBox(height: 12),
                if (items.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Text('No models found', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF52525B))),
                  )
                else
                  Flexible(
                    child: ScrollConfiguration(
                      behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
                      child: Scrollbar(
                        child: ListView.builder(
                          shrinkWrap: true,
                          padding: const EdgeInsets.only(right: 8),
                          itemCount: items.length,
                          itemBuilder: (_, i) => _tile(items[i]),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _tile(AgentModel m) {
    final selected = m.id == widget.current.id;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: selected ? const Color(0xFF27272A) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => _pick(m, m.canThink ? AgentThinking.off : null),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          UiAssistantProviderIcon(provider: m.provider, size: 22, accent: m.accent),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(m.label, style: TextStyle(color: selected ? m.accent : const Color(0xFFF4F4F5), fontWeight: FontWeight.w600, fontSize: 14)),
                                Text(m.local ? 'This PC' : m.priceLabel, style: const TextStyle(color: Color(0xFF71717A), fontSize: 12)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (m.canThink) ...[
                        const SizedBox(height: 8),
                        Row(children: [for (final level in AgentThinking.values) _badge(m, level)]),
                      ],
                    ],
                  ),
                ),
                if (selected) Padding(padding: const EdgeInsets.only(left: 8), child: Icon(Icons.check_rounded, color: m.accent, size: 18)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _badge(AgentModel m, AgentThinking level) {
    final on = m.id == widget.current.id && widget.current.thinking == level;
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: uiTooltip(
        message: level.tooltip,
        preferBelow: false,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            key: ValueKey('think-${m.id}-${level.wire}'),
            onTap: () => _pick(m, level),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: on ? m.accent.withValues(alpha: 0.22) : const Color(0xFF18181B),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: on ? m.accent.withValues(alpha: 0.75) : const Color(0xFF3F3F46)),
              ),
              child: Text(level.label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: on ? m.accent : const Color(0xFFA1A1AA))),
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:alienai_c35/c/llm/agent_model.dart';
import 'package:alienai_c35/widgets/ai/ui_assistant_provider_icon.dart';
import 'package:alienai_c35/widgets/ui/ui_input_decoration.dart';
import 'package:alienai_c35/widgets/ui/ui_tooltip.dart';
import 'package:flutter/material.dart';

Future<AgentModel?> agentModelPick(BuildContext context, AgentModel current, List<AgentModel> models, {bool modelsLoading = false}) {
  final rows = models.isEmpty ? const [AgentModel.alien] : models;
  return showModalBottomSheet<AgentModel>(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFF18181B),
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
    builder: (ctx) => UiAssistantModelSheet(current: current, models: rows, modelsLoading: modelsLoading),
  );
}

class UiAssistantModelSheet extends StatefulWidget {
  const UiAssistantModelSheet({super.key, required this.current, required this.models, this.modelsLoading = false});

  final AgentModel current;
  final List<AgentModel> models;
  final bool modelsLoading;

  @override
  State<UiAssistantModelSheet> createState() => _UiAssistantModelSheetState();
}

class _UiAssistantModelSheetState extends State<UiAssistantModelSheet> {
  late final _searchCtrl = TextEditingController()..addListener(_onSearch);
  var _query = '';
  var _provider = '';

  void _onSearch() => setState(() => _query = _searchCtrl.text);
  void _pick(AgentModel m, [AgentThinking? thinking]) => Navigator.of(context).pop(thinking == null ? m : m.copyWith(thinking: thinking));

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final providers = agentModelProviders(widget.models);
    final items = agentModelFilter(widget.models, _query, provider: _provider);
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
                if (widget.modelsLoading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 48),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFA1A1AA)),
                        SizedBox(height: 16),
                        Text('Loading models…', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF71717A), fontSize: 14)),
                      ],
                    ),
                  )
                else ...[
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _searchCtrl,
                            autofocus: true,
                            style: const TextStyle(color: Color(0xFFF4F4F5), fontSize: 14),
                            decoration: UiInputDecoration.of(context, hintText: 'Search models…', prefixIcon: const Icon(Icons.search_rounded, size: 20)).copyWith(counter: null),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _providerFilter(providers),
                      ],
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
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _providerFilter(List<String> providers) {
    final active = _provider.isNotEmpty;
    return PopupMenuButton<String>(
      tooltip: uiPopupMenuTooltipText('Filter provider'),
      initialValue: _provider,
      color: const Color(0xFF18181B),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: const BorderSide(color: Color(0xFF3F3F46))),
      onSelected: (v) => setState(() => _provider = v),
      itemBuilder: (_) => [
        for (final p in providers)
          PopupMenuItem<String>(
            value: p,
            height: 44,
            child: Row(
              children: [
                if (p.isEmpty)
                  const Icon(Icons.apps_rounded, size: 18, color: Color(0xFFA1A1AA))
                else
                  UiAssistantProviderIcon(provider: p, size: 18),
                const SizedBox(width: 10),
                Expanded(child: Text(agentModelProviderLabel(p), style: TextStyle(color: _provider == p ? const Color(0xFFF4F4F5) : const Color(0xFFA1A1AA), fontWeight: _provider == p ? FontWeight.w600 : FontWeight.w500))),
                if (_provider == p) const Icon(Icons.check_rounded, size: 16, color: Color(0xFF38BDF8)),
              ],
            ),
          ),
      ],
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF27272A),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: active ? const Color(0xFF38BDF8) : const Color(0xFF3F3F46)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.filter_list_rounded, size: 18, color: active ? const Color(0xFF38BDF8) : const Color(0xFFA1A1AA)),
            if (active) ...[
              const SizedBox(width: 6),
              Text(agentModelProviderLabel(_provider), style: const TextStyle(color: Color(0xFFF4F4F5), fontSize: 12, fontWeight: FontWeight.w600)),
            ],
            const SizedBox(width: 2),
            Icon(Icons.expand_more_rounded, size: 18, color: active ? const Color(0xFF38BDF8) : const Color(0xFFA1A1AA)),
          ],
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

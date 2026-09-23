import 'package:alienai_c35/c/trace/trace_view.dart';
import 'package:alienai_c35/c/ui/ui_format.dart';
import 'package:flutter/material.dart';

class UiAgentToolAccordion extends StatefulWidget {
  const UiAgentToolAccordion({
    super.key,
    required this.chips,
    this.live = false,
    this.initiallyExpanded,
  });

  final List<MsgTraceToolChip> chips;
  final bool live;
  final bool? initiallyExpanded;

  @override
  State<UiAgentToolAccordion> createState() => _UiAgentToolAccordionState();
}

class _UiAgentToolAccordionState extends State<UiAgentToolAccordion> {
  static const _bg = Color(0xFF141418);
  static const _border = Color(0xFF27272A);
  static const _text = Color(0xFFF4F4F5);
  static const _muted = Color(0xFF71717A);
  static const _accent = Color(0xFF06B6D4);

  late bool _expanded;

  @override
  void initState() {
    super.initState();
    _expanded = widget.initiallyExpanded ?? widget.live;
  }

  @override
  void didUpdateWidget(covariant UiAgentToolAccordion oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.live && !widget.live) {
      // Completed -> auto collapse if not explicitly toggled
      if (widget.initiallyExpanded == null) {
        _expanded = false;
      }
    } else if (!oldWidget.live && widget.live) {
      _expanded = true;
    }
  }

  IconData _iconForTool(String label) {
    final l = label.toLowerCase();
    if (l.contains('search') || l.contains('web')) return Icons.travel_explore_rounded;
    if (l.contains('device') || l.contains('phone')) return Icons.smartphone_rounded;
    if (l.contains('file') || l.contains('read') || l.contains('write')) return Icons.description_outlined;
    if (l.contains('sql') || l.contains('db') || l.contains('query')) return Icons.storage_rounded;
    if (l.contains('calc') || l.contains('math')) return Icons.calculate_outlined;
    return Icons.terminal_rounded;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.chips.isEmpty && !widget.live) return const SizedBox.shrink();

    final stepCount = widget.chips.length;
    final totalDurationMs = widget.chips.fold(0, (acc, c) => acc + c.durationMs);
    final totalDurationStr = uiFmtDurationMs(totalDurationMs);

    final titleText = widget.live
        ? (stepCount > 0
            ? 'Agent executing step $stepCount...'
            : 'Agent thinking & executing...')
        : 'Agent executed $stepCount step${stepCount > 1 ? 's' : ''}';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header Bar
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(7),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Row(
                children: [
                  if (widget.live) ...[
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(_accent),
                      ),
                    ),
                  ] else ...[
                    const Icon(Icons.auto_awesome_rounded, size: 14, color: _accent),
                  ],
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      titleText,
                      style: TextStyle(
                        color: widget.live ? _accent : _text,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (totalDurationStr.isNotEmpty) ...[
                    Text(
                      totalDurationStr,
                      style: const TextStyle(color: _muted, fontSize: 11),
                    ),
                    const SizedBox(width: 6),
                  ],
                  Icon(
                    _expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                    size: 16,
                    color: _muted,
                  ),
                ],
              ),
            ),
          ),
          // Expanded Content
          if (_expanded && widget.chips.isNotEmpty) ...[
            Container(height: 1, color: _border),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              child: Column(
                children: [
                  for (final chip in widget.chips)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Icon(
                            chip.ok ? Icons.check_circle_outline_rounded : Icons.error_outline_rounded,
                            size: 14,
                            color: chip.ok ? const Color(0xFF22C55E) : const Color(0xFFF59E0B),
                          ),
                          const SizedBox(width: 8),
                          Icon(_iconForTool(chip.label), size: 13, color: _muted),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              chip.label,
                              style: const TextStyle(
                                color: _text,
                                fontSize: 12,
                                fontFamily: 'Consolas',
                              ),
                            ),
                          ),
                          if (chip.durationMs > 0)
                            Text(
                              uiFmtDurationMs(chip.durationMs),
                              style: const TextStyle(color: _muted, fontSize: 11),
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

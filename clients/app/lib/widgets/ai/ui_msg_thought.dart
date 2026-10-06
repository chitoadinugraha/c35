import 'package:alienai_c35/c/chat/chat_inbox.dart';
import 'package:alienai_c35/widgets/ui/ui_loading.dart' show UiLiveElapsed, UiThinkingDots;
import 'package:flutter/material.dart';
import 'package:alienai_c35/widgets/ai/ui_markdown_body.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';

const uiMsgThoughtColor = Color(0xFF6BA8C8);

class MsgThoughtView {
  const MsgThoughtView({this.thought, required this.content});
  final String? thought;
  final String content;
}

String? msgThoughtVisible({required String thought, required String content, required bool thinking}) =>
    msgThoughtView(thought: thought, content: content, thinking: thinking).thought;

MsgThoughtView msgThoughtView({required String thought, required String content, required bool thinking}) {
  final visibleThought = msgThoughtStripPlaceholders(thought.trim());
  if (visibleThought.isNotEmpty) return MsgThoughtView(thought: visibleThought, content: content);
  if (thinking && content.trim().isEmpty) return MsgThoughtView(thought: 'Thinking', content: content);
  return MsgThoughtView(thought: null, content: content);
}

/// Live prompt thinking row (label, floating dots, elapsed). Same on mobile, desktop, and web.
class UiPromptThinkingIndicator extends StatelessWidget {
  const UiPromptThinkingIndicator({
    super.key,
    this.startedAtMs,
    this.stopping = false,
    this.align = Alignment.centerLeft,
  });

  final int? startedAtMs;
  final bool stopping;
  final Alignment align;

  @override
  Widget build(BuildContext context) => Align(
        alignment: align,
        child: UiMsgThought(
          text: 'Thinking',
          thinking: !stopping,
          stopping: stopping,
          startedAtMs: startedAtMs,
        ),
      );
}

class UiMsgThought extends StatefulWidget {
  const UiMsgThought({super.key, required this.text, this.thinking = false, this.stopping = false, this.startedAtMs});

  final String text;
  final bool thinking;
  final bool stopping;
  final int? startedAtMs;

  @override
  State<UiMsgThought> createState() => _UiMsgThoughtState();
}

class _UiMsgThoughtState extends State<UiMsgThought> {
  var _open = false;

  @override
  void initState() {
    super.initState();
    _open = widget.thinking;
  }

  @override
  void didUpdateWidget(covariant UiMsgThought old) {
    super.didUpdateWidget(old);
    if (!old.thinking && widget.thinking) _open = true;
    if (old.thinking && !widget.thinking) _open = false;
  }

  bool get _expanded => _open;

  bool get _hasBody => widget.text.isNotEmpty && widget.text != 'Thinking' && widget.text != 'Stopping…';

  String get _headerLabel => widget.stopping ? 'Stopping…' : widget.thinking ? 'Thinking' : 'Thought';

  bool get _live => widget.thinking || widget.stopping;

  MarkdownStyleSheet get _styleSheet => MarkdownStyleSheet(
        p: const TextStyle(color: uiMsgThoughtColor, fontSize: 12.5, height: 1.4, fontWeight: FontWeight.w400, fontStyle: FontStyle.italic),
        strong: const TextStyle(color: uiMsgThoughtColor, fontSize: 12.5, height: 1.4, fontWeight: FontWeight.w700, fontStyle: FontStyle.italic),
        em: const TextStyle(color: uiMsgThoughtColor, fontSize: 12.5, height: 1.4, fontWeight: FontWeight.w400, fontStyle: FontStyle.italic),
        code: const TextStyle(color: uiMsgThoughtColor, fontSize: 12, height: 1.35, fontFamily: 'Consolas'),
        listBullet: const TextStyle(color: uiMsgThoughtColor, fontSize: 12.5, height: 1.4, fontStyle: FontStyle.italic),
        blockquote: const TextStyle(color: uiMsgThoughtColor, fontSize: 12.5, height: 1.4, fontStyle: FontStyle.italic),
        blockquoteDecoration: const BoxDecoration(border: Border(left: BorderSide(color: Color(0xFF3F6378), width: 3))),
      );

  @override
  Widget build(BuildContext context) {
    if (widget.text.isEmpty && !_live) return const SizedBox.shrink();
    final previewMaxW = MediaQuery.sizeOf(context).width * 0.62;
    return ExcludeSemantics(
      child: Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _hasBody || _live ? () => setState(() => _open = !_open) : null,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _expanded ? Icons.expand_less_rounded : Icons.psychology_alt_rounded,
                        size: 16,
                        color: uiMsgThoughtColor,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _headerLabel,
                        style: const TextStyle(color: uiMsgThoughtColor, fontSize: 12, fontWeight: FontWeight.w600, height: 1.2),
                      ),
                      if (_live) ...[
                        const SizedBox(width: 8),
                        UiThinkingDots(color: uiMsgThoughtColor, size: 4, spacing: 2.5, bounceHeight: 3),
                      ],
                      if (_live && widget.startedAtMs != null) ...[
                        const SizedBox(width: 8),
                        UiLiveElapsed(
                          startedAtMs: widget.startedAtMs!,
                          style: const TextStyle(
                            color: Color(0xFF71717A),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            height: 1.2,
                            fontFeatures: [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                      if (!_expanded && _hasBody) ...[
                        const SizedBox(width: 8),
                        ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: previewMaxW),
                          child: Text(
                            widget.text.replaceAll('\n', ' ').trim(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Color(0xFF71717A), fontSize: 12, fontStyle: FontStyle.italic, height: 1.2),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (_expanded && _hasBody)
            Padding(
              padding: const EdgeInsets.only(top: 4, left: 22),
              child: UiMarkdownBody(data: widget.text, selectable: false, styleSheet: _styleSheet),
            ),
        ],
      ),
    ),
    );
  }
}


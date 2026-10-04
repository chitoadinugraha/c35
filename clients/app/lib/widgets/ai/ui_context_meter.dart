import 'dart:async';

import 'package:alienai_c35/c/parts/version_label.dart';
import 'package:alienai_c35/c/ui/money_format.dart';
import 'package:flutter/material.dart';

const _bg = Color(0xFF18181B);
const _panel = Color(0xFF27272A);
const _border = Color(0xFF3F3F46);
const _text = Color(0xFFF4F4F5);
const _muted = Color(0xFFA1A1AA);
const _ring = Color(0xFF71717A);
const _cInstructions = Color(0xFFA1A1AA);
const _cMemory = Color(0xFFC4B5FD);
const _cContext = Color(0xFFFBBF24);
const _cTools = Color(0xFF7DD3FC);
const _cConversation = Color(0xFFFB7185);

class ContextUsageParts {
  const ContextUsageParts({this.instructions = 0, this.memory = 0, this.context = 0, this.tools = 0, this.conversation = 0});

  final int instructions;
  final int memory;
  final int context;
  final int tools;
  final int conversation;

  int get total => instructions + memory + context + tools + conversation;

  ContextUsageParts copyConversation(int conversation) => ContextUsageParts(
        instructions: instructions,
        memory: memory,
        context: context,
        tools: tools,
        conversation: conversation,
      );
}

const contextWindowChoices = <int>[32768, 65536, 131072, 262144, 524288];

String contextWindowChoiceLabel(int tokens) => switch (tokens) {
      32768 => '32K',
      65536 => '64K',
      131072 => '128K',
      262144 => '256K',
      524288 => '512K',
      _ => tokens >= 1024 ? '${(tokens / 1024).round()}K' : '$tokens',
    };

/// App bar label beside [UiContextMeter] (build id for support screenshots).
class UiAppBarVersionLabel extends StatelessWidget {
  const UiAppBarVersionLabel({super.key});

  static const _labelStyle = TextStyle(color: _muted, fontSize: 10, fontWeight: FontWeight.w500, height: 1.0);
  static const _versionStyle = TextStyle(color: _muted, fontSize: 9, height: 1.0, fontFeatures: [FontFeature.tabularFigures()]);

  @override
  Widget build(BuildContext context) => DefaultTextStyle.merge(
        style: const TextStyle(height: 1.0, leadingDistribution: TextLeadingDistribution.even),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Alien AI', textAlign: TextAlign.right, style: _labelStyle),
            Text('Version ${csaiVersionBuild()}', textAlign: TextAlign.right, style: _versionStyle),
          ],
        ),
      );
}

class UiContextMeter extends StatefulWidget {
  const UiContextMeter({
    super.key,
    this.promptTokens = 0,
    this.usage = const ContextUsageParts(),
    this.tokensIn = 0,
    this.tokensOut = 0,
    this.contextLimit = 128000,
    this.costUsd = 0.0,
    this.billingCurrency = moneyDefaultCurrency,
    this.fxMicroPerUsd = moneyDefaultFxMicroPerUsd,
    this.windowOptions = const [],
    this.onWindowSelected,
    this.onSummarize,
    this.summarizeBusy = false,
    this.tapPadding = const EdgeInsets.all(6),
  });

  /// Next-prompt estimate. This is the ring numerator.
  final int promptTokens;
  final ContextUsageParts usage;

  /// Lifetime thread usage. Keeps the meter on screen before an estimate arrives. Not the ring fill.
  final int tokensIn;
  final int tokensOut;
  final int contextLimit;
  final double costUsd;
  final String billingCurrency;
  final int fxMicroPerUsd;
  final List<int> windowOptions;
  final void Function(int window)? onWindowSelected;
  final void Function()? onSummarize;
  final bool summarizeBusy;
  final EdgeInsets tapPadding;

  @override
  State<UiContextMeter> createState() => _UiContextMeterState();
}

class _UiContextMeterState extends State<UiContextMeter> {
  OverlayEntry? _hover;
  OverlayEntry? _menu;

  int get _used => widget.promptTokens < 0 ? 0 : widget.promptTokens;
  bool get _visible => _used > 0 || widget.tokensIn > 0 || widget.tokensOut > 0;
  double get _fraction => widget.contextLimit > 0 ? (_used / widget.contextLimit).clamp(0.0, 1.0) : 0.0;

  String get _percent => (_fraction * 100).toStringAsFixed(_fraction >= 0.1 ? 0 : 1);

  Color get _ringColor {
    if (_fraction >= 0.9) return const Color(0xFFEF4444);
    if (_fraction >= 0.7) return const Color(0xFFF59E0B);
    return _ring;
  }

  String _formatK(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }

  void _hideHover() {
    _hover?.remove();
    _hover = null;
  }

  void _hideMenu() {
    _menu?.remove();
    _menu = null;
  }

  Rect? _targetRect() {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize || !box.attached) return null;
    final overlay = Overlay.of(context, rootOverlay: true).context.findRenderObject() as RenderBox?;
    final origin = overlay == null || !overlay.attached ? box.localToGlobal(Offset.zero) : box.localToGlobal(Offset.zero, ancestor: overlay);
    return origin & box.size;
  }

  void _showHover() {
    if (_hover != null || _menu != null || !mounted) return;
    _hover = OverlayEntry(builder: _hoverBuild);
    Overlay.of(context, rootOverlay: true).insert(_hover!);
    WidgetsBinding.instance.addPostFrameCallback((_) => _hover?.markNeedsBuild());
  }

  Widget _hoverBuild(BuildContext ctx) {
    final rect = _targetRect();
    if (rect == null) return const SizedBox.shrink();
    final view = MediaQuery.sizeOf(ctx);
    final pad = MediaQuery.viewPaddingOf(ctx);
    const panelW = 168.0;
    const panelH = 52.0;
    final left = (rect.center.dx - panelW / 2).clamp(pad.left + 8, view.width - pad.right - panelW - 8);
    final top = (rect.bottom + 6).clamp(pad.top + 8, view.height - pad.bottom - panelH - 8);
    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned(
          left: left,
          top: top,
          child: IgnorePointer(
            child: ExcludeSemantics(
              child: Material(
                color: Colors.transparent,
                elevation: 0,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: _panel,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _border),
                    boxShadow: const [BoxShadow(color: Color(0x80000000), blurRadius: 12, offset: Offset(0, 4))],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('$_percent% context used', style: const TextStyle(color: _text, fontSize: 12, fontWeight: FontWeight.w600, height: 1.2)),
                        const SizedBox(height: 2),
                        Text('${_formatK(_used)} / ${_formatK(widget.contextLimit)} tokens', style: const TextStyle(color: _muted, fontSize: 11, height: 1.2)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _showMenu() async {
    _hideHover();
    if (!mounted || _menu != null) return;
    _menu = OverlayEntry(builder: _menuBuild);
    Overlay.of(context, rootOverlay: true).insert(_menu!);
    WidgetsBinding.instance.addPostFrameCallback((_) => _menu?.markNeedsBuild());
  }

  Future<void> _pickWindow(int window) async {
    _hideMenu();
    final cb = widget.onWindowSelected;
    if (cb == null) return;
    await Future<void>.sync(() => cb(window));
  }

  void _summarize() {
    if (widget.summarizeBusy) return;
    _hideMenu();
    widget.onSummarize?.call();
  }

  List<(String, int, Color)> get _usageRows {
    final u = widget.usage;
    final rows = <(String, int, Color)>[
      if (u.instructions > 0) ('Instructions', u.instructions, _cInstructions),
      if (u.memory > 0) ('Memory', u.memory, _cMemory),
      if (u.context > 0) ('Context', u.context, _cContext),
      if (u.tools > 0) ('Tools', u.tools, _cTools),
      if (u.conversation > 0) ('Conversation', u.conversation, _cConversation),
    ];
    if (rows.isEmpty && _used > 0) return [('Conversation', _used, _cConversation)];
    return rows;
  }

  Widget _usageBar() {
    final rows = _usageRows;
    final used = rows.fold<int>(0, (acc, row) => acc + row.$2);
    final rest = (widget.contextLimit - used).clamp(0, widget.contextLimit);
    if (used <= 0) {
      return Container(height: 6, decoration: BoxDecoration(color: _panel, borderRadius: BorderRadius.circular(99)));
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(99),
      child: SizedBox(
        height: 6,
        child: Row(
          children: [
            for (final row in rows)
              Expanded(flex: row.$2, child: ColoredBox(color: row.$3)),
            if (rest > 0) Expanded(flex: rest, child: const ColoredBox(color: _panel)),
          ],
        ),
      ),
    );
  }

  Widget _usageLine(String label, int tokens, Color color) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          children: [
            Container(width: 8, height: 8, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
            const SizedBox(width: 8),
            Expanded(child: Text(label, style: const TextStyle(color: _text, fontSize: 12))),
            Text(_formatK(tokens), style: const TextStyle(color: _muted, fontSize: 12, fontFeatures: [FontFeature.tabularFigures()])),
          ],
        ),
      );

  Widget _menuBuild(BuildContext ctx) {
    final rect = _targetRect();
    if (rect == null) return const SizedBox.shrink();
    final view = MediaQuery.sizeOf(ctx);
    final pad = MediaQuery.viewPaddingOf(ctx);
    const panelW = 320.0;
    final left = (rect.right - panelW).clamp(pad.left + 8, view.width - pad.right - panelW - 8);
    final top = (rect.bottom + 6).clamp(pad.top + 8, view.height - pad.bottom - 8);
    final costLabel = moneyCostLabel(widget.costUsd, currency: widget.billingCurrency, fxMicroPerUsd: widget.fxMicroPerUsd);
    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned.fill(
          child: GestureDetector(
            onTap: _hideMenu,
            behavior: HitTestBehavior.opaque,
          ),
        ),
        Positioned(
          left: left,
          top: top,
          width: panelW,
          child: Material(
            color: _bg,
            elevation: 8,
            borderRadius: BorderRadius.circular(10),
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _border),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text('Context usage', style: TextStyle(color: _text, fontSize: 13, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Text('$_percent% full', style: TextStyle(color: _ringColor, fontSize: 12, fontWeight: FontWeight.w600)),
                              const Spacer(),
                              Text('${_formatK(_used)} / ${_formatK(widget.contextLimit)}', style: const TextStyle(color: _muted, fontSize: 12)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          _usageBar(),
                          const SizedBox(height: 8),
                          for (final row in _usageRows) _usageLine(row.$1, row.$2, row.$3),
                          if (costLabel.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(costLabel, style: const TextStyle(color: _muted, fontSize: 11)),
                          ],
                        ],
                      ),
                    ),
                    if (widget.windowOptions.isNotEmpty) ...[
                      const Divider(height: 8, color: _border),
                      for (final w in widget.windowOptions) _windowRow(w),
                    ],
                    const Divider(height: 8, color: _border),
                    InkWell(
                      onTap: widget.summarizeBusy ? null : _summarize,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Summarize earlier messages',
                                style: TextStyle(color: widget.summarizeBusy ? _muted : _text, fontSize: 13, fontWeight: FontWeight.w500),
                              ),
                            ),
                            if (widget.summarizeBusy)
                              const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 1.6, color: _muted)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _windowRow(int window) {
    final active = window == widget.contextLimit;
    return InkWell(
      onTap: () => unawaited(_pickWindow(window)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: Text(
                contextWindowChoiceLabel(window),
                style: TextStyle(color: active ? _text : _muted, fontSize: 13, fontWeight: active ? FontWeight.w600 : FontWeight.w500),
              ),
            ),
            if (active) const Icon(Icons.check_rounded, size: 16, color: _ring),
          ],
        ),
      ),
    );
  }

  @override
  void didUpdateWidget(UiContextMeter oldWidget) {
    super.didUpdateWidget(oldWidget);
    _menu?.markNeedsBuild();
  }

  @override
  void dispose() {
    _hideHover();
    _hideMenu();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_visible) return const SizedBox.shrink();
    return ExcludeSemantics(
      child: MouseRegion(
        onEnter: (_) => _showHover(),
        onExit: (_) => _hideHover(),
        child: Listener(
          onPointerDown: (_) => _hideHover(),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: _showMenu,
              child: Padding(
                padding: widget.tapPadding,
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    value: _fraction,
                    strokeWidth: 2.2,
                    backgroundColor: _panel,
                    valueColor: AlwaysStoppedAnimation<Color>(_ringColor),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

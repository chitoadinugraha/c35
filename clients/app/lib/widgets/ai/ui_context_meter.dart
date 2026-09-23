import 'package:alienai_c35/c/ui/money_format.dart';
import 'package:flutter/material.dart';

const _bg = Color(0xFF18181B);
const _panel = Color(0xFF27272A);
const _border = Color(0xFF3F3F46);
const _text = Color(0xFFF4F4F5);
const _muted = Color(0xFFA1A1AA);
const _inColor = Color(0xFF06B6D4);
const _outColor = Color(0xFFA78BFA);

class UiContextMeter extends StatefulWidget {
  const UiContextMeter({
    super.key,
    required this.tokensIn,
    required this.tokensOut,
    this.contextLimit = 128000,
    this.costUsd = 0.0,
    this.billingCurrency = moneyDefaultCurrency,
    this.fxMicroPerUsd = moneyDefaultFxMicroPerUsd,
  });

  final int tokensIn;
  final int tokensOut;
  final int contextLimit;
  final double costUsd;
  final String billingCurrency;
  final int fxMicroPerUsd;

  @override
  State<UiContextMeter> createState() => _UiContextMeterState();
}

class _UiContextMeterState extends State<UiContextMeter> {
  OverlayEntry? _hover;

  int get _total => widget.tokensIn + widget.tokensOut;
  double get _fraction => widget.contextLimit > 0 ? (_total / widget.contextLimit).clamp(0.0, 1.0) : 0.0;

  String get _percent => (_fraction * 100).toStringAsFixed(_fraction >= 0.1 ? 0 : 1);

  Color get _ringColor {
    if (_fraction >= 0.9) return const Color(0xFFEF4444);
    if (_fraction >= 0.7) return const Color(0xFFF59E0B);
    return _inColor;
  }

  String _formatK(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }

  String _formatComma(int n) {
    final s = n.toString();
    final reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    return s.replaceAllMapped(reg, (Match m) => '${m[1]},');
  }

  void _hideHover() {
    _hover?.remove();
    _hover = null;
  }

  Rect? _targetRect() {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize || !box.attached) return null;
    final overlay = Overlay.of(context, rootOverlay: true).context.findRenderObject() as RenderBox?;
    final origin = overlay == null || !overlay.attached ? box.localToGlobal(Offset.zero) : box.localToGlobal(Offset.zero, ancestor: overlay);
    return origin & box.size;
  }

  void _showHover() {
    if (_hover != null || !mounted) return;
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
                        Text('${_formatK(_total)} / ${_formatK(widget.contextLimit)} tokens', style: const TextStyle(color: _muted, fontSize: 11, height: 1.2)),
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

  Future<void> _showDetail() async {
    _hideHover();
    if (!mounted) return;
    final costLabel = moneyCostLabel(widget.costUsd, currency: widget.billingCurrency, fxMicroPerUsd: widget.fxMicroPerUsd);
    await showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: _bg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: _border)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Expanded(child: Text('Context Usage', style: TextStyle(color: _text, fontSize: 15, fontWeight: FontWeight.w600))),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(Icons.close_rounded, size: 18, color: _muted),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Text('$_percent% Full', style: TextStyle(color: _ringColor, fontSize: 13, fontWeight: FontWeight.w600)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${_formatK(_total)} / ${_formatK(widget.contextLimit)} Tokens',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.end,
                        style: const TextStyle(color: _muted, fontSize: 12),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: SizedBox(
                    height: 8,
                    child: Row(
                      children: [
                        if (widget.tokensIn > 0)
                          Expanded(
                            flex: widget.tokensIn,
                            child: const ColoredBox(color: _inColor),
                          ),
                        if (widget.tokensOut > 0)
                          Expanded(
                            flex: widget.tokensOut,
                            child: const ColoredBox(color: _outColor),
                          ),
                        if (_total < widget.contextLimit)
                          Expanded(
                            flex: widget.contextLimit - _total,
                            child: const ColoredBox(color: _panel),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                if (widget.tokensIn > 0) _detailRow('Input', widget.tokensIn, _inColor),
                if (widget.tokensOut > 0) _detailRow('Output', widget.tokensOut, _outColor),
                _detailRow('Total', _total, _text),
                if (costLabel.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  _detailRow('Est. cost', null, _muted, value: costLabel),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _detailRow(String label, int? tokens, Color dot, {String? value}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Container(width: 8, height: 8, decoration: BoxDecoration(color: dot, borderRadius: BorderRadius.circular(2))),
            const SizedBox(width: 8),
            Expanded(child: Text(label, style: const TextStyle(color: _muted, fontSize: 12))),
            Text(value ?? _formatComma(tokens!), style: const TextStyle(color: _text, fontSize: 12, fontWeight: FontWeight.w500, fontFeatures: [FontFeature.tabularFigures()])),
          ],
        ),
      );

  @override
  void dispose() {
    _hideHover();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_total <= 0) return const SizedBox.shrink();
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
              onTap: _showDetail,
              child: Padding(
                padding: const EdgeInsets.all(6),
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

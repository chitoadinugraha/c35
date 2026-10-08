import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:alienai_c35/widgets/ui/ui_input_decoration.dart';

/// Compact numeric size field (e.g. font size in px).
class InSize extends StatefulWidget {
  const InSize({
    super.key,
    required this.value,
    required this.onChanged,
    this.labelText = 'Size',
    this.min = 8,
    this.max = 48,
    this.suffix = 'px',
  });

  final double value;
  final ValueChanged<double> onChanged;
  final String labelText;
  final double min;
  final double max;
  final String suffix;

  @override
  State<InSize> createState() => _InSizeState();
}

class _InSizeState extends State<InSize> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: '${widget.value.round()}');
  }

  @override
  void didUpdateWidget(covariant InSize oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value.round() == widget.value.round()) return;
    final next = '${widget.value.round()}';
    if (_ctrl.text == next) return;
    _ctrl.value = TextEditingValue(text: next, selection: TextSelection.collapsed(offset: next.length));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _commit(String raw) {
    final n = int.tryParse(raw.trim());
    if (n == null) {
      _ctrl.text = '${widget.value.round()}';
      return;
    }
    final clamped = n.toDouble().clamp(widget.min, widget.max);
    if (clamped != widget.value) widget.onChanged(clamped);
    final shown = '${clamped.round()}';
    if (_ctrl.text != shown) _ctrl.text = shown;
  }

  @override
  Widget build(BuildContext context) => TextField(
        controller: _ctrl,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        textAlign: TextAlign.end,
        decoration: UiInputDecoration.of(
          context,
          labelText: widget.labelText,
          suffixText: widget.suffix,
        ),
        onChanged: (v) {
          final n = int.tryParse(v.trim());
          if (n == null) return;
          final clamped = n.toDouble().clamp(widget.min, widget.max);
          if (clamped != widget.value) widget.onChanged(clamped);
        },
        onEditingComplete: () => _commit(_ctrl.text),
        onSubmitted: _commit,
      );
}

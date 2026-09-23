import 'package:alienai_c35/core/format/fraction.dart';
import 'package:alienai_c35/widgets/ui/ui_input_decoration.dart';
import 'package:flutter/material.dart';

Future<double?> askFraction({
  required BuildContext context,
  double? value,
  int maxNum = 30,
  int maxDen = 12,
}) =>
    showDialog<double>(
      context: context,
      builder: (_) => _FractionPickerDialog(
        initial: value ?? 1,
        maxNum: maxNum,
        maxDen: maxDen,
      ),
    );

/// Tappable portion field — opens stepper + fraction chips (½, ¼, …).
class InFraction extends StatelessWidget {
  const InFraction({
    super.key,
    required this.value,
    this.onChanged,
    this.labelText = 'Porsi',
    this.decoration,
    this.maxNum = 30,
    this.maxDen = 12,
  });

  final double value;
  final ValueChanged<double>? onChanged;
  final String? labelText;
  final InputDecoration? decoration;
  final int maxNum;
  final int maxDen;

  Future<void> _open(BuildContext context) async {
    if (onChanged == null) return;
    final picked = await askFraction(
      context: context,
      value: value,
      maxNum: maxNum,
      maxDen: maxDen,
    );
    if (picked == null) return;
    onChanged!(picked);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final label = fractionLabel(value, maxDen: maxDen);
    return Semantics(
      button: onChanged != null,
      label: '${labelText ?? 'Porsi'}: $label',
      child: InkWell(
        onTap: onChanged == null ? null : () => _open(context),
        borderRadius: BorderRadius.circular(UiInputDecoration.kRadius),
        child: InputDecorator(
          decoration: decoration ?? UiInputDecoration.of(context, labelText: labelText),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: onChanged == null ? cs.onSurface.withValues(alpha: 0.55) : null,
            ),
          ),
        ),
      ),
    );
  }
}

class _FractionPickerDialog extends StatefulWidget {
  const _FractionPickerDialog({
    required this.initial,
    required this.maxNum,
    required this.maxDen,
  });

  final double initial;
  final int maxNum;
  final int maxDen;

  @override
  State<_FractionPickerDialog> createState() => _FractionPickerDialogState();
}

class _FractionPickerDialogState extends State<_FractionPickerDialog> {
  late final _parts = fractionPartsFromQty(widget.initial, maxDen: widget.maxDen);
  late int _whole = _parts.whole.clamp(0, widget.maxNum);
  late int _fracNum = _parts.fracNum;
  late int _fracDen = _parts.fracDen;

  double get _qty {
    final q = fractionPartsToQty(_whole, _fracNum, _fracDen);
    return q > 0 ? q : 1;
  }

  void _setWhole(int v) => setState(() => _whole = v.clamp(0, widget.maxNum));

  void _setFrac(int num, int den) => setState(() {
        _fracNum = num;
        _fracDen = den;
      });

  @override
  Widget build(BuildContext context) {
    final label = fractionQtyPartsLabel(_whole, _fracNum, _fracDen);
    final isId = Localizations.maybeLocaleOf(context)?.languageCode == 'id';
    return AlertDialog(
      title: Text(isId ? 'Porsi' : 'Portion'),
      contentPadding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      content: SizedBox(
        width: 320,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _QtyStepper(
              label: label,
              value: _whole,
              max: widget.maxNum,
              onChanged: _setWhole,
            ),
            const SizedBox(height: 16),
            _QtyFracChips(
              fracNum: _fracNum,
              fracDen: _fracDen,
              onSelected: _setFrac,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(isId ? 'Batal' : 'Cancel')),
        FilledButton(onPressed: () => Navigator.pop(context, _qty), child: Text(isId ? 'Terapkan' : 'Apply')),
      ],
    );
  }
}

class _QtyStepper extends StatelessWidget {
  const _QtyStepper({
    required this.label,
    required this.value,
    required this.max,
    required this.onChanged,
  });

  final String label;
  final int value;
  final int max;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Row(
      children: [
        _QtyStepBtn(
          icon: Icons.remove,
          onTap: value > 0 ? () => onChanged(value - 1) : null,
        ),
        Expanded(
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: cs.primary,
            ),
          ),
        ),
        _QtyStepBtn(
          icon: Icons.add,
          onTap: value < max ? () => onChanged(value + 1) : null,
        ),
      ],
    );
  }
}

class _QtyStepBtn extends StatelessWidget {
  const _QtyStepBtn({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: cs.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.35)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(
          width: 48,
          height: 48,
          child: Icon(
            icon,
            color: onTap == null ? cs.onSurface.withValues(alpha: 0.3) : cs.primary,
          ),
        ),
      ),
    );
  }
}

class _QtyFracChips extends StatelessWidget {
  const _QtyFracChips({
    required this.fracNum,
    required this.fracDen,
    required this.onSelected,
  });

  final int fracNum;
  final int fracDen;
  final void Function(int num, int den) onSelected;

  static const _common = <(int, int, String)>[
    (0, 1, 'Bulat'),
    (1, 2, '½'),
    (1, 4, '¼'),
    (3, 4, '¾'),
    (1, 3, '⅓'),
    (2, 3, '⅔'),
  ];

  static const _more = <(int, int, String)>[
    (1, 8, '⅛'),
    (3, 8, '⅜'),
    (5, 8, '⅝'),
    (7, 8, '⅞'),
    (1, 5, '⅕'),
    (2, 5, '⅖'),
    (3, 5, '⅗'),
    (4, 5, '⅘'),
  ];

  Widget _chip((int, int, String) c, {bool prominent = false}) => _QtyChip(
        label: c.$3,
        prominent: prominent,
        selected: (fracNum, fracDen) == (c.$1, c.$2),
        onTap: () => onSelected(c.$1, c.$2),
      );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isId = Localizations.maybeLocaleOf(context)?.languageCode == 'id';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          isId ? 'Porsi Pecahan' : 'Fractions',
          textAlign: TextAlign.center,
          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: [for (final c in _common) _chip(c, prominent: true)],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          alignment: WrapAlignment.center,
          children: [for (final c in _more) _chip(c)],
        ),
      ],
    );
  }
}

class _QtyChip extends StatelessWidget {
  const _QtyChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.prominent = false,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool prominent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return FilterChip(
      label: Text(label),
      selected: selected,
      showCheckmark: false,
      padding: prominent ? const EdgeInsets.symmetric(horizontal: 10, vertical: 6) : null,
      labelStyle: (prominent ? theme.textTheme.titleSmall : theme.textTheme.bodySmall)?.copyWith(
        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
        color: selected ? cs.onPrimaryContainer : cs.onSurface,
      ),
      onSelected: (_) => onTap(),
      selectedColor: cs.primaryContainer,
    );
  }
}

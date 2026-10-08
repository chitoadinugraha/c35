import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

import 'package:alienai_c35/c/site/design/site_color.dart';
import 'in_color.dart';

const _inColorStopsMax = 6;

/// Multi-stop color input (outline rings, accent gradients).
///
/// Value is comma-separated hex stops, e.g. `#FF2D6A,#00D4FF,#F5E642`.
/// For a single solid color use [InColor].
class InColorStops extends StatelessWidget {
  const InColorStops({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final String value;
  final ValueChanged<String> onChanged;

  List<String> get _stops {
    final parsed = value
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .map((s) => s.startsWith('#') ? s.toUpperCase() : '#${s.toUpperCase()}')
        .toList();
    return parsed.isEmpty ? ['#6366F1'] : parsed;
  }

  void _emit(List<String> stops) => onChanged(siteColorStopsFormat(stops.map(siteColorParse).toList()));

  Future<void> _pickStop(BuildContext context, int index) async {
    final stops = List<String>.from(_stops);
    final next = await inColorPickerShow(context, current: stops[index]);
    if (next == null) return;
    stops[index] = next;
    _emit(stops);
  }

  void _removeStop(int index) {
    final stops = List<String>.from(_stops);
    if (stops.length <= 1) return;
    stops.removeAt(index);
    _emit(stops);
  }

  Future<void> _addStop(BuildContext context) async {
    final stops = List<String>.from(_stops);
    if (stops.length >= _inColorStopsMax) return;
    final next = await inColorPickerShow(context, current: stops.last);
    if (next == null) return;
    stops.add(next);
    _emit(stops);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final stops = _stops;
    final canAdd = stops.length < _inColorStopsMax;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label.isNotEmpty) ...[
          Text(label, style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
        ],
        Container(
          height: 40,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            gradient: siteColorGradient(stops.join(','), sweep: true),
            border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.4)),
          ),
        ),
        const SizedBox(height: 12),
        Text('io.colors'.tr(), style: Theme.of(context).textTheme.labelMedium?.copyWith(color: cs.onSurfaceVariant)),
        const SizedBox(height: 8),
        for (var i = 0; i < stops.length; i++) ...[
          _ColorStopRow(
            index: i,
            hex: stops[i],
            canRemove: stops.length > 1,
            onPick: () => _pickStop(context, i),
            onRemove: () => _removeStop(i),
          ),
          if (i < stops.length - 1) const SizedBox(height: 6),
        ],
        if (canAdd) ...[
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () => _addStop(context),
            icon: const Icon(Icons.add, size: 18),
            label: Text('io.addColor'.tr()),
            style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
          ),
        ],
        const SizedBox(height: 12),
        Text('io.presets'.tr(), style: Theme.of(context).textTheme.labelMedium?.copyWith(color: cs.onSurfaceVariant)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final swatch in sitePaletteSwatches)
              _StopsPresetDot(
                value: swatch,
                selected: siteColorValueEq(swatch, value),
                onTap: () => onChanged(swatch),
              ),
          ],
        ),
      ],
    );
  }
}

class _ColorStopRow extends StatelessWidget {
  const _ColorStopRow({
    required this.index,
    required this.hex,
    required this.canRemove,
    required this.onPick,
    required this.onRemove,
  });

  final int index;
  final String hex;
  final bool canRemove;
  final VoidCallback onPick;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = siteColorParse(hex);
    return Material(
      color: cs.surfaceContainerHighest.withValues(alpha: 0.4),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onPick,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 8, 4, 8),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(color: cs.outlineVariant),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Color ${index + 1}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    Text(hex.toUpperCase(), style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
                  ],
                ),
              ),
              Icon(Icons.palette_outlined, size: 18, color: cs.onSurfaceVariant),
              if (canRemove)
                IconButton(
                  tooltip: 'common.remove'.tr(),
                  onPressed: onRemove,
                  icon: const Icon(Icons.close, size: 18),
                  visualDensity: VisualDensity.compact,
                )
              else
                const SizedBox(width: 12),
            ],
          ),
        ),
      ),
    );
  }
}

class _StopsPresetDot extends StatelessWidget {
  const _StopsPresetDot({required this.value, required this.selected, required this.onTap});

  final String value;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final stops = siteColorStopsParse(value);
    final multi = stops.length > 1;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: multi ? null : stops.first,
          gradient: multi ? siteColorGradient(value) : null,
          border: Border.all(
            color: selected ? cs.onSurface : Colors.transparent,
            width: selected ? 2.5 : 0,
          ),
        ),
      ),
    );
  }
}

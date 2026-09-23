import 'package:flutter/material.dart';

const _bg = Color(0xFF18181B);
const _section = Color(0xFF27272A);
const _border = Color(0xFF3F3F46);
const _text = Color(0xFFF4F4F5);
const _muted = Color(0xFFA1A1AA);
const _accent = Color(0xFF22C55E);

enum DateRangePreset { today, yesterday, last7d, last30d, custom }

typedef DateRange = ({DateTime from, DateTime to});

DateTime _startOfDay(DateTime d) => DateTime(d.year, d.month, d.day);

DateRange dateRangePreset(DateRangePreset preset, {DateTime? now}) {
  final cur = now ?? DateTime.now();
  final today = _startOfDay(cur);
  return switch (preset) {
    DateRangePreset.today => (from: today, to: cur),
    DateRangePreset.yesterday => (
        from: today.subtract(const Duration(days: 1)),
        to: DateTime(today.year, today.month, today.day).subtract(const Duration(milliseconds: 1)),
      ),
    DateRangePreset.last7d => (from: today.subtract(const Duration(days: 6)), to: cur),
    DateRangePreset.last30d => (from: today.subtract(const Duration(days: 29)), to: cur),
    DateRangePreset.custom => (from: today.subtract(const Duration(days: 6)), to: cur),
  };
}

String dateRangeLabel(DateRangePreset preset) => switch (preset) {
      DateRangePreset.today => 'Today',
      DateRangePreset.yesterday => 'Yesterday',
      DateRangePreset.last7d => '7d',
      DateRangePreset.last30d => '30d',
      DateRangePreset.custom => 'Custom',
    };

String dateRangeShortLabel(DateRange range) {
  String d(DateTime t) => '${t.month}/${t.day}';
  return '${d(range.from)} – ${d(range.to)}';
}

Future<DateRange?> dateRangeSheet(BuildContext context, {required DateRange initial}) => showModalBottomSheet<DateRange>(
      context: context,
      backgroundColor: _bg,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16)), side: BorderSide(color: _border)),
      builder: (ctx) => _DateRangeSheet(initial: initial),
    );

class UiDateRangeChip extends StatelessWidget {
  const UiDateRangeChip({super.key, required this.range, required this.onChanged});

  final DateRange range;
  final ValueChanged<DateRange> onChanged;

  Future<void> _open(BuildContext context) async {
    final picked = await dateRangeSheet(context, initial: range);
    if (picked != null) onChanged(picked);
  }

  @override
  Widget build(BuildContext context) => ActionChip(
        label: Text(dateRangeShortLabel(range), style: const TextStyle(color: _text, fontSize: 12)),
        avatar: const Icon(Icons.calendar_today_outlined, size: 14, color: _muted),
        backgroundColor: _section,
        side: const BorderSide(color: _border),
        onPressed: () => _open(context),
      );
}

class _DateRangeSheet extends StatefulWidget {
  const _DateRangeSheet({required this.initial});

  final DateRange initial;

  @override
  State<_DateRangeSheet> createState() => _DateRangeSheetState();
}

class _DateRangeSheetState extends State<_DateRangeSheet> {
  late DateTime _from = widget.initial.from;
  late DateTime _to = widget.initial.to;

  Future<void> _pickFrom() async {
    final picked = await showDatePicker(context: context, initialDate: _from, firstDate: DateTime(2020), lastDate: DateTime.now().add(const Duration(days: 1)));
    if (picked == null) return;
    setState(() => _from = DateTime(picked.year, picked.month, picked.day));
  }

  Future<void> _pickTo() async {
    final picked = await showDatePicker(context: context, initialDate: _to, firstDate: _from, lastDate: DateTime.now().add(const Duration(days: 1)));
    if (picked == null) return;
    setState(() => _to = DateTime(picked.year, picked.month, picked.day, 23, 59, 59, 999));
  }

  void _applyPreset(DateRangePreset preset) => Navigator.pop(context, dateRangePreset(preset));

  @override
  Widget build(BuildContext context) => SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(16, 12, 16, 16 + MediaQuery.viewInsetsOf(context).bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Date range', style: TextStyle(color: _text, fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: DateRangePreset.values
                    .where((p) => p != DateRangePreset.custom)
                    .map((p) => ActionChip(
                          label: Text(dateRangeLabel(p)),
                          backgroundColor: _section,
                          side: const BorderSide(color: _border),
                          labelStyle: const TextStyle(color: _text, fontSize: 12),
                          onPressed: () => _applyPreset(p),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 14),
              _DateTile(label: 'From', value: dateRangeShortLabel((from: _from, to: _from)), onTap: _pickFrom),
              const SizedBox(height: 8),
              _DateTile(label: 'To', value: dateRangeShortLabel((from: _to, to: _to)), onTap: _pickTo),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _to.isAfter(_from) ? () => Navigator.pop(context, (from: _from, to: _to)) : null,
                child: const Text('Apply'),
              ),
            ],
          ),
        ),
      );
}

class _DateTile extends StatelessWidget {
  const _DateTile({required this.label, required this.value, required this.onTap});

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: _section.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), border: Border.all(color: _border.withValues(alpha: 0.65))),
            child: Row(
              children: [
                Text(label, style: const TextStyle(color: _muted, fontSize: 12)),
                const Spacer(),
                Text(value, style: const TextStyle(color: _accent, fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(width: 4),
                const Icon(Icons.calendar_today_outlined, size: 14, color: _muted),
              ],
            ),
          ),
        ),
      );
}

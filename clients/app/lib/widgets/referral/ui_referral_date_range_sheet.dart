import 'package:alienai_c35/c/referral/referral_period.dart';
import 'package:flutter/material.dart';

const _bg = Color(0xFF18181B);
const _section = Color(0xFF27272A);
const _border = Color(0xFF3F3F46);
const _text = Color(0xFFF4F4F5);
const _muted = Color(0xFFA1A1AA);
const _accent = Color(0xFF22C55E);

Future<ReferralPeriodRange?> referralDateRangeSheet(
  BuildContext context, {
  required ReferralPeriodRange initial,
}) =>
    showModalBottomSheet<ReferralPeriodRange>(
      context: context,
      backgroundColor: _bg,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16)), side: BorderSide(color: _border)),
      builder: (ctx) => _ReferralDateRangeSheet(initial: initial),
    );

class _ReferralDateRangeSheet extends StatefulWidget {
  const _ReferralDateRangeSheet({required this.initial});

  final ReferralPeriodRange initial;

  @override
  State<_ReferralDateRangeSheet> createState() => _ReferralDateRangeSheetState();
}

class _ReferralDateRangeSheetState extends State<_ReferralDateRangeSheet> {
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

  void _applyPreset(ReferralPeriodPreset preset) => Navigator.pop(context, referralPeriodRange(preset));

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
                children: ReferralPeriodPreset.values
                    .where((p) => p != ReferralPeriodPreset.custom)
                    .map((p) => ActionChip(
                          label: Text(referralPeriodLabel(p)),
                          backgroundColor: _section,
                          side: const BorderSide(color: _border),
                          labelStyle: const TextStyle(color: _text, fontSize: 12),
                          onPressed: () => _applyPreset(p),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 14),
              _DateTile(label: 'From', value: referralPeriodShortLabel((from: _from, to: _from)), onTap: _pickFrom),
              const SizedBox(height: 8),
              _DateTile(label: 'To', value: referralPeriodShortLabel((from: _to, to: _to)), onTap: _pickTo),
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

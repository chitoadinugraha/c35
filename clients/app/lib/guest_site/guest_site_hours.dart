import 'package:alienai_c35/c/site/site_schedule.dart';
import 'package:alienai_c35/c/site/site_schedule_status.dart';
import 'package:alienai_c35/c/site/site_schedule_summary.dart';
import 'package:flutter/material.dart';

const _guestTextPrimary = Color(0xFFF4F4F5);
const _guestTextSecondary = Color(0xFFA1A1AA);

/// CSA-style expandable open-hours chip for guest hub.
class GuestSiteHoursCompact extends StatefulWidget {
  const GuestSiteHoursCompact({
    super.key,
    required this.openHours,
    this.fg = _guestTextPrimary,
    this.muted = _guestTextSecondary,
    this.alignment = Alignment.center,
  });

  final List<SiteScheduleSlot> openHours;
  final Color fg;
  final Color muted;
  final Alignment alignment;

  @override
  State<GuestSiteHoursCompact> createState() => _GuestSiteHoursCompactState();
}

class _GuestSiteHoursCompactState extends State<GuestSiteHoursCompact> {
  var _expanded = false;

  @override
  Widget build(BuildContext context) {
    if (widget.openHours.isEmpty) return const SizedBox.shrink();
    final status = siteScheduleStatus(widget.openHours);
    final muted = widget.muted;
    final statusColor = status.open ? const Color(0xFF16A34A) : muted;
    final columns = siteScheduleSummarySplit(widget.openHours);
    final twoCol = columns.left.isNotEmpty && columns.right.isNotEmpty;

    return Align(
      alignment: widget.alignment,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 320),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              alignment: widget.alignment,
              child: IntrinsicWidth(
                child: _HoursMetaChip(
                  muted: muted,
                  fg: widget.fg,
                  onTap: () => setState(() => _expanded = !_expanded),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.schedule_outlined, size: 14, color: statusColor),
                      const SizedBox(width: 6),
                      Text(
                        status.label,
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: statusColor),
                      ),
                      Icon(_expanded ? Icons.expand_less : Icons.expand_more, size: 16, color: muted),
                    ],
                  ),
                ),
              ),
            ),
            if (_expanded) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
                decoration: BoxDecoration(
                  color: widget.fg.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: muted.withValues(alpha: 0.25)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _HoursColumn(rows: columns.left, fg: widget.fg, muted: muted)),
                    if (twoCol) ...[
                      const SizedBox(width: 12),
                      Expanded(child: _HoursColumn(rows: columns.right, fg: widget.fg, muted: muted)),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _HoursColumn extends StatelessWidget {
  const _HoursColumn({required this.rows, required this.fg, required this.muted});

  final List<SiteScheduleDaySummary> rows;
  final Color fg;
  final Color muted;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final row in rows)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(siteScheduleWeekdayLabelsLong[row.day], style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: fg)),
                  const SizedBox(height: 2),
                  for (final time in row.times) Text(time, style: TextStyle(fontSize: 11, height: 1.35, color: muted)),
                ],
              ),
            ),
        ],
      );
}

class _HoursMetaChip extends StatelessWidget {
  const _HoursMetaChip({
    required this.muted,
    required this.fg,
    required this.onTap,
    required this.child,
  });

  final Color muted;
  final Color fg;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) => Material(
        color: fg.withValues(alpha: 0.04),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: muted.withValues(alpha: 0.28)),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: child,
          ),
        ),
      );
}

import 'package:alienai_c35/c/pb/c35/site.pb.dart';
import 'package:alienai_c35/c/site/site_draft_extras.dart';
import 'package:alienai_c35/c/site/site_schedule.dart';
import 'package:alienai_c35/c/site/site_work_shift_ui.dart';
import 'package:alienai_c35/widgets/io/in_schedule_slots.dart';
import 'package:alienai_c35/widgets/sites/editor/ui_site_catalog_detail_header.dart';
import 'package:alienai_c35/widgets/ui/ui_dropdown_item.dart';
import 'package:alienai_c35/widgets/ui/ui_input_decoration.dart';
import 'package:flutter/material.dart';

class UiSiteWorkHoursDetail extends StatefulWidget {
  const UiSiteWorkHoursDetail({
    super.key,
    required this.shift,
    required this.onRename,
    required this.onMethod,
    required this.onSlots,
    required this.onDelete,
  });

  final SiteWorkShift shift;
  final ValueChanged<String> onRename;
  final ValueChanged<String> onMethod;
  final ValueChanged<List<SiteScheduleSlot>> onSlots;
  final VoidCallback onDelete;

  @override
  State<UiSiteWorkHoursDetail> createState() => _UiSiteWorkHoursDetailState();
}

class _UiSiteWorkHoursDetailState extends State<UiSiteWorkHoursDetail> {
  late final _nameCtrl = TextEditingController();
  late String _attendanceMethod;

  @override
  void initState() {
    super.initState();
    _sync();
  }

  @override
  void didUpdateWidget(covariant UiSiteWorkHoursDetail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.shift.id != widget.shift.id) _sync();
  }

  void _sync() {
    _nameCtrl.text = widget.shift.name;
    _attendanceMethod =
        siteWorkShiftAttendanceMethods.contains(widget.shift.attendanceMethod) ? widget.shift.attendanceMethod : 'none';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  List<SiteScheduleSlot> get _slots => [
        for (final s in widget.shift.slots)
          SiteScheduleSlot(
            id: s.id.isEmpty ? siteDraftNewId('slot') : s.id,
            startDay: s.startDay,
            startMin: s.startMin,
            endDay: s.endDay,
            endMin: s.endMin,
          ),
      ];

  void _addSlot() => widget.onSlots([..._slots, siteScheduleSlotDefault()]);

  void _updateSlot(String id, {int? startDay, int? startMin, int? endDay, int? endMin}) {
    widget.onSlots(_slots.map((s) {
      if (s.id != id) return s;
      return s.copyWith(startDay: startDay, startMin: startMin, endDay: endDay, endMin: endMin);
    }).toList(growable: false));
  }

  void _removeSlot(String id) => widget.onSlots(_slots.where((s) => s.id != id).toList(growable: false));

  @override
  Widget build(BuildContext context) {
    final shift = widget.shift;
    final cs = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
      children: [
        UiSiteCatalogDetailHeader(
          title: 'Work hours',
          subtitle: siteWorkShiftSubtitle(shift),
          icon: Icons.schedule_outlined,
          onDelete: widget.onDelete,
          deleteConfirmTitle: 'Delete this schedule?',
          deleteConfirmBody: shift.name.trim().isEmpty ? 'This work hours entry will be removed.' : 'Delete ${shift.name.trim()}?',
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _nameCtrl,
          decoration: UiInputDecoration.of(context, labelText: 'Shift name'),
          onChanged: widget.onRename,
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          key: ValueKey('${shift.id}-$_attendanceMethod'),
          initialValue: _attendanceMethod,
          decoration: UiInputDecoration.of(context, labelText: 'Attendance method'),
          isExpanded: true,
          selectedItemBuilder: (context) => [
            for (final m in siteWorkShiftAttendanceMethods)
              UiDropdownItem(icon: siteWorkShiftAttendanceIcon(m), label: siteWorkShiftAttendanceLabel(m)),
          ],
          items: [
            for (final m in siteWorkShiftAttendanceMethods)
              DropdownMenuItem(
                value: m,
                child: UiDropdownItem(icon: siteWorkShiftAttendanceIcon(m), label: siteWorkShiftAttendanceLabel(m)),
              ),
          ],
          onChanged: (v) {
            if (v == null) return;
            setState(() => _attendanceMethod = v);
            widget.onMethod(v);
          },
        ),
        const SizedBox(height: 20),
        InScheduleSlots(
          label: 'Work hours',
          slots: _slots,
          onAdd: _addSlot,
          onUpdate: _updateSlot,
          onRemove: _removeSlot,
        ),
        const SizedBox(height: 12),
        Text(
          'Assign this schedule to team members on the Team screen.',
          style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
        ),
      ],
    );
  }
}

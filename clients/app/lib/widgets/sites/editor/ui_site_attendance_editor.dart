import 'dart:async';

import 'package:alienai_c35/c/pb/c35/site.pb.dart';
import 'package:alienai_c35/c/site/site_api.dart';
import 'package:alienai_c35/c/site/site_draft_extras.dart';
import 'package:alienai_c35/c/site/site_schedule.dart';
import 'package:alienai_c35/c/ui/ui_friendly_error.dart';
import 'package:alienai_c35/widgets/io/in_site_schedule.dart';
import 'package:alienai_c35/widgets/sites/editor/site_editor_save_scope.dart';
import 'package:alienai_c35/widgets/sites/editor/ui_site_catalog_detail_header.dart';
import 'package:alienai_c35/widgets/sites/editor/ui_site_editor_form.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flutter/material.dart';

const _muted = Color(0xFF71717A);
const _text = Color(0xFFF4F4F5);
const _border = Color(0xFF27272A);

const _methods = ['none', 'geo', 'face', 'geo_face'];

String _methodLabel(String raw) => switch (raw) {
      'geo' => 'Location',
      'face' => 'Face',
      'geo_face' => 'Location and face',
      _ => 'None',
    };

class UiSiteAttendanceEditor extends StatefulWidget {
  const UiSiteAttendanceEditor({super.key, required this.api, required this.siteIid});

  final SiteApi api;
  final int siteIid;

  @override
  State<UiSiteAttendanceEditor> createState() => _UiSiteAttendanceEditorState();
}

class _UiSiteAttendanceEditorState extends State<UiSiteAttendanceEditor> {
  var _loading = true;
  String? _error;
  String? _detailId;
  Timer? _saveTimer;
  final _locations = <SitePresenceLocation>[];
  final _shifts = <SiteWorkShift>[];
  late final _nameCtrl = TextEditingController();
  late final _pointsCtrl = TextEditingController();
  var _suppress = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl.addListener(_onAreaField);
    _pointsCtrl.addListener(_onAreaField);
    unawaited(_load());
  }

  @override
  void dispose() {
    _saveTimer?.cancel();
    _nameCtrl.dispose();
    _pointsCtrl.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant UiSiteAttendanceEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.siteIid != widget.siteIid) unawaited(_load());
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final locations = await widget.api.presenceLocationList(widget.siteIid);
      final shifts = await widget.api.workShiftList(widget.siteIid);
      _locations
        ..clear()
        ..addAll(locations.map((e) => e.clone()));
      _shifts
        ..clear()
        ..addAll(shifts.map((e) => e.clone()));
    } catch (e) {
      _error = uiFriendlyError(e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _schedule(void Function() fn) {
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 500), fn);
  }

  Future<void> _putLocations() async {
    await SiteEditorSaveScope.run(context, () async {
      await widget.api.presenceLocationPut(widget.siteIid, _locations.map((e) => e.clone()).toList(growable: false));
    });
  }

  Future<void> _putShifts() async {
    await SiteEditorSaveScope.run(context, () async {
      await widget.api.workShiftPut(widget.siteIid, _shifts.map((e) => e.clone()).toList(growable: false));
    });
  }

  SitePresenceLocation? _area(String id) {
    for (final loc in _locations) {
      if (loc.id == id) return loc;
    }
    return null;
  }

  SiteWorkShift? _shift(String id) {
    for (final shift in _shifts) {
      if (shift.id == id) return shift;
    }
    return null;
  }

  String _pointsText(SitePresenceLocation loc) => [
        for (final p in loc.polygon) '${p.lat}, ${p.lng}',
      ].join('\n');

  List<SitePresenceLatLng> _parsePoints(String raw) {
    final out = <SitePresenceLatLng>[];
    for (final line in raw.split('\n')) {
      final parts = line.split(RegExp(r'[,;\s]+')).where((p) => p.isNotEmpty).toList();
      if (parts.length < 2) continue;
      final lat = double.tryParse(parts[0]);
      final lng = double.tryParse(parts[1]);
      if (lat == null || lng == null) continue;
      out.add(SitePresenceLatLng(lat: lat, lng: lng));
    }
    return out;
  }

  void _openArea(String id) {
    final loc = _area(id);
    if (loc == null) return;
    _suppress = true;
    _nameCtrl.text = loc.name;
    _pointsCtrl.text = _pointsText(loc);
    _suppress = false;
    setState(() => _detailId = 'area:$id');
  }

  void _onAreaField() {
    if (_suppress || _loading) return;
    final id = _detailId;
    if (id == null || !id.startsWith('area:')) return;
    final loc = _area(id.substring(5));
    if (loc == null) return;
    loc.name = _nameCtrl.text;
    loc.polygon
      ..clear()
      ..addAll(_parsePoints(_pointsCtrl.text));
    _schedule(() => unawaited(_putLocations()));
  }

  void _addArea() {
    final loc = SitePresenceLocation(siteIid: Int64(widget.siteIid), id: siteDraftNewId('area'), name: 'Area');
    _locations.add(loc);
    setState(() {});
    _openArea(loc.id);
    unawaited(_putLocations());
  }

  Future<void> _deleteArea(String id) async {
    _locations.removeWhere((e) => e.id == id);
    setState(() => _detailId = null);
    await _putLocations();
  }

  void _addShift() {
    final shift = SiteWorkShift(
      siteIid: Int64(widget.siteIid),
      id: siteDraftNewId('shift'),
      name: 'Shift',
      attendanceMethod: 'geo',
    );
    _shifts.add(shift);
    setState(() => _detailId = 'shift:${shift.id}');
    unawaited(_putShifts());
  }

  Future<void> _deleteShift(String id) async {
    _shifts.removeWhere((e) => e.id == id);
    setState(() => _detailId = null);
    await _putShifts();
  }

  void _renameShift(SiteWorkShift shift, String name) {
    shift.name = name;
    _schedule(() => unawaited(_putShifts()));
  }

  void _method(SiteWorkShift shift, String method) {
    shift.attendanceMethod = method;
    setState(() {});
    unawaited(_putShifts());
  }

  void _slots(SiteWorkShift shift, List<SiteScheduleSlot> slots) {
    shift.slots
      ..clear()
      ..addAll(slots.map((s) => SiteWorkShiftSlot(id: s.id, startDay: s.startDay, startMin: s.startMin, endDay: s.endDay, endMin: s.endMin)));
    _schedule(() => unawaited(_putShifts()));
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    final detail = _detailId;
    if (detail != null && detail.startsWith('area:')) {
      final loc = _area(detail.substring(5));
      if (loc != null) return _areaDetail(loc);
    }
    if (detail != null && detail.startsWith('shift:')) {
      final shift = _shift(detail.substring(6));
      if (shift != null) return _shiftDetail(shift);
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        if (_error != null) ...[
          Text(_error!, style: const TextStyle(color: Color(0xFFF87171), fontSize: 12)),
          const SizedBox(height: 12),
        ],
        _section('Areas', onAdd: _addArea),
        if (_locations.isEmpty)
          const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: Text('No attendance areas yet.', style: TextStyle(color: _muted, fontSize: 12)),
          )
        else
          for (final loc in _locations) _tile(loc.name.isEmpty ? 'Area' : loc.name, () => _openArea(loc.id)),
        const SizedBox(height: 8),
        _section('Shifts', onAdd: _addShift),
        if (_shifts.isEmpty)
          const Text('No work shifts yet.', style: TextStyle(color: _muted, fontSize: 12))
        else
          for (final shift in _shifts)
            _tile(
              shift.name.isEmpty ? 'Shift' : shift.name,
              () => setState(() => _detailId = 'shift:${shift.id}'),
              subtitle: _methodLabel(shift.attendanceMethod),
            ),
      ],
    );
  }

  Widget _section(String label, {required VoidCallback onAdd}) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            Expanded(
              child: Text(label.toUpperCase(), style: const TextStyle(color: _muted, fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 0.8)),
            ),
            IconButton(
              tooltip: 'Add',
              onPressed: onAdd,
              icon: const Icon(Icons.add, size: 20, color: _muted),
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
      );

  Widget _tile(String title, VoidCallback onTap, {String? subtitle}) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Material(
          color: const Color(0xFF18181B),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: _border)),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: const TextStyle(color: _text, fontSize: 13, fontWeight: FontWeight.w600)),
                        if (subtitle != null) Text(subtitle, style: const TextStyle(color: _muted, fontSize: 12)),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, size: 18, color: _muted),
                ],
              ),
            ),
          ),
        ),
      );

  Widget _areaDetail(SitePresenceLocation loc) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        TextButton.icon(
          onPressed: () => setState(() => _detailId = null),
          icon: const Icon(Icons.arrow_back, size: 16),
          label: const Text('Attendance'),
        ),
        UiSiteCatalogDetailHeader(
          title: 'Area',
          icon: Icons.place_outlined,
          onDelete: () => _deleteArea(loc.id),
          deleteConfirmTitle: 'Delete this area?',
        ),
        const SizedBox(height: 12),
        UiSiteEditorLabeledField(
          label: 'Name',
          child: TextField(controller: _nameCtrl, style: const TextStyle(color: _text, fontSize: 14), decoration: siteEditorInputDecoration(hintText: 'Front desk')),
        ),
        UiSiteEditorLabeledField(
          label: 'Boundary points',
          child: TextField(
            controller: _pointsCtrl,
            minLines: 4,
            maxLines: 8,
            style: const TextStyle(color: _text, fontSize: 13),
            decoration: siteEditorInputDecoration(hintText: 'lat, lng'),
          ),
        ),
        const Text('One point per line. Saved on the presence location.', style: TextStyle(color: _muted, fontSize: 12)),
      ],
    );
  }

  Widget _shiftDetail(SiteWorkShift shift) {
    final slots = [
      for (final s in shift.slots)
        SiteScheduleSlot(id: s.id.isEmpty ? siteDraftNewId('slot') : s.id, startDay: s.startDay, startMin: s.startMin, endDay: s.endDay, endMin: s.endMin),
    ];
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        TextButton.icon(
          onPressed: () => setState(() => _detailId = null),
          icon: const Icon(Icons.arrow_back, size: 16),
          label: const Text('Attendance'),
        ),
        UiSiteCatalogDetailHeader(
          title: 'Shift',
          icon: Icons.schedule_outlined,
          onDelete: () => _deleteShift(shift.id),
          deleteConfirmTitle: 'Delete this shift?',
        ),
        const SizedBox(height: 12),
        UiSiteEditorLabeledField(
          label: 'Name',
          child: TextFormField(
            initialValue: shift.name,
            style: const TextStyle(color: _text, fontSize: 14),
            decoration: siteEditorInputDecoration(hintText: 'Morning'),
            onChanged: (v) => _renameShift(shift, v),
          ),
        ),
        UiSiteEditorLabeledField(
          label: 'Check-in',
          child: DropdownButtonFormField<String>(
            initialValue: _methods.contains(shift.attendanceMethod) ? shift.attendanceMethod : 'none',
            dropdownColor: const Color(0xFF18181B),
            style: const TextStyle(color: _text, fontSize: 14),
            decoration: siteEditorInputDecoration(),
            items: [for (final m in _methods) DropdownMenuItem(value: m, child: Text(_methodLabel(m)))],
            onChanged: (v) {
              if (v != null) _method(shift, v);
            },
          ),
        ),
        InSiteSchedule(label: 'Hours', slots: slots, onChanged: (next) => _slots(shift, next)),
      ],
    );
  }
}

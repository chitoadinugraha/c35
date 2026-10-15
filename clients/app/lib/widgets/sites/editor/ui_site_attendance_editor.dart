import 'dart:async';

import 'package:alienai_c35/c/pb/c35/site.pb.dart';
import 'package:alienai_c35/c/site/site_api.dart';
import 'package:alienai_c35/c/site/site_draft_extras.dart';
import 'package:alienai_c35/c/site/site_schedule.dart';
import 'package:alienai_c35/c/ui/ui_friendly_error.dart';
import 'package:alienai_c35/widgets/sites/editor/site_attendance_detail_ids.dart';
import 'package:alienai_c35/c/site/site_editor_autosave.dart';
import 'package:alienai_c35/widgets/sites/editor/site_editor_save_scope.dart';
import 'package:alienai_c35/widgets/sites/editor/ui_site_attendance_area_detail.dart';
import 'package:alienai_c35/widgets/sites/editor/ui_site_attendance_my_clock.dart';
import 'package:alienai_c35/widgets/sites/editor/ui_site_attendance_section.dart';
import 'package:alienai_c35/widgets/sites/editor/ui_site_catalog_shared.dart';
import 'package:alienai_c35/widgets/sites/editor/ui_site_work_hours_detail.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flutter/material.dart';

const _muted = Color(0xFF71717A);

class UiSiteAttendanceEditor extends StatefulWidget {
  const UiSiteAttendanceEditor({
    super.key,
    required this.api,
    required this.siteIid,
    required this.masterDetail,
    this.detailId,
    this.onDetailIdChanged,
  });

  final SiteApi api;
  final int siteIid;
  final bool masterDetail;
  final String? detailId;
  final ValueChanged<String?>? onDetailIdChanged;

  @override
  State<UiSiteAttendanceEditor> createState() => _UiSiteAttendanceEditorState();
}

class _UiSiteAttendanceEditorState extends State<UiSiteAttendanceEditor> {
  late final _searchCtrl = TextEditingController();
  var _search = '';
  var _loading = true;
  String? _error;
  String? _selectedId;
  final _locations = <SitePresenceLocation>[];
  final _shifts = <SiteWorkShift>[];

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant UiSiteAttendanceEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.siteIid != widget.siteIid) unawaited(_load());
    if (oldWidget.masterDetail != widget.masterDetail) _pickDefault();
    if (widget.detailId != null && _detailExists(widget.detailId!)) {
      _selectedId = widget.detailId;
    }
  }

  bool _detailExists(String id) {
    final raw = siteAttendanceDetailRawId(id);
    if (raw == null) return false;
    if (siteAttendanceDetailIsMyClock(id)) return true;
    if (siteAttendanceDetailIsArea(id)) return _area(raw) != null;
    if (siteAttendanceDetailIsShift(id)) return _shift(raw) != null;
    return false;
  }

  String? _defaultDetailId() => siteAttendanceMyClockDetailId();

  String? get _activeId => widget.masterDetail ? (_selectedId ?? widget.detailId ?? _defaultDetailId()) : widget.detailId;

  void _pickDefault() {
    if (widget.masterDetail) {
      if (_selectedId == null || !_detailExists(_selectedId!)) {
        _selectedId = _defaultDetailId();
      }
      return;
    }
    if (widget.detailId != null && !_detailExists(widget.detailId!)) {
      widget.onDetailIdChanged?.call(_defaultDetailId());
    }
  }

  void _select(String id) {
    if (widget.masterDetail) {
      setState(() => _selectedId = id);
    } else {
      widget.onDetailIdChanged?.call(id);
    }
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
      _pickDefault();
    } catch (e) {
      _error = uiFriendlyError(e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _schedule(String key, Future<void> Function() fn) {
    siteEditorScheduleSave(context, key: key, save: fn);
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

  void _addArea() {
    final loc = SitePresenceLocation(siteIid: Int64(widget.siteIid), id: siteDraftNewId('area'), name: 'Area');
    _locations.add(loc);
    setState(() {});
    _searchCtrl.clear();
    setState(() => _search = '');
    _select(siteAttendanceAreaDetailId(loc.id));
    unawaited(_putLocations());
  }

  Future<void> _deleteArea(String id) async {
    _locations.removeWhere((e) => e.id == id);
    _onDeleted();
    await _putLocations();
  }

  void _patchArea(String id, void Function(SitePresenceLocation loc) fn) {
    final loc = _area(id);
    if (loc == null) return;
    fn(loc);
    setState(() {});
    _schedule('attendance:locations', _putLocations);
  }

  void _addShift() {
    final shift = SiteWorkShift(
      siteIid: Int64(widget.siteIid),
      id: siteDraftNewId('shift'),
      name: 'Shift',
      attendanceMethod: 'geo',
    );
    _shifts.add(shift);
    setState(() {});
    _searchCtrl.clear();
    setState(() => _search = '');
    _select(siteAttendanceShiftDetailId(shift.id));
    unawaited(_putShifts());
  }

  Future<void> _deleteShift(String id) async {
    _shifts.removeWhere((e) => e.id == id);
    _onDeleted();
    await _putShifts();
  }

  void _onDeleted() {
    final next = _defaultDetailId();
    _selectedId = next;
    if (widget.masterDetail) {
      setState(() {});
    } else {
      widget.onDetailIdChanged?.call(null);
    }
  }

  void _renameShift(SiteWorkShift shift, String name) {
    shift.name = name;
    setState(() {});
    _schedule('attendance:shifts', _putShifts);
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
    setState(() {});
    _schedule('attendance:shifts', _putShifts);
  }

  Widget _listPane({required String? selectedId}) => UiSiteAttendanceSection(
        searchController: _searchCtrl,
        search: _search,
        onSearchChanged: (v) => setState(() => _search = v),
        locations: _locations,
        shifts: _shifts,
        selectedId: selectedId,
        onSelect: _select,
        onAddArea: _addArea,
        onAddShift: _addShift,
        masterDetail: widget.masterDetail,
      );

  Widget _detailPane(String detailId) {
    if (siteAttendanceDetailIsMyClock(detailId)) {
      return UiSiteAttendanceMyClock(key: const ValueKey('my-clock'), api: widget.api, siteIid: widget.siteIid);
    }
    final raw = siteAttendanceDetailRawId(detailId);
    if (raw == null) return const SizedBox.shrink();
    if (siteAttendanceDetailIsArea(detailId)) {
      final loc = _area(raw);
      if (loc == null) {
        return const Center(child: Text('Area not found', style: TextStyle(color: _muted)));
      }
      return UiSiteAttendanceAreaDetail(
        key: ValueKey('area-$raw'),
        location: loc,
        onPatch: (fn) => _patchArea(raw, fn),
        onDelete: () => unawaited(_deleteArea(raw)),
      );
    }
    if (siteAttendanceDetailIsShift(detailId)) {
      final shift = _shift(raw);
      if (shift == null) {
        return const Center(child: Text('Schedule not found', style: TextStyle(color: _muted)));
      }
      return UiSiteWorkHoursDetail(
        key: ValueKey('shift-$raw'),
        shift: shift,
        onRename: (v) => _renameShift(shift, v),
        onMethod: (v) => _method(shift, v),
        onSlots: (next) => _slots(shift, next),
        onDelete: () => unawaited(_deleteShift(raw)),
      );
    }
    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: _muted)));
    }

    final hasAny = true;
    final detailId = _activeId;

    final Widget body;
    if (widget.masterDetail && hasAny) {
      final selected = detailId ?? _defaultDetailId()!;
      body = Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(width: siteCatalogMasterListW, child: _listPane(selectedId: selected)),
          siteCatalogMasterDivider(context),
          Expanded(child: _detailPane(selected)),
        ],
      );
    } else {
      body = widget.masterDetail || detailId == null ? _listPane(selectedId: detailId) : _detailPane(detailId);
    }

    if (_error == null || _error!.isEmpty) return body;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Material(
          color: const Color(0x33F87171),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Text(_error!, style: const TextStyle(color: Color(0xFFF87171), fontSize: 12)),
          ),
        ),
        Expanded(child: body),
      ],
    );
  }
}

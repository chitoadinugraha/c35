import 'package:alienai_c35/c/pb/c35/site.pb.dart';
import 'package:alienai_c35/widgets/sites/editor/site_attendance_detail_ids.dart';
import 'package:alienai_c35/widgets/sites/editor/ui_site_catalog_toolbar.dart';
import 'package:alienai_c35/c/site/site_work_shift_ui.dart';
import 'package:alienai_c35/widgets/ui/ui_empty_state.dart';
import 'package:flutter/material.dart';

const _border = Color(0xFF27272A);
const _muted = Color(0xFF71717A);
const _text = Color(0xFFF4F4F5);
const _accent = Color(0xFF34D399);

class UiSiteAttendanceSection extends StatelessWidget {
  const UiSiteAttendanceSection({
    super.key,
    required this.searchController,
    required this.search,
    required this.onSearchChanged,
    required this.locations,
    required this.shifts,
    required this.selectedId,
    required this.onSelect,
    required this.onAddArea,
    required this.onAddShift,
    this.masterDetail = true,
  });

  final TextEditingController searchController;
  final String search;
  final ValueChanged<String> onSearchChanged;
  final List<SitePresenceLocation> locations;
  final List<SiteWorkShift> shifts;
  final String? selectedId;
  final ValueChanged<String> onSelect;
  final VoidCallback onAddArea;
  final VoidCallback onAddShift;
  final bool masterDetail;

  List<SitePresenceLocation> get _filteredAreas {
    final q = search.trim().toLowerCase();
    if (q.isEmpty) return locations;
    return locations.where((l) => l.name.toLowerCase().contains(q)).toList(growable: false);
  }

  List<SiteWorkShift> get _filteredShifts {
    final q = search.trim().toLowerCase();
    if (q.isEmpty) return shifts;
    return shifts
        .where((s) {
          return s.name.toLowerCase().contains(q) ||
              siteWorkShiftAttendanceLabel(s.attendanceMethod).toLowerCase().contains(q);
        })
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final areas = _filteredAreas;
    final shiftList = _filteredShifts;
    final empty = areas.isEmpty && shiftList.isEmpty;
    final searching = search.trim().isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        UiSiteCatalogToolbar(
          searchController: searchController,
          hintText: 'Search attendance',
          onSearchChanged: onSearchChanged,
          menuItems: const [
            SiteCatalogMenuItem(value: 'area', label: 'Add area', leading: Icon(Icons.location_on_outlined, size: 18)),
            SiteCatalogMenuItem(value: 'shift', label: 'Add work hours', leading: Icon(Icons.schedule_outlined, size: 18)),
          ],
          onMenuAction: (a) {
            if (a == 'area') onAddArea();
            if (a == 'shift') onAddShift();
          },
        ),
        Expanded(
          child: empty
              ? UiEmptyState(
                  icon: Icons.fingerprint_outlined,
                  title: searching ? 'No matches' : 'No attendance setup',
                  subtitle: searching ? 'Try another search' : 'Add an area or work hours schedule',
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(8, 4, 8, 12),
                  children: [
                    _sectionHeader('Area'),
                    if (areas.isEmpty)
                      _emptyHint(searching ? 'No matching areas' : 'No areas yet')
                    else
                      for (var i = 0; i < areas.length; i++) ...[
                        if (i > 0) const SizedBox(height: 6),
                        _areaTile(areas[i]),
                      ],
                    _sectionHeader('Work hours'),
                    if (shiftList.isEmpty)
                      _emptyHint(searching ? 'No matching schedules' : 'No work hours yet')
                    else
                      for (var i = 0; i < shiftList.length; i++) ...[
                        if (i > 0) const SizedBox(height: 6),
                        _shiftTile(shiftList[i]),
                      ],
                  ],
                ),
        ),
      ],
    );
  }

  Widget _sectionHeader(String label) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 10, 4, 6),
        child: Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8,
            color: _muted,
          ),
        ),
      );

  Widget _emptyHint(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8, left: 4),
        child: Text(text, style: const TextStyle(fontSize: 12, color: _muted)),
      );

  Widget _areaTile(SitePresenceLocation loc) {
    final detailId = siteAttendanceAreaDetailId(loc.id);
    final active = detailId == selectedId;
    final name = loc.name.trim().isEmpty ? 'Unnamed area' : loc.name.trim();
    final points = loc.polygon.length;

    return Material(
      color: active ? const Color(0xFF1A2E28) : const Color(0xFF18181B),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: active ? _accent.withValues(alpha: 0.45) : _border.withValues(alpha: 0.85)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => onSelect(detailId),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Icon(Icons.location_on_outlined, size: 18, color: active ? _accent : _muted),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        color: _text,
                        fontSize: 13,
                        fontWeight: active ? FontWeight.w700 : FontWeight.w600,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        sitePresenceAreaListSubtitle(points),
                        style: const TextStyle(fontSize: 11, color: _muted),
                      ),
                    ),
                  ],
                ),
              ),
              if (!masterDetail) const Icon(Icons.chevron_right, size: 18, color: _muted),
            ],
          ),
        ),
      ),
    );
  }

  Widget _shiftTile(SiteWorkShift shift) {
    final detailId = siteAttendanceShiftDetailId(shift.id);
    final active = detailId == selectedId;
    final name = shift.name.trim().isEmpty ? 'Unnamed schedule' : shift.name.trim();
    return Material(
      color: active ? const Color(0xFF1A2E28) : const Color(0xFF18181B),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: active ? _accent.withValues(alpha: 0.45) : _border.withValues(alpha: 0.85)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => onSelect(detailId),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Icon(Icons.schedule_outlined, size: 18, color: active ? _accent : _muted),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        color: _text,
                        fontSize: 13,
                        fontWeight: active ? FontWeight.w700 : FontWeight.w600,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        siteWorkShiftSubtitle(shift),
                        style: const TextStyle(fontSize: 11, color: _muted),
                      ),
                    ),
                  ],
                ),
              ),
              if (!masterDetail) const Icon(Icons.chevron_right, size: 18, color: _muted),
            ],
          ),
        ),
      ),
    );
  }
}

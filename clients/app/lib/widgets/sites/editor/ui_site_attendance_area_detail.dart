import 'package:alienai_c35/c/config.dart';
import 'package:alienai_c35/c/geo/geo_geocode.dart';
import 'package:alienai_c35/c/pb/c35/site.pb.dart';
import 'package:alienai_c35/c/site/site_work_shift_ui.dart';
import 'package:alienai_c35/widgets/io/in_geo_area.dart';
import 'package:alienai_c35/widgets/sites/editor/ui_site_catalog_detail_header.dart';
import 'package:alienai_c35/widgets/sites/editor/ui_site_editor_form.dart';
import 'package:alienai_c35/widgets/ui/ui_input_decoration.dart';
import 'package:flutter/material.dart';

class UiSiteAttendanceAreaDetail extends StatefulWidget {
  const UiSiteAttendanceAreaDetail({
    super.key,
    required this.location,
    required this.onPatch,
    required this.onDelete,
    this.initialCenterLat,
    this.initialCenterLng,
  });

  final SitePresenceLocation location;
  final void Function(void Function(SitePresenceLocation loc) fn) onPatch;
  final VoidCallback onDelete;
  final double? initialCenterLat;
  final double? initialCenterLng;

  @override
  State<UiSiteAttendanceAreaDetail> createState() => _UiSiteAttendanceAreaDetailState();
}

class _UiSiteAttendanceAreaDetailState extends State<UiSiteAttendanceAreaDetail> {
  late final _nameCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _nameCtrl.text = widget.location.name;
  }

  @override
  void didUpdateWidget(covariant UiSiteAttendanceAreaDetail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.location.id != widget.location.id) {
      _nameCtrl.text = widget.location.name;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  String get _geoBaseUrl => C35Config.authApiBase.replaceAll(RegExp(r'/+$'), '');

  List<GeoAreaPoint> get _points => [
        for (final p in widget.location.polygon) GeoAreaPoint(lat: p.lat, lng: p.lng),
      ];

  @override
  Widget build(BuildContext context) {
    final loc = widget.location;
    final pointCount = loc.polygon.length;
    final cs = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
      children: [
        UiSiteCatalogDetailHeader(
          title: 'Attendance area',
          subtitle: sitePresenceAreaListSubtitle(pointCount),
          icon: Icons.location_on_outlined,
          onDelete: widget.onDelete,
          deleteConfirmTitle: 'Delete attendance area?',
          deleteConfirmBody: loc.name.trim().isEmpty ? 'This area will be removed.' : 'Delete ${loc.name.trim()}?',
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _nameCtrl,
          decoration: UiInputDecoration.of(context, labelText: 'Area name'),
          onChanged: (v) => widget.onPatch((l) => l.name = v),
        ),
        const SizedBox(height: 12),
        InGeoArea(
          baseUrl: _geoBaseUrl,
          labelText: 'Geofence',
          points: _points,
          initialCenterLat: widget.initialCenterLat,
          initialCenterLng: widget.initialCenterLng,
          onChanged: (v) => widget.onPatch((l) {
            l.polygon
              ..clear()
              ..addAll([for (final p in v.points) SitePresenceLatLng(lat: p.lat, lng: p.lng)]);
          }),
        ),
        const SizedBox(height: 12),
        Text(
          'Staff must be inside this geofence to clock in when the shift uses location attendance.',
          style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
        ),
      ],
    );
  }
}

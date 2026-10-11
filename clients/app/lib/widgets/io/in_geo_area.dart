import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import 'package:alienai_c35/c/geo/geo_geocode.dart';
import 'package:alienai_c35/widgets/ui/ui_input_decoration.dart';

const _defaultCenter = LatLng(-6.2, 106.816666);

/// Tappable geofence field — opens map picker to draw / edit a polygon.
class InGeoArea extends StatelessWidget {
  const InGeoArea({
    super.key,
    required this.baseUrl,
    required this.points,
    required this.onChanged,
    this.labelText = 'Area',
    this.initialCenterLat,
    this.initialCenterLng,
  });

  final String baseUrl;
  final List<GeoAreaPoint> points;
  final ValueChanged<GeoAreaValue> onChanged;
  final String labelText;
  final double? initialCenterLat;
  final double? initialCenterLng;

  Future<void> _open(BuildContext context) async {
    final result = await Navigator.push<GeoAreaValue>(
      context,
      MaterialPageRoute(
        builder: (_) => _InGeoAreaPicker(
          baseUrl: baseUrl,
          initialPoints: points,
          initialCenterLat: initialCenterLat,
          initialCenterLng: initialCenterLng,
        ),
      ),
    );
    if (result != null) onChanged(result);
  }

  String get _summary {
    final n = points.length;
    if (n == 0) return 'Tap to draw area';
    return '$n polygon point${n == 1 ? '' : 's'}';
  }

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: () => _open(context),
        borderRadius: BorderRadius.circular(UiInputDecoration.kRadius),
        child: InputDecorator(
          decoration: UiInputDecoration.of(context, labelText: labelText),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  _summary,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    color: points.isEmpty ? Theme.of(context).colorScheme.onSurfaceVariant : null,
                  ),
                ),
              ),
              Icon(Icons.chevron_right, size: 20, color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
            ],
          ),
        ),
      );
}

class _InGeoAreaPicker extends StatefulWidget {
  const _InGeoAreaPicker({
    required this.baseUrl,
    required this.initialPoints,
    this.initialCenterLat,
    this.initialCenterLng,
  });

  final String baseUrl;
  final List<GeoAreaPoint> initialPoints;
  final double? initialCenterLat;
  final double? initialCenterLng;

  @override
  State<_InGeoAreaPicker> createState() => _InGeoAreaPickerState();
}

class _InGeoAreaPickerState extends State<_InGeoAreaPicker> {
  final _search = TextEditingController();
  final _searchFocus = FocusNode();
  final _resultsScroll = ScrollController();
  final _mapCtrl = MapController();
  Timer? _searchTimer;
  var _loading = true;
  var _searchLoading = false;
  var _error = '';
  late var _points = <LatLng>[for (final p in widget.initialPoints) LatLng(p.lat, p.lng)];
  var _searchResults = <GeocodeResult>[];
  var _searchOpen = false;
  var _searchHighlight = -1;

  @override
  void initState() {
    super.initState();
    _searchFocus.onKeyEvent = _onSearchKey;
    _initCenter();
  }

  @override
  void dispose() {
    _searchTimer?.cancel();
    _search.dispose();
    _searchFocus.dispose();
    _resultsScroll.dispose();
    _mapCtrl.dispose();
    super.dispose();
  }

  LatLng get _fallbackCenter {
    if (_points.isNotEmpty) return _points.first;
    final lat = widget.initialCenterLat;
    final lng = widget.initialCenterLng;
    if (lat != null && lng != null) return LatLng(lat, lng);
    return _defaultCenter;
  }

  Future<void> _initCenter() async {
    if (_points.length >= 2) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _fitPoints();
        setState(() => _loading = false);
      });
      return;
    }
    if (_points.length == 1) {
      _scheduleMapMove(_points.first.latitude, _points.first.longitude);
      if (mounted) setState(() => _loading = false);
      return;
    }
    if (widget.initialCenterLat != null && widget.initialCenterLng != null) {
      _scheduleMapMove(widget.initialCenterLat!, widget.initialCenterLng!);
      if (mounted) setState(() => _loading = false);
      return;
    }
    try {
      final perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        final req = await Geolocator.requestPermission();
        if (req == LocationPermission.denied || req == LocationPermission.deniedForever) {
          await _setDefault();
          return;
        }
      }
      final pos = await Geolocator.getCurrentPosition();
      _scheduleMapMove(pos.latitude, pos.longitude);
      if (mounted) setState(() => _loading = false);
    } on Object {
      await _setDefault();
    }
  }

  Future<void> _setDefault() async {
    _scheduleMapMove(_defaultCenter.latitude, _defaultCenter.longitude);
    if (mounted) setState(() => _loading = false);
  }

  void _scheduleMapMove(double lat, double lng, {double zoom = 15}) => WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _mapCtrl.move(LatLng(lat, lng), zoom);
      });

  void _fitPoints() {
    if (_points.isEmpty) return;
    if (_points.length == 1) {
      _scheduleMapMove(_points.first.latitude, _points.first.longitude);
      return;
    }
    final bounds = LatLngBounds.fromPoints(_points);
    _mapCtrl.fitCamera(CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(48)));
  }

  void _onTap(TapPosition _, LatLng point) {
    if (_searchOpen) {
      setState(() {
        _searchOpen = false;
        _searchHighlight = -1;
      });
      return;
    }
    setState(() => _points = [..._points, point]);
  }

  void _undo() {
    if (_points.isEmpty) return;
    setState(() => _points = _points.sublist(0, _points.length - 1));
  }

  void _clear() => setState(() => _points = []);

  void _removeAt(int i) {
    if (i < 0 || i >= _points.length) return;
    setState(() => _points = [..._points]..removeAt(i));
  }

  void _onSearchChanged(String value) {
    _searchTimer?.cancel();
    _searchTimer = Timer(const Duration(milliseconds: 300), () async {
      if (!mounted) return;
      setState(() => _searchLoading = true);
      try {
        final results = await geoAddressSearch(widget.baseUrl, value);
        if (!mounted) return;
        setState(() {
          _searchResults = results;
          _searchOpen = results.isNotEmpty;
          _searchHighlight = results.isEmpty ? -1 : 0;
        });
      } finally {
        if (mounted) setState(() => _searchLoading = false);
      }
    });
  }

  void _moveHighlight(int delta) {
    if (!_searchOpen || _searchResults.isEmpty) return;
    final next = (_searchHighlight + delta).clamp(0, _searchResults.length - 1);
    if (next == _searchHighlight) return;
    setState(() => _searchHighlight = next);
    _scrollHighlightIntoView();
  }

  void _scrollHighlightIntoView() {
    if (!_resultsScroll.hasClients || _searchHighlight < 0) return;
    const itemExtent = 56.0;
    final target = _searchHighlight * itemExtent;
    final view = _resultsScroll.position;
    if (target < view.pixels) {
      _resultsScroll.jumpTo(target);
    } else if (target + itemExtent > view.pixels + view.viewportDimension) {
      _resultsScroll.jumpTo(target + itemExtent - view.viewportDimension);
    }
  }

  KeyEventResult _onSearchKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) return KeyEventResult.ignored;
    final key = event.logicalKey;
    final hasResults = _searchResults.isNotEmpty;
    if (key == LogicalKeyboardKey.arrowDown) {
      if (!hasResults) return KeyEventResult.ignored;
      if (!_searchOpen) {
        setState(() {
          _searchOpen = true;
          _searchHighlight = 0;
        });
      } else {
        _moveHighlight(1);
      }
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowUp) {
      if (!_searchOpen || !hasResults) return KeyEventResult.ignored;
      _moveHighlight(-1);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.enter || key == LogicalKeyboardKey.numpadEnter) {
      if (_searchOpen && _searchHighlight >= 0 && _searchHighlight < _searchResults.length) {
        _selectResult(_searchResults[_searchHighlight]);
        return KeyEventResult.handled;
      }
    }
    if (key == LogicalKeyboardKey.escape) {
      if (_searchOpen) {
        setState(() {
          _searchOpen = false;
          _searchHighlight = -1;
        });
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  Future<void> _useMyLocation() async {
    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) {
        if (mounted) setState(() => _error = 'Could not access device location.');
        return;
      }
      final pos = await Geolocator.getCurrentPosition();
      if (!mounted) return;
      setState(() => _error = '');
      _scheduleMapMove(pos.latitude, pos.longitude);
    } on Object {
      if (mounted) setState(() => _error = 'Could not access device location.');
    }
  }

  void _selectResult(GeocodeResult result) {
    setState(() {
      _searchOpen = false;
      _searchResults = [];
      _searchHighlight = -1;
      _search.text = result.label;
    });
    _scheduleMapMove(result.lat, result.lng);
  }

  void _save() {
    Navigator.pop(
      context,
      GeoAreaValue(points: [for (final p in _points) GeoAreaPoint(lat: p.latitude, lng: p.longitude)]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final n = _points.length;
    return Scaffold(
      appBar: AppBar(
        title: Text('Attendance area'),
        actions: [
          TextButton(onPressed: _save, child: Text('Save')),
        ],
      ),
      body: Stack(
        clipBehavior: Clip.none,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: TextField(
                  controller: _search,
                  focusNode: _searchFocus,
                  decoration: UiInputDecoration.of(context, hintText: 'Search address').copyWith(
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchLoading
                        ? const Padding(padding: EdgeInsets.all(12), child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)))
                        : null,
                  ),
                  onChanged: _onSearchChanged,
                  onTap: () {
                    if (_searchResults.isNotEmpty) {
                      setState(() {
                        _searchOpen = true;
                        if (_searchHighlight < 0) _searchHighlight = 0;
                      });
                    }
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Text(
                  n == 0
                      ? 'Tap the map to add polygon points'
                      : n < 3
                          ? '$n point${n == 1 ? '' : 's'} — need at least 3 to close the area'
                          : '$n points — tap a marker to remove',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(UiInputDecoration.kRadius),
                    child: Stack(
                      children: [
                        FlutterMap(
                          mapController: _mapCtrl,
                          options: MapOptions(
                            initialCenter: _fallbackCenter,
                            initialZoom: 15,
                            onTap: _onTap,
                            interactionOptions: const InteractionOptions(flags: InteractiveFlag.all & ~InteractiveFlag.rotate),
                          ),
                          children: [
                            TileLayer(
                              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                              userAgentPackageName: 'id.alienai.app',
                            ),
                            if (_points.length >= 2)
                              PolylineLayer(
                                polylines: [
                                  Polyline(
                                    points: n >= 3 ? [..._points, _points.first] : _points,
                                    color: cs.primary,
                                    strokeWidth: 2.5,
                                  ),
                                ],
                              ),
                            if (_points.length >= 3)
                              PolygonLayer(
                                polygons: [
                                  Polygon(
                                    points: _points,
                                    color: cs.primary.withValues(alpha: 0.22),
                                    borderColor: cs.primary,
                                    borderStrokeWidth: 0,
                                  ),
                                ],
                              ),
                            MarkerLayer(
                              markers: [
                                for (var i = 0; i < _points.length; i++)
                                  Marker(
                                    point: _points[i],
                                    width: 28,
                                    height: 28,
                                    child: GestureDetector(
                                      onTap: () => _removeAt(i),
                                      child: DecoratedBox(
                                        decoration: BoxDecoration(
                                          color: cs.primary,
                                          shape: BoxShape.circle,
                                          border: Border.all(color: cs.onPrimary, width: 2),
                                          boxShadow: const [BoxShadow(blurRadius: 4, color: Color(0x44000000))],
                                        ),
                                        child: Center(
                                          child: Text(
                                            '${i + 1}',
                                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: cs.onPrimary),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                        Positioned(
                          right: 12,
                          bottom: 12,
                          child: Material(
                            elevation: 2,
                            color: cs.surface,
                            shape: const CircleBorder(),
                            clipBehavior: Clip.antiAlias,
                            child: IconButton(
                              onPressed: _useMyLocation,
                              icon: const Icon(Icons.my_location),
                              tooltip: 'Use my location',
                            ),
                          ),
                        ),
                        if (_loading)
                          const ColoredBox(
                            color: Color(0x88000000),
                            child: Center(child: CircularProgressIndicator()),
                          ),
                        if (_error.isNotEmpty)
                          Positioned(
                            top: 12,
                            left: 12,
                            right: 12,
                            child: Material(
                              color: cs.errorContainer,
                              borderRadius: BorderRadius.circular(8),
                              child: Padding(
                                padding: const EdgeInsets.all(10),
                                child: Text(_error, style: TextStyle(color: cs.onErrorContainer)),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: Row(
                    children: [
                      OutlinedButton.icon(
                        onPressed: _points.isEmpty ? null : _undo,
                        icon: const Icon(Icons.undo, size: 18),
                        label: Text('Undo'),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        onPressed: _points.isEmpty ? null : _clear,
                        icon: const Icon(Icons.delete_outline, size: 18),
                        label: Text('Clear'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (_searchOpen && _searchResults.isNotEmpty)
            Positioned(
              left: 16,
              right: 16,
              top: 64,
              child: Material(
                elevation: 8,
                color: cs.surface,
                borderRadius: BorderRadius.circular(UiInputDecoration.kRadius),
                clipBehavior: Clip.antiAlias,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 180),
                  child: ListView.builder(
                    controller: _resultsScroll,
                    shrinkWrap: true,
                    padding: EdgeInsets.zero,
                    itemCount: _searchResults.length,
                    itemBuilder: (context, i) {
                      final result = _searchResults[i];
                      final selected = i == _searchHighlight;
                      return ListTile(
                        dense: true,
                        selected: selected,
                        selectedTileColor: cs.primaryContainer.withValues(alpha: 0.45),
                        title: Text(result.label, maxLines: 2, overflow: TextOverflow.ellipsis),
                        onTap: () => _selectResult(result),
                      );
                    },
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

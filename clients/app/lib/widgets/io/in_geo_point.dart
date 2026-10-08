import 'dart:async';

import 'package:alienai_c35/c/geo/geo_geocode.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import 'package:alienai_c35/widgets/ui/ui_input_decoration.dart';

const _defaultCenter = LatLng(-6.2, 106.816666);

/// Tappable location field — opens map picker with search + reverse geocoding.
class InGeoPoint extends StatelessWidget {
  const InGeoPoint({
    super.key,
    required this.baseUrl,
    required this.locationLabel,
    required this.latitude,
    required this.longitude,
    required this.onChanged,
    this.labelText = 'Location',
  });

  final String baseUrl;
  final String locationLabel;
  final double? latitude;
  final double? longitude;
  final ValueChanged<GeoPointValue> onChanged;
  final String labelText;

  Future<void> _open(BuildContext context) async {
    final result = await Navigator.push<GeoPointValue>(
      context,
      MaterialPageRoute(
        builder: (_) => _InGeoPointPicker(
          baseUrl: baseUrl,
          initialLabel: locationLabel,
          initialLat: latitude,
          initialLng: longitude,
        ),
      ),
    );
    if (result != null) onChanged(result);
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
                  locationLabel.trim().isNotEmpty ? locationLabel.trim() : 'Tap to set location',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    color: locationLabel.trim().isNotEmpty ? null : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              Icon(Icons.chevron_right, size: 20, color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
            ],
          ),
        ),
      );
}

class _InGeoPointPicker extends StatefulWidget {
  const _InGeoPointPicker({
    required this.baseUrl,
    this.initialLabel = '',
    this.initialLat,
    this.initialLng,
  });

  final String baseUrl;
  final String initialLabel;
  final double? initialLat;
  final double? initialLng;

  @override
  State<_InGeoPointPicker> createState() => _InGeoPointPickerState();
}

class _InGeoPointPickerState extends State<_InGeoPointPicker> {
  final _search = TextEditingController();
  final _searchFocus = FocusNode();
  final _resultsScroll = ScrollController();
  final _mapCtrl = MapController();
  Timer? _searchTimer;
  Timer? _reverseTimer;
  var _loading = true;
  var _searchLoading = false;
  var _error = '';
  var _draftLabel = '';
  double? _draftLat;
  double? _draftLng;
  var _searchResults = <GeocodeResult>[];
  var _searchOpen = false;
  var _searchHighlight = -1;
  var _suppressMoveEnd = false;
  var _suppressSearchChanged = false;

  @override
  void initState() {
    super.initState();
    _draftLabel = widget.initialLabel;
    _draftLat = widget.initialLat;
    _draftLng = widget.initialLng;
    _setSearchText(widget.initialLabel);
    _searchFocus.onKeyEvent = _onSearchKey;
    _searchFocus.addListener(_onSearchFocusChanged);
    _initCenter();
  }

  @override
  void dispose() {
    _searchTimer?.cancel();
    _reverseTimer?.cancel();
    _searchFocus.removeListener(_onSearchFocusChanged);
    _search.dispose();
    _searchFocus.dispose();
    _resultsScroll.dispose();
    _mapCtrl.dispose();
    super.dispose();
  }

  void _onSearchFocusChanged() {
    if (_searchFocus.hasFocus) _reverseTimer?.cancel();
  }

  void _setSearchText(String text) {
    if (_search.text == text) return;
    _suppressSearchChanged = true;
    _search.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
    _suppressSearchChanged = false;
  }

  void _dismissSearch() {
    _searchFocus.unfocus();
    if (!_searchOpen && _searchHighlight < 0) return;
    setState(() {
      _searchOpen = false;
      _searchHighlight = -1;
    });
  }

  bool get _searchActive => _searchFocus.hasFocus || _searchOpen;

  void _handlePop() {
    if (_searchOpen) {
      setState(() {
        _searchOpen = false;
        _searchHighlight = -1;
      });
      return;
    }
    if (_searchFocus.hasFocus) {
      _searchFocus.unfocus();
      return;
    }
    Navigator.of(context).pop();
  }

  LatLng get _mapCenter => LatLng(_draftLat ?? _defaultCenter.latitude, _draftLng ?? _defaultCenter.longitude);

  Future<void> _initCenter() async {
    if (_draftLat != null && _draftLng != null) {
      _scheduleMapMove(_draftLat!, _draftLng!);
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
      await _moveMap(pos.latitude, pos.longitude, reverse: true);
    } on Object {
      await _setDefault();
    }
  }

  Future<void> _setDefault() async {
    await _moveMap(_defaultCenter.latitude, _defaultCenter.longitude, reverse: _draftLabel.isEmpty);
    if (mounted) setState(() => _loading = false);
  }

  void _scheduleMapMove(double lat, double lng) => WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _suppressMoveEnd = true;
        _mapCtrl.move(LatLng(lat, lng), 15);
        Future.delayed(const Duration(milliseconds: 350), () {
          if (mounted) _suppressMoveEnd = false;
        });
      });

  Future<void> _moveMap(double lat, double lng, {bool reverse = false}) async {
    setState(() {
      _draftLat = lat;
      _draftLng = lng;
      _loading = false;
    });
    _scheduleMapMove(lat, lng);
    if (reverse) await _reverseGeocode(lat, lng);
  }

  Future<void> _reverseGeocode(double lat, double lng) async {
    if (_searchActive) return;
    var label = await geoReverseLabel(widget.baseUrl, lat, lng);
    if (label.isEmpty) label = geoCoordLabel(lat, lng);
    if (!mounted || _searchActive) return;
    setState(() => _draftLabel = label);
    _setSearchText(label);
  }

  void _onMapMoveEnd() {
    if (_suppressMoveEnd) return;
    if (_searchOpen) _dismissSearch();
    if (_searchFocus.hasFocus) return;
    final center = _mapCtrl.camera.center;
    setState(() {
      _draftLat = center.latitude;
      _draftLng = center.longitude;
    });
    _reverseTimer?.cancel();
    _reverseTimer = Timer(const Duration(milliseconds: 400), () => _reverseGeocode(center.latitude, center.longitude));
  }

  void _onSearchChanged(String value) {
    if (_suppressSearchChanged) return;
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
      if (_searchFocus.hasFocus) {
        _searchFocus.unfocus();
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
      await _moveMap(pos.latitude, pos.longitude, reverse: true);
    } on Object {
      if (mounted) setState(() => _error = 'Could not access device location.');
    }
  }

  void _selectResult(GeocodeResult result) {
    _searchFocus.unfocus();
    setState(() {
      _searchOpen = false;
      _searchResults = [];
      _searchHighlight = -1;
      _draftLabel = result.label;
    });
    _setSearchText(result.label);
    _moveMap(result.lat, result.lng);
  }

  void _save() {
    final lat = _draftLat;
    final lng = _draftLng;
    if (lat == null || lng == null) return;
    Navigator.pop(
      context,
      GeoPointValue(
        label: _draftLabel.trim().isNotEmpty ? _draftLabel.trim() : geoCoordLabel(lat, lng),
        latitude: lat,
        longitude: lng,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _handlePop();
      },
      child: Scaffold(
      appBar: AppBar(
        title: const Text('Location'),
        leading: BackButton(onPressed: _handlePop),
        actions: [
          TextButton(onPressed: _draftLat != null && _draftLng != null ? _save : null, child: const Text('Save')),
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
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                child: Text(
                  _draftLabel.isNotEmpty ? _draftLabel : 'No address yet',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: _draftLabel.isNotEmpty ? null : cs.onSurfaceVariant,
                      ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(UiInputDecoration.kRadius),
                    child: Stack(
                      children: [
                        FlutterMap(
                          mapController: _mapCtrl,
                          options: MapOptions(
                            initialCenter: _mapCenter,
                            initialZoom: 15,
                            onTap: (_, __) => _dismissSearch(),
                            onMapEvent: (event) {
                              if (event is MapEventMoveStart) _dismissSearch();
                              if (event is MapEventMoveEnd) _onMapMoveEnd();
                            },
                            interactionOptions: const InteractionOptions(flags: InteractiveFlag.all & ~InteractiveFlag.rotate),
                          ),
                          children: [
                            TileLayer(
                              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                              userAgentPackageName: 'id.alienai.app',
                            ),
                          ],
                        ),
                        IgnorePointer(
                          child: Center(
                            child: Transform.translate(
                              offset: const Offset(0, -18),
                              child: Icon(Icons.location_on, size: 44, color: cs.error),
                            ),
                          ),
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
    ),
    );
  }
}

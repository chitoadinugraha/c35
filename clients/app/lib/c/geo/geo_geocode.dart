import 'dart:convert';

import 'package:http/http.dart' as http;

class GeoPointValue {
  const GeoPointValue({required this.label, required this.latitude, required this.longitude});

  final String label;
  final double latitude;
  final double longitude;
}

class GeocodeResult {
  const GeocodeResult({required this.lat, required this.lng, required this.label});

  final double lat;
  final double lng;
  final String label;
}

const _geoSearchPath = '/api/geo/search';
const _geoReversePath = '/api/geo/reverse';

Future<List<GeocodeResult>> geoAddressSearch(String baseUrl, String query) async {
  final q = query.trim();
  if (q.length < 2) return [];
  try {
    final root = baseUrl.replaceAll(RegExp(r'/+$'), '');
    final uri = Uri.parse('$root$_geoSearchPath').replace(queryParameters: {'q': q});
    final resp = await http.get(uri);
    if (resp.statusCode != 200) return [];
    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    final rows = (data['results'] as List?)?.cast<Map<String, dynamic>>() ?? const [];
    return rows
        .map((row) {
          final lat = (row['lat'] as num?)?.toDouble();
          final lng = (row['lng'] as num?)?.toDouble();
          final label = (row['label'] as String?)?.trim() ?? '';
          if (lat == null || lng == null || label.isEmpty) return null;
          return GeocodeResult(lat: lat, lng: lng, label: label);
        })
        .whereType<GeocodeResult>()
        .toList();
  } on Object {
    return [];
  }
}

Future<String> geoReverseLabel(String baseUrl, double lat, double lng) async {
  try {
    final root = baseUrl.replaceAll(RegExp(r'/+$'), '');
    final uri = Uri.parse('$root$_geoReversePath').replace(queryParameters: {'lat': '$lat', 'lng': '$lng'});
    final resp = await http.get(uri);
    if (resp.statusCode != 200) return '';
    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    return (data['label'] as String?)?.trim() ?? '';
  } on Object {
    return '';
  }
}

String geoCoordLabel(double lat, double lng) => '${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}';

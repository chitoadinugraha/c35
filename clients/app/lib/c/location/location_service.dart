import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

class LocationResolveResult {
  const LocationResolveResult({required this.city, required this.region, required this.country});

  final String city;
  final String region;
  final String country;
}

LocationResolveResult? _locationResolveCache;

Future<LocationResolveResult?> locationServiceResolve({bool force = false}) async {
  if (kIsWeb || !(Platform.isAndroid || Platform.isIOS)) return null;
  if (!force && _locationResolveCache != null) return _locationResolveCache;
  try {
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) return null;
    final pos = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.low, timeLimit: Duration(seconds: 12)),
    );
    final marks = await placemarkFromCoordinates(pos.latitude, pos.longitude);
    if (marks.isEmpty) return null;
    final p = marks.first;
    final city = (p.locality?.trim().isNotEmpty == true ? p.locality! : p.subAdministrativeArea ?? p.administrativeArea ?? '').trim();
    final region = (p.administrativeArea ?? p.subAdministrativeArea ?? '').trim();
    final country = (p.isoCountryCode ?? '').trim().toUpperCase();
    if (city.isEmpty && region.isEmpty && country.isEmpty) return null;
    _locationResolveCache = LocationResolveResult(city: city, region: region, country: country);
    return _locationResolveCache;
  } catch (_) {
    return null;
  }
}

void locationServiceCacheClear() => _locationResolveCache = null;

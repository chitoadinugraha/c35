import 'dart:convert';

import 'package:alienai_c35/c/pb/c35/site.pb.dart';
import 'package:alienai_c35/c/site/site_schedule.dart';

class SiteInfoSnapshot {
  const SiteInfoSnapshot({
    required this.name,
    required this.tagline,
    required this.pic,
    required this.locationLabel,
    required this.locationHref,
    this.latitude,
    this.longitude,
    this.openHours = const [],
  });

  final String name;
  final String tagline;
  final String pic;
  final String locationLabel;
  final String locationHref;
  final double? latitude;
  final double? longitude;
  final List<SiteScheduleSlot> openHours;
}

String siteMetaTaglineRead(String metaJson) {
  final map = _metaMap(metaJson);
  final tagline = map['tagline']?.toString().trim() ?? '';
  if (tagline.isNotEmpty) return tagline;
  return map['seo_desc']?.toString().trim() ?? '';
}

String siteMetaMergeInfo(
  String metaJson, {
  String? tagline,
  String? locationLabel,
  String? locationHref,
  double? latitude,
  double? longitude,
  List<SiteScheduleSlot>? openHours,
}) {
  final map = _metaMap(metaJson);
  if (tagline != null) {
    final t = tagline.trim();
    if (t.isEmpty) {
      map.remove('tagline');
      map.remove('seo_desc');
    } else {
      map['tagline'] = t;
      map['seo_desc'] = t;
    }
    map.remove('seo_title');
  }
  if (locationLabel != null) {
    final label = locationLabel.trim();
    if (label.isEmpty) {
      map.remove('location_label');
    } else {
      map['location_label'] = label;
    }
  }
  if (locationHref != null) {
    final href = locationHref.trim();
    if (href.isEmpty) {
      map.remove('location_href');
    } else {
      map['location_href'] = href;
    }
  }
  if (latitude != null) {
    map['lat'] = latitude;
  }
  if (longitude != null) {
    map['lng'] = longitude;
  }
  if (openHours != null) {
    if (openHours.isEmpty) {
      map.remove('open_hours');
    } else {
      map['open_hours'] = openHours.map((s) => s.toJson()).toList(growable: false);
    }
  }
  return jsonEncode(map);
}

SiteDoc siteInfoApplyToDoc(SiteDoc doc, SiteInfoSnapshot snap) {
  final out = doc.clone();
  out.metaJson = siteMetaMergeInfo(
    out.metaJson,
    tagline: snap.tagline,
    locationLabel: snap.locationLabel,
    locationHref: snap.locationHref,
    latitude: snap.latitude,
    longitude: snap.longitude,
    openHours: snap.openHours,
  );

  final hoursRows = siteScheduleSlotsToHoursRows(snap.openHours);
  final showHours = snap.openHours.isNotEmpty;

  for (final page in out.pages) {
    var hoursIdx = -1;
    for (var i = 0; i < page.blocks.length; i++) {
      final block = page.blocks[i];
      if (block.type == 'hours') hoursIdx = i;
      if (block.type == 'hub_profile' || block.type == 'hero') {
        final props = _propsMap(block.propsJson);
        if (block.type == 'hub_profile') {
          props['title'] = snap.name;
          props['subtitle'] = snap.tagline;
          if (snap.pic.isNotEmpty) props['pic'] = snap.pic;
          props['location_label'] = snap.locationLabel;
          props['location_href'] = snap.locationHref;
          props['show_hours'] = showHours;
        } else {
          props['title'] = snap.name;
          props['subtitle'] = snap.tagline;
          if (snap.pic.isNotEmpty) props['pic'] = snap.pic;
        }
        block.propsJson = jsonEncode(props);
      }
    }

    if (hoursRows.isNotEmpty) {
      final hoursProps = {'title': 'Open hours', 'schedule': hoursRows};
      if (hoursIdx >= 0) {
        page.blocks[hoursIdx].propsJson = jsonEncode(hoursProps);
      } else {
        final hubIdx = page.blocks.indexWhere((b) => b.type == 'hub_profile');
        final insertAt = hubIdx >= 0 ? hubIdx + 1 : 0;
        page.blocks.insert(
          insertAt,
          SiteBlock(id: 'hours1', type: 'hours', propsJson: jsonEncode(hoursProps)),
        );
      }
    } else if (hoursIdx >= 0) {
      page.blocks.removeAt(hoursIdx);
    }
  }
  return out;
}

Map<String, dynamic> _propsMap(String propsJson) {
  if (propsJson.trim().isEmpty) return {};
  try {
    final decoded = jsonDecode(propsJson);
    return decoded is Map<String, dynamic> ? Map<String, dynamic>.from(decoded) : {};
  } catch (_) {
    return {};
  }
}

Map<String, dynamic> _metaMap(String metaJson) {
  if (metaJson.trim().isEmpty) return {};
  try {
    final decoded = jsonDecode(metaJson);
    return decoded is Map<String, dynamic> ? decoded : {};
  } catch (_) {
    return {};
  }
}

String siteLocationHrefBuild({required String label, double? lat, double? lng}) {
  if (lat != null && lng != null) {
    return 'https://www.google.com/maps/search/?api=1&query=$lat,$lng';
  }
  final q = label.trim();
  if (q.isEmpty) return '';
  return 'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(q)}';
}

void siteMetaLocationRead(String metaJson, void Function(String label, String href, double? lat, double? lng) fn) {
  final map = _metaMap(metaJson);
  final lat = (map['lat'] as num?)?.toDouble();
  final lng = (map['lng'] as num?)?.toDouble();
  fn(
    map['location_label']?.toString() ?? '',
    map['location_href']?.toString() ?? '',
    lat,
    lng,
  );
}

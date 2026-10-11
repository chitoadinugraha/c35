import 'package:alienai_c35/c/pb/c35/site.pb.dart';
import 'package:flutter/material.dart';

const siteWorkShiftAttendanceMethods = ['none', 'geo', 'face', 'geo_face'];

String siteWorkShiftAttendanceLabel(String method) => switch (method) {
      'geo' => 'Location',
      'face' => 'Face',
      'geo_face' => 'Location and face',
      _ => 'None',
    };

IconData siteWorkShiftAttendanceIcon(String method) => switch (method) {
      'geo' => Icons.location_on_outlined,
      'face' => Icons.face_outlined,
      'geo_face' => Icons.verified_user_outlined,
      _ => Icons.touch_app_outlined,
    };

String siteWorkShiftSubtitle(SiteWorkShift shift) {
  final method = siteWorkShiftAttendanceMethods.contains(shift.attendanceMethod) ? shift.attendanceMethod : 'none';
  final slots = shift.slots.length;
  return '${siteWorkShiftAttendanceLabel(method)} · $slots slot${slots == 1 ? '' : 's'}';
}

String sitePresenceAreaListSubtitle(int pointCount) =>
    '$pointCount polygon point${pointCount == 1 ? '' : 's'}';

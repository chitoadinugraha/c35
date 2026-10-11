import 'package:alienai_c35/c/ui/ui_format.dart';
import 'package:easy_localization/easy_localization.dart';

String _uiDurationUnitLabel(UiDurationUnit unit, int count) {
  if (count <= 0) return '';
  final n = '$count';
  switch (unit) {
    case UiDurationUnit.month:
      return count == 1 ? 'time.unitMonth'.tr() : 'time.unitMonths'.tr(namedArgs: {'count': n});
    case UiDurationUnit.day:
      return count == 1 ? 'time.unitDay'.tr() : 'time.unitDays'.tr(namedArgs: {'count': n});
    case UiDurationUnit.hour:
      return count == 1 ? 'time.unitHour'.tr() : 'time.unitHours'.tr(namedArgs: {'count': n});
    case UiDurationUnit.minute:
      return count == 1 ? 'time.unitMinute'.tr() : 'time.unitMinutes'.tr(namedArgs: {'count': n});
    case UiDurationUnit.second:
      return count == 1 ? 'time.unitSecond'.tr() : 'time.unitSeconds'.tr(namedArgs: {'count': n});
  }
}

/// Largest unit only (e.g. `4 days`, `3 hours`) — for compact UI hints.
String uiFmtDurationOneMajor(Duration duration) {
  final parts = uiDurationTwoMajorParts(duration);
  return _uiDurationUnitLabel(parts.firstUnit, parts.first);
}

/// Human-readable span using two major units (e.g. `14 days 5 hours`, `4 hours 5 minutes`).
String uiFmtDurationTwoMajor(Duration duration) {
  final parts = uiDurationTwoMajorParts(duration);
  final a = _uiDurationUnitLabel(parts.firstUnit, parts.first);
  if (parts.second <= 0) return a;
  final b = _uiDurationUnitLabel(parts.secondUnit, parts.second);
  if (a.isEmpty) return b;
  if (b.isEmpty) return a;
  return '$a $b';
}

const _areaPrefix = 'area:';
const _shiftPrefix = 'shift:';
const _myClockDetailId = 'clock:my';

String siteAttendanceMyClockDetailId() => _myClockDetailId;

bool siteAttendanceDetailIsMyClock(String detailId) => detailId == _myClockDetailId;

String siteAttendanceAreaDetailId(String id) => '$_areaPrefix$id';
String siteAttendanceShiftDetailId(String id) => '$_shiftPrefix$id';

bool siteAttendanceDetailIsArea(String detailId) => detailId.startsWith(_areaPrefix);
bool siteAttendanceDetailIsShift(String detailId) => detailId.startsWith(_shiftPrefix);

String? siteAttendanceDetailRawId(String detailId) {
  if (detailId == _myClockDetailId) return 'my';
  if (detailId.startsWith(_areaPrefix)) return detailId.substring(_areaPrefix.length);
  if (detailId.startsWith(_shiftPrefix)) return detailId.substring(_shiftPrefix.length);
  return null;
}

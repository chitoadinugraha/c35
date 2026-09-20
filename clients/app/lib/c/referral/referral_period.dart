import 'package:alienai_c35/c/pb/c35/referral.pb.dart';
import 'package:fixnum/fixnum.dart';

enum ReferralPeriodPreset { thisWeek, lastWeek, mtd, lastMonth, custom }

typedef ReferralPeriodRange = ({DateTime from, DateTime to});

DateTime _startOfDay(DateTime d) => DateTime(d.year, d.month, d.day);

DateTime _startOfWeek(DateTime d) {
  final day = _startOfDay(d);
  final delta = day.weekday - DateTime.monday;
  return day.subtract(Duration(days: delta < 0 ? 6 : delta));
}

DateTime _startOfMonth(DateTime d) => DateTime(d.year, d.month);

ReferralPeriodRange referralPeriodRange(ReferralPeriodPreset preset, {DateTime? now, ReferralPeriodRange? custom}) {
  final cur = now ?? DateTime.now();
  switch (preset) {
    case ReferralPeriodPreset.thisWeek:
      return (from: _startOfWeek(cur), to: cur);
    case ReferralPeriodPreset.lastWeek:
      final start = _startOfWeek(cur).subtract(const Duration(days: 7));
      return (from: start, to: start.add(const Duration(days: 7)));
    case ReferralPeriodPreset.mtd:
      return (from: _startOfMonth(cur), to: cur);
    case ReferralPeriodPreset.lastMonth:
      final thisMonth = _startOfMonth(cur);
      final lastMonth = DateTime(thisMonth.year, thisMonth.month - 1);
      return (from: lastMonth, to: thisMonth);
    case ReferralPeriodPreset.custom:
      return custom ?? (from: _startOfMonth(cur), to: cur);
  }
}

ReferralStatPeriod referralStatPeriod(ReferralPeriodRange range) => ReferralStatPeriod(
      fromMs: Int64(range.from.millisecondsSinceEpoch),
      toMs: Int64(range.to.millisecondsSinceEpoch),
    );

String referralPeriodLabel(ReferralPeriodPreset preset) => switch (preset) {
      ReferralPeriodPreset.thisWeek => 'This Week',
      ReferralPeriodPreset.lastWeek => 'Last Week',
      ReferralPeriodPreset.mtd => 'MTD',
      ReferralPeriodPreset.lastMonth => 'Last Month',
      ReferralPeriodPreset.custom => 'Custom',
    };

String referralPeriodShortLabel(ReferralPeriodRange range) {
  final from = range.from;
  final to = range.to;
  String d(DateTime t) => '${t.month}/${t.day}';
  return '${d(from)} – ${d(to)}';
}

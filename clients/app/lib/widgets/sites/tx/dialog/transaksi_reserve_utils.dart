import 'package:alienai_c35/c/pb/c35/tx.pb.dart';

enum ReserveTimeUnit { minutes, hours, days }

String reserveTimeUnitLabel(ReserveTimeUnit unit) => switch (unit) {
      ReserveTimeUnit.minutes => 'Menit',
      ReserveTimeUnit.hours => 'Jam',
      ReserveTimeUnit.days => 'Hari',
    };

int calculateDurationQty(DateTime start, DateTime end, ReserveTimeUnit unit) {
  if (!end.isAfter(start)) return 1;
  final diff = end.difference(start);
  return switch (unit) {
    ReserveTimeUnit.minutes => (diff.inMinutes / 30).ceil().clamp(1, 9999),
    ReserveTimeUnit.hours => (diff.inMinutes / 60).ceil().clamp(1, 9999),
    ReserveTimeUnit.days => (diff.inHours / 24).ceil().clamp(1, 9999),
  };
}

String formatReserveRange(DateTime start, DateTime end, ReserveTimeUnit unit) {
  final startStr = '${start.day}/${start.month} ${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')}';
  final endStr = '${end.day}/${end.month} ${end.hour.toString().padLeft(2, '0')}:${end.minute.toString().padLeft(2, '0')}';
  return '$startStr – $endStr';
}

int totalLineQtyFromReservations(List<TxItemReservation> reservations) {
  if (reservations.isEmpty) return 0;
  return reservations.fold(0, (sum, r) => sum + (r.qty > 0 ? r.qty : 1) * (r.durationQty > 0 ? r.durationQty : 1));
}

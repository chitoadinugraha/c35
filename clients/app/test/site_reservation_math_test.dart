import 'package:alienai_c35/c/site/site_reservation_math.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('day range is half-open nights', () {
    final start = DateTime(2026, 1, 1);
    final end = DateTime(2026, 1, 3);
    expect(reservationDurationCount(start: start, end: end, unit: 'day'), 2);
    expect(reservationBillable(units: 2, durationCount: 2), 4);
  });

  test('hour keeps clock time', () {
    final start = DateTime(2026, 1, 1, 14);
    final end = DateTime(2026, 1, 1, 16);
    expect(reservationNeedsTime('hour'), isTrue);
    expect(reservationNeedsTime('day'), isFalse);
    expect(reservationNeedsTime(''), isFalse);
    expect(reservationNeedsTime('  day  '), isFalse);
    expect(reservationDurationCount(start: start, end: end, unit: 'hour'), 2);
  });

  test('month uses calendar month index', () {
    expect(
      reservationDurationCount(
        start: DateTime(2026, 1, 31),
        end: DateTime(2026, 3, 1),
        unit: 'month',
      ),
      2,
    );
    expect(
      reservationDurationCount(
        start: DateTime(2026, 1, 10),
        end: DateTime(2026, 1, 20),
        unit: 'month',
      ),
      0,
    );
  });

  test('end from duration inverts day and hour', () {
    final dayStart = DateTime(2026, 1, 1);
    final dayEnd = reservationEndFromDuration(start: dayStart, unit: 'day', count: 2);
    expect(dayEnd, DateTime(2026, 1, 3));
    expect(reservationDurationCount(start: dayStart, end: dayEnd, unit: 'day'), 2);

    final hourStart = DateTime(2026, 1, 1, 14);
    final hourEnd = reservationEndFromDuration(start: hourStart, unit: 'hour', count: 2);
    expect(hourEnd, DateTime(2026, 1, 1, 16));
    expect(reservationDurationCount(start: hourStart, end: hourEnd, unit: 'hour'), 2);
  });
}

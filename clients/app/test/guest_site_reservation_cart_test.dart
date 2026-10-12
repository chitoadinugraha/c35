import 'package:alienai_c35/c/site/guest_order_api.dart';
import 'package:alienai_c35/c/site/site_reservation_math.dart';
import 'package:alienai_c35/guest_site/guest_site_cart.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('day product 1 Jan to 3 Jan with 2 units stores billable qty 4', () {
    final start = DateTime(2026, 1, 1);
    final end = DateTime(2026, 1, 3);
    final durationQty = reservationDurationCount(start: start, end: end, unit: 'day');
    expect(durationQty, 2);

    final line = GuestSiteCartLine(
      productId: 11,
      name: 'Kamar',
      price: 100000,
      slots: [
        GuestReservationSlot(
          start: start,
          end: end,
          units: 2,
          durationQty: durationQty,
        ),
      ],
    );

    expect(line.qty, 4);
    expect(line.slots, hasLength(1));
    expect(line.reservationJson().single['duration_qty'], 2);
    expect(line.reservationJson().single['qty'], 2);
    expect(line.reservationJson().single['state'], 'pending');

    final body = guestOrderPutBody(
      siteIid: 9,
      customerName: 'Tamu',
      items: [line.orderItemJson()],
      reservations: line.reservationJson(),
    );
    final items = (body['tx'] as Map)['items'] as List;
    final item = items.single as Map;
    expect(item['qty'], 4);
    final reservations = item['reservations'] as List;
    expect(reservations, hasLength(1));
    expect((reservations.single as Map)['duration_qty'], 2);
    expect((body['reservations'] as List), hasLength(1));
  });

  test('guest picks two units expands to two reservation rows', () {
    final start = DateTime(2026, 6, 1);
    final end = DateTime(2026, 6, 2);
    final line = GuestSiteCartLine(
      productId: 5,
      name: 'Meja',
      price: 50000,
      slots: [
        GuestReservationSlot(
          start: start,
          end: end,
          units: 2,
          durationQty: 1,
          assignments: const [
            GuestReservationAssignment(siteObjectId: 101, objectName: 'A'),
            GuestReservationAssignment(siteObjectId: 102, objectName: 'B'),
          ],
        ),
      ],
    );
    final rows = line.reservationJson();
    expect(rows, hasLength(2));
    expect(rows[0]['qty'], 1);
    expect(rows[1]['qty'], 1);
    expect(rows[0]['site_object_id'], 101);
    expect(rows[1]['site_object_id'], 102);
    expect(line.qty, 2);
  });

  test('qty-only cart maps load as non-reservable lines', () {
    final lines = guestCartLinesFromJsonMap({'4': 2});
    expect(lines[4]!.qty, 2);
    expect(lines[4]!.slots, isEmpty);
    expect(lines[4]!.orderItemJson().containsKey('reservations'), isFalse);
  });
}

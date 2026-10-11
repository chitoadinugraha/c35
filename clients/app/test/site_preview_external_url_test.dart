import 'package:alienai_c35/c/site/site_preview_external_url.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('guestOrderTrackPollLabel', () {
    test('matches c35GuestOrder.poll precedence', () {
      expect(
        guestOrderTrackPollLabel({'progress_label': 'Diproses', 'state': 'pending', 'status': 'x'}),
        'Diproses',
      );
      expect(guestOrderTrackPollLabel({'state': 'waiting_payment'}), 'waiting_payment');
      expect(guestOrderTrackPollLabel({'status': 'ok'}), 'ok');
      expect(guestOrderTrackPollLabel({}), '—');
    });
  });
}

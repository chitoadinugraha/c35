import 'package:alienai_c35/c/site/guest_contact_api.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('guestContactPutBody matches guest-contact JSON wire shape', () {
    final body = guestContactPutBody(
      siteIid: 42,
      name: 'Budi',
      contactVal: '08123456789',
      message: 'Halo',
    );
    expect(body['site_iid'], 42);
    expect(body['name'], 'Budi');
    expect(body['contact_val'], '08123456789');
    expect(body['message'], 'Halo');
  });
}

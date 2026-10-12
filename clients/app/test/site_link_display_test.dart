import 'package:alienai_c35/c/site/site_link_display.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('normalize display modes', () {
    expect(siteLinkDisplayNormalize(''), siteLinkDisplayList);
    expect(siteLinkDisplayNormalize('ICON'), siteLinkDisplayIcon);
    expect(siteLinkDisplayNormalize('card'), siteLinkDisplayCard);
    expect(siteLinkDisplayNormalize('icon_label'), siteLinkDisplayList);
    expect(siteLinkDisplayNormalize('unknown'), siteLinkDisplayList);
  });
}

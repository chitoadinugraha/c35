import 'package:alienai_c35/c/share/share_inbound_payload.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('shareInboundKindFromPath detects image and video', () {
    expect(shareInboundKindFromPath('/tmp/photo.JPG'), ShareInboundKind.image);
    expect(shareInboundKindFromPath('/tmp/clip.mov'), ShareInboundKind.video);
    expect(shareInboundKindFromPath('/tmp/doc.pdf'), ShareInboundKind.other);
    expect(shareInboundKindFromPath('/x', mime: 'image/png'), ShareInboundKind.image);
  });
}

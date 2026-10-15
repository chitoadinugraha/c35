import 'package:alienai_c35/pages/mail/mail_html_sanitize.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('sanitizeMailHtml removes script and on* handlers', () {
    const raw = '<p>Hi</p><script>alert(1)</script><a href="javascript:evil()" onclick="x()">x</a>';
    final out = sanitizeMailHtml(raw);
    expect(out.toLowerCase().contains('<script'), isFalse);
    expect(out.contains('onclick'), isFalse);
    expect(out.contains('javascript:'), isFalse);
    expect(out.contains('Hi'), isTrue);
  });
}

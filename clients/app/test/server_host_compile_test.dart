import 'package:alienai_c35/c/conn/server_host.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('C35_SERVER compile value', () {
    expect(serverHostCompile, 'http://127.0.0.1:8080');
  });
}

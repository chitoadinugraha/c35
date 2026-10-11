import 'package:alienai_c35/c/conn/server_host.dart';
import 'package:alienai_c35/c/conn/server_host_port.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('C35_SERVER compile define defaults empty', () {
    expect(serverHostCompile, '');
  });

  test('local dev URL uses default server_ai port', () {
    expect(serverHostLocalUrl, 'http://127.0.0.1:$c35ServerHttpPort');
  });
}

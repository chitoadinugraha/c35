import 'package:alienai_c35/c/conn/server_host.dart';

Future<String> desktopWindowTitle() async {
  if (!serverHostPickerVisible()) return 'Alien AI';
  final host = await serverHostActiveBase();
  if (serverHostNormalize(host) == serverHostNormalize(serverHostProductionUrl)) return 'Alien AI';
  return '(dev: $host)';
}

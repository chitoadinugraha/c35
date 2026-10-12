import 'package:alienai_c35/c/config.dart';
import 'package:alienai_c35/c/conn/server_host.dart';

Future<String> desktopWindowTitle() async {
  if (!serverHostPickerVisible()) return 'Alien AI';
  final configured = C35Config.authApiBase.trim();
  final host = configured.isNotEmpty ? configured : await serverHostActiveBase();
  if (serverHostNormalize(host) == serverHostNormalize(serverHostProductionUrl)) return 'Alien AI';
  return 'Alien AI - ${serverHostLabelFromUrl(host)}';
}

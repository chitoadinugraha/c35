import 'package:alienai_c35/c/conn/server_host.dart';
import 'package:alienai_c35/c/parts/version_label.dart';

Future<String> desktopWindowTitle() async {
  final base = 'Alien AI ${appVersionLabel()}';
  if (!serverHostPickerVisible()) return base;
  final host = await serverHostActiveBase();
  if (serverHostNormalize(host) == serverHostNormalize(serverHostProductionUrl)) return base;
  return '$base (${serverHostLabelFromUrl(host)})';
}

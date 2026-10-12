import 'package:alienai_c35/c/conn/server_host.dart';

Future<String> desktopWindowTitle() async {
  if (!serverHostPickerVisible()) return 'Alien AI';
  // Match header host chip: prefs/active base, not [C35Config.authApiBase] (can lag before [serverHostInit]).
  final host = await serverHostActiveBase();
  if (serverHostNormalize(host) == serverHostNormalize(serverHostProductionUrl)) return 'Alien AI';
  return 'Alien AI - ${serverHostLabelFromUrl(host)}';
}

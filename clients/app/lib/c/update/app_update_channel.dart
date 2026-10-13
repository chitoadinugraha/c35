import 'package:shared_preferences/shared_preferences.dart';

enum AppUpdateChannel { play, apk }

const _channelKey = 'app_update_channel';

Future<AppUpdateChannel> appUpdateChannelGet() async {
  final p = await SharedPreferences.getInstance();
  final raw = (p.getString(_channelKey) ?? 'play').trim().toLowerCase();
  if (raw == 'apk') return AppUpdateChannel.apk;
  return AppUpdateChannel.play;
}

Future<void> appUpdateChannelPut(AppUpdateChannel channel) async {
  final p = await SharedPreferences.getInstance();
  await p.setString(_channelKey, channel == AppUpdateChannel.apk ? 'apk' : 'play');
}

Future<void> appUpdateChannelPreferApk() => appUpdateChannelPut(AppUpdateChannel.apk);

String appUpdateChannelStorageValue(AppUpdateChannel channel) => channel == AppUpdateChannel.apk ? 'apk' : 'play';

AppUpdateChannel appUpdateChannelParse(String? raw) {
  if (raw != null && raw.trim().toLowerCase() == 'apk') return AppUpdateChannel.apk;
  return AppUpdateChannel.play;
}
